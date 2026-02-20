import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/zone_location.dart';

import '../data/zone.dart';
import '../data/entity.dart';
import 'weighted_drop_table.dart';
import '../data/ObjectStack.dart';
import '../data/item.dart';
import 'package:flutter/material.dart';

class ZoneController {
  static final Map<Zones, Zone> _zones = {};
  static Zones activeZone = Zones.STARTING_FOREST;

  ZoneController() {
    _initialize();
  }

  void _initialize() {
    _zones[Zones.TUTORIAL_FARM] = Zone(
      id: Zones.TUTORIAL_FARM,
      name: "Blanchy's Farm",
      permanentLocations: [],
      discoverableEntities: [
        WeightedDropTableEntry<Entities>(id: Entities.TREE, weight: 2),
        WeightedDropTableEntry<Entities>(id: Entities.GOBLIN, weight: 1),
        WeightedDropTableEntry<Entities>(id: Entities.COPPER, weight: 1),
      ],
    );
    _zones[Zones.STARTING_FOREST] = Zone(
      id: Zones.STARTING_FOREST,
      name: "The Forest",
      permanentLocations: [ZoneLocationId.ANVIL, ZoneLocationId.POND_1],
      discoverableEntities: [
        WeightedDropTableEntry<Entities>(id: Entities.TREE, weight: 2),
        WeightedDropTableEntry<Entities>(id: Entities.GOBLIN, weight: 1),
        WeightedDropTableEntry<Entities>(id: Entities.COPPER, weight: 1),
      ],
    );

    _zones[Zones.CHALLENGING_MOUNTAIN] = Zone(
      id: Zones.CHALLENGING_MOUNTAIN,
      name: "The Mountain",
      permanentLocations: [],

      discoverableEntities: [
        WeightedDropTableEntry<Entities>(id: Entities.TREE, weight: 2),
        WeightedDropTableEntry<Entities>(id: Entities.GOBLIN, weight: 1),
        WeightedDropTableEntry<Entities>(id: Entities.COPPER, weight: 1),
      ],
    );
  }

  static void removeCampfireFromCurrentZone() {
    final zone = _zones[activeZone];
    if (zone == null) {
      debugPrint("Error: Zone with id $activeZone not found.");
      return;
    }
    if (!zone.permanentLocations.contains(ZoneLocationId.CAMPFIRE)) {
      return;
    }

    zone.permanentLocations.remove(ZoneLocationId.CAMPFIRE);
    PlayerDataController.instance.refresh();
  }

  static void addCampfireToCurrentZone(Item fireItem) {
    final zone = _zones[activeZone];
    if (zone == null) {
      debugPrint("Error: Zone with id $activeZone not found.");
      return;
    }
    if (zone.permanentLocations.contains(ZoneLocationId.CAMPFIRE)) {
      return;
    }

    (ZoneLocationController.locations[ZoneLocationId.CAMPFIRE]
                as CampfireLocation)
            .fireId =
        fireItem.id;
    zone.permanentLocations.add(ZoneLocationId.CAMPFIRE);
    PlayerDataController.instance.refresh();
  }

  static List<ZoneLocationId> getZoneLocations(Zones zoneId) {
    return _zones[zoneId]?.permanentLocations ?? [];
  }

  static Zone? getZone(Zones zoneId) {
    return _zones[zoneId];
  }

  ObjectStack discoverEntity(Zones zoneId) {
    debugPrint("discover entity");
    if (_zones[zoneId] == null) {
      return ObjectStack(id: Entities.NULL, count: 0);
    }
    final result = WeightedDropTable.roll(_zones[zoneId]!.discoverableEntities);

    return result;
  }
}
