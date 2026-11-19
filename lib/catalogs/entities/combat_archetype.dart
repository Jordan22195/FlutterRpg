import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/combat_type.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// The kind of monster: what every monster built on it shares.
///
/// That is its art, how it fights ([combatType], [attackInterval]) and its
/// common loot. Everything else — name, level, its own loot, the rarity
/// border it is drawn with — belongs to each `CombatEntityDefinition`
/// built on it in `EntityId`, so one archetype can stand behind a level-3
/// regular and a level-89 named elite alike.
///
/// [itemDrops] and [bonusDrops] are written for a monster on
/// [lootFibLevel]. A monster further up the ladder inherits them scaled by
/// how many rungs above it sits (`CombatEntityDefinition.lootSteps`), so
/// the loot keeps pace with the fight without being written twice.
///
/// These consts are design-time only and are never persisted, so they may
/// be freely renamed — unlike the `EntityId` values that reference them.
///
/// fib   level   gear
/// 0     1       copper
/// 1     2       copper
/// 2     3       copper
/// 3     5       copper
/// 4     8       copper
/// 5     13      iron
/// 6     21      iron
/// 7     34      steel
/// 8     55      mith
/// 9     89      addy
/// 10    144     rune
/// 11    233     dragon
/// 12    377
/// 13    610
class CombatArchetype {
  final String iconAsset;

  /// The rung [itemDrops] and [bonusDrops] are written for. A monster on
  /// this rung drops them as written; each rung above multiplies them
  /// (`WeightedDrops.scaledBy`). No monster may sit below it.
  final int lootFibLevel;

  /// How the level's stat budget splits.
  final CombatType combatType;

  /// Seconds between swings, for every monster that does not set its own.
  final double attackInterval;

  /// The common loot: every monster on this archetype that does not write
  /// its own table drops this one, scaled to its rung.
  final List<ItemDropType> itemDrops;

  /// The common bonus rolls, inherited the way [itemDrops] is.
  final List<DropRoll> bonusDrops;

  /// The kind of creature this is, for alchemy: every monster on it drops
  /// this family's part at the grade its level reaches
  /// (`CombatEntityDefinition.reagentDrop`). Null for people, who leave
  /// nothing a potion wants. See design/ALCHEMY_POTIONS.md.
  final ReagentFamily? reagentFamily;

  const CombatArchetype({
    required this.iconAsset,
    required this.lootFibLevel,
    required this.combatType,
    this.attackInterval = 2.0,
    this.itemDrops = const [],
    this.bonusDrops = const [],
    this.reagentFamily,
  });
}

// ── ROSTER ARCHETYPES · by tier, then by the zone they belong to ──
//
// One const per kind of monster. The monsters built on it live in
// EntityId and point back here, each on its own rung of the ladder.

// ── Tier 3 · level 3 ──
// Chicken · roster tier 1 · farm
const chicken = CombatArchetype(
  iconAsset: 'assets/images/entities/chicken.png',
  lootFibLevel: 2,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 2.0,
  itemDrops: [ItemDropType(id: ItemId.CHICKEN_MEAT, weight: 1)],
);

// ── Tier 4 · level 5 ──
// Cow · roster tier 1 · farm
const cow = CombatArchetype(
  iconAsset: 'assets/images/entities/cow.png',
  lootFibLevel: 3,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.0,
  itemDrops: [
    ItemDropType(id: ItemId.COW_MEAT, weight: 1),
    ItemDropType(id: ItemId.COW_HIDE, weight: 1),
  ],
);

// ── Tier 5 · level 8 ──
// Giant Rat · roster tier 1 · farm
const giantRat = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_rat.png',
  lootFibLevel: 4,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 1.5,
  itemDrops: [ItemDropType(id: ItemId.GOLD_RING, lowCount: 1, weight: 1)],
);

