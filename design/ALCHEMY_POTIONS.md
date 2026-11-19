# Alchemy potions

How potions are brewed, and where their ingredients come from. Read this before adding a potion, a herb, a reagent, or a monster that should drop alchemy ingredients.

## Goals

- Grinding monsters in the world feeds strong alchemy buffs.
- A full set of buffs is not tedious to keep up. One monster's drop feeds two potions, and every brew is a single craft.
- A new zone can drop alchemy ingredients without new items or new recipes.

## The recipe

Every potion is one craft: **one herb + one reagent → potion**.

- **The herb sets the tier.** Each tier has two herbs, a **core herb** and a **combat herb**, and each herb is the thematic herb of one zone.
- **The reagent sets the stat.** A reagent is a creature-family part (Feather, Fang, Horn, Shell, Venom, Ichor) at the tier's grade (Small … Primal).

There are no essences, no distilling step, and no points or auto-picked reagents. Those were considered and rejected as too complicated.

## Tiers

| Tier | Potion | Bonus | Alchemy | Core herb (zone) | Combat herb (zone) | Reagent grade |
|---|---|---|---|---|---|---|
| 1 | Minor | +5 | 1 → 10 | Meadowsweet (Southglen Meadow) | Bramblewort (Southwood Forest) | Small |
| 2 | (plain) | +8 | 15 → 24 | Reedmint (Reedwater Vale) | Duskthorn (Darkwood Forest) | Sturdy |
| 3 | Super | +13 | 25 → 34 | Silt Lily (Mudmouth Delta) | Mirecap (Blackmire Swamp) | Thick |
| 4 | Greater | +21 | 35 → 50 | Saltwort (Saltwind Coast) | Bluestem (Stormgrass Prairie) | Heavy |
| 5 | Grand | +34 | 55 → 80 | Glimmercap (Witchlight Grove) | Bloodroot (Redwall Bluffs) | Ancient |
| 6 | Supreme | +55 | 89 → 99 | Frostbloom (Frostcrown Peaks) | Emberroot (Moltenspire Peaks) | Primal |

Each tier's ten potions unlock one at a time, spread evenly between the tier's first and last level (minor is 1 → 10, one level apiece). The unlock order column below is each potion's place in that spread; xp is spread the same way.

## The 10 potions of every tier

| Potion | Herb | Reagent | Unlock order |
|---|---|---|---|
| Speed | core | Feather | 2 |
| Stamina | core | Horn | 5 |
| Strength | core | Fang | 7 |
| Recovery | core | Venom | 9 |
| Exploration | core | Ichor | 10 |
| Defence | combat | Shell | 3 |
| Woodcutting | combat | Fang | 4 |
| Fishing | combat | Shell | 1 |
| Mining | combat | Horn | 6 |
| Herbalism | combat | Venom | 8 |

For example, a **Greater Mining Potion** is Bluestem + Heavy Horn at Alchemy 43, and a **Minor Recovery Potion** is Meadowsweet + Small Venom at Alchemy 9.

That is 10 potions × 6 tiers = **60 potions**, five on each herb. There are no Hitpoints, Attack, Ranged or Magic potions; those are not skills the ladder buffs.

Step 1 of the Minor tier works from a fresh save: chickens drop Small Feather, cows Small Horn, wolves Small Fang, and the pond and creek give Small Shell.

## Reagent families

A monster's archetype names its family. Every monster built on that archetype drops the family's part at the grade its level reaches. A new zone only tags its archetypes; it needs no new items or recipes.

| Family | Who drops it | Potions |
|---|---|---|
| Feather | birds, bats, harpies, rocs | Speed |
| Fang | predators, rats, bears, big cats, crocodiles, serpents, dragons | Strength · Woodcutting |
| Horn | heavy beasts: cattle, hippos, rams, orcs, centaurs, giants, trolls | Stamina · Mining |
| Shell | turtles, crabs, mudlurcs, nagas, crawlers, golems; fishing waters | Defence · Fishing |
| Venom | spiders, snakes, scorpions, toads, striders | Recovery · Herbalism |
| Ichor | slimes, oozes, fungus, the undead, spirits, elementals, demons, imps | Exploration |

Goblins, kobolds and other people have no family.

### Grades

The grade comes from the monster's rung on the Fibonacci ladder.

| Grade | Monster rung | Monster level | Tier it brews |
|---|---|---|---|
| Small | 0–5 | 1–13 | Minor |
| Sturdy | 6 | 21 | Regular |
| Thick | 7 | 34 | Super |
| Heavy | 8 | 55 | Greater |
| Ancient | 9 | 89 | Grand |
| Primal | 10+ | 144+ | Supreme |

