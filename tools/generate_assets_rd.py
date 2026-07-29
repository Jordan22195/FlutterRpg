#!/usr/bin/env python3
"""Generate missing game art with the Retro Diffusion API.

The Dart source is the source of truth: this script scans `lib/**/*.dart` for
quoted `assets/...png` literals, checks each one against the filesystem, and
generates whatever doesn't exist yet. Four kinds of asset, split by path, each
with its own style and size:

    assets/icons/skills/**       skill icons   32x32   rd_fast__mc_item
    assets/icons/**              item icons    32x32   rd_fast__mc_item
    assets/images/entities/**    entity art   128x128  rd_fast__game_asset
    assets/images/{zones,dungeons}/**   scene art     -- no style chosen --

Scene art (zone headers, dungeon splashes) is a different job from an entity
sprite, and no style has been settled on for it. Those assets are reported but
never generated until you pass --scene-style and --scene-size explicitly.

Prompts come from the filename ("guam_leaf.png" -> "guam leaf"), overridden per
asset by `tools/rd_prompt_overrides.json` — filenames alone make weak prompts
for invented names, so tune them there rather than renaming assets. Note that
some names exist as BOTH an icon and an entity (a picked herb vs. the plant
growing in the ground), so override those by full path, not by filename.

Usage:
    export RETRO_DIFFUSION_API_KEY=rdpk-...
    python3 tools/generate_assets_rd.py --list       # inventory, no API calls
    python3 tools/generate_assets_rd.py --dry-run    # prompts + cost, no spend
    python3 tools/generate_assets_rd.py              # generate everything missing
    python3 tools/generate_assets_rd.py --kind entities   # just the entity art
    python3 tools/generate_assets_rd.py --only herb --limit 5
    python3 tools/generate_assets_rd.py --force      # redo existing files

Requires: pip install -r tools/requirements.txt  (Pillow; HTTP is stdlib)
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import re
import sys
import time
import ssl
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Missing dependency (Pillow). Run: pip install -r tools/requirements.txt")


# Repo layout: this file lives in <repo>/tools/, assets live in <repo>/assets/.
REPO_ROOT = Path(__file__).resolve().parent.parent
# Scan all of lib/, not just lib/catalogs/ — skill icons are referenced from
# lib/data/skill_data.dart, and any future asset reference should be found
# wherever it lives rather than needing this constant widened again.
SOURCE_DIR = REPO_ROOT / "lib"
DEFAULT_OVERRIDES = REPO_ROOT / "tools" / "rd_prompt_overrides.json"

API_BASE = "https://api.retrodiffusion.ai/v1"
KEY_ENV_VARS = ("RETRO_DIFFUSION_API_KEY", "RD_TOKEN")

ICON_STYLE = "rd_fast__mc_item"
ICON_SIZE = 32
# Skill icons share the item-icon style and size, but stay their own kind so
# they can be listed, filtered and re-rolled as a set — they're a UI row that
# has to read as one family, unlike the item icons.
SKILL_STYLE = "rd_fast__mc_item"
SKILL_SIZE = 32
ENTITY_STYLE = "rd_fast__game_asset"
ENTITY_SIZE = 128
# Scene art (zone headers, dungeon splashes) is a different job from an entity
# sprite — it's a place, not a subject on a plain background — and no style has
# been picked for it yet. Left unset on purpose: scene assets are reported but
# never generated until --scene-style and --scene-size are passed explicitly.
SCENE_STYLE = None
SCENE_SIZE = None

# Appended to filename-derived prompts. Retro Diffusion's guidance is to describe
# the subject only — never the words "pixel art" — so these stay about content.
ICON_SUFFIX = "single fantasy RPG inventory item on a plain background"
SKILL_SUFFIX = "single emblem representing the skill, on a plain background"
ENTITY_SUFFIX = "single fantasy RPG creature or object, centered, side view"
SCENE_SUFFIX = "fantasy RPG location"

# Which kind an asset is, decided by its path prefix. Order matters: first match
# wins, so skills/ must be tested before the icons/ catch-all and entities/
# before images/. Anything unmatched is reported rather than guessed at.
KIND_PREFIXES = (
    ("skills", "assets/icons/skills/"),
    ("icons", "assets/icons/"),
    ("entities", "assets/images/entities/"),
    ("scenes", "assets/images/"),
)
KIND_NAMES = tuple(name for name, _ in KIND_PREFIXES)
# CLI flag stem per kind — not just kind[:-1], which mangles "entities".
KIND_FLAGS = {"skills": "skill", "icons": "icon",
              "entities": "entity", "scenes": "scene"}

# Any quoted string that looks like an asset path, e.g. "assets/icons/items/x.png".
ASSET_RE = re.compile(r"""['"](assets/[A-Za-z0-9_./-]+\.png)['"]""")


