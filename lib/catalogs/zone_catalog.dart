import 'entity_catalog.dart';
import '../data/skill_data.dart';
import '../data/inventory_data.dart';
import '../services/weighted_drop_table_service.dart';
import '../catalogs/item_catalog.dart';

enum ZoneId {
  TUTORIAL_FARM,
  SOUTHWOOD_FOREST,
  SOUTH_HAVEN,
  FOREST_MINE,
  CHALLENGING_MOUNTAIN,
  DEV_FOREST,
  NULL,
}

class Zone {
  final ZoneId id;
  final String name;
  final List<Entity> permanentEntities;
  final List<Entity> discoveredEntities;

  /// Items turned up by the current explore session in this zone. Mirrors
  /// the encounter screen's session drops: the finds also go to the player
  /// inventory, and this list is session-scoped rather than saved.
  final InventoryData discoveredItems;

  Zone({
    required this.id,
    required this.name,
    required this.discoveredEntities,
    required this.permanentEntities,
    InventoryData? discoveredItems,
  }) : discoveredItems = discoveredItems ?? InventoryData(itemMap: {});

  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'name': name,
      'permanentEntities': permanentEntities.map((e) => e.toJson()).toList(),
      'discoveredEntities': discoveredEntities.map((e) => e.toJson()).toList(),
    };
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    final rawPermanent = json['permanentEntities'];
    final rawDiscovered = json['discoveredEntities'];

    if (rawId is! String) {
      throw FormatException('Missing or invalid "id". Expected String.');
    }

    if (rawName is! String) {
      throw FormatException('Missing or invalid "name". Expected String.');
    }

    if (rawPermanent is! List) {
      throw FormatException(
        'Missing or invalid "permanentEntities". Expected list.',
      );
    }

    if (rawDiscovered is! List) {
      throw FormatException(
        'Missing or invalid "discoveredEntities". Expected list.',
      );
    }

    final zoneId = ZoneId.values.firstWhere(
      (z) => z.name == rawId,
      orElse: () => throw FormatException('Invalid ZoneId "\$rawId".'),
    );

    //final permanentEntities = rawPermanent.map((e) {
    //  if (e is! Map<String, dynamic>) {
    //    throw FormatException('Invalid permanent entity entry.');
    //  }
    //  return Entity.fromJson(e);
    // }).toList();

    // entities the current content no longer defines are skipped rather than
    // rejecting the whole save. that is what lets an entity be retired — the
    // campfires that became fire buffs, for instance — without a bespoke
    // migration for every removal.
    final discoveredEntities = <Entity>[];
    for (final e in rawDiscovered) {
      if (e is! Map<String, dynamic>) {
        throw FormatException('Invalid discovered entity entry.');
      }
      try {
        discoveredEntities.add(Entity.fromJson(e));
      } on FormatException {
        continue;
      }
    }

    // discoveredItems is explore-session state, so it isn't saved: a
    // reloaded zone starts with an empty find list
    return Zone(
      id: zoneId,
      name: rawName,
      permanentEntities: [],
      discoveredEntities: discoveredEntities,
    );
  }
}

class ZoneDefinition {
  final ZoneId id;
  final String name;
  final List<EntityId> permanentEntities;
  final List<WeightedDropTableEntry<EntityId>> discoverableEntities;
  // items are on a separate drop table and have a chance to drop when
  // an exploration action happens.
  final List<WeightedDropTableEntry<ItemId>> discoverableItems;
  final String iconAsset;

  /// Skill level gate for entering the zone; NULL/0 means unrestricted.
  /// Separate from (and additional to) [explorationLevel].
  final SkillId requiredSkill;
  final int requiredLevel;

  /// The zone's base difficulty, as an Exploration level. It gates entry
  /// and is the baseline every discoverable's [WeightedDropTableEntry
  /// .unlockLevel] and the find-count curve are measured against. 0 means
  /// unrestricted.
  final int explorationLevel;

  /// Average Exploration xp one explore action in this zone is worth. The
  /// per-entity award divides this pool by drop weight, so rare finds pay
  /// more while the expected rate stays exactly this number — extra finds
  /// grant no xp, which keeps a zone's xp/hr flat however far it has been
  /// outlevelled.
  final double xpPerExplore;

  ZoneDefinition({
    required this.id,
    required this.name,
    required this.discoverableEntities,
    required this.permanentEntities,
    this.discoverableItems = const [],
    required this.iconAsset,
    this.requiredSkill = SkillId.NULL,
    this.requiredLevel = 0,
    this.explorationLevel = 0,
    this.xpPerExplore = 0,
  });
}

class ZoneCatalog {
  static final Map<ZoneId, ZoneDefinition> _zones = {};
  static ZoneId activeZone = ZoneId.SOUTHWOOD_FOREST;

  // travel edges with stamina costs; the world map is a path/tree.
  // farm <-5-> forest <-1-> mine
  static const Map<ZoneId, Map<ZoneId, double>> _connections = {
    ZoneId.TUTORIAL_FARM: {ZoneId.SOUTHWOOD_FOREST: 5},
    ZoneId.SOUTHWOOD_FOREST: {ZoneId.TUTORIAL_FARM: 5, ZoneId.SOUTH_HAVEN: 10},
    ZoneId.SOUTH_HAVEN: {ZoneId.SOUTHWOOD_FOREST: 10, ZoneId.FOREST_MINE: 1},
    ZoneId.FOREST_MINE: {ZoneId.SOUTH_HAVEN: 10},
  };