A non-combat source (a fishing water) uses the same bands by its level requirement: Small below 21, Sturdy 21–33, Thick 34–54, Heavy 55–88, Ancient 89–143, Primal 144+.

That is 6 families × 6 grades = **36 reagent items**, named `<Grade> <Family>` (Small Feather, Primal Ichor).

### Drop rate

- A regular monster drops one part at a 50% chance per kill.
- A dungeon boss always drops 2–4.

The roll is derived rather than written. `CombatArchetype.reagentFamily` names the family, and `CombatEntityDefinition.reagentDrop` builds the roll from the monster's rung. `rolledBonusDrops` is what kills roll and what the info sheet lists. Tune the numbers here and in `CombatEntityDefinition` together.

Bosses can also carry hand-written bulk stacks of a part in their main table, such as the Broodmother's Heavy Venom. Dungeon chests haul parts at the dungeon's grade.

### Fishing waters

Each water's reagent table drops a Shell at the water's grade. The marsh also drops a Venom. The waters keep their fire reagents.

## Herbs

Each herb grows in one zone. Its Herbalism level sits a little under the tier's Alchemy level.

| Herb | Zone | Herbalism |
|---|---|---|
| Meadowsweet | Southglen Meadow | 1 |
| Bramblewort | Southwood Forest | 5 |
| Reedmint | Reedwater Vale | 13 |
| Duskthorn | Darkwood Forest | 18 |
| Silt Lily | Mudmouth Delta | 21 |
| Mirecap | Blackmire Swamp | 25 |
| Saltwort | Saltwind Coast | 30 |
| Bluestem | Stormgrass Prairie | 35 |
| Glimmercap | Witchlight Grove | 50 |
| Bloodroot | Redwall Bluffs | 55 |
| Frostbloom | Frostcrown Peaks | 80 |
| Emberroot | Moltenspire Peaks | 89 |

## Code

- `lib/catalogs/items/definition/potion_definition.dart` holds the whole ladder: `PotionTier`, `ReagentFamily`, `ReagentGrade`, `potionSlots`, `PotionDefinition`, `ReagentPartDefinition` and `reagentPart()`.
- `lib/catalogs/recipes/data/alchemy_recipes.dart` derives one recipe per `PotionDefinition`.

## Saves and ids

Enum names are the save format, so nothing is renamed.

- **Retired herbs:** Guam Leaf through Torstol (and Harralander, Ranarr and the rest of the old ladder) no longer grow anywhere and no recipe uses them. They stay as items so saves load, and they can still be sold.
- **Retired reagents:** the old specific reagents (Rat Tail, Bat Wing, Hippo Tusk and the rest) stay as items, but monsters stop dropping them.
- **Kept potions:** existing potions keep their ids and recipe ids (`alch_<item id>`), and only their inputs change. The four utility potions fill Super slots:
  - Prospector's → Super Mining
  - Forager's → Super Herbalism
  - Woodsman's → Super Woodcutting
  - Explorer's → Super Exploration
- **Attack potions:** the four Attack potions have no recipe any more. Ones already held can still be drunk, and they keep their red icons.
- **Magic potions:** briefly on the ladder, then dropped. `ItemId.renamed` turns any brewed one into its tier's Exploration potion.
- **Regular tier:** the plain tier gives +8, on the Fibonacci ladder. It was +10 before the ladder.

## Held off: crafting potions

Potions for the crafting skills are deferred: Cooking, Firemaking, Alchemy, Enchanting, Tailoring, Blacksmithing, Jewelcrafting, Fletching and Leatherworking. The plan when they come:

- Each crafting skill gets its own non-combat reagent, graded on the same Small → Primal ladder.
  - Cooking: Salt Crystal
  - Firemaking: Cinder
  - Alchemy: Dewdrop
  - Enchanting: Glimmer Shard
  - Tailoring: Flax Bundle
  - Blacksmithing: Flux Stone
  - Jewelcrafting: Geode
  - Fletching: Amber
  - Leatherworking: Tanroot
- Cooking, Firemaking, Alchemy, Enchanting and Tailoring would use the core herb. Blacksmithing, Jewelcrafting, Fletching and Leatherworking would use the combat herb.

Until then, the four crafting potions that already exist keep hand-written recipes (`_craftingPotionRecipes` in `alchemy_recipes.dart`): Smith's, Alchemist's, Minor Cooking and Cooking. They brew with their tier's core herb and their old reagent. Those reagents still drop: lily pad from the pond, freshwater mussel from the river, venom gland from rattlesnakes, and mithril bars from smelting.