// ── Tier 6 · level 13 ──
// Rotwood Scarecrow · roster tier 1 · farm
const scarecrow = CombatArchetype(
  iconAsset: 'assets/images/entities/rotwood_scarecrow.png',
  lootFibLevel: 4,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.LOGS, weight: 1, lowCount: 1, highCount: 4),
    ItemDropType(id: ItemId.IRON_ORE, weight: 1, lowCount: 1, highCount: 2),
    // the pitchfork is a main-table line, not a bonus roll: it used to
    // be an independent 5% layered on top, and moving it inline is what
    // takes the other three drops from a third each down to 2/7
    ItemDropType(id: ItemId.PITCHFORK, weight: .5),
    ItemDropType(id: ItemId.WOOD_SHIELD, weight: .3),
  ],
);
// River Toad · reedwater vale. The vale's starter: tough-skinned and slow.
const riverToad = CombatArchetype(
  iconAsset: 'assets/images/entities/river_toad.png',
  lootFibLevel: 5,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.VENOM,
  attackInterval: 2.0,
  itemDrops: [
    ItemDropType(id: ItemId.TOAD_LEGS, weight: 2),
    NestedDrop(ironMinorArmorDropTable, weight: 0.3),
  ],
  bonusDrops: [DropRoll(chance: 0.05, entries: riverReagentDropTable)],
);
// Water Strider · reedwater vale. Fast and fragile.
const waterStrider = CombatArchetype(
  iconAsset: 'assets/images/entities/water_strider.png',
  lootFibLevel: 5,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.VENOM,
  attackInterval: 1.0,
  itemDrops: [ItemDropType(id: ItemId.LILY_PAD, weight: 1)],
  bonusDrops: [DropRoll(chance: 0.05, entries: riverReagentDropTable)],
);

// ── Tier 7 · level 21 ──
// Giant Spider · roster tier 2 · forest
const spider = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_spider.png',
  lootFibLevel: 6,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.VENOM,
  attackInterval: 1.5,
);
// Forest Wolf · roster tier 2 · forest
const wolf = CombatArchetype(
  iconAsset: 'assets/images/entities/wolf.png',
  lootFibLevel: 6,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 1.0,
  itemDrops: [ItemDropType(id: ItemId.WOLF_PELT, weight: 1)],
);
// Giant Bat · roster tier 2 · mine
const giantBat = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_bat.png',
  lootFibLevel: 7,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 1.0,
  itemDrops: [],
);
// Slime · roster tier 2 · mine
const slime = CombatArchetype(
  iconAsset: 'assets/images/entities/slime.png',
  lootFibLevel: 7,
  combatType: CombatType.ROCK_CRAB,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
  itemDrops: [
    // rare, and for nothing yet
  ],
);
// Carrion Crow · swamp
const carrionCrow = CombatArchetype(
  iconAsset: 'assets/images/entities/carrion_crow.png',
  lootFibLevel: 7,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 1.0,
  itemDrops: [],
);
// Crab · mudmouth delta and saltwind coast. One archetype for both: the
// delta's mud crab sits on the loot rung, the coast's shore crab one above
// it, inheriting the table scaled and adding the sea's kelp.
const crab = CombatArchetype(
  iconAsset: 'assets/images/entities/crab.png',
  lootFibLevel: 6,
  combatType: CombatType.ROCK_CRAB,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.CRAB_MEAT, weight: 2),
    ItemDropType(id: ItemId.PEAT_CLOD, weight: 0.5),
  ],
  bonusDrops: [DropRoll(chance: 0.05, entries: marshReagentDropTable)],
);

