# Missing asset files

Art referenced by the catalogs that does not exist on disk yet.
Each file below renders as a broken-image placeholder in game until added.

**The authoritative list is now generated, not hand-maintained.** Run:

```
python3 tools/generate_assets_rd.py --list
```

`test/catalog_integrity_test.dart` asserts the same set via its
`knownMissingArt` allowlist, and fails if an entry there has quietly been
drawn — so that allowlist and this file should only ever shrink.

Verified against actual references in `lib/catalogs/**` on 2026-08-20 — the
catalogs moved to one file per type and the item/entity definitions now hang
off their id enums, so references live in `lib/catalogs/items/item_id.dart`
and friends rather than one big map.

## New this pass — the steel and mithril tiers

The 31 `ItemId` values that had no definition now have one, so their icons are
referenced and generatable. Prompts for all of them are in
`tools/rd_prompt_overrides.json`.

Ores and bars: `gold_ore`, `mithril_ore`, `adamantite_ore`, `runeite_ore`,
`steel_bar`, `gold_bar`, `mithril_bar`, `adamantite_bar`, `runite_bar`.

Steel set: `steel_helmet`, `steel_chestplate`, `steel_legs`, `steel_boots`,
`steel_gloves`, `steel_shield`, `steel_dagger`, `steel_axe`, `steel_pickaxe`,
`steel_sickle`.

Mithril set: the same ten slots, `mithril_*`.

Boss unique: `goblin_scepter` — the Goblin Queen's second guaranteed drop, and
the Wandering Merchant's stock item. Until this pass it had no definition at
all, so both handed the player a junk "Null" item.

## Known wrong art (not missing, just wrong)

- `GOLD_RING` and `GOLD_NECKLACE` display as gold and are consumed as gold
  bases by the jewelcrafting recipes, but still point at `copper_ring.png` and
  `copper_necklace.png`. Point them at `gold_ring.png` / `gold_necklace.png`
  once that art exists.

## Undeclared directories

`assets/images/dungeons/` is referenced by every `DungeonDefinition` but is
**not declared in `pubspec.yaml`**, so files placed there would not ship even
once drawn. `assets/images/zones/` is declared but empty. Fixing either means
adding the art *and* the pubspec entry in the same change — Flutter treats a
declared-but-empty directory as a build error.

## Item icons — `assets/icons/items/`

Herbs (herbalism drops — node images exist in `assets/images/entities/`, but the
inventory/item icons are still missing):

- [ ] guam_leaf.png
- [ ] marrentill.png
- [ ] tarromin.png
- [ ] harralander.png
- [ ] ranarr_weed.png
- [ ] toadflax.png
- [ ] irit_leaf.png
- [ ] avantoe.png
- [ ] kwuarm.png
- [ ] snapdragon.png
- [ ] cadantine.png
- [ ] lantadyme.png
- [ ] dwarf_weed.png
- [ ] torstol.png

Jewelry (jewelcrafting):

- [ ] ruby_ring.png
- [ ] ruby_necklace.png

Optional (currently reusing basic_campfire.png):

- [ ] oak_campfire.png

## Skill icons — `assets/icons/skills/`

- [ ] herbalism.png (herbalism skill, e.g. a sickle over an herb sprig)

## Entity images — `assets/images/entities/`

Fishing spots (tranquil_pond.png exists as reference style; the deep pond reuses tranquil_pond.png):

- [ ] river.png
- [ ] lake.png
- [ ] ocean.png

New entities:

- [ ] oak_tree.png
- [ ] iron.png (iron ore rock, distinct from the copper.png rock already in use)

Shops (dev forest proof of concept):

- [ ] trading_post.png
- [ ] wandering_merchant.png

Dungeon boss:

- [ ] goblin_queen.png
- [ ] spider_broodmother.png (Spider Den boss)

Dungeon entrances (zone dungeons; shown in the zone's entity list):

- [ ] spider_den.png (Spider Den entrance in the forest — separate from `assets/images/dungeons/spider_den.png`, which exists as the dungeon header)

Herb nodes (dev forest herbalism):

- [ ] cadantine.png
- [ ] lantadyme.png
- [ ] dwarf_weed.png
- [ ] torstol.png

## Dungeon images — `assets/images/dungeons/`

- [ ] goblin_queen_lair.png (Goblin Queen's Lair landmark header)
