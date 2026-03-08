import 'package:flutter/material.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/catalogs/location_catalog.dart';

import '../catalogs/entity_catalog.dart';
import '../data/ObjectStack.dart';
import '../catalogs/item_catalog.dart';
import 'weighted_drop_table_service.dart';
import '../catalogs/zone_catalog.dart';

class WorldService {
  List<WeightedDropTableEntry> getZoneDropTableEntries(
    PlayerData playerState,
    ZoneCatalog zoneCatalog,
  ) {
    final zone = zoneCatalog.getDefinitionFor(playerState.currentZoneId);
    return zone.discoverableEntities;
  }

  // get the entity instance of the player view
  Entity getSelectedEntity(PlayerData playerState, WorldData worldState) {
    return worldState.discoveredEntitiesByZone[playerState
            .currentZoneId]?[playerState.currentEntityViewId] ??
        Entity(id: EntityId.NULL, name: "error");
  }

  void decrimentEncounterEntity(WorldData worldState, Entity entity) {}

  void addEntityToCurrentZone(
    ObjectStack<EntityId> newEntity,
    EntityCatalog entityCatalog,
    PlayerData playerState,
    WorldData worldState,
  ) {
    final zoneId = playerState.currentZoneId;

    // create the zone entry if it does not exist
    if (!worldState.discoveredEntitiesByZone.containsKey(zoneId)) {
      worldState.discoveredEntitiesByZone[zoneId] = {};
    }

    Map<EntityId, Entity> entityMap =
        worldState.discoveredEntitiesByZone[zoneId] ?? {};

    if (entityMap.containsKey(newEntity.id)) {
      final e = entityMap[newEntity.id];
      if (e is EncounterEntity) {
        e.count += newEntity.count;
      }
    } else {
      entityMap[newEntity.id] = entityCatalog
          .getDefinitionFor(newEntity.id)
          .toEntity(newEntity.id);
      final e = entityMap[newEntity.id];
      if (e is EncounterEntity) {
        e.count = newEntity.count;
      }
    }
  }

  // todo change this to not modify the catalog
  void removeCampfireFromCurrentZone(
    PlayerData playerState,
    WorldData worldState,
    ZoneCatalog zoneCatalog,
  ) {
    final zone = zoneCatalog.getDefinitionFor(playerState.currentZoneId);

    if (!zone.permanentLocations.contains(LocationId.CAMPFIRE)) {
      return;
    }

    zone.permanentLocations.remove(LocationId.CAMPFIRE);
  }

  // todo don't modify the catalog
  void addCampfireToCurrentZone(
    Item fireItem,
    PlayerData playerState,
    WorldData worldState,
    ZoneCatalog zoneCatalog,
  ) {
    final zone = zoneCatalog.getDefinitionFor(playerState.currentZoneId);

    if (zone.permanentLocations.contains(LocationId.CAMPFIRE)) {
      return;
    }

    (LocationCatalog.locations[LocationId.CAMPFIRE] as CampfireLocation)
            .fireId =
        fireItem.id;
    zone.permanentLocations.add(LocationId.CAMPFIRE);
  }

  List<LocationId> getCurrentZoneLocations(
    PlayerData playerState,
    WorldData worldState,
    ZoneCatalog zoneCatalog,
  ) {
    final zone = zoneCatalog.getDefinitionFor(playerState.currentZoneId);
    return zone.permanentLocations;
  }

  Map<EntityId, int> getCurrentZoneEntities(
    PlayerData playerState,
    WorldData worldState,
  ) {
    final zoneId = playerState.currentZoneId;
    if (worldState.discoveredEntitiesByZone.containsKey(zoneId)) {
      return worldState.discoveredEntitiesByZone[zoneId] ?? {};
    } else {
      return {};
    }
  }
}