// ── Tier 8 · level 34 ──
// Goblin · roster tier 2 · forest
const goblin = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin.png',
  lootFibLevel: 5,
  combatType: CombatType.CLOTH_DPS,
  attackInterval: 2.0,
  itemDrops: [
    NestedDrop(cookedFishDropTable, weight: 2),
    NestedDrop(mediumLeatherMinorArmorDropTable, weight: 1),
    ...goblinSupplyDrops,
  ],
  bonusDrops: [
    DropRoll(
      chance: 0.05,
      entries: [ItemDropType(id: ItemId.GOBLIN_QUEEN_KEY)],
    ),
  ],
);
// Bear · roster tier 2 · forest
const bear = CombatArchetype(
  iconAsset: 'assets/images/entities/bear.png',
  lootFibLevel: 6,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.BEAR_HIDE, weight: 1),
    ItemDropType(id: ItemId.BEAR_RUMP, weight: 1),
  ],
);
// Mudlurc · roster tier 2 · swamp
const mudlurc = CombatArchetype(
  iconAsset: 'assets/images/entities/mudlurc.png',
  lootFibLevel: 7,
  combatType: CombatType.CLOTH_DPS,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 1.0,
  itemDrops: [
    ItemDropType(id: ItemId.SALMON, weight: 1),
    ItemDropType(id: ItemId.STEEL_BAR, weight: 1),
    // the uncommon mudlurc's dagger, now that only the Drowned Fen
    // fields that variant
    ItemDropType(id: ItemId.FISHBONE_DAGGER, weight: 0.1),
    ItemDropType(id: ItemId.MEDIUM_LEATHER_BELT, weight: 1),
    ItemDropType(id: ItemId.MEDIUM_LEATHER_BOOTS, weight: 1),
    ItemDropType(id: ItemId.MEDIUM_LEATHER_BRACERS, weight: 1),
    ItemDropType(id: ItemId.MEDIUM_LEATHER_GLOVES, weight: 1),
  ],
);
// Fungal Monster · roster tier 2 · swamp
const fungalMonster = CombatArchetype(
  iconAsset: 'assets/images/entities/fungal_monster.png',
  lootFibLevel: 8,
  combatType: CombatType.SHELL,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.MIRECAP, weight: 1),
    ItemDropType(id: ItemId.BOG_LOGS, weight: 1),
    ItemDropType(id: ItemId.COAL, weight: 1),
    ItemDropType(id: ItemId.MINOR_STRENGTH_POTION, weight: 1),
    ItemDropType(id: ItemId.MINOR_STAMINA_POTION, weight: 1),
  ],
);
// Ooze · swamp. The slime a rung further on: slower still, and harder.
const ooze = CombatArchetype(
  iconAsset: 'assets/images/entities/ooze.png',
  lootFibLevel: 8,
  combatType: CombatType.ROCK_CRAB,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
  itemDrops: [],
);
// Murkjaw · swamp. The bog's rare ambusher, a slow and tanky crocodilian.
const murkjaw = CombatArchetype(
  iconAsset: 'assets/images/entities/murkjaw.png',
  lootFibLevel: 8,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.5,
  itemDrops: [ItemDropType(id: ItemId.MURKJAW_HIDE, weight: 1)],
);
// Kobold · roster tier 2 · mine
const kobold = CombatArchetype(
  iconAsset: 'assets/images/entities/kobold.png',
  lootFibLevel: 7,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.5,
  itemDrops: [
    // todo ore drop table
    // todo big rat tail ach
  ],
);
// Snapping Turtle · reedwater vale. The vale's top end: all shell.
const snappingTurtle = CombatArchetype(
  iconAsset: 'assets/images/entities/snapping_turtle.png',
  lootFibLevel: 7,
  combatType: CombatType.SHELL,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.TURTLE_MEAT, weight: 2),
    NestedDrop(steelMinorArmorDropTable, weight: 0.4),
    ItemDropType(id: ItemId.STEEL_SHIELD, weight: 0.1),
  ],
  bonusDrops: [DropRoll(chance: 0.03, entries: riverReagentDropTable)],
);
// Mire Hippo · mudmouth delta. Slow, huge and very hard to put down.
const mireHippo = CombatArchetype(
  iconAsset: 'assets/images/entities/mire_hippo.png',
  lootFibLevel: 7,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.HIPPO_RUMP, weight: 1),
    ItemDropType(id: ItemId.HIPPO_HIDE, weight: 1),
    NestedDrop(mediumLeatherMinorArmorDropTable, weight: 0.4),
  ],
);

