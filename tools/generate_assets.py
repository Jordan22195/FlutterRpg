#!/usr/bin/env python3
"""Generate missing game art from assets/MISSING_ASSETS.md using the OpenAI API.

Two-step pipeline per asset:
  1. Feed the item name to a "prompt writer" system prompt (chat completion).
     The model returns a single optimized image prompt in a fixed style.
  2. Feed that optimized prompt to the image model (gpt-image-1) to render a
     transparent PNG, then write it into the correct asset folder.

Item icons are rendered at 1024x1024 and downscaled to 32x32 with nearest-
neighbour so the pixel-art stays crisp. Entity/zone art is kept at full size.

Usage (API, needs OpenAI API credit — separate from a ChatGPT subscription):
    export OPENAI_API_KEY=sk-...
    python3 tools/generate_assets.py                 # generate everything missing
    python3 tools/generate_assets.py --dry-run       # print prompts, write nothing
    python3 tools/generate_assets.py --only iron      # only names containing "iron"
    python3 tools/generate_assets.py --limit 5        # stop after 5 assets
    python3 tools/generate_assets.py --force          # regenerate even if file exists

Usage (ChatGPT GUI, uses your subscription — no API credit needed):
    python3 tools/generate_assets.py --emit-prompts  # write a paste-ready prompt pack
    # ...generate + download the images in the ChatGPT GUI, naming each file as
    #    shown in [brackets], into one folder, then file them into place:
    python3 tools/generate_assets.py --import ~/Downloads/rpg_assets

Requires:  pip install -r tools/requirements.txt
"""
from __future__ import annotations

import argparse
import base64
import io
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path

try:
    from openai import OpenAI
except ImportError:
    sys.exit("Missing dependency. Run: pip install -r tools/requirements.txt")

try:
    from PIL import Image
except ImportError:
    sys.exit("Missing dependency (Pillow). Run: pip install -r tools/requirements.txt")


# Repo layout: this file lives in <repo>/tools/, assets live in <repo>/assets/.
REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_ROOT = REPO_ROOT / "assets"
MISSING_MD = ASSETS_ROOT / "MISSING_ASSETS.md"

ICON_SIZE = 1254  # final on-disk size for inventory icons

# Shared style rules. Tuned for image models: forbid the things they add
# unprompted (backgrounds, frames, shadows, text, multiple objects) and, for
# icons, design for readability AFTER a 1024->32 downscale (bold silhouette,
# few large shapes, thick outline, high contrast). These rules are reused by
# both the API framing (return prompt text) and the GUI framing (draw directly).
ICON_STYLE_BODY = (
    "Permanent style rules — apply ALL of them:\n"
    "- Subject: exactly ONE item, centered, filling ~80% of the frame, shown from "
    "a consistent slight 3/4 top-down angle.\n"
    "- Format: true pixel art on a 32x32 pixel grid, chunky oversized pixels, a "
    "bold readable silhouette built from a few large shapes; omit fine detail that "
    "would vanish when shrunk.\n"
    "- Outline: clean dark 1-pixel outline around the whole silhouette for contrast "
    "against a transparent background.\n"
    "- Color: limited, warm, cohesive palette; 3-4 flat value steps per material; "
    "no gradients.\n"
    "- Lighting: single consistent light source from the top-left, with a subtle "
    "rim/glow highlight on the upper edge.\n"
    "- Sparkle: at most 2-3 tiny sparkle/dust pixels, never covering the item.\n"
    "- Background: FULLY TRANSPARENT — no scene, no ground, no cast shadow, no "
    "frame, no border, no card, no backdrop of any kind.\n"
    "- Rendering: crisp hard pixel edges, no anti-aliasing, no blur, no drop "
    "shadow, no gradient, no 3D render look.\n"
    "- Forbidden: any text, letters, numbers, watermark, UI, or more than one item.\n"
    "- The result must sit in a cohesive matching icon set."
)

