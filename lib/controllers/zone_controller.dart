import 'package:rpg/data/zone_location.dart';

import '../data/zone.dart';
import '../data/entity.dart';
import 'weighted_drop_table.dart';
import '../data/ObjectStack.dart';
import '../data/zone_location.dart';

class ZoneController {
  static final Map<Zones, Zone> _zones = {};

  ZoneController() {
    _initialize();
  }

  void _initialize() {
    _zones[Zones.TUTORIAL_FARM] = Zone(
      id: Zones.TUTORIAL_FARM,
      name: "Blanchy's Farm",
      permanentLocations: [],
      discoverableEntities: [
        WeightedDropTableEntry<Entities>(item: Entities.TREE, weight: 2),
        WeightedDropTableEntry<Entities>(item: Entities.GOBLIN, weight: 1),
        WeightedDropTableEntry<Entities>(item: Entities.COPPER, weight: 1),
      ],
    );
    _zones[Zones.STARTING_FOREST] = Zone(
      id: Zones.STARTING_FOREST,
      name: "The Forest",
      permanentLocations: [ZoneLocationType.ANVIL],
      discoverableEntities: [
        WeightedDropTableEntry<Entities>(item: Entities.TREE, weight: 2),
        WeightedDropTableEntry<Entities>(item: Entities.GOBLIN, weight: 1),
        WeightedDropTableEntry<Entities>(item: Entities.COPPER, weight: 1),
      ],
    );

    _zones[Zones.CHALLENGING_MOUNTAIN] = Zone(
      id: Zones.CHALLENGING_MOUNTAIN,
      name: "The Mountain",
      permanentLocations: [],

      discoverableEntities: [
        WeightedDropTableEntry<Entities>(item: Entities.TREE, weight: 2),
        WeightedDropTableEntry<Entities>(item: Entities.GOBLIN, weight: 1),
        WeightedDropTableEntry<Entities>(item: Entities.COPPER, weight: 1),
      ],
    );
  }

  static List<ZoneLocationType> getZoneLocations(Zones zoneId) {
    return _zones[zoneId]?.permanentLocations ?? [];
  }

  ObjectStack discoverEntity(Zones zoneId) {
    print("discover entity");
    if (_zones[zoneId] == null) {
      return ObjectStack(id: Entities.NULL, count: 0);
    }
    final result = _zones[zoneId]?.entityTable.roll();
    if (result == null) {
      return ObjectStack(id: Entities.NULL, count: 0);
    }
    return result;
  }
}