// ── Tier 9 · level 55 ──
// Skeleton · roster tier 3 · dark forest
const skeleton = CombatArchetype(
  iconAsset: 'assets/images/entities/skeleton.png',
  lootFibLevel: 7,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.0,
  itemDrops: [
    NestedDrop(graveScrapDropTable, weight: 3),
    NestedDrop(steelMinorArmorDropTable, weight: 1),
    NestedDrop(steelToolsDropTable, weight: 0.6),
    NestedDrop(steelMajorArmorDropTable, weight: 0.4),
    ItemDropType(id: ItemId.STEEL_SHIELD, weight: 0.2, rarity: Rarity.UNCOMMON),
  ],
);
// Zombie · roster tier 3 · dark forest
const zombie = CombatArchetype(
  iconAsset: 'assets/images/entities/zombie.png',
  lootFibLevel: 8,
  combatType: CombatType.ROCK_CRAB,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
  itemDrops: [NestedDrop(graveScrapDropTable)],
  bonusDrops: [DropRoll(entries: tatteredClothDropTable, chance: 0.04)],
);
// Harpy · roster tier 3 · unplaced (cut from Ironroot Hills; id kept for saves)
const harpy = CombatArchetype(
  iconAsset: 'assets/images/entities/harpy.png',
  lootFibLevel: 8,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 1.0,
  itemDrops: [],
);
// Rock Ram · roster tier 3 · ironroot hills. Charges down the switchbacks:
// slow, heavy hits, a pelt for the leatherworker
const rockRam = CombatArchetype(
  iconAsset: 'assets/images/entities/rock_ram.png',
  lootFibLevel: 8,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.0,
  itemDrops: [
    ItemDropType(id: ItemId.ANIMAL_PELT, lowCount: 2, highCount: 4, weight: 1),
  ],
);
// Naga · roster tier 3 · coast
const naga = CombatArchetype(
  iconAsset: 'assets/images/entities/naga.png',
  lootFibLevel: 8,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 1.5,
  itemDrops: [
    ItemDropType(
      id: ItemId.ENCHANTING_ESSENCE,
      lowCount: 1,
      highCount: 2,
      weight: 1,
    ),
    NestedDrop(oceanReagentDropTable, weight: 1),
    NestedDrop(mithrilWeaponsDropTable, weight: 0.2),
  ],
);
// Crocodile · mudmouth delta. The delta's top end, and its biggest bite.
const crocodile = CombatArchetype(
  iconAsset: 'assets/images/entities/crocodile.png',
  lootFibLevel: 8,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.5,
  itemDrops: [ItemDropType(id: ItemId.CROCODILE_HIDE, weight: 1)],
  bonusDrops: [DropRoll(chance: 0.05, entries: heavyLeatherDropTable)],
);
// Orc · roster tier 3 · stormgrass prairie. One archetype for every orc:
// the common is the prairie's level 55 raider and the uncommon its level
// 89 warband
const orc = CombatArchetype(
  iconAsset: 'assets/images/entities/orc.png',
  lootFibLevel: 8,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.0,
  itemDrops: [ItemDropType(id: ItemId.ANIMAL_PELT, weight: 1)],
  bonusDrops: [DropRoll(entries: orcSteelDropTable, chance: 0.1)],
);
// Rattlesnake · roster tier 3 · stormgrass prairie
const rattlesnake = CombatArchetype(
  iconAsset: 'assets/images/entities/rattlesnake.png',
  lootFibLevel: 8,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.VENOM,
  attackInterval: 1.0,
  itemDrops: [ItemDropType(id: ItemId.VENOM_GLAND, weight: 1)],
);

// ── Tier 10 · level 89 ──
// Giant Scorpion · roster tier 3 · copperdust flats
const giantScorpion = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_scorpion.png',
  lootFibLevel: 9,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.VENOM,
  attackInterval: 1.5,
  itemDrops: [],
);
// Imp · roster tier 3 · ironroot hills
const imp = CombatArchetype(
  iconAsset: 'assets/images/entities/imp.png',
  lootFibLevel: 9,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 1.0,
  itemDrops: [
    ItemDropType(
      id: ItemId.ENCHANTING_ESSENCE,
      lowCount: 1,
      highCount: 3,
      weight: 1,
    ),
  ],
);
// Sabertooth · roster tier 3 · stormgrass prairie
const sabertooth = CombatArchetype(
  iconAsset: 'assets/images/entities/sabertooth.png',
  lootFibLevel: 9,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 1.5,
  itemDrops: [ItemDropType(id: ItemId.SABERTOOTH_PELT, weight: 1)],
);
// Centaur · roster tier 3 · stormgrass prairie
const centaur = CombatArchetype(
  iconAsset: 'assets/images/entities/centaur.png',
  lootFibLevel: 9,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 1.5,
  itemDrops: [ItemDropType(id: ItemId.BOWSTRING_SINEW, weight: 1)],
);
// Dust Devil · roster tier 3 · stormgrass prairie. The first magic thing
// the player meets, so it fights like the casters do: all attack, little
// to stand behind
const dustDevil = CombatArchetype(
  iconAsset: 'assets/images/entities/dust_devil.png',
  lootFibLevel: 9,
  combatType: CombatType.CLOTH_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 1.5,
  itemDrops: [
    ItemDropType(
      id: ItemId.ENCHANTING_ESSENCE,
      lowCount: 1,
      highCount: 3,
      weight: 1,
    ),
  ],
);
// Sea Serpent · saltwind coast. The coast's top end.
const seaSerpent = CombatArchetype(
  iconAsset: 'assets/images/entities/sea_serpent.png',
  lootFibLevel: 9,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 1.5,
  itemDrops: [
    ItemDropType(id: ItemId.SERPENT_SCALE, weight: 2),
    NestedDrop(oceanCookedFishDropTable, weight: 1),
  ],
  // no adamant table exists yet, so mithril stands in
  bonusDrops: [DropRoll(chance: 0.03, entries: mithrilArmorDropTable)],
);

