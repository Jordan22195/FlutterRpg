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
| Mid | 2–3 | Uncommon / Rare | Wolf Den (t2), Spider Den (t3), Drowned Fen (t3) |
| Late | 4–5 | Rare / Epic | Tempest Reach (t4), Goblin Queen's Lair (t5) |
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

1. **The combat stat keeps the highest weight.** When a piece carries both a combat stat and a core stat, the combat stat is the heavier one: `{ATTACK: 2, SPEED: 1}`, never `{SPEED: 2, ATTACK: 1}`. A piece made only of core stats leads with Speed or Strength, and Stamina and Recovery ride second: `{STRENGTH: 2, RECOVERY: 1}`, `{SPEED: 2, STAMINA: 1}`.
2. **Pure Defence is the smith's.** Only metal armour is Defence-only, which keeps blacksmithing relevant. Every unique has at least two stats.
3. **Coverage.** Attack, Defence, Strength and Speed each appear within any 2–3 adjacent tiers. A stat counts whether it's on an item as the lead or the second weight. Not every tier needs every stat.
4. **Stamina and Recovery are minor.** They are never a piece's lead next to a combat stat. Sprinkle them in as the second weight on Speed or Strength pieces.
5. **Mirror same-tier siblings.** Two or three dungeons at one tier match piece for piece: the same rungs and the same stat-weight totals, but different slots and focuses. Spider Den and Drowned Fen pair this way, enforced by `test/drowned_fen_test.dart`. Neither replaces the other.

Weights are a ratio, not amounts: only each weight's share of the total matters. A hide splits its budget exactly, so heavy-leather uniques like the Wolf Den set are worth precisely their heavy-leather counterpart and only split it differently.

## 5. Weapons

- Damage is derived: `weaponDamageForRung(materialRung) × swing seconds × damageScale × rarity`. So **a dagger, a sword and a greatsword deal the same damage per second at a tier**. A faster swing hits for less.
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
| Goblin Queen's Lair (t5, R/E) | Goblin Queen | Goblin Crown (Def 12 · Atk 4) → chest · Goblin Scepter (scepter) |
| | *chest* | Queen's Train (Spd 2 · Rec 1) |

**Stat coverage by tier.** ● means some piece leads with the stat; ○ means it only appears as a second weight.

| Tier | Attack | Defence | Strength | Speed |
|---|---|---|---|---|
| 0 | ● | ● | ● | ○ |
| 1 | ● | ● | ○ | weapon (dagger) |
| 2 | ● | ● | ● | ○ |
| 3 | ● | ● | ● | ● |
| 4 | ● | ● | ● | ○ |
| 5 | ○ | ● | — | ● |
| 6–7 | not designed yet | | | |

Under the combat-leads rule, Speed leads only on pure-core pieces: Broodsilk Leggings and Queen's Train. Pure-core Speed pieces are the lever if Speed coverage needs to grow.

The new dungeons' proposed focuses, as a brief for whoever builds them:

| Dungeon | Boss focuses | Chest exclusive |
|---|---|---|
| Spinehold Caverns (t6) | Elder Roc → Speed · Steel Sentinel → Defence (shield) · Greyspine Drake → Strength (greatsword) | Attack helm |
| Ashen Vaults (t6) | Ash Wyvern → Attack · Slag Warden → Defence · Heart of the Ridge → Strength ring | Speed chest piece |
| Hoarfrost Hollow (t7) | Yeti Patriarch → Strength · Frost Giant → Defence · Frost Wyrm → Attack | Speed boots |
| Thunderhall (t7) | Roc Broodmother → Speed · Thunderbird → Attack · Storm Giant → Strength (2h) | Defence legs |
| The Caldera (t7) | Lesser Demon → Attack · Greater Demon → Strength · Dragon → Defence (+ weapon) | Speed cloak |

Hoarfrost Hollow, Thunderhall and The Caldera are three dungeons at one tier, so mirror them (rule 5) before any ships.