SCENE_STYLE_BODY = (
    "Permanent style rules — apply ALL of them:\n"
    "- Subject: ONE clear subject, centered and large in frame, instantly "
    "recognizable at a glance.\n"
    "- Style: cozy stylized hand-painted fantasy illustration, soft painterly "
    "brushwork, warm inviting lighting, gentle ambient occlusion and soft rim light.\n"
    "- Palette: rich but harmonious, warm-leaning colors that read as one set.\n"
    "- Composition: minimal, uncluttered surroundings that support the subject; "
    "shallow depth; subject isolated as a clean cutout.\n"
    "- Background: TRANSPARENT around the subject — no frame, no border, no "
    "vignette, no ground plane, no cast shadow.\n"
    "- Forbidden: any text, letters, numbers, watermark, UI, maps, or a collage "
    "of multiple scenes.\n"
    "- The result must sit in a cohesive matching set of RPG art."
)

# --- API framing: chat returns prompt TEXT, which step 2 renders separately. ---
ICON_SYSTEM_PROMPT = (
    "You are a professional pixel-art asset generator for a cozy fantasy RPG. "
    "You write ONE optimized image-generation prompt for a single inventory icon "
    "that must stay crisp and instantly readable when shrunk to 32x32 pixels.\n\n"
    + ICON_STYLE_BODY + "\n\n"
    "When I give you an item name (and an optional category for context), infer "
    "that item's material, shape, and signature colors, then write ONE final "
    "optimized prompt describing THAT specific item in the exact style above. "
    "Output ONLY the final prompt text — no preamble, no quotes, no explanation."
)

SCENE_SYSTEM_PROMPT = (
    "You are a professional illustration prompt-writer for a cozy fantasy RPG. "
    "You write ONE optimized image-generation prompt for a single scene or "
    "creature portrait that matches the game's warm storybook art.\n\n"
    + SCENE_STYLE_BODY + "\n\n"
    "When I give you a subject name (and an optional category for context), infer "
    "what it is in a fantasy RPG setting and write ONE final optimized prompt "
    "describing THAT specific subject in the exact style above. Output ONLY the "
    "final prompt text — no preamble, no quotes, no explanation."
)

# --- GUI framing: ChatGPT composes the prompt silently and DRAWS the image
# itself, so there is nothing to copy-paste. Used only in the prompt pack. ---
ICON_GUI_PROMPT = (
    "You are my pixel-art asset generator, and you create the images yourself. "
    "For each item I list, do BOTH steps in one go — without asking me first and "
    "without printing the prompt text: (1) silently compose ONE optimized image "
    "prompt that follows the style rules below; (2) immediately generate the image "
    "directly from that prompt. Produce exactly one image per item, working through "
    "the list in order. Directly above each image print only its [filename] label "
    "(e.g. [iron_helmet.png]) so I know what to save it as.\n\n"
    + ICON_STYLE_BODY + "\n\n"
    "Acknowledge with one short line, then wait for the numbered item list and "
    "generate every image. If you can only render a few per turn, keep going when "
    "I say \"continue\" until the list is done."
)

SCENE_GUI_PROMPT = (
    "You are my fantasy RPG scene-art generator, and you create the images "
    "yourself. For each subject I list, do BOTH steps in one go — without asking me "
    "first and without printing the prompt text: (1) silently compose ONE optimized "
    "image prompt that follows the style rules below; (2) immediately generate the "
    "image directly from that prompt. Produce exactly one image per subject, working "
    "through the list in order. Directly above each image print only its [filename] "
    "label (e.g. [river.png]) so I know what to save it as.\n\n"
    + SCENE_STYLE_BODY + "\n\n"
    "Acknowledge with one short line, then wait for the numbered item list and "
    "generate every image. If you can only render a few per turn, keep going when "
    "I say \"continue\" until the list is done."
)


