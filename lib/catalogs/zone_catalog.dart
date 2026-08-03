import 'entity_catalog.dart';
import '../data/skill_data.dart';
import '../data/ObjectStack.dart';
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

  /// Items found while exploring this zone. Kept separate from the player's
  /// inventory for now; the two get wired together later.
  final List<ObjectStack<ItemId>> discoveredItems;

  Zone({
    required this.id,
    required this.name,
    required this.discoveredEntities,
    required this.permanentEntities,
    List<ObjectStack<ItemId>>? discoveredItems,
  }) : discoveredItems = discoveredItems ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'name': name,
      'permanentEntities': permanentEntities.map((e) => e.toJson()).toList(),
      'discoveredEntities': discoveredEntities.map((e) => e.toJson()).toList(),
      'discoveredItems': discoveredItems
          .map((s) => {'id': s.id.name, 'count': s.count})
          .toList(),
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

    final discoveredEntities = rawDiscovered.map((e) {
      if (e is! Map<String, dynamic>) {
        throw FormatException('Invalid discovered entity entry.');
      }
      return Entity.fromJson(e);
    }).toList();

    // absent in saves written before zones kept their own item inventory
    final rawItems = json['discoveredItems'];
    final discoveredItems = <ObjectStack<ItemId>>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is! Map<String, dynamic>) continue;
        final rawItemId = entry['id'];
        final rawCount = entry['count'];
        if (rawItemId is! String || rawCount is! int) continue;
        final itemId = ItemId.values.firstWhere(
          (i) => i.name == rawItemId,
          orElse: () => ItemId.NULL,
        );
        if (itemId == ItemId.NULL) continue;
        discoveredItems.add(ObjectStack<ItemId>(id: itemId, count: rawCount));
      }
    }

    return Zone(
      id: zoneId,
      name: rawName,
      permanentEntities: [],
      discoveredEntities: discoveredEntities,
      discoveredItems: discoveredItems,
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
  List<WeightedDropTableEntry<ItemId>> discoverableItems;
  final String iconAsset;

  /// Skill level gate for entering the zone; NULL/0 means unrestricted.
  final SkillId requiredSkill;
  final int requiredLevel;

  ZoneDefinition({
    required this.id,
    required this.name,
    required this.discoverableEntities,
    required this.permanentEntities,
    this.discoverableItems = const [],
    required this.iconAsset,
    this.requiredSkill = SkillId.NULL,
    this.requiredLevel = 0,
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
        WeightedDropTableEntry<EntityId>(id: EntityId.BIG_RED, weight: .1),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.COINS,
          count: 1,
          highCount: 10,
          weight: .1,
        ),
        WeightedDropTableEntry(id: ItemId.NULL, weight: 1),
      ],
    );
    _zones[ZoneId.SOUTHWOOD_FOREST] = ZoneDefinition(
      id: ZoneId.SOUTHWOOD_FOREST,
      iconAsset: 'assets/images/zones/forest.png',

      name: "Southwood Forest",
      permanentEntities: [EntityId.TRANQUIL_POND],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.OAK_TREE, weight: .5),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: .5),
      ],
    );
    _zones[ZoneId.SOUTH_HAVEN] = ZoneDefinition(
      id: ZoneId.SOUTH_HAVEN,
      iconAsset: 'assets/images/zones/south_haven.png',

      name: "South Haven",
      permanentEntities: [EntityId.ANVIL, EntityId.TRADING_POST],
      discoverableEntities: [],
    );

    // a mine deeper in the forest; gated behind mining experience
    _zones[ZoneId.FOREST_MINE] = ZoneDefinition(
      id: ZoneId.FOREST_MINE,
      name: "Forest Mine",
      iconAsset: 'assets/images/zones/mine.png',
      requiredSkill: SkillId.MINING,
      requiredLevel: 5,

      permanentEntities: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GIANT_SPIDER, weight: 1),
      ],
    );

    // dev/test zone: every entity is discoverable
    _zones[ZoneId.DEV_FOREST] = ZoneDefinition(
      id: ZoneId.DEV_FOREST,
      name: "Dev Forest",
      iconAsset: 'assets/images/zones/forest.png',

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

      permanentEntities: [],

      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );
  }
}
