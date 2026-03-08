import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:flutter/material.dart';
import '../catalogs/zone_catalog.dart';

import '../catalogs/entity_catalog.dart';

class WorldData {

  // use entity Id locate the instance of the entity type so the service can
  //  update the count. 
  final Map<ZoneId, Map<EntityId, Entity>> discoveredEntitiesByZone;
  
  // map of all entities with uuid as the key so you can get the entity instance
  // without knowing the zone. 
  // .. you still need to know the zone in order to keep the counts syncd.
  //  unless the entries in discoveredEntities is pointing to the same object instance
  //  in discoveredEntities. 
  //  I would need a function to go manually find it and removed it from discovereEntitiesByZone
  //  when the count decriments to zero. 
  final Map<String, Entity> discoveredEntities; 

  WorldData({required this.discoveredEntitiesByZone});

  factory WorldData({Map<ZoneId, Map<EntityId, int>>? discoveredEntities}) {
    if (discoveredEntities != null) {
      discoveredEntities = discoveredEntities;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'discoveredEntities': discoveredEntitiesByZone.map(
        (zone, entityMap) => MapEntry(
          zone.name,
          entityMap.map((entity, count) => MapEntry(entity.name, count)),
        ),
      ),
    };
  }

  factory WorldData.fromJson(Map<String, dynamic> json) {
    final rawZones = json['discoveredEntities'] as Map<String, dynamic>? ?? {};

    final Map<ZoneId, Map<EntityId, int>> discovered = {};

    for (final zoneEntry in rawZones.entries) {
      final zone = ZoneId.values.firstWhere(
        (z) => z.name == zoneEntry.key,
        orElse: () => ZoneId.values.first, // safe fallback
      );

      final rawEntities = zoneEntry.value as Map<String, dynamic>;
      final Map<EntityId, int> entityMap = {};

      for (final entityEntry in rawEntities.entries) {
        final entity = EntityId.values.firstWhere(
          (e) => e.name == entityEntry.key,
          orElse: () => EntityId.values.first, // safe fallback
        );

        entityMap[entity] = entityEntry.value as int;
      }

      discovered[zone] = entityMap;
    }

    return WorldData(discoveredEntitiesByZone: discovered);
  }
}
ß