@dataclass
class Asset:
    name: str            # human-readable, e.g. "iron helmet"
    filename: str        # e.g. "iron_helmet.png"
    dest_dir: Path       # absolute folder the PNG belongs in
    is_icon: bool        # True -> 32x32 pixel-art icon pipeline
    category: str = ""   # nearest label in the md, e.g. "Tier 2 armor" (context)
    note: str = ""       # inline parenthetical on the checklist line, if any

    @property
    def dest_path(self) -> Path:
        return self.dest_dir / self.filename


# Matches a section header like:  ## Item icons — `assets/icons/items/`
# Group 1 = title ("Item icons"), group 2 = path.
HEADER_RE = re.compile(r"^#{2,}\s*(.*?)\s*[—-]\s*`([^`]+)`")
# Matches a checklist entry like:  - [ ] iron_helmet.png (some note)
# Group 1 = filename, group 2 = optional parenthetical note.
ITEM_RE = re.compile(r"^\s*-\s*\[[ xX]?\]\s*([A-Za-z0-9_./-]+\.png)\s*(?:\((.*)\))?")
# Matches a category label line like:  Tier 2 armor:  or  Gems (mining drops):
LABEL_RE = re.compile(r"^([A-Za-z0-9][A-Za-z0-9 /'-]+?)\s*(?:\(.*\))?\s*:\s*$")


def parse_missing(md_path: Path) -> list[Asset]:
    """Parse MISSING_ASSETS.md into a flat list of assets to generate.

    The target folder is taken from the most recent `path` in a section header;
    checklist lines below it are the files that belong in that folder.
    """
    assets: list[Asset] = []
    current_dir: Path | None = None
    current_title = ""   # from the section header, e.g. "Zone images"
    current_label = ""   # from a sub-label line, e.g. "Tier 2 armor"

    for raw in md_path.read_text().splitlines():
        header = HEADER_RE.match(raw)
        if header:
            current_title = header.group(1).strip()
            rel = header.group(2).strip().strip("/")  # e.g. "assets/icons/items"
            # Header paths are repo-relative and start with "assets/".
            current_dir = (REPO_ROOT / rel).resolve()
            current_label = ""
            continue

        item = ITEM_RE.match(raw)
        if item and current_dir is not None:
            filename = os.path.basename(item.group(1))
            name = os.path.splitext(filename)[0].replace("_", " ")
            is_icon = "icons" in current_dir.parts
            note = (item.group(2) or "").strip()
            # Prefer the specific sub-label; fall back to the section title.
            category = current_label or current_title
            assets.append(Asset(name, filename, current_dir, is_icon, category, note))
            continue

        # A label line (e.g. "Tier 2 armor:") gives context for the items below it.
        label = LABEL_RE.match(raw)
        if label:
            current_label = label.group(1).strip()

    return assets


def build_user_message(asset: Asset, oneline: bool = False) -> str:
    """The name + context we hand to the prompt writer (or list in the pack)."""
    label = "Item name" if asset.is_icon else "Subject name"
    sep = " | " if oneline else "\n"
    parts = [f"{label}: {asset.name}"]
    if asset.category:
        parts.append(f"Category: {asset.category}")
    if asset.note:
        parts.append(f"Note: {asset.note}")
    return sep.join(parts)


def write_optimized_prompt(client: OpenAI, asset: Asset, model: str) -> str:
    """Step 1: turn a bare item name (+ category) into an optimized image prompt."""
    system = ICON_SYSTEM_PROMPT if asset.is_icon else SCENE_SYSTEM_PROMPT
    resp = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": build_user_message(asset)},
        ],
    )
    return resp.choices[0].message.content.strip()


def generate_image(client: OpenAI, prompt: str, image_model: str) -> Image.Image:
    """Step 2: render the optimized prompt to an RGBA image."""
    resp = client.images.generate(
        model=image_model,
        prompt=prompt,
        size="1024x1024",
        background="transparent",
        n=1,
    )
    png_bytes = base64.b64decode(resp.data[0].b64_json)
    return Image.open(io.BytesIO(png_bytes)).convert("RGBA")