@dataclass
class Asset:
    rel: str              # repo-relative path, e.g. "assets/icons/items/guam_leaf.png"
    sources: list[str]    # catalog files that reference it, for reporting

    @property
    def path(self) -> Path:
        return REPO_ROOT / self.rel

    @property
    def filename(self) -> str:
        return os.path.basename(self.rel)

    @property
    def stem(self) -> str:
        return os.path.splitext(self.filename)[0]

    @property
    def kind(self) -> str | None:
        """One of KIND_NAMES, or None for a path under no known prefix."""
        for name, prefix in KIND_PREFIXES:
            if self.rel.startswith(prefix):
                return name
        return None

    def exists(self) -> bool:
        """Case-sensitive existence check.

        macOS is case-insensitive, so a plain `Path.exists()` happily matches
        `copper_ore.png` against a reference to `COPPER_ORE.png` — which then
        fails to load on Android/iOS builds. Compare against the real directory
        listing so a case mismatch surfaces as missing here instead of in game.
        """
        parent = self.path.parent
        if not parent.is_dir():
            return False
        return self.filename in os.listdir(parent)


def scan_sources(source_dir: Path) -> list[Asset]:
    """Collect every asset path referenced by the Dart source, deduplicated."""
    found: dict[str, Asset] = {}
    for dart in sorted(source_dir.rglob("*.dart")):
        for match in ASSET_RE.finditer(dart.read_text()):
            rel = match.group(1)
            asset = found.setdefault(rel, Asset(rel, []))
            name = dart.relative_to(source_dir).as_posix()
            if name not in asset.sources:
                asset.sources.append(name)
    return [found[k] for k in sorted(found)]


def load_overrides(path: Path) -> dict[str, dict]:
    """Load per-asset prompt overrides, normalizing each value to a dict.

    A value may be a bare prompt string or an object with any of
    `prompt`, `seed`, `style`, `size`, `remove_bg`.
    """
    if not path.exists():
        return {}
    raw = json.loads(path.read_text())
    out: dict[str, dict] = {}
    for key, value in raw.items():
        if key.startswith("//") or key.startswith("_"):
            continue  # comment keys
        out[key] = {"prompt": value} if isinstance(value, str) else dict(value)
    return out


def override_for(asset: Asset, overrides: dict[str, dict]) -> dict:
    """Look up an override by repo-relative path, then filename, then stem."""
    for key in (asset.rel, asset.filename, asset.stem):
        if key in overrides:
            return overrides[key]
    return {}


def build_prompt(asset: Asset, override: dict, suffix: str) -> str:
    """Filename-derived prompt, replaced wholesale by an override when present."""
    prompt = override.get("prompt") or asset.stem.replace("_", " ").lower()
    if suffix and not override.get("prompt"):
        return f"{prompt}, {suffix}"
    return prompt


@dataclass
class Plan:
    """One asset with its style/size/prompt fully resolved, ready to send."""
    asset: Asset
    prompt: str
    style: str
    size: int
    seed: int | None
    remove_bg: bool
    from_override: bool

    @property
    def shape(self) -> tuple[str, int]:
        """Requests with the same shape cost the same and preflight together."""
        return (self.style, self.size)


def build_plans(assets: list[Asset], overrides: dict[str, dict],
                settings: dict[str, dict], seed: int | None,
                remove_bg: bool) -> list[Plan]:
    """Resolve each asset's kind defaults, then layer its override on top."""
    plans = []
    for asset in assets:
        kind = settings[asset.kind]
        ov = override_for(asset, overrides)
        plans.append(Plan(
            asset=asset,
            prompt=build_prompt(asset, ov, kind["suffix"]),
            style=ov.get("style", kind["style"]),
            size=int(ov.get("size", kind["size"])),
            seed=ov.get("seed", seed),
            remove_bg=ov.get("remove_bg", remove_bg),
            from_override=bool(ov.get("prompt")),
        ))
    return plans


# --- API ---------------------------------------------------------------------

def api_key() -> str | None:
    for var in KEY_ENV_VARS:
        if os.environ.get(var):
            return os.environ[var]
    return None