// ── Tier 11 · level 144 ──
// Wraith · roster tier 4 · dark forest
const wraith = CombatArchetype(
  iconAsset: 'assets/images/entities/wraith.png',
  lootFibLevel: 10,
  combatType: CombatType.CLOTH_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 1.5,
  itemDrops: [
    ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1),
    ItemDropType(id: ItemId.BLACK_GREATSWORD, weight: 0.2),
  ],
  // it wears the same rags a zombie does, better cut and far more often
  bonusDrops: [DropRoll(entries: tatteredClothUncommonDropTable, chance: 0.15)],
);
// Banshee · roster tier 4 · dark forest
const banshee = CombatArchetype(
  iconAsset: 'assets/images/entities/banshee.png',
  lootFibLevel: 10,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 1.5,
  itemDrops: [ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1)],
);
// Troll · roster tier 4 · ironroot hills
const troll = CombatArchetype(
  iconAsset: 'assets/images/entities/troll.png',
  lootFibLevel: 10,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.ANIMAL_PELT, lowCount: 2, highCount: 5, weight: 1),
  ],
);
// Minotaur · roster tier 4 · mine
const minotaur = CombatArchetype(
  iconAsset: 'assets/images/entities/minotaur.png',
  lootFibLevel: 10,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.0,
);
// Basilisk · roster tier 4 · redwall bluffs
const basilisk = CombatArchetype(
  iconAsset: 'assets/images/entities/basilisk.png',
  lootFibLevel: 10,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.0,
);
// Dark Wizard · roster tier 4 · crypt
const darkWizard = CombatArchetype(
  iconAsset: 'assets/images/entities/dark_wizard.png',
  lootFibLevel: 10,
  combatType: CombatType.CLOTH_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.0,
);
// Gargoyle · roster tier 4 · redwall bluffs
const gargoyle = CombatArchetype(
  iconAsset: 'assets/images/entities/gargoyle.png',
  lootFibLevel: 10,
  combatType: CombatType.SHELL,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 2.5,
);

// Cliff Chimera · roster tier 4 · redwall bluffs
const cliffChimera = CombatArchetype(
  iconAsset: 'assets/images/entities/cliff_chimera.png',
  lootFibLevel: 10,
  combatType: CombatType.SHELL,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.5,
);

// ── Tier 12 · level 233 ──
// Moss Golem · roster tier 5 · swamp
const mossGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/moss_golem.png',
  lootFibLevel: 11,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 3.0,
  itemDrops: [
    // the mid-tier potions
    ItemDropType(id: ItemId.ATTACK_POTION, weight: 1),
    ItemDropType(id: ItemId.STRENGTH_POTION, weight: 1),
    ItemDropType(id: ItemId.DEFENCE_POTION, weight: 1),
    ItemDropType(id: ItemId.STAMINA_POTION, weight: 1),
    ItemDropType(id: ItemId.SPEED_POTION, weight: 1),
    NestedDrop(herbDropTable, weight: 3),
    ItemDropType(id: ItemId.OAK_LOGS, lowCount: 2, highCount: 5, weight: 1),
    ItemDropType(id: ItemId.WILLOW_LOGS, lowCount: 2, highCount: 5, weight: 1),
    ItemDropType(id: ItemId.MAPLE_LOGS, lowCount: 2, highCount: 4, weight: 1),
    ItemDropType(id: ItemId.STEEL_BAR, lowCount: 1, highCount: 3, weight: 1),
    ItemDropType(id: ItemId.MITHRIL_BAR, lowCount: 1, highCount: 2, weight: 1),
    NestedDrop(mithrilArmorDropTable, weight: 1),
    NestedDrop(mithrilWeaponsDropTable, weight: 1),
  ],
  // the stone it is grown over carries gems
  bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.3)],
);
// Hill Giant · roster tier 5 · ironroot hills
const hillGiant = CombatArchetype(
  iconAsset: 'assets/images/entities/hill_giant.png',
  lootFibLevel: 11,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.5,
  itemDrops: [
    ItemDropType(id: ItemId.COAL, lowCount: 1, highCount: 3, weight: 1),
    ItemDropType(id: ItemId.GOLD_ORE, weight: .5),
  ],
);
// Earth Elemental · roster tier 5 · mine
const earthElemental = CombatArchetype(
  iconAsset: 'assets/images/entities/earth_elemental.png',
  lootFibLevel: 11,
  combatType: CombatType.SHELL,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
);
// Ogre · roster tier 5 · mountains
const ogre = CombatArchetype(
  iconAsset: 'assets/images/entities/ogre.png',
  lootFibLevel: 11,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.5,
);
// Stone Golem · roster tier 5 · mountains
const stoneGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/stone_golem.png',
  lootFibLevel: 11,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 3.0,
);
// Griffin · roster tier 5 · redwall bluffs
const griffin = CombatArchetype(
  iconAsset: 'assets/images/entities/griffin.png',
  lootFibLevel: 11,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 1.5,
);
// Fire Elemental · roster tier 5 · volcanic
const fireElemental = CombatArchetype(
  iconAsset: 'assets/images/entities/fire_elemental.png',
  lootFibLevel: 11,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 1.5,
);
// Water Elemental · roster tier 5 · coast
const waterElemental = CombatArchetype(
  iconAsset: 'assets/images/entities/water_elemental.png',
  lootFibLevel: 11,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.0,
);