def finalize(image: Image.Image, asset: Asset) -> Image.Image:
    """Downscale icons to 32x32 with nearest-neighbour; leave scenes full-size."""
    if asset.is_icon:
        return image.resize((ICON_SIZE, ICON_SIZE), Image.NEAREST)
    return image


def _rel(path: Path) -> str:
    """Repo-relative path for display, falling back to the full path."""
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def emit_prompts(assets: list[Asset], out: Path) -> None:
    """Write a paste-ready pack for the ChatGPT GUI (no API needed).

    Icons and scenes use different framings, so they get separate blocks. In each
    block you paste the INSTRUCTION, then the numbered ITEM LIST; ChatGPT composes
    each prompt silently and generates the image directly — nothing to copy-paste.
    """
    icons = [a for a in assets if a.is_icon]
    scenes = [a for a in assets if not a.is_icon]
    lines: list[str] = [
        "# Asset prompt pack",
        "",
        "Workflow: for each block below, start a new ChatGPT chat, paste the",
        "INSTRUCTION, then paste the numbered ITEM LIST. ChatGPT writes each prompt",
        "itself and generates the image directly — you do NOT copy any prompt back.",
        "Each image is labeled with its [filename]; download it under that exact",
        "name into one folder, then run:",
        "    python3 tools/generate_assets.py --import <download_folder>",
        "",
    ]

    for title, group, instruction in (
        ("ICON BLOCK", icons, ICON_GUI_PROMPT),
        ("SCENE BLOCK", scenes, SCENE_GUI_PROMPT),
    ):
        if not group:
            continue
        lines += [f"{'=' * 70}", f"{title}  ({len(group)} assets)", f"{'=' * 70}",
                  "", "--- INSTRUCTION (paste first) ---", "", instruction, "",
                  "--- ITEM LIST (paste second) ---", ""]
        for i, a in enumerate(group, 1):
            lines.append(f"{i}. [{a.filename}]  {build_user_message(a, oneline=True)}")
        lines.append("")

    out.write_text("\n".join(lines))
    print(f"Wrote prompt pack for {len(assets)} assets to {out}")