  /// Unique travel edges (each bidirectional pair listed once), for
  /// drawing the path graph on the map.
  static List<(ZoneId, ZoneId, double)> travelEdges() {
    final seen = <String>{};
    final edges = <(ZoneId, ZoneId, double)>[];
    _connections.forEach((from, destinations) {
      destinations.forEach((to, cost) {
        final key = ([from.index, to.index]..sort()).join('-');
        if (seen.add(key)) {
          edges.add((from, to, cost));
        }
      });
    });
    return edges;
  }

  /// Total stamina cost to travel from [from] to [to], summing the edge
  /// costs along the path. The dev forest is always free to enter and
  /// leave. Returns [double.infinity] when no path exists.
  double travelCost(ZoneId from, ZoneId to) {
    if (from == to) return 0;
    if (from == ZoneId.DEV_FOREST || to == ZoneId.DEV_FOREST) return 0;

    final visited = <ZoneId>{from};
    final queue = <(ZoneId, double)>[(from, 0)];
    while (queue.isNotEmpty) {
      final (zone, costSoFar) = queue.removeAt(0);
      for (final edge in (_connections[zone] ?? const {}).entries) {
        if (!visited.add(edge.key)) continue;
        final total = costSoFar + edge.value;
        if (edge.key == to) return total;
        queue.add((edge.key, total));
      }
    }
    return double.infinity;
  }

  final nullZone = ZoneDefinition(
    id: ZoneId.NULL,
    name: "error",
    discoverableEntities: [],
    permanentEntities: [],
    iconAsset: "",
  );

  ZoneCatalog() {
    _initialize();
  }

  ZoneDefinition getDefinitionFor(ZoneId zoneId) {
    if (_zones.containsKey(zoneId)) {
      return _zones[zoneId] ?? nullZone;
    } else {
      return nullZone;
    }
  }

  List<ZoneDefinition> get all => _zones.values.toList();

  void _initialize() {
    // starting zone: a gentle tutorial farm with trees, a pond, and
    // chickens to learn woodcutting, fishing, and combat on
    _zones[ZoneId.TUTORIAL_FARM] = ZoneDefinition(
      id: ZoneId.TUTORIAL_FARM,
      name: "Southglen Meadow",
      iconAsset: "assets/images/zones/farm.png",
      explorationLevel: 1,
      xpPerExplore: 8,

      permanentEntities: [
        EntityId.TRANQUIL_POND,
        EntityId.FIREPIT,
        EntityId.FARMER,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.OAK_TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.CHICKEN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COW, weight: 1),
        // the skill's first payoff: an existing rare, now something you
        // earn rather than something you stumble into on turn one
        WeightedDropTableEntry<EntityId>(
          id: EntityId.BIG_RED,
          weight: .1,
          unlockLevel: 4,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ROTWOOD_SCARECROW,
          weight: .05,
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
    );
    _zones[ZoneId.SOUTHWOOD_FOREST] = ZoneDefinition(
      id: ZoneId.SOUTHWOOD_FOREST,
      iconAsset: 'assets/images/zones/forest.png',
      explorationLevel: 5,
      xpPerExplore: 20,

      name: "Southwood Forest",
      permanentEntities: [
        EntityId.TRANQUIL_POND,
        EntityId.FIREPIT,
        EntityId.SPIDER_DEN_ENTRANCE,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.OAK_TREE, weight: .5),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: .5),
        // herb geography: the low herbs grow here once you can spot them,
        // which is what makes Herbalism reachable through Exploration
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GUAM,
          weight: 1,
          count: 3,
          unlockLevel: 8,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MARRENTILL,
          weight: .7,
          count: 3,
          unlockLevel: 8,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TARROMIN,
          weight: .5,
          count: 3,
          unlockLevel: 8,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GIANT_SPIDER,
          weight: .3,
          unlockLevel: 11,
        ),
        // the valuable herb everyone wants, reserved for explorers who
        // have really learned these woods
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RANARR,
          weight: .1,
          count: 3,
          unlockLevel: 17,
        ),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.LOGS,
          count: 1,
          highCount: 5,
          weight: .15,
          unlockLevel: 8,
        ),
        WeightedDropTableEntry(
          id: ItemId.ENCHANTING_ESSENCE,
          weight: .03,
          unlockLevel: 14,
        ),
        WeightedDropTableEntry(id: ItemId.NULL, weight: 1),
      ],
    );
    // a town: nothing to discover, so exploring here turns up nothing
    _zones[ZoneId.SOUTH_HAVEN] = ZoneDefinition(
      id: ZoneId.SOUTH_HAVEN,
      iconAsset: 'assets/images/zones/south_haven.png',
      explorationLevel: 1,

      name: "South Haven",
      permanentEntities: [
        EntityId.ANVIL,
        EntityId.FIREPIT,
        EntityId.TRADING_POST,
      ],
      discoverableEntities: [],
    );

    // a mine deeper in the forest; gated behind mining experience on top
    // of its exploration difficulty
    _zones[ZoneId.FOREST_MINE] = ZoneDefinition(
      id: ZoneId.FOREST_MINE,
      name: "Forest Mine",
      iconAsset: 'assets/images/zones/mine.png',
      requiredSkill: SkillId.MINING,
      requiredLevel: 5,
      explorationLevel: 15,
      xpPerExplore: 50,

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
    );

    // dev/test zone: every entity is discoverable
    _zones[ZoneId.DEV_FOREST] = ZoneDefinition(
      id: ZoneId.DEV_FOREST,
      name: "Dev Forest",
      iconAsset: 'assets/images/zones/forest.png',
      xpPerExplore: 10,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.ANVIL,
        EntityId.ENCHANTING_BENCH,
        EntityId.JEWELCRAFTING_BENCH,
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
    );

    _zones[ZoneId.CHALLENGING_MOUNTAIN] = ZoneDefinition(
      id: ZoneId.CHALLENGING_MOUNTAIN,
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
    );
  }
}
