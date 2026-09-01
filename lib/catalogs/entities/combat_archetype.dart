import 'package:rpg/catalogs/entities/combat_type.dart';

/// What the five rarity variants of one monster share.
///
/// A monster is one archetype plus up to five `CombatEntityDefinition`s
/// hanging off it in `EntityId` — one per [Rarity]. The variants differ in
/// name, rarity and drop table; everything else is here, so re-tiering a
/// monster or changing how it fights is a one-line edit rather than five.
///
/// Level is deliberately absent: it falls out of [fibLevel] and the
/// variant's own rarity, in `CombatEntityDefinition.level`.
///
/// These consts are design-time only and are never persisted, so they may
/// be freely renamed — unlike the `EntityId` values that reference them.
class CombatArchetype {
  final String iconAsset;

  /// Index into `Util.fibonacciCache`: the level of the COMMON variant.
  /// Each rarity step above common is one more rung up the same ladder.
  final int fibLevel;

  /// How the level's stat budget splits.
  final CombatType combatType;

  final double attackInterval;

  const CombatArchetype({
    required this.iconAsset,
    required this.fibLevel,
    required this.combatType,
    this.attackInterval = 2.0,
  });
}

// ── ROSTER ARCHETYPES · by tier, then by the zone they belong to ──
//
// One const per monster. Its five rarity variants live in EntityId and
// point back here; the level each of them lands on is fibLevel plus its
// own rarity step, so the whole column of a tier moves together.

// ── Tier 3 · level 3 (uncommon 5, rare 8, epic 13, legendary 21) ──
// Chicken · roster tier 1 · farm
const chicken = CombatArchetype(
  iconAsset: 'assets/images/entities/chicken.png',
  fibLevel: 2,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 2.0,
);

// ── Tier 4 · level 5 (uncommon 8, rare 13, epic 21, legendary 34) ──
// Cow · roster tier 1 · farm
const cow = CombatArchetype(
  iconAsset: 'assets/images/entities/cow.png',
  fibLevel: 3,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.0,
);

// ── Tier 5 · level 8 (uncommon 13, rare 21, epic 34, legendary 55) ──
// Giant Rat · roster tier 1 · farm
const giantRat = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_rat.png',
  fibLevel: 4,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.5,
);

// ── Tier 6 · level 13 (uncommon 21, rare 34, epic 55, legendary 89) ──
// Rotwood Scarecrow · roster tier 1 · farm
const scarecrow = CombatArchetype(
  iconAsset: 'assets/images/entities/rotwood_scarecrow.png',
  fibLevel: 5,
  combatType: CombatType.PLATE_TANK,
  attackInterval: 2.5,
);

// ── Tier 7 · level 21 (uncommon 34, rare 55, epic 89, legendary 144) ──
// Giant Spider · roster tier 2 · forest
const spider = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_spider.png',
  fibLevel: 6,
  combatType: CombatType.BALANCE,
  attackInterval: 1.5,
);
// Forest Wolf · roster tier 2 · forest
const wolf = CombatArchetype(
  iconAsset: 'assets/images/entities/wolf.png',
  fibLevel: 6,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.0,
);
// Giant Bat · roster tier 2 · mine
const giantBat = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_bat.png',
  fibLevel: 6,
  combatType: CombatType.GLASS_CANNON,
  attackInterval: 1.0,
);
// Slime · roster tier 2 · mine
const slime = CombatArchetype(
  iconAsset: 'assets/images/entities/slime.png',
  fibLevel: 6,
  combatType: CombatType.ROCK_CRAB,
  attackInterval: 2.5,
);

// ── Tier 8 · level 34 (uncommon 55, rare 89, epic 144, legendary 233) ──
// Goblin · roster tier 2 · forest
const goblin = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin.png',
  fibLevel: 7,
  combatType: CombatType.CLOTH_DPS,
  attackInterval: 2.0,
);
// Bear · roster tier 2 · forest
const bear = CombatArchetype(
  iconAsset: 'assets/images/entities/bear.png',
  fibLevel: 7,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.5,
);
// Mudlurc · roster tier 2 · swamp
const mudlurc = CombatArchetype(
  iconAsset: 'assets/images/entities/mudlurc.png',
  fibLevel: 7,
  combatType: CombatType.CLOTH_DPS,
  attackInterval: 1.0,
);
// Fungal Monster · roster tier 2 · swamp
const fungalMonster = CombatArchetype(
  iconAsset: 'assets/images/entities/fungal_monster.png',
  fibLevel: 7,
  combatType: CombatType.SHELL,
  attackInterval: 2.5,
);
// Kobold · roster tier 2 · mine
const kobold = CombatArchetype(
  iconAsset: 'assets/images/entities/kobold.png',
  fibLevel: 7,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.5,
);

