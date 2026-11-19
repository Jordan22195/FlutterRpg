# Dungeon loot guide

Read this before designing the loot for a new dungeon or changing an existing one. The rules here are enforced by the `loot curve` and `loot structure` groups in `test/catalog_integrity_test.dart`. If a rule changes, change the test with it.

## 1. Reading an item's power

Every monster and every piece of gear sits on the same Fibonacci ladder (`Util.fibonacciCache`).

- **Monster rung** is `CombatEntityDefinition.fibLevel`. Its level is `fib(rung)`: rung 8 = L55, 9 = L89, 10 = L144, 11 = L233, 12 = L377, 13 = L610.
- **Item rung** is `EquipmentItemDefinition.fibLevel`. A common piece's stat total is about `fib(rung)`.
- **Item tier** is the rung the piece is *worth*: `fibLevel − fibOffset`, which removes the slot's bonus and the weapon shape's bonus. It's the same scale as the material ladder:

| Tier | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| Metal / hide | copper / light leather | iron / medium | steel / heavy | mithril / light dragonhide | adamant / medium dragonhide | rune / heavy dragonhide | dragon / light demonhide | medium demonhide | heavy demonhide |
| Wear level | 0–1 | 20 | 40 | 60 | 70 | 80 | 90 | 95 | 99 |

Slot offsets:
- +1: chest, legs, shoulder, neck.
- +2: offhand.
- 0: everything else.

Weapon shape offsets:
- 0: dagger.
- +1: sword and scepter.
- +2: greatsword and pitchfork.

So a rung-5 legs piece is tier 4.

**Wear requirement.** A piece made of no material (a unique) asks for the level of the material its tier matches. This comes from `EquipmentItemDefinition.skillLevelRequirement`. Tier 0 and below is free. Cloth opts out with `ungated: true`, and jewellery is gated at the bench instead.

## 2. Where a dungeon sits

- **Boss rung → item tier.** A boss's gear tier may be at most **boss rung − 5** (`loot curve`). The usual is rung − 5 for bosses and about rung − 6 for the dungeon's trash material drops.
- **Bands** set the rarity pair every unique in the dungeon drops at, and how long the grind is:

| Band | Item tiers | Rarity pair | Dungeons today |
|---|---|---|---|
| Early | 0–1 | Common / Uncommon | Grainery (t0), Goblin Camp (t1) |
| Mid | 2–3 | Uncommon / Rare | Wolf Den (t2), The Reedmaze (t2), Spider Den (t3), Drowned Fen (t3), The Silt Warrens (t3) |
| Late | 4–5 | Rare / Epic | Tempest Reach (t4), Brinedeep Caves (t4), Haunted Ruins (t4), Old Sorrow Mine (t4), Goblin Queen's Lair (t5) |
| Endgame | 6–7 | Rare / Epic | Spinehold Caverns, Ashen Vaults (t6); Hoarfrost Hollow, Thunderhall, The Caldera (t7). Gear not designed yet. |

## 3. The shape of a dungeon's loot

**Each boss:**
- owns **1–2 uniques**. No other boss drops them; trash monsters may.
- drops each unique at the **band's two rarities**, as two `DropRoll`s: the lower one more often, the higher one rarely.
- carries its uniques in its bonus rolls (`bonusDrops` / `extraBonusDrops`). Its main table (`itemDrops`) is the material haul: logs, ore, hides, food. Material gear such as an iron dagger can sit there; it doesn't count as a unique.
- has every boss in the same dungeon drop at the same pair.

