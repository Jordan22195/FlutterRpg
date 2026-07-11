# tools

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
