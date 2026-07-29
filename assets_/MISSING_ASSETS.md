# Missing asset files

Art referenced by the catalogs that does not exist on disk yet.
Each file below renders as a broken-image placeholder in game until added.

Verified against actual references in `lib/catalogs/*.dart` on 2026-07-15 — most
items from the previous pass now exist (fish, cooked fish, tier 2 gear/materials,
gems, most jewelry, enchanting materials, dungeon uniques, herb sickles, benches,
farm/mine zone headers, herb nodes). Remaining gaps below.

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