**The full-clear chest:**
- has **1–2 chest-exclusive uniques**. They're the same tier as the bosses' pieces, in slots the bosses don't cover (body pieces work well). They drop at the band's two rarities.
- gives **some, never all**, of the bosses' pieces: at most 3, and fewer than the dungeon has. They come at **that boss's top rarity, never above**, as bad-luck protection. A chest that hands out boss items at a *higher* rarity makes farming the bosses pointless.
- keeps its bulk material rolls (20–80 of the zone's resources).

A typical dungeon carries 5–8 uniques across 13 slots. Smithed metal and crafted leather fill the rest of a kit, so a full kit is always a mix.

## 4. Stats

**Combat stats:** Attack, Defence. **Core stats:** Speed, Strength, Stamina, Recovery.

A unique is built the way crafted gear is: a **primary** budget plus **secondaries** by rarity.

| Rarity | Primary (× material budget) | Secondaries (each 0.2 × budget) |
|---|---|---|
| Common | 1.0 | 0 |
| Uncommon | 1.0 | 1 |
| Rare | 1.2 | 2 |
| Epic | 1.4 | 3 |
| Legendary | 1.6 | 4 |

Crafted gear rolls each secondary at random from the four core stats. A unique sets them in the catalog instead (`catalogSecondaries`):

1. **The primary is combat stats only.** `statWeights` names Attack, Defence, or both, as a ratio: `{ATTACK: 1}`, `{DEFENCE: 2, ATTACK: 1}`, `{ATTACK: 3, DEFENCE: 1}`. Pick it to fit the item and its source (a shell defends, a fang attacks), and vary the split so a tier's pieces aren't all alike.
2. **Every unique lists four secondaries**, in the order the tiers unlock them: an uncommon carries the first, a rare the first two, a legendary all four. The first is the piece's lean. A stat can repeat, so `[SPEED, SPEED, STAMINA, SPEED]` is a speed piece with a touch of stamina. Damage weapons carry them too (`catalog_integrity_test` checks).
   A piece never carries both Strength and Speed: it leans one or the other (`catalog_integrity_test` checks).
3. **Pure Defence is the smith's.** Only metal armour is Defence and nothing else. A unique with a Defence primary still carries its secondaries.
4. **Coverage.** Strength and Speed each lead a unique within any 2–3 adjacent tiers. Not every tier needs every stat.
5. **Stamina and Recovery are minor.** They lead a piece only where it fits the theme (a cow's ring, a banner, an ooze), and otherwise ride later in the list.
6. **Mirror same-tier siblings.** Two or three dungeons at one tier match piece for piece: the same rungs and four secondaries each, but different slots and leans. Spider Den and Drowned Fen pair this way, enforced by `test/drowned_fen_test.dart` (since the 2026-11-16 monster rebalance lowered the Spider Den's bosses, its Webbed Cloak sits a rung under the Fen's Ooze-Slick Belt; the test allows the Fen up to one rung above its twin); Brinedeep Caves mirrors Tempest Reach (its bosses stop at L89, so the Leviathan's pair sits a rung under the Tempest's) and the Silt Warrens' trims mirror the Fen's, enforced by `test/west_coast_dungeons_test.dart`; the Haunted Ruins are the tier's third dungeon but not a strict mirror: one weapon instead of three, the Gravekeeper's chest piece shares its slot with the Pearlscale Cuirass (on a different lead), and the chest's Reliquary Gauntlets take the hands, the one slot no tier-4 dungeon filled, checked by `test/haunted_ruins_loot_test.dart`; Old Sorrow Mine is the fourth, also not a strict mirror: four bosses, the first two with one trim each, and every piece on a slot and lead no other unique at its tier holds (the tier's only shoulder piece and tier-5 greatsword, a Stamina duster on the back beside the Speed-led Alpha's Mantle), checked by `test/old_sorrow_mine_test.dart`. Neither replaces the other.

Weights are a ratio, not amounts: only each weight's share of the total matters. A hide splits its budget exactly, so heavy-leather uniques like the Wolf Den set are worth precisely their heavy-leather counterpart's primary and only split it differently.

## 5. Weapons

- Damage is derived: `weaponDamageForRung(materialRung) × swing seconds × damageScale × primary multiplier`. So **a dagger, a sword and a greatsword deal the same damage per second at a tier**. A faster swing hits for less.
- Pick the tier with `fibLevel`, and the feel with the shape. Never override a weapon's `actionInterval` (`loot curve` checks).
- A shape that both hits and carries stats takes a reduced hit. The scepter's `damageScale` is 0.5 because its stat budget is the other half; any new hybrid shape follows the same rule (`loot curve` checks).
- Tools (axe, pickaxe, rod) hit at 0.5 scale; the sickle doesn't hit.

## 6. Drop rates: time, not kills

Rates are a **target time between drops**, and the grind grows with the band:

| Drop | Early | Mid | Late | Endgame |
|---|---|---|---|---|
| Boss unique, lower rarity | ~20 min | ~1 h | ~2 h | ~4 h |
| Boss unique, higher rarity | ~1 h | ~3 h | ~8 h | ~12 h |
| Chest exclusive, lower rarity | ~30 min | ~2 h | ~4 h | ~8 h |
| Chest exclusive, higher rarity | ~2 h | ~6 h | ~16 h | ~24 h |
| Chest boss-piece roll | ~1 h | ~3 h | ~6 h | ~10 h |

For boss rows the time counts from looping that boss's floor. For chest rows it counts from full clears.

Convert each target with **`chance = 1 / (kills or chests per hour × target hours)`**.

Measure kills per hour with a throwaway sim:
1. Copy how `test/offline_segments_test.dart` settles a looping dungeon.
2. Give the player the band's wear level in every combat skill, the tier's smithed metal (helmet, chest, legs, boots, gloves, shield, sword), and the tier's cooked fish.
3. Call `setLoopDungeon` and settle 8 hours.
4. Read `dungeonProgress.runsFor` per floor and `chestsWaiting`.

Keep the sim out of the repo.

**Measured (2026-11), full clears per hour:**
- Grainery ~9
- Goblin Camp ~35 (one floor)
- Wolf Den ~1
- Spider Den and Drowned Fen ~1.1
- Tempest Reach ~0.125
- Goblin Queen's Lair: never clears (the Queen out-scales the gear)
- The five new dungeons: stall on their first trash

**The late and endgame rates in the catalog are placeholders** until late combat is retuned: 17% / 4% per boss kill, 25% / 6% chest exclusive, 17% chest boss-piece. Re-measure and convert once a full clear fits in an hour or two.

Current early and mid rates:

| | Boss lower / higher | Chest exclusive lower / higher | Chest boss pieces |
|---|---|---|---|
| Grainery | 10% / 3.5% | 20% / 5% | 10% |
| Goblin Camp | 8% / 3% | 5% / 1.5% | 3% |
| Wolf Den | 33% / 11% | 50% / 15% | 30% |
| Spider Den, Drowned Fen | 30% / 10% | 50% / 15% | 30% |
| The Reedmaze, The Silt Warrens (unmeasured: sibling rates) | 30% / 10% | 50% / 15% | 30% |

## 7. Adding a dungeon at tier N

If it follows this guide, **existing dungeons need no rebalancing**. Every rule is per tier, and monster stats come from `fibLevel`.

1. **Place it.** Bosses go at rung N + 5. Trash a rung or two below drops material gear about 6 rungs under itself. The band gives the rarity pair and the rate column.
2. **Fill gaps; don't stack.** Read tiers N − 1 to N + 1 in the table in section 8.
   - Give the bosses the stats that window lacks.
   - If it has all four, lean on Speed and Strength, the scarce ones.
3. **Write each piece's weights under section 4's rules:** combat stat leads when present, no pure Defence, Stamina and Recovery second.
4. **Mirror any sibling** at the same tier.
5. **Pick the chest exclusive's slot** from what this tier's dungeons leave open.
6. **New items get new ids.** Never rename an existing id; the enum names are the save format. Add their art to `knownMissingArt` in the integrity test until it is drawn, and take it off once it is.
7. **Measure a lap and set the rates** (section 6).
8. **Run** `flutter test test/catalog_integrity_test.dart` plus the dungeon's own drops test (model: `test/wolf_den_set_test.dart`), then update section 8.

**When existing content does need touching:**
- **Tier 7+ has no smithing.** Metal stops at dragon (tier 6). Either add a metal tier (material ladder, `blacksmithing_recipes.dart`, ore and veins), or accept dragon plate as the endgame Defence lane.
- **Tier 8 is the ceiling.** Wear levels run out at 99. A rung-14+ dungeon needs the ladder extended first.
- **Slot collision.** If a new piece takes the same slot and lead stat as a same-tier unique, change one of them, or the older one becomes dead loot.

## 8. Current loot (keep this up to date)

The weights column gives the lead stat first. "→ chest" marks boss pieces the chest also gives at the boss's top rarity.

| Dungeon (tier, band) | Boss | Uniques (weights) |
|---|---|---|
| Grainery (t0, C/U) | Big Red | Chicken Charm (Atk 2 · Spd 1) → chest |
| | Bo | Mood Ring (Def 2 · Sta 1) |
| | Brainless | Pitchfork (2h) → chest · Wood Shield (Def 2 · Str 1) |
| | *chest* | Farmhand's Gloves (Str 2 · Sta 1) |
| Goblin Camp (t1, C/U) | Goblin Sergeant | Sergeant's Shiv (dagger) → chest · Warband Belt (Atk 2 · Str 1) |
| | *chest* | Camp Banner Cloak (Def 2 · Atk 1) |
| Wolf Den (t2, U/R) | Cave Bear | Bear Hide Bracers (Str 2 · Rec 1) · Wolf Den Helm (Atk 2 · Spd 1) → chest |
| | Den Alpha Wolf | Wolf Hide Bracers (Atk 2 · Spd 1) · Wolf Den Boots (Atk 2 · Spd 1) → chest |
| | Grotto Fungal Monster | Redcap Ring (Str 2 · Rec 1) · Wolf Den Gloves (Atk 2 · Spd 1) → chest |
| | *chest* | Wolf Den Chestguard (Def 2 · Spd 1) · Wolf Den Legguards (Atk 2 · Spd 1) |
| | *den trash, 2%* | Wolf Den Cloak (Elder Forest Wolf) · Wolf Hide Belt (Bear) |
| Spider Den (t3, U/R) | Thicket Weaver | Webbed Cloak (Def 2 · Atk 1) → chest · Webbed Bracers (Def 2 · Spd 1) |
| | Cocooned Zombie | Venomfang Ring (Atk 2 · Str 1) |
| | Broodmother | Spider Silk Necklace (Atk 8 · Def 4) → chest · Broodmother's Mantle (Def 2 · Spd 1) |
| | *chest* | Broodsilk Leggings (Spd 2 · Sta 1) |
| Drowned Fen (t3, U/R) | Murder King | Crowquill Bracers (Atk 2 · Spd 1) → chest |
| | Primordial Ooze | Ooze-Slick Belt (Str 2 · Sta 1) |
| | Murkjaw Matriarch | Murkjaw Pauldrons (Def 8 · Str 4) → chest |
| | *chest* | Murkhide Cuirass (Def 2 · Str 1) |
| Tempest Reach (t4, R/E) | Orc Warlord | Warlord's Cleaver (sword) · Warlord's Warhelm (Def 2 · Str 1) → chest |
| | Sabertooth Alpha | Alpha's Fang (dagger) · Alpha's Mantle (Atk 2 · Spd 1) → chest |
| | Tempest | Stormcaller's Scepter (scepter, Atk 12 · Def 4) · Galewrap Gauntlets (Def 8 · Atk 4) → chest |
| | *chest* | Stormhide Legs (Str 2 · Sta 1) |
| The Reedmaze (t2, U/R) | Old Croaker | Croaker's Charm (Spd 2 · Sta 1) → chest |
| | Old Snapjaw | Snapjaw Shell (Def 2 · Str 1) |
| | *chest* | Rivercane Mantle (Str 2 · Spd 1) |
| The Silt Warrens (t3, U/R) | Old Mudclaw | Mudclaw Grips (Atk 2 · Spd 1) → chest |
| | Wallow Bull | Wallowhide Treads (Str 2 · Rec 1) → chest |
| | Mudmaw | Mudmaw Jawblade (sword) |
| | *chest* | Siltscale Coif (Def 2 · Spd 1) |
| Brinedeep Caves (t4, R/E) | Brinecrusher | Brinecrusher's Claw (greatsword) · Brineclaw Bracers (Atk 2 · Str 1) → chest |
| | Naga Tidecaller | Tidecaller's Scepter (scepter) · Saltscale Sandals (Spd 2 · Sta 1) → chest |
| | Leviathan | Leviathan's Fang (dagger) · Leviathan Girdle (Str 8 · Rec 4) → chest |
| | *chest* | Pearlscale Cuirass (Def 2 · Spd 1) |
| Haunted Ruins (t4, R/E) | The Gravekeeper | Gravekeeper's Greatcoat (chest, Def 2 · Sta 1) · Gravekeeper's Keyring (Def 2 · Str 1) → chest |
| | The Shrouded Wraith | Shroudreaver (greatsword) · Weeping Rosary (Atk 3 · Rec 1) → chest |
| | The Undying Abbot | Abbot's Grimoire (offhand, Atk 3 · Str 1, t5) · Ossuary Pauldrons (Atk 2 · Spd 1, t5) → chest |
| | *chest* | Reliquary Gauntlets (hands, Def 2 · Spd 1) |
| Old Sorrow Mine (t4, R/E) | The Packrat King | Packrat's Trinket (finger, Atk 2 · Spd 1) → chest |
| | Duskwing Matriarch | Duskwing Cuffs (wrist, Atk 2 · Rec 1) → chest |
| | The Borer | Borer's Mandible (dagger, Str) · Borer's Shell Pauldrons (Def 2 · Str 1) → chest |
| | The Lode Golem | Lodestone Maul (greatsword, Str, t5) · Heart of the Lode (offhand, Def 2 · Sta 1, t5) |
| | *chest* | Prospector's Duster (back, Def 2 · Sta 1) · Mother Lode Nugget (neck, Atk 3 · Str 1) |
| Goblin Queen's Lair (t5, R/E) | Goblin Queen | Goblin Crown (Def 12 · Atk 4) → chest · Goblin Scepter (scepter) |
| | *chest* | Queen's Train (Spd 2 · Rec 1) |

**Stat coverage by tier.** ● means some piece leads with the stat; ○ means it only appears as a second weight.

| Tier | Attack | Defence | Strength | Speed |
|---|---|---|---|---|
| 0 | ● | ● | ● | ○ |
| 1 | ● | ● | ○ | weapon (dagger) |
| 2 | ● | ● | ● | ● |
| 3 | ● | ● | ● | ● (+ first weapon) |
| 4 | ● | ● | ● | ● |
| 5 | ● | ● | ○ | ● |
| 6–7 | not designed yet | | | |

Under the combat-leads rule, Speed leads only on pure-core pieces: Broodsilk Leggings, Queen's Train, Croaker's Charm and Saltscale Sandals. Pure-core Speed pieces are the lever if Speed coverage needs to grow.

The new dungeons' proposed focuses, as a brief for whoever builds them:

| Dungeon | Boss focuses | Chest exclusive |
|---|---|---|
| Spinehold Caverns (t6) | Elder Roc → Speed · Steel Sentinel → Defence (shield) · Greyspine Drake → Strength (greatsword) | Attack helm |
| Ashen Vaults (t6) | Ash Wyvern → Attack · Slag Warden → Defence · Heart of the Ridge → Strength ring | Speed chest piece |
| Hoarfrost Hollow (t7) | Yeti Patriarch → Strength · Frost Giant → Defence · Frost Wyrm → Attack | Speed boots |
| Thunderhall (t7) | Roc Broodmother → Speed · Thunderbird → Attack · Storm Giant → Strength (2h) | Defence legs |
| The Caldera (t7) | Lesser Demon → Attack · Greater Demon → Strength · Dragon → Defence (+ weapon) | Speed cloak |

Hoarfrost Hollow, Thunderhall and The Caldera are three dungeons at one tier, so mirror them (rule 5) before any ships.
