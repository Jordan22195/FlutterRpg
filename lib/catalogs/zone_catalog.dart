import 'entity_catalog.dart';
import '../services/weighted_drop_table_service.dart';

enum ZoneId { TUTORIAL_FARM, STARTING_FOREST, CHALLENGING_MOUNTAIN, NULL }

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

  ZoneDefinition({
    required this.id,
    required this.name,
    required this.discoverableEntities,
    required this.permanentEntities,
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
    _zones[ZoneId.TUTORIAL_FARM] = ZoneDefinition(
      id: ZoneId.TUTORIAL_FARM,
      name: "Blanchy's Farm",
      permanentEntities: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );
    _zones[ZoneId.STARTING_FOREST] = ZoneDefinition(
      id: ZoneId.STARTING_FOREST,
      name: "The Forest",
      permanentEntities: [EntityId.ANVIL, EntityId.TRANQUIL_POND],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );

    _zones[ZoneId.CHALLENGING_MOUNTAIN] = ZoneDefinition(
      id: ZoneId.CHALLENGING_MOUNTAIN,
      name: "The Mountain",
      permanentEntities: [],

      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );
  }
}