// ── Tier 13 · level 377 ──
// Yeti · roster tier 6 · frozen peaks
const yeti = CombatArchetype(
  iconAsset: 'assets/images/entities/yeti.png',
  lootFibLevel: 12,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.5,
);
// Iron Golem · roster tier 6 · volcanic
const ironGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/iron_golem.png',
  lootFibLevel: 12,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 3.0,
);
// Steel Golem · roster tier 6 · mine
const steelGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/steel_golem.png',
  lootFibLevel: 12,
  combatType: CombatType.SHELL,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 3.0,
);
// Lich · roster tier 6 · crypt
const lich = CombatArchetype(
  iconAsset: 'assets/images/entities/lich.png',
  lootFibLevel: 12,
  combatType: CombatType.CLOTH_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.0,
);
// Cloud Giant · roster tier 6 · mountains
const cloudGiant = CombatArchetype(
  iconAsset: 'assets/images/entities/cloud_giant.png',
  lootFibLevel: 12,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.5,
);
// Roc · roster tier 6 · frozen peaks
const roc = CombatArchetype(
  iconAsset: 'assets/images/entities/roc.png',
  lootFibLevel: 12,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 1.5,
);
// Wyvern · roster tier 6 · volcanic
const wyvern = CombatArchetype(
  iconAsset: 'assets/images/entities/wyvern.png',
  lootFibLevel: 12,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 1.5,
);
// Drake · roster tier 6 · volcanic
const drake = CombatArchetype(
  iconAsset: 'assets/images/entities/drake.png',
  lootFibLevel: 12,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.0,
);

// ── Tier 14 · level 610 ──
// Kraken · roster tier 7 · deep water dungeon
const kraken = CombatArchetype(
  iconAsset: 'assets/images/entities/kraken.png',
  lootFibLevel: 13,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 3.0,
);
// Dragon · roster tier 7 · dragon's lair
const dragon = CombatArchetype(
  iconAsset: 'assets/images/entities/dragon.png',
  lootFibLevel: 13,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 3.0,
);
// Lesser Demon · roster tier 7 · underworld
const lesserDemon = CombatArchetype(
  iconAsset: 'assets/images/entities/lesser_demon.png',
  lootFibLevel: 13,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.0,
);
// Greater Demon · roster tier 7 · underworld
const greaterDemon = CombatArchetype(
  iconAsset: 'assets/images/entities/greater_demon.png',
  lootFibLevel: 13,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
);
// Frost Giant · roster tier 7 · frostcrown peaks
const frostGiant = CombatArchetype(
  iconAsset: 'assets/images/entities/frost_giant.png',
  lootFibLevel: 13,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 3.0,
);
// Frost Wyrm · roster tier 7 · frostcrown peaks
const frostWyrm = CombatArchetype(
  iconAsset: 'assets/images/entities/frost_wyrm.png',
  lootFibLevel: 13,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.5,
);
// Thunderbird · roster tier 7 · stormcrown peaks
const thunderbird = CombatArchetype(
  iconAsset: 'assets/images/entities/thunderbird.png',
  lootFibLevel: 13,
  combatType: CombatType.GLASS_CANNON,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 1.5,
);
// Storm Giant · roster tier 7 · stormcrown peaks
const stormGiant = CombatArchetype(
  iconAsset: 'assets/images/entities/storm_giant.png',
  lootFibLevel: 13,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.5,
);