// ── Tier 9 · level 55 (uncommon 89, rare 144, epic 233, legendary 377) ──
// Skeleton · roster tier 3 · dark forest
const skeleton = CombatArchetype(
  iconAsset: 'assets/images/entities/skeleton.png',
  fibLevel: 8,
  combatType: CombatType.BALANCE,
  attackInterval: 2.0,
);
// Zombie · roster tier 3 · dark forest
const zombie = CombatArchetype(
  iconAsset: 'assets/images/entities/zombie.png',
  fibLevel: 8,
  combatType: CombatType.ROCK_CRAB,
  attackInterval: 2.5,
);
// Harpy · roster tier 3 · foothills
const harpy = CombatArchetype(
  iconAsset: 'assets/images/entities/harpy.png',
  fibLevel: 8,
  combatType: CombatType.GLASS_CANNON,
  attackInterval: 1.0,
);
// Naga · roster tier 3 · coast
const naga = CombatArchetype(
  iconAsset: 'assets/images/entities/naga.png',
  fibLevel: 8,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.5,
);

// ── Tier 10 · level 89 (uncommon 144, rare 233, epic 377, legendary 610) ──
// Giant Scorpion · roster tier 3 · swamp
const giantScorpion = CombatArchetype(
  iconAsset: 'assets/images/entities/giant_scorpion.png',
  fibLevel: 9,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 1.5,
);
// Imp · roster tier 3 · foothills
const imp = CombatArchetype(
  iconAsset: 'assets/images/entities/imp.png',
  fibLevel: 9,
  combatType: CombatType.GLASS_CANNON,
  attackInterval: 1.0,
);
// Orc · roster tier 3 · foothills
const orc = CombatArchetype(
  iconAsset: 'assets/images/entities/orc.png',
  fibLevel: 9,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.0,
);

// ── Tier 11 · level 144 (uncommon 233, rare 377, epic 610, legendary 987) ──
// Wraith · roster tier 4 · dark forest
const wraith = CombatArchetype(
  iconAsset: 'assets/images/entities/wraith.png',
  fibLevel: 10,
  combatType: CombatType.CLOTH_DPS,
  attackInterval: 1.5,
);
// Banshee · roster tier 4 · dark forest
const banshee = CombatArchetype(
  iconAsset: 'assets/images/entities/banshee.png',
  fibLevel: 10,
  combatType: CombatType.GLASS_CANNON,
  attackInterval: 1.5,
);
// Troll · roster tier 4 · foothills
const troll = CombatArchetype(
  iconAsset: 'assets/images/entities/troll.png',
  fibLevel: 10,
  combatType: CombatType.LEATHER_TANK,
  attackInterval: 2.5,
);
// Minotaur · roster tier 4 · mine
const minotaur = CombatArchetype(
  iconAsset: 'assets/images/entities/minotaur.png',
  fibLevel: 10,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.0,
);
// Basilisk · roster tier 4 · mine
const basilisk = CombatArchetype(
  iconAsset: 'assets/images/entities/basilisk.png',
  fibLevel: 10,
  combatType: CombatType.BALANCE,
  attackInterval: 2.0,
);
// Dark Wizard · roster tier 4 · crypt
const darkWizard = CombatArchetype(
  iconAsset: 'assets/images/entities/dark_wizard.png',
  fibLevel: 10,
  combatType: CombatType.CLOTH_DPS,
  attackInterval: 2.0,
);
// Gargoyle · roster tier 4 · crypt
const gargoyle = CombatArchetype(
  iconAsset: 'assets/images/entities/gargoyle.png',
  fibLevel: 10,
  combatType: CombatType.SHELL,
  attackInterval: 2.5,
);

// ── Tier 12 · level 233 (uncommon 377, rare 610, epic 987, legendary 1597) ──
// Moss Golem · roster tier 5 · swamp
const mossGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/moss_golem.png',
  fibLevel: 11,
  combatType: CombatType.PLATE_TANK,
  attackInterval: 3.0,
);
// Hill Giant · roster tier 5 · foothills
const hillGiant = CombatArchetype(
  iconAsset: 'assets/images/entities/hill_giant.png',
  fibLevel: 11,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.5,
);
// Earth Elemental · roster tier 5 · mine
const earthElemental = CombatArchetype(
  iconAsset: 'assets/images/entities/earth_elemental.png',
  fibLevel: 11,
  combatType: CombatType.SHELL,
  attackInterval: 2.5,
);
// Ogre · roster tier 5 · mountains
const ogre = CombatArchetype(
  iconAsset: 'assets/images/entities/ogre.png',
  fibLevel: 11,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.5,
);
// Stone Golem · roster tier 5 · mountains
const stoneGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/stone_golem.png',
  fibLevel: 11,
  combatType: CombatType.PLATE_TANK,
  attackInterval: 3.0,
);
// Griffin · roster tier 5 · frozen peaks
const griffin = CombatArchetype(
  iconAsset: 'assets/images/entities/griffin.png',
  fibLevel: 11,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.5,
);
// Fire Elemental · roster tier 5 · volcanic
const fireElemental = CombatArchetype(
  iconAsset: 'assets/images/entities/fire_elemental.png',
  fibLevel: 11,
  combatType: CombatType.GLASS_CANNON,
  attackInterval: 1.5,
);
// Water Elemental · roster tier 5 · coast
const waterElemental = CombatArchetype(
  iconAsset: 'assets/images/entities/water_elemental.png',
  fibLevel: 11,
  combatType: CombatType.BALANCE,
  attackInterval: 2.0,
);

