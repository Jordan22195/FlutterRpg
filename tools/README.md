# tools

## generate_assets_rd.py

Generates missing art via the [Retro Diffusion](https://www.retrodiffusion.ai)
API. Unlike `generate_assets.py`, the **catalogs are the source of truth** —
nothing to keep in sync by hand.

1. Scans `lib/**/*.dart` for quoted `assets/…png` literals — the whole source
   tree, since item art is referenced from `lib/catalogs/` but skill art from
   `lib/data/skill_data.dart`.
2. Checks each against disk (case-sensitively, so a `COPPER_ORE.png` vs
   `copper_ore.png` mismatch surfaces here instead of breaking on device).
3. Generates whatever is missing, on a transparent background, into its
   referenced path.

Four kinds of asset, split by path, each with its own style and size:

| Path | Kind | Size | Style |
| --- | --- | --- | --- |
| `assets/icons/skills/**` | skill icons | 32×32 | `rd_fast__mc_item` |
| `assets/icons/**` | item icons | 32×32 | `rd_fast__mc_item` |
| `assets/images/entities/**` | entity art | 128×128 | `rd_fast__game_asset` |
| `assets/images/zones/**`, `assets/images/dungeons/**` | scene art | — | *not chosen yet* |

Skill icons share the item-icon style but stay a separate kind, so you can list,
filter and re-roll the whole skills row as a set (`--kind skills`) — they have to
read as one family in the UI in a way the item icons don't.

**Scene art is deliberately unconfigured.** A zone header or dungeon splash is a
*place*, not a subject on a plain background, and no style has been settled on
for it. Those assets are listed but never generated — a normal run skips them
with a note, and `--kind scenes` exits 2 until you pass both `--scene-style` and
`--scene-size`:

```bash
python3 tools/generate_assets_rd.py --kind scenes \
    --scene-style rd_plus__environment --scene-size 256 --dry-run
```

Once you've picked one, set `SCENE_STYLE` / `SCENE_SIZE` at the top of the
script so it becomes the default. Anything outside all three prefixes is
reported by `--list` and never generated.

```bash
pip install -r tools/requirements.txt
export RETRO_DIFFUSION_API_KEY=rdpk-...        # or RD_TOKEN

python3 tools/generate_assets_rd.py --list      # inventory, no API calls
python3 tools/generate_assets_rd.py --dry-run   # prompts + total cost, no spend
python3 tools/generate_assets_rd.py             # generate everything missing
python3 tools/generate_assets_rd.py --kind entities   # one kind only
python3 tools/generate_assets_rd.py --only herb --limit 5
python3 tools/generate_assets_rd.py --force --only ruby_ring   # re-roll one
```

`--dry-run` uses the API's free `check_cost` mode. It runs once per distinct
style+size in the batch, so it validates each combination and prints a real
per-kind and total price before you spend anything.

Other flags: `--kind`, `--seed`, `--no-remove-bg`, `--sleep`, `--overrides`,
`--no-preflight`, and `--{icon,skill,entity,scene}-{style,size,suffix}`.

### Prompts

A filename becomes a prompt by default (`pitchfork.png` → "pitchfork, single
fantasy RPG inventory item…"). That's useless for invented names, so
[`rd_prompt_overrides.json`](rd_prompt_overrides.json) maps an asset to a
hand-written prompt — keyed by repo-relative path, filename, or bare stem,
checked in that order:

```json
{
  "guam_leaf.png": "a small bundle of pale green herb leaves tied with twine",
  "ruby_ring.png": { "prompt": "a gold ring set with a ruby", "seed": 12345 }
}
```

An override replaces the whole prompt (the kind's suffix is **not** appended).
Pin a `seed` on an asset you're happy with so `--force` re-rolls stay stable;
`style`, `size`, and `remove_bg` can be overridden per asset too.

**Key colliding names by full path.** Several stems exist as both an icon and an
entity — `cadantine`, `lantadyme`, `dwarf_weed`, `torstol`, `spider_den` and
others. The icon is the picked object, the entity is what stands in the world,
so a bare `"cadantine.png"` key would put "a bundle of leaves tied with twine"
on the plant node too. The shipped file keys all of those by full path.

Pre-filled: **every referenced asset** — all item icons, all 20 skill icons, all
entity art, and the 5 scenes. Sets are written to stay coherent (copper gear all
warm orange, iron all cold grey, each gem's color reused by its ring and
necklace, each herb's color matched between its item icon and its plant node).
The scene prompts are written but unused until a scene style is chosen.

## generate_assets.py

Generates the missing art listed in [`assets/MISSING_ASSETS.md`](../assets/MISSING_ASSETS.md)
via the OpenAI API and writes each PNG into the folder named by its section header.

For every checklist entry it:
1. Turns the filename into an item name (`iron_helmet.png` → "iron helmet").
2. Sends that name to a "prompt writer" system prompt (chat) that returns one
   optimized image prompt in a fixed pixel-art (icons) or scene (entities/zones) style.
3. Renders the prompt with `gpt-image-1` on a transparent background.
4. Downscales icons to 32×32 nearest-neighbour (scenes keep full size) and saves.

```bash
pip install -r tools/requirements.txt
```

There are two ways to run it, depending on what you want to pay with.

### Option A — API (needs OpenAI API credit)

A ChatGPT Plus/Pro **subscription does not include API access** — the API is billed
separately, so this path needs credit on the account behind your key.

```bash
export OPENAI_API_KEY=sk-...
python3 tools/generate_assets.py                # generate everything still missing
python3 tools/generate_assets.py --dry-run      # print the optimized prompts only
python3 tools/generate_assets.py --only iron    # filter by filename substring
python3 tools/generate_assets.py --limit 5      # cap this run
python3 tools/generate_assets.py --force        # regenerate even if the file exists
```

Only files that don't yet exist on disk are generated, so it's safe to re-run.

### Option B — ChatGPT GUI (uses your subscription, no API credit)

1. Write a paste-ready prompt pack (no key needed):
   ```bash
   python3 tools/generate_assets.py --emit-prompts   # -> tools/asset_prompts.txt
   ```
2. Open `tools/asset_prompts.txt`. For each block, start a new ChatGPT chat, paste
   the SYSTEM PROMPT, then the numbered ITEM LIST. ChatGPT returns one optimized
   prompt per line. Generate each image, and **download it named exactly as the
   `[filename]`** shown for that line, into a single folder.
3. File them into the correct asset folders (downscales icons to 32×32):
   ```bash
   python3 tools/generate_assets.py --import ~/Downloads/rpg_assets
   ```
   Matching ignores a leading number and separators, so `20_iron_helmet.png` or
   `iron helmet.png` still map to `iron_helmet.png`. Use `--force` to overwrite.

After either path, review the output and tick items off `MISSING_ASSETS.md`.