def import_images(assets: list[Asset], src_dir: Path, force: bool) -> int:
    """File downloaded PNGs into the correct asset folders (no API needed).

    Matches each PNG in src_dir to an asset by filename (a leading number and
    separators are ignored, so "12_iron_helmet.png" or "iron helmet.png" match
    iron_helmet.png), downscales icons to 32x32, and writes to the dest folder.
    """
    def key(fn: str) -> str:
        stem = os.path.splitext(fn)[0].lower()
        stem = re.sub(r"^\d+[\s._-]*", "", stem)          # drop leading "12_" etc.
        return re.sub(r"[\s._-]+", "", stem)               # normalize separators

    by_key = {key(a.filename): a for a in assets}
    imported = failures = skipped = 0

    for src in sorted(src_dir.glob("*.png")):
        asset = by_key.get(key(src.name))
        if asset is None:
            print(f"  ? no match for {src.name}", file=sys.stderr)
            failures += 1
            continue
        if asset.dest_path.exists() and not force:
            print(f"  = skip {asset.filename} (exists; use --force)")
            skipped += 1
            continue
        try:
            image = finalize(Image.open(src).convert("RGBA"), asset)
            asset.dest_dir.mkdir(parents=True, exist_ok=True)
            image.save(asset.dest_path)
            print(f"  + {src.name}  ->  {_rel(asset.dest_path)}")
            imported += 1
        except Exception as exc:
            print(f"  ! {src.name}: {exc}", file=sys.stderr)
            failures += 1

    print(f"\nImported {imported}, skipped {skipped}, failed {failures}.")
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true",
                        help="Print the optimized prompts but do not call the image API or write files.")
    parser.add_argument("--force", action="store_true",
                        help="Regenerate assets even if the target PNG already exists.")
    parser.add_argument("--only", metavar="SUBSTR",
                        help="Only process assets whose filename contains SUBSTR.")
    parser.add_argument("--limit", type=int, metavar="N",
                        help="Process at most N assets this run.")
    parser.add_argument("--text-model", default="gpt-4o",
                        help="Chat model that writes the optimized prompt (default: gpt-4o).")
    parser.add_argument("--image-model", default="gpt-image-1",
                        help="Image model (default: gpt-image-1).")
    parser.add_argument("--sleep", type=float, default=0.0,
                        help="Seconds to sleep between assets to ease rate limits.")
    parser.add_argument("--emit-prompts", nargs="?", const="tools/asset_prompts.txt",
                        metavar="PATH",
                        help="No API: write a paste-ready prompt pack for the ChatGPT "
                             "GUI (default PATH: tools/asset_prompts.txt) and exit.")
    parser.add_argument("--import", dest="import_dir", metavar="DIR",
                        help="No API: file PNGs you downloaded from the GUI in DIR into "
                             "the correct asset folders (downscaling icons to 32x32).")
    args = parser.parse_args()

    if not MISSING_MD.exists():
        return _fail(f"Cannot find {MISSING_MD}")

    assets = parse_missing(MISSING_MD)
    if args.only:
        assets = [a for a in assets if args.only.lower() in a.filename.lower()]

    # No-API modes: prompt pack and import. These run against the full missing
    # list (minus --only) and exit before any network call.
    if args.emit_prompts is not None:
        emit_prompts(assets, (REPO_ROOT / args.emit_prompts).resolve())
        return 0
    if args.import_dir:
        src = Path(args.import_dir).expanduser().resolve()
        if not src.is_dir():
            return _fail(f"--import dir not found: {src}")
        return import_images(assets, src, args.force)

    if not args.force:
        assets = [a for a in assets if not a.dest_path.exists()]
    if args.limit is not None:
        assets = assets[: args.limit]

    if not assets:
        print("Nothing to generate. (Use --force to regenerate existing files.)")
        return 0

    print(f"{len(assets)} asset(s) to generate:")
    for a in assets:
        kind = "icon" if a.is_icon else "scene"
        print(f"  [{kind}] {_rel(a.dest_path)}")
    print()

    client = None
    if not args.dry_run:
        if not os.environ.get("OPENAI_API_KEY"):
            return _fail("OPENAI_API_KEY is not set.")
        client = OpenAI()
    else:
        # Dry-run still needs a client for step 1 (prompt writing) unless the
        # key is absent, in which case we only print the plan above.
        if os.environ.get("OPENAI_API_KEY"):
            client = OpenAI()

    failures = 0
    for i, asset in enumerate(assets, 1):
        rel = _rel(asset.dest_path)
        print(f"[{i}/{len(assets)}] {asset.name}  ->  {rel}")
        try:
            if client is None:
                print("    (no API key; skipping prompt + image)")
                continue

            prompt = write_optimized_prompt(client, asset, args.text_model)
            print(f"    prompt: {prompt}")

            if args.dry_run:
                continue

            image = finalize(generate_image(client, prompt, args.image_model), asset)
            asset.dest_dir.mkdir(parents=True, exist_ok=True)
            image.save(asset.dest_path)
            print(f"    saved {asset.dest_path.stat().st_size} bytes")
        except Exception as exc:  # keep going; one bad asset shouldn't stop the batch
            failures += 1
            print(f"    ERROR: {exc}", file=sys.stderr)

        if args.sleep and i < len(assets):
            time.sleep(args.sleep)

    print()
    done = len(assets) - failures
    print(f"Done. {done} succeeded, {failures} failed.")
    return 1 if failures else 0


def _fail(msg: str) -> int:
    print(f"error: {msg}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