// ── Tier 13 · level 377 (uncommon 610, rare 987, epic 1597, legendary 2584) ──
// Yeti · roster tier 6 · frozen peaks
const yeti = CombatArchetype(
  iconAsset: 'assets/images/entities/yeti.png',
  fibLevel: 12,
  combatType: CombatType.LEATHER_TANK,
  attackInterval: 2.5,
);
// Iron Golem · roster tier 6 · volcanic
const ironGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/iron_golem.png',
  fibLevel: 12,
  combatType: CombatType.PLATE_TANK,
  attackInterval: 3.0,
);
// Steel Golem · roster tier 6 · mine
const steelGolem = CombatArchetype(
  iconAsset: 'assets/images/entities/steel_golem.png',
  fibLevel: 12,
  combatType: CombatType.SHELL,
  attackInterval: 3.0,
);
// Lich · roster tier 6 · crypt
const lich = CombatArchetype(
  iconAsset: 'assets/images/entities/lich.png',
  fibLevel: 12,
  combatType: CombatType.CLOTH_DPS,
  attackInterval: 2.0,
);
// Cloud Giant · roster tier 6 · mountains
const cloudGiant = CombatArchetype(
  iconAsset: 'assets/images/entities/cloud_giant.png',
  fibLevel: 12,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.5,
);
// Roc · roster tier 6 · frozen peaks
const roc = CombatArchetype(
  iconAsset: 'assets/images/entities/roc.png',
  fibLevel: 12,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.5,
);
// Wyvern · roster tier 6 · volcanic
const wyvern = CombatArchetype(
  iconAsset: 'assets/images/entities/wyvern.png',
  fibLevel: 12,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 1.5,
);
// Drake · roster tier 6 · volcanic
const drake = CombatArchetype(
  iconAsset: 'assets/images/entities/drake.png',
  fibLevel: 12,
  combatType: CombatType.BALANCE,
  attackInterval: 2.0,
);

// ── Tier 14 · level 610 (uncommon 987, rare 1597, epic 2584, legendary 4181) ──
// Kraken · roster tier 7 · deep water dungeon
const kraken = CombatArchetype(
  iconAsset: 'assets/images/entities/kraken.png',
  fibLevel: 13,
  combatType: CombatType.PLATE_TANK,
  attackInterval: 3.0,
);
// Dragon · roster tier 7 · dragon's lair
const dragon = CombatArchetype(
  iconAsset: 'assets/images/entities/dragon.png',
  fibLevel: 13,
  combatType: CombatType.BALANCE,
  attackInterval: 3.0,
);
// Lesser Demon · roster tier 7 · underworld
const lesserDemon = CombatArchetype(
  iconAsset: 'assets/images/entities/lesser_demon.png',
  fibLevel: 13,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 2.0,
);
// Greater Demon · roster tier 7 · underworld
const greaterDemon = CombatArchetype(
  iconAsset: 'assets/images/entities/greater_demon.png',
  fibLevel: 13,
  combatType: CombatType.PLATE_DPS,
  attackInterval: 2.5,
);

// ── BESPOKE ARCHETYPES ──
//
// Named characters and one-offs that are not roster rows. Each is a
// single variant, so its fibLevel is back-solved from the rarity it
// ships at to leave the level it already had exactly where it was.
// The level-1 starter, older than the roster and kept off it.
const fieldRat = CombatArchetype(
  iconAsset: 'assets/images/entities/field_rat.png',
  fibLevel: 0,
  combatType: CombatType.BALANCE,
  attackInterval: 2.0,
);
// A named uncommon chicken: fib(3)+1 keeps it at level 8.
const bigRed = CombatArchetype(
  iconAsset: 'assets/images/entities/big_red.png',
  fibLevel: 3,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 2.0,
);
// Uncommon, so fib(3)+1 holds its level 8.
const goblinScout = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin_scout.png',
  fibLevel: 3,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 2.0,
);
// Rare, so fib(4)+2 holds its level 21.
const goblinSeargent = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin_scout.png',
  fibLevel: 4,
  combatType: CombatType.LEATHER_DPS,
  attackInterval: 2.0,
);
// Epic, so fib(5)+3 holds its level 55.
const spiderBroodmother = CombatArchetype(
  iconAsset: 'assets/images/entities/spider_broodmother.png',
  fibLevel: 5,
  combatType: CombatType.LEATHER_TANK,
  attackInterval: 2.5,
);
// Legendary, so fib(7)+4 holds its level 233.
const goblinQueen = CombatArchetype(
  iconAsset: 'assets/images/entities/goblin_queen.png',
  fibLevel: 7,
  combatType: CombatType.LEATHER_TANK,
  attackInterval: 2.5,
);
