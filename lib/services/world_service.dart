import 'package:flutter/material.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';

import '../catalogs/entity_catalog.dart';
import '../data/ObjectStack.dart';
import '../catalogs/item_catalog.dart';
import 'weighted_drop_table_service.dart';
import '../catalogs/zone_catalog.dart';

class WorldService {
  Zone nullZone = Zone(
    id: ZoneId.NULL,
    name: "",
    discoveredEntities: [],
    permanentEntities: [],
  );

  List<WeightedDropTableEntry> getZoneDropTableEntries(
    PlayerData playerState,
    ZoneCatalog zoneCatalog,
  ) {
    final zone = zoneCatalog.getDefinitionFor(playerState.currentZoneId);
    return zone.discoverableEntities;
  }

  Entity getEntity(EntityId entityId, ZoneId zoneId, WorldData worldState) {
    Zone z =
        worldState.zones[zoneId] ??
        Zone(
          id: ZoneId.NULL,
          name: "",
          discoveredEntities: [],
          permanentEntities: [],
        );
    for (final e in z.permanentEntities) {
      if (e.id == entityId) {
        return e;
      }
    }
    for (final e in z.discoveredEntities) {
      if (e.id == entityId) {
        return e;
      }
    }
    return Entity(id: EntityId.NULL, name: "");
  }

  // get the entity instance of the player view
  Entity getSelectedEntity(PlayerData playerState, WorldData worldState) {
    return getEntity(
      playerState.currentEntityViewId,
      playerState.currentZoneId,
      worldState,
    );
  }

  Entity? getDiscoveredEntity(EntityId id, Zone zone) {
    for (final e in zone.discoveredEntities) {
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }

  void addEntityToCurrentZone(
    ObjectStack<EntityId> newEntity,
    EntityCatalog entityCatalog,
    PlayerData playerState,
    WorldData worldState,
  ) {
    final zoneId = playerState.currentZoneId;

    // create the zone entry if it does not exist
    if (!worldState.zones.containsKey(zoneId)) {
      return;
    }

    final zone = worldState.zones[zoneId] ?? nullZone;
    List<Entity> entities = zone.discoveredEntities;

    final e = getDiscoveredEntity(newEntity.id, zone);

    if (e == null) {
      final newEnt = entityCatalog
          .getDefinitionFor(newEntity.id)
          .toEntity(newEntity.id);

      if (newEnt is EncounterEntity) {
        newEnt.count = newEntity.count;
      }

      zone.discoveredEntities.add(newEnt);
    }
  }

  // todo change this to not modify the catalog
  void removeCampfireFromZone(ZoneId zoneId, WorldData worldState) {
    final zone = worldState.zones[zoneId] ?? nullZone;
    for (final e in zone.discoveredEntities) {
      if (e is CampfireEntity) {
        zone.discoveredEntities.remove(e);
        return;
      }
    }
  }

  List<Entity> getCurrentZoneEntities(
    PlayerData playerState,
    WorldData worldState,
  ) {
    final allEnts = [] as List<Entity>;
    final zone = worldState.zones[playerState.currentZoneId] ?? nullZone;

    allEnts.addAll(zone.permanentEntities);
    allEnts.addAll(zone.discoveredEntities);
    return allEnts;
  }
}
