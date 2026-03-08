import 'package:rpg/catalogs/location_catalog.dart';

import 'entity_catalog.dart';
import '../services/weighted_drop_table_service.dart';

enum ZoneId { TUTORIAL_FARM, STARTING_FOREST, CHALLENGING_MOUNTAIN, NULL }

class Zone {
  final ZoneId id;
  final String name;
  final List<LocationId> permanentLocations;
  final List<WeightedDropTableEntry<EntityId>> discoverableEntities;

  Zone({
    required this.id,
    required this.name,
    required this.discoverableEntities,
    required this.permanentLocations,
  });
}

class ZoneCatalog {
  static final Map<ZoneId, Zone> _zones = {};
  static ZoneId activeZone = ZoneId.STARTING_FOREST;
  final nullZone = Zone(
    id: ZoneId.NULL,
    name: "error",
    discoverableEntities: [],
    permanentLocations: [],
  );

  ZoneCatalog() {
    _initialize();
  }

  Zone getDefinitionFor(ZoneId zoneId) {
    if (_zones.containsKey(zoneId)) {
      return _zones[zoneId] ?? nullZone;
    } else {
      return nullZone;
    }
  }

  void _initialize() {
    _zones[ZoneId.TUTORIAL_FARM] = Zone(
      id: ZoneId.TUTORIAL_FARM,
      name: "Blanchy's Farm",
      permanentLocations: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );
    _zones[ZoneId.STARTING_FOREST] = Zone(
      id: ZoneId.STARTING_FOREST,
      name: "The Forest",
      permanentLocations: [LocationId.ANVIL, LocationId.POND_1],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );

    _zones[ZoneId.CHALLENGING_MOUNTAIN] = Zone(
      id: ZoneId.CHALLENGING_MOUNTAIN,
      name: "The Mountain",
      permanentLocations: [],

      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    );
  }
}
