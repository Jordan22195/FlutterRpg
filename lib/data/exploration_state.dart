import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:flutter/material.dart';

import 'zone.dart';
import 'skill.dart';
import 'entity.dart';

class ExploreController {
  Map<Zones, Map<Entities, int>> discoveredEntities;
  Map<Zones, Map<Entities, EntityEncounter>> entityEncounters = {};

  // Singleton implementation
  static final ExploreController instance = ExploreController._internal();

  factory ExploreController({
    Map<Zones, Map<Entities, int>>? discoveredEntities,
  }) {
    if (discoveredEntities != null) {
      instance.discoveredEntities = discoveredEntities;
    }
    return instance;
  }

  ExploreController._internal() : discoveredEntities = {};

  Map<String, dynamic> toJson() {
    return {
      'discoveredEntities': discoveredEntities.map(
        (zone, entityMap) => MapEntry(
          zone.name,
          entityMap.map((entity, count) => MapEntry(entity.name, count)),
        ),
      ),
    };
  }

  factory ExploreController.fromJson(Map<String, dynamic> json) {
    final rawZones = json['discoveredEntities'] as Map<String, dynamic>? ?? {};

    final Map<Zones, Map<Entities, int>> discovered = {};

    for (final zoneEntry in rawZones.entries) {
      final zone = Zones.values.firstWhere(
        (z) => z.name == zoneEntry.key,
        orElse: () => Zones.values.first, // safe fallback
      );

      final rawEntities = zoneEntry.value as Map<String, dynamic>;
      final Map<Entities, int> entityMap = {};

      for (final entityEntry in rawEntities.entries) {
        final entity = Entities.values.firstWhere(
          (e) => e.name == entityEntry.key,
          orElse: () => Entities.values.first, // safe fallback
        );

        entityMap[entity] = entityEntry.value as int;
      }

      discovered[zone] = entityMap;
    }

    return ExploreController(discoveredEntities: discovered);
  }

  List<ObjectStack> getEntityList(Zones zoneId) {
    List<ObjectStack> list = [];
    if (discoveredEntities[zoneId] == null) return list;
    for (final entry in discoveredEntities[zoneId]!.entries) {
      ObjectStack e = ObjectStack(id: entry.key, count: entry.value);
      list.add(e);
    }
    return list;
  }

  EntityEncounter getEntityEncounter(Zones zoneId, Entities entityId) {
    final zoneEncounters = entityEncounters[zoneId];
    if (zoneEncounters == null) {
      final e = EntityEncounter(entityId: entityId);
      entityEncounters[zoneId] = {entityId: e};
      debugPrint(
        "No zone found. creating new encounter for $entityId in $zoneId with hp ${e.entity.hitpoints} and max hp ${e.entity.maxHitPoints}",
      );
      return e;
    }

    final encounter = zoneEncounters[entityId];
    if (encounter == null) {
      final e = EntityEncounter(entityId: entityId);
      entityEncounters[zoneId]![entityId] = e;
      debugPrint(
        "no encounter found. creating new encounter for $entityId in $zoneId with hp ${e.entity.hitpoints} and max hp ${e.entity.maxHitPoints}",
      );
      return e;
    }
    debugPrint(
      "returning existing encounter for $entityId in $zoneId with hp ${encounter.entity.hitpoints} and max hp ",
    );
    return encounter;
  }

  int getEntityCount(Zones zoneId, Entities entityId) {
    final zoneMap = discoveredEntities[zoneId];
    if (zoneMap == null) return 0;

    final count = zoneMap[entityId];
    if (count == null) return 0;

    return count;
  }

  void clearEntities() {
    discoveredEntities.clear();
  }

  void decrimentEntity(Zones zoneId, Entities entityId, {int count = 1}) {
    final zoneMap = discoveredEntities[zoneId];
    if (zoneMap == null) return;

    zoneMap.update(entityId, (existing) => existing - count);
    if (zoneMap[entityId] == 0) {
      zoneMap.remove(entityId);
    }
  }

  void addEntities(Zones zoneId, Entities id, int count) {
    print("add entities $zoneId, $id, $count");
    discoveredEntities.update(
      zoneId,
      (existing) => existing,
      ifAbsent: () => {},
    );

    final zoneMap = discoveredEntities[zoneId];
    if (zoneMap == null) return;

    zoneMap.update(id, (existing) => existing + count, ifAbsent: () => count);
  }

  Duration maxInterval() {
    return Duration(seconds: 2);
  }
}