def ssl_context() -> ssl.SSLContext:
    """Verified TLS context, falling back to certifi's bundle.

    python.org builds on macOS ship without a wired-up CA bundle unless you run
    "Install Certificates.command", so the system default fails to verify. Use
    certifi's bundle when the default has no cafile rather than skipping
    verification.
    """
    if ssl.get_default_verify_paths().cafile:
        return ssl.create_default_context()
    try:
        import certifi
    except ImportError:
        return ssl.create_default_context()
    return ssl.create_default_context(cafile=certifi.where())


def api_post(path: str, body: dict, key: str, timeout: int = 180) -> dict:
    """POST JSON to the API, raising RuntimeError with the server's message."""
    req = urllib.request.Request(
        f"{API_BASE}{path}",
        data=json.dumps(body).encode(),
        headers={"X-RD-Token": key, "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=ssl_context()) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")[:500]
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from None
    except urllib.error.URLError as exc:
        raise RuntimeError(f"network error: {exc.reason}") from None


def api_post_with_retry(path: str, body: dict, key: str, attempts: int = 3) -> dict:
    """Retry 429 (rate limit) and 5xx (server, charges refunded) with backoff."""
    delay = 5.0
    for attempt in range(1, attempts + 1):
        try:
            return api_post(path, body, key)
        except RuntimeError as exc:
            retryable = re.match(r"HTTP (429|5\d\d):", str(exc)) or "network error" in str(exc)
            if not retryable or attempt == attempts:
                raise
            print(f"    retrying in {delay:.0f}s ({exc})", file=sys.stderr)
            time.sleep(delay)
            delay *= 2
    raise AssertionError("unreachable")


def inference_body(prompt: str, style: str, size: int, seed: int | None,
                   remove_bg: bool) -> dict:
    body = {
        "prompt": prompt,
        "prompt_style": style,
        "width": size,
        "height": size,
        "num_images": 1,
        "remove_bg": remove_bg,
    }
    if seed is not None:
        body["seed"] = seed
    return body


def preflight(body: dict, key: str) -> float | None:
    """Free dry run: validates style/size limits and returns the price.

    `check_cost` is charged nothing, so this catches "32x32 not supported by
    this style" before the batch spends anything.
    """
    resp = api_post("/inferences", {**body, "check_cost": True}, key)
    for field in ("balance_cost", "cost", "credit_cost", "price"):
        if isinstance(resp.get(field), (int, float)):
            return float(resp[field])
    return None


def generate(body: dict, key: str) -> Image.Image:
    resp = api_post_with_retry("/inferences", body, key)
    images = resp.get("base64_images") or []
    if not images:
        raise RuntimeError(f"no image in response: {json.dumps(resp)[:300]}")
    return Image.open(io.BytesIO(base64.b64decode(images[0]))).convert("RGBA")


def finalize(image: Image.Image, size: int, rel: str) -> Image.Image:
    """Guarantee the on-disk file is exactly `size` square.

    The style should already return the requested size; if a model tier ignores
    it, nearest-neighbour keeps the pixel grid crisp rather than blurring it.
    """
    if image.size != (size, size):
        print(f"    note: got {image.size[0]}x{image.size[1]}, "
              f"downscaling to {size}x{size} (nearest) for {rel}")
        image = image.resize((size, size), Image.NEAREST)
    return image


# --- reporting ---------------------------------------------------------------

def describe(cfg: dict) -> str:
    """How a kind will be generated, or why it won't be."""
    if not configured(cfg):
        return "no style chosen — pass --scene-style/--scene-size to generate"
    return f"{cfg['style']} @ {cfg['size']}x{cfg['size']}"


def configured(cfg: dict) -> bool:
    return bool(cfg.get("style")) and bool(cfg.get("size"))


def print_inventory(assets: list[Asset], settings: dict[str, dict]) -> None:
    for name in KIND_NAMES:
        group = [a for a in assets if a.kind == name]
        missing = [a for a in group if not a.exists()]
        print(f"{name}: {len(group)} referenced, {len(missing)} missing "
              f"[{describe(settings[name])}]")
        for a in missing:
            print(f"  - {a.rel}  ({', '.join(a.sources)})")

    unknown = [a for a in assets if a.kind is None]
    if unknown:
        print(f"\nunrecognized ({len(unknown)}) — not under any known prefix, "
              f"never generated:")
        for a in unknown:
            print(f"  ? {a.rel}  ({', '.join(a.sources)})")

    print(f"\ntotal: {len(assets)} referenced, "
          f"{sum(1 for a in assets if not a.exists())} missing")


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--list", action="store_true",
                        help="Print every catalog asset reference and what's missing, then exit.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print prompts and the API-reported cost without generating.")
    parser.add_argument("--force", action="store_true",
                        help="Regenerate even if the PNG already exists.")
    parser.add_argument("--only", metavar="SUBSTR",
                        help="Only assets whose path contains SUBSTR.")
    parser.add_argument("--limit", type=int, metavar="N", help="Process at most N assets.")
    parser.add_argument("--kind", choices=[*KIND_NAMES, "all"], default="all",
                        help="Which asset kind to generate (default: all "
                             "configured kinds).")
    parser.add_argument("--icon-style", default=ICON_STYLE,
                        help=f"prompt_style for assets/icons/** (default: {ICON_STYLE}).")
    parser.add_argument("--icon-size", type=int, default=ICON_SIZE,
                        help=f"Square size for icons (default: {ICON_SIZE}).")
    parser.add_argument("--icon-suffix", default=ICON_SUFFIX,
                        help="Appended to filename-derived icon prompts (not to overrides).")
    parser.add_argument("--skill-style", default=SKILL_STYLE,
                        help=f"prompt_style for assets/icons/skills/** "
                             f"(default: {SKILL_STYLE}).")
    parser.add_argument("--skill-size", type=int, default=SKILL_SIZE,
                        help=f"Square size for skill icons (default: {SKILL_SIZE}).")
    parser.add_argument("--skill-suffix", default=SKILL_SUFFIX,
                        help="Appended to filename-derived skill prompts (not to overrides).")
    parser.add_argument("--entity-style", default=ENTITY_STYLE,
                        help=f"prompt_style for assets/images/entities/** "
                             f"(default: {ENTITY_STYLE}).")
    parser.add_argument("--entity-size", type=int, default=ENTITY_SIZE,
                        help=f"Square size for entity art (default: {ENTITY_SIZE}).")
    parser.add_argument("--entity-suffix", default=ENTITY_SUFFIX,
                        help="Appended to filename-derived entity prompts (not to overrides).")
    parser.add_argument("--scene-style", default=SCENE_STYLE,
                        help="prompt_style for zone and dungeon art. No default — "
                             "scene assets are skipped until you pick one.")
    parser.add_argument("--scene-size", type=int, default=SCENE_SIZE,
                        help="Square size for zone and dungeon art. No default.")
    parser.add_argument("--scene-suffix", default=SCENE_SUFFIX,
                        help="Appended to filename-derived scene prompts (not to overrides).")
    parser.add_argument("--seed", type=int, help="Fixed seed for reproducible runs.")
    parser.add_argument("--no-remove-bg", action="store_true",
                        help="Keep the generated background instead of asking for transparency.")
    parser.add_argument("--overrides", default=str(DEFAULT_OVERRIDES), metavar="PATH",
                        help="JSON file of per-asset prompt overrides.")
    parser.add_argument("--sleep", type=float, default=0.0,
                        help="Seconds between assets, to ease rate limits.")
    parser.add_argument("--no-preflight", action="store_true",
                        help="Skip the free check_cost validation before generating.")
    args = parser.parse_args()

    if not SOURCE_DIR.is_dir():
        return _fail(f"Cannot find Dart source at {SOURCE_DIR}")

    assets = scan_sources(SOURCE_DIR)
    if not assets:
        return _fail(f"No asset paths found in {SOURCE_DIR}/**/*.dart")

    settings = {
        "skills": {"style": args.skill_style, "size": args.skill_size,
                   "suffix": args.skill_suffix},
        "icons": {"style": args.icon_style, "size": args.icon_size,
                  "suffix": args.icon_suffix},
        "entities": {"style": args.entity_style, "size": args.entity_size,
                     "suffix": args.entity_suffix},
        "scenes": {"style": args.scene_style, "size": args.scene_size,
                   "suffix": args.scene_suffix},
    }

    if args.list:
        print_inventory(assets, settings)
        return 0

    # A kind with no style/size can't be generated. Asking for it explicitly is
    # an error; sweeping it up in "all" just skips it with a note.
    if args.kind != "all" and not configured(settings[args.kind]):
        flag = KIND_FLAGS[args.kind]
        return _fail(f"no style chosen for '{args.kind}' — pass "
                     f"--{flag}-style and --{flag}-size.")

    wanted = {k for k in KIND_NAMES if configured(settings[k])}
    if args.kind != "all":
        wanted &= {args.kind}
    deferred = [a for a in assets if a.kind in set(KIND_NAMES) - wanted
                and not a.exists()]
    unknown = [a for a in assets if a.kind is None and not a.exists()]
    todo = [a for a in assets if a.kind in wanted]
    if args.only:
        todo = [a for a in todo if args.only.lower() in a.rel.lower()]
    if not args.force:
        todo = [a for a in todo if not a.exists()]
    if args.limit is not None:
        todo = todo[: args.limit]

    if args.kind == "all":
        for kind in KIND_NAMES:
            waiting = [a for a in deferred if a.kind == kind]
            if waiting:
                print(f"Skipping {len(waiting)} missing {kind} asset(s): "
                      f"{describe(settings[kind])}.")
    if unknown:
        print(f"Skipping {len(unknown)} missing asset(s) under no known "
              f"prefix — see --list.")
    if deferred or unknown:
        print()

    if not todo:
        print("Nothing to generate. (Use --force to regenerate existing files.)")
        return 0

    overrides = load_overrides(Path(args.overrides).expanduser())
    plans = build_plans(todo, overrides, settings, args.seed,
                        not args.no_remove_bg)

    print(f"{len(plans)} asset(s) to generate:")
    for kind in KIND_NAMES:
        group = [p for p in plans if p.asset.kind == kind]
        if not group:
            continue
        print(f"\n  {kind} — {describe(settings[kind])} ({len(group)}):")
        for p in group:
            tag = "" if p.from_override else "  (from filename)"
            print(f"    {p.asset.rel}\n        \"{p.prompt}\"{tag}")
    print()

    key = api_key()
    if key is None:
        msg = f"no API key; set {KEY_ENV_VARS[0]}"
        if args.dry_run:
            print(f"({msg} — cannot check cost, plan printed above)")
            return 0
        return _fail(f"{msg} (or {KEY_ENV_VARS[1]}).")

    # Free validation, once per distinct (style, size) — a batch now mixes
    # shapes, and each one has its own limits and its own price.
    if not args.no_preflight:
        total = 0.0
        priced = True
        for shape in dict.fromkeys(p.shape for p in plans):
            style, size = shape
            count = sum(1 for p in plans if p.shape == shape)
            sample = next(p for p in plans if p.shape == shape)
            body = inference_body(sample.prompt, style, size, sample.seed,
                                  sample.remove_bg)
            try:
                cost = preflight(body, key)
            except RuntimeError as exc:
                # Only a validation rejection implies the style/size pairing is
                # bad; auth and network failures say nothing about it.
                hint = ""
                if re.match(r"HTTP (400|422):", str(exc)):
                    hint = (f" — {style} may not accept {size}x{size}; "
                            f"try a different --*-size or --*-style")
                return _fail(f"preflight failed for {style} @ {size}x{size}: "
                             f"{exc}{hint}")
            if cost is None:
                priced = False
                print(f"  {style} @ {size}x{size}: OK ({count} image(s))")
            else:
                total += cost * count
                print(f"  {style} @ {size}x{size}: ~${cost:.4f} each, "
                      f"~${cost * count:.2f} for {count}")
        print(f"Preflight OK. Estimated total: ~${total:.2f}\n" if priced
              else "Preflight OK.\n")

    if args.dry_run:
        print("Dry run — nothing generated.")
        return 0

    failures = 0
    for i, plan in enumerate(plans, 1):
        asset = plan.asset
        print(f"[{i}/{len(plans)}] {asset.rel}  [{plan.style} @ "
              f"{plan.size}x{plan.size}]")
        try:
            body = inference_body(plan.prompt, plan.style, plan.size,
                                  plan.seed, plan.remove_bg)
            image = finalize(generate(body, key), plan.size, asset.rel)
            asset.path.parent.mkdir(parents=True, exist_ok=True)
            image.save(asset.path)
            print(f"    saved {asset.path.stat().st_size} bytes")
        except Exception as exc:  # one bad asset shouldn't stop the batch
            failures += 1
            print(f"    ERROR: {exc}", file=sys.stderr)

        if args.sleep and i < len(plans):
            time.sleep(args.sleep)

    print(f"\nDone. {len(plans) - failures} succeeded, {failures} failed.")
    return 1 if failures else 0


def _fail(msg: str) -> int:
    print(f"error: {msg}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
