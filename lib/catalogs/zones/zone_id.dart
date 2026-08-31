import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/zones/definition/zone_definition.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';

// ignore_for_file: constant_identifier_names

/// Every zone in the game, and its definition.
///
/// Ordered by exploration level ascending, with dev/test zones last.
///
/// Definitions are `const`. Call `definition.copyWith(...)` for a variant
/// template; the runtime [Zone] (which carries discovered entities and other
/// per-save state) is built by the session, not from here.
///
/// The enum *value names* are the save format, so they must never be renamed.
enum ZoneId {
  // ── ZONES · exploration level ascending ─────────────────────────
  TUTORIAL_FARM(
    ZoneDefinition(
      name: "Southglen Meadow",
      iconAsset: "assets/images/zones/farm.png",
      explorationLevel: 1,
      xpPerExplore: 3,

      permanentEntities: [
        EntityId.TRANQUIL_POND,
        EntityId.ANVIL,
        EntityId.FIREPIT,
        EntityId.FARMER,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.CHICKEN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COW, weight: 1),
        // the skill's first payoff: an existing rare, now something you
        // earn rather than something you stumble into on turn one
        WeightedDropTableEntry<EntityId>(
          id: EntityId.BIG_RED,
          weight: .07,
          unlockLevel: 4,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ROTWOOD_SCARECROW,
          weight: .7,
          unlockLevel: 8,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ROTWOOD_SCARECROW_1,
          weight: .007,
          unlockLevel: 8,
        ),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.COINS,
          count: 1,
          highCount: 10,
          weight: .1,
          unlockLevel: 3,
        ),
        // a lucky gem turned up in the dirt; feeds jewelcrafting from the
        // starter zone
        WeightedDropTableEntry(
          id: ItemId.SAPPHIRE,
          weight: .02,
          unlockLevel: 6,
        ),
        WeightedDropTableEntry(id: ItemId.NULL, weight: 1),
      ],
    ),
  ),
  SOUTHWOOD_FOREST(
    ZoneDefinition(
      iconAsset: 'assets/images/zones/forest.png',
      explorationLevel: 5,
      xpPerExplore: 5,

      name: "Southwood Forest",
      permanentEntities: [EntityId.RIVER, EntityId.FIREPIT],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.OAK_TREE, weight: .5),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GOBLIN_SEARGENT,
          weight: 1,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.FOREST_WOLF, weight: 1),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.FOREST_WOLF_UNCOMMON,
          weight: 1,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: .5),
        WeightedDropTableEntry(id: EntityId.GOBLIN_CAMP, weight: .01),
        // herb geography: the low herbs grow here once you can spot them,
        // which is what makes Herbalism reachable through Exploration
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GUAM,
          weight: 1,
          count: 3,
          unlockLevel: 8,
        ),

        // the river runs through these woods, and the mudlurcs come out of
        // it — the same pairing the forest wolves have with the treeline
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MUDLURC,
          weight: 1,
          unlockLevel: 11,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MUDLURC_WARRIOR,
          weight: .5,
          unlockLevel: 11,
        ),

        // the valuable herb everyone wants, reserved for explorers who
        // have really learned these woods
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.LOGS,
          count: 1,
          highCount: 5,
          weight: .15,
          unlockLevel: 8,
        ),
      ],
    ),
  ),
  SOUTH_HAVEN(
    ZoneDefinition(
      iconAsset: 'assets/images/zones/south_haven.png',
      type: MapNodeType.SETTLEMENT,
      explorationLevel: 1,

      name: "South Haven",
      permanentEntities: [
        EntityId.ANVIL,
        EntityId.FIREPIT,
        EntityId.TRADING_POST,
        EntityId.ALCHEMY_STATION,
      ],
      discoverableEntities: [],
    ),
  ),
  DARKWOOD_FOREST(
    ZoneDefinition(
      name: "Darkwood Forest",
      iconAsset: 'assets/images/zones/darkwood_forest.png',
      explorationLevel: 20,
      xpPerExplore: 10,

      // The Spider Den moved here from Southwood: the den's own cards run to
      // the Broodmother at level 55, which never sat comfortably behind a
      // level-5 zone's front door.
      permanentEntities: [EntityId.FIREPIT, EntityId.SPIDER_DEN_ENTRANCE],
      discoverableEntities: [
        // tier 3 gathering: willow for woodcutting, coal for mining. The
        // gold vein is the mine's, not the darkwood's.
        WeightedDropTableEntry<EntityId>(id: EntityId.WILLOW_TREE, weight: 1.5),
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: 1),
        // the spiders that spill out of the den
        WeightedDropTableEntry<EntityId>(id: EntityId.GIANT_SPIDER, weight: 1),
        // the high herbs grow in the deep woods, the way the low ones grow
        // in Southwood — the next rung of the same Herbalism ladder
        WeightedDropTableEntry<EntityId>(
          id: EntityId.HARRALANDER,
          weight: .6,
          count: 2,
          unlockLevel: 24,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RANARR,
          weight: .2,
          unlockLevel: 30,
        ),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.WILLOW_LOGS,
          count: 1,
          highCount: 4,
          weight: .15,
          unlockLevel: 24,
        ),
      ],
    ),
  ),
  FOREST_MINE(
    ZoneDefinition(
      name: "Forest Mine",
      iconAsset: 'assets/images/zones/mine.png',
      requiredSkill: SkillId.MINING,
      requiredLevel: 5,
      explorationLevel: 15,
      xpPerExplore: 8,

      permanentEntities: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GIANT_SPIDER, weight: 1),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.COAL_VEIN,
          weight: .8,
          unlockLevel: 21,
        ),
        // gold sits with the other veins, deeper in than coal
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GOLD_VEIN,
          weight: .5,
          unlockLevel: 23,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GEM_VEIN,
          weight: .08,
          unlockLevel: 25,
        ),
      ],
      discoverableItems: [
        // a lost miner's purse, kept off the ore/gem axis so it doesn't
        // pre-empt either vein
        WeightedDropTableEntry(
          id: ItemId.COINS,
          count: 5,
          highCount: 50,
          weight: .12,
          unlockLevel: 18,
        ),
        WeightedDropTableEntry(
          id: ItemId.SOUL_SHARD,
          weight: .01,
          unlockLevel: 30,
        ),
        WeightedDropTableEntry(id: ItemId.NULL, weight: 1),
      ],
    ),
  ),
  CHALLENGING_MOUNTAIN(
    ZoneDefinition(
      name: "The Mountain",
      iconAsset: "",
      explorationLevel: 30,
      xpPerExplore: 120,

      permanentEntities: [],

      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    ),
  ),
  // ── DEV ZONES · outside the travel graph, free to enter ─────────
  DEV_FOREST(
    ZoneDefinition(
      name: "Dev Forest",
      iconAsset: 'assets/images/zones/forest.png',
      xpPerExplore: 10,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.ANVIL,
        EntityId.ENCHANTING_BENCH,
        EntityId.JEWELCRAFTING_BENCH,
        EntityId.ALCHEMY_STATION,
        EntityId.DEEP_POND,
        EntityId.RIVER,
        EntityId.LAKE,
        EntityId.OCEAN,
        EntityId.TRADING_POST,
        EntityId.WANDERING_MERCHANT,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.OAK_TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.CHICKEN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: 1),
        // every herb, each found as a patch of 3 picks. herbs live only
        // here until real zones get herb geography
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GUAM,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MARRENTILL,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TARROMIN,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.HARRALANDER,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RANARR,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TOADFLAX,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.IRIT,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.AVANTOE,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.KWUARM,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SNAPDRAGON,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.CADANTINE,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.LANTADYME,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DWARF_WEED,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TORSTOL,
          weight: 1,
          count: 3,
        ),
      ],
    ),
  ),
  DEV_DUNGEON_TESTING(
    ZoneDefinition(
      name: "Dev Dungeons",
      iconAsset: 'assets/images/zones/forest.png',
      xpPerExplore: 10,

      permanentEntities: [EntityId.SPIDER_DEN_ENTRANCE],

      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DEV_DUNGEON_ENTRANCE,
          weight: 10,
        ),
      ],
    ),
  ),
  // ── SENTINEL ────────────────────────────────────────────────────
  NULL(
    ZoneDefinition(
      name: "Nowhere",
      iconAsset: "",
      permanentEntities: [],
      discoverableEntities: [],
    ),
  );

  const ZoneId(this.definition);

  /// The design-time template for this zone. Never mutate it.
  final ZoneDefinition definition;

  String get iconAsset => definition.iconAsset;
}