// ── BESPOKE ARCHETYPES ──
//
// Named characters and one-offs that are not roster rows: each has one
// monster built on it, which sets its own rung.
// The level-1 starter, older than the roster and kept off it.
const fieldRat = CombatArchetype(
  iconAsset: 'assets/images/entities/field_rat.png',
  lootFibLevel: 0,
  combatType: CombatType.BALANCE,
  reagentFamily: ReagentFamily.FANG,
  attackInterval: 2.0,
  // The weakest thing in the game, so it pays the smallest purse rather
  // than nothing: an empty table is not rollable — roll() returns
  // `ObjectStack(id: 0 as T)` for one, which throws on the cast.
  itemDrops: [ItemDropType(id: ItemId.COINS, lowCount: 1, highCount: 5)],
);
// A named chicken, level 8.
const bigRed = CombatArchetype(
  iconAsset: 'assets/images/entities/big_red.png',
  lootFibLevel: 3,
  combatType: CombatType.LEATHER_DPS,
  reagentFamily: ReagentFamily.FEATHER,
  attackInterval: 2.0,
);
const goblinScout = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin_scout.png',
  lootFibLevel: 3,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 2.0,
);
const goblinSeargent = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin_scout.png',
  lootFibLevel: 4,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 2.0,
);
const spiderBroodmother = CombatArchetype(
  iconAsset: 'assets/images/entities/spider_broodmother.png',
  lootFibLevel: 6,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.VENOM,
  attackInterval: 2.5,
);
const goblinQueen = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin_queen.png',
  lootFibLevel: 7,
  combatType: CombatType.LEATHER_TANK,
  attackInterval: 2.5,
);
// Tempest Reach's first boss, level 144. It fights unlike its orcs — a wall to wear down rather than a brawler.
const orcWarlord = CombatArchetype(
  iconAsset: 'assets/images/entities/orc_warlord.png',
  lootFibLevel: 9,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.HORN,
  attackInterval: 2.5,
);
// Tempest Reach's last boss: a dust devil grown into a storm, level 144,
// and it swings faster than any dust devil.
const tempest = CombatArchetype(
  iconAsset: 'assets/images/entities/tempest.png',
  lootFibLevel: 9,
  combatType: CombatType.CLOTH_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 1.0,
);

// ── Old Sorrow Mine · Copperdust Flats ──
// The mine's own kinds. Its packrats, bats and stone golems stand on the
// existing rat, bat and golem archetypes, and so do its first two bosses;
// these are the shapes nothing else in the game has.

// The drifts' crawler: a cave centipede plated in the rock it bores
// through, level 89.
const rockCrawler = CombatArchetype(
  iconAsset: 'assets/images/entities/rock_crawler.png',
  lootFibLevel: 9,
  combatType: CombatType.LEATHER_TANK,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 2.0,
);
// The Mother Lode's crawler, grown a crust of raw gems, level 89.
const gemCrawler = CombatArchetype(
  iconAsset: 'assets/images/entities/gem_crawler.png',
  lootFibLevel: 9,
  combatType: CombatType.SHELL,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 2.5,
);
// The Stamp Mill's boss, level 89: the burrowing worm that dug the deep
// tunnels, a brawler rather than a wall.
const theBorer = CombatArchetype(
  iconAsset: 'assets/images/entities/the_borer.png',
  lootFibLevel: 9,
  combatType: CombatType.PLATE_DPS,
  reagentFamily: ReagentFamily.ICHOR,
  attackInterval: 2.5,
);
// The mine's last boss, level 144: the gold vein itself, awake. A wall to
// wear down, slow and heavy.
const lodeGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/lode_golem.png',
  lootFibLevel: 10,
  combatType: CombatType.PLATE_TANK,
  reagentFamily: ReagentFamily.SHELL,
  attackInterval: 3.0,
);
