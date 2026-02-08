import 'package:rpg/data/ObjectStack.dart';

import 'zone.dart';
import 'entity.dart';

class ZoneState {
  Map<Zones, Map<Entities, int>> discoveredEntities;

  ZoneState({required this.discoveredEntities});

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

  factory ZoneState.fromJson(Map<String, dynamic> json) {
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

    return ZoneState(discoveredEntities: discovered);
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
}
