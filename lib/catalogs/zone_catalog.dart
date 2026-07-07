import 'entity_catalog.dart';
import '../services/weighted_drop_table_service.dart';

enum ZoneId {
  TUTORIAL_FARM,
  STARTING_FOREST,
  CHALLENGING_MOUNTAIN,
  DEV_FOREST,
  NULL,
}

class Zone {
  final ZoneId id;
  final String name;
  final List<Entity> permanentEntities;
  final List<Entity> discoveredEntities;

  Zone({
    required this.id,
    required this.name,
    required this.discoveredEntities,
    required this.permanentEntities,
  });

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

    final permanentEntities = rawPermanent.map((e) {
      if (e is! Map<String, dynamic>) {
        throw FormatException('Invalid permanent entity entry.');
      }
      return Entity.fromJson(e);
    }).toList();

    final discoveredEntities = rawDiscovered.map((e) {
      if (e is! Map<String, dynamic>) {
        throw FormatException('Invalid discovered entity entry.');
      }
      return Entity.fromJson(e);
    }).toList();

    return Zone(
      id: zoneId,
      name: rawName,
      permanentEntities: permanentEntities,
      discoveredEntities: discoveredEntities,
    );
  }
}

class ZoneDefinition {
  final ZoneId id;
  final String name;
  final List<EntityId> permanentEntities;
  final List<WeightedDropTableEntry<EntityId>> discoverableEntities;
  final String iconAsset;

  ZoneDefinition({
    required this.id,
    required this.name,
    required this.discoverableEntities,
    required this.permanentEntities,
    required this.iconAsset,
  });
}

// todo make a zone builder that has access to entity catalog

class ZoneCatalog {
  static final Map<ZoneId, ZoneDefinition> _zones = {};
  static ZoneId activeZone = ZoneId.STARTING_FOREST;
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

  void _initialize() {
    // starting zone: a gentle tutorial farm with trees, a pond, and
    // chickens to learn woodcutting, fishing, and combat on
    _zones[ZoneId.TUTORIAL_FARM] = ZoneDefinition(
      id: ZoneId.TUTORIAL_FARM,
      name: "Blanchy's Farm",
      iconAsset: "assets/images/zones/farm.png",

      permanentEntities: [EntityId.TRANQUIL_POND],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.CHICKEN, weight: 2),
      ],
    );
    _zones[ZoneId.STARTING_FOREST] = ZoneDefinition(
      id: ZoneId.STARTING_FOREST,
      iconAsset: 'assets/images/zones/forest.png',

      name: "The Forest",
      permanentEntities: [EntityId.ANVIL, EntityId.TRANQUIL_POND],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );

    // dev/test zone: every entity is discoverable
    _zones[ZoneId.DEV_FOREST] = ZoneDefinition(
      id: ZoneId.DEV_FOREST,
      name: "Dev Forest",
      iconAsset: 'assets/images/zones/forest.png',

      permanentEntities: [
        EntityId.ANVIL,
        EntityId.ENCHANTING_BENCH,
        EntityId.DEEP_POND,
        EntityId.RIVER,
        EntityId.LAKE,
        EntityId.OCEAN,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.OAK_TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.CHICKEN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.TRANQUIL_POND, weight: 1),
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
