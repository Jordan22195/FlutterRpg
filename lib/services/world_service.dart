import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/ObjectStack.dart';
import '../catalogs/entity_catalog.dart';
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

  List<WeightedDropTableEntry> getZoneEntityDropTableEntries(
    PlayerData playerState,
    ZoneCatalog zoneCatalog,
  ) {
    final zone = zoneCatalog.getDefinitionFor(playerState.currentZoneId);
    return zone.discoverableEntities;
  }

  List<WeightedDropTableEntry<ItemId>> getZoneItemDropTableEntries(
    PlayerData playerState,
    ZoneCatalog zoneCatalog,
  ) {
    final zone = zoneCatalog.getDefinitionFor(playerState.currentZoneId);
    return zone.discoverableItems;
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
    EntityId entityId,
    int entityCount,
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

    final e = getDiscoveredEntity(entityId, zone);

    if (e == null) {
      final newEnt = entityCatalog
          .getDefinitionFor(entityId)
          .toEntity(entityId);

      if (newEnt is EncounterEntity) {
        newEnt.count = entityCount;
      }

      zone.discoveredEntities.add(newEnt);
    } else if (e is EncounterEntity) {
      e.count += entityCount;
    }
  }

  /// Adds [count] of [itemId] to the current zone's own item inventory,
  /// merging onto an existing stack. NULL ids are the drop table's "found
  /// nothing" entry and are ignored.
  void addItemToCurrentZone(
    ItemId itemId,
    int count,
    PlayerData playerState,
    WorldData worldState,
  ) {
    if (itemId == ItemId.NULL || count <= 0) return;

    final zone = worldState.zones[playerState.currentZoneId];
    if (zone == null) return;

    for (final stack in zone.discoveredItems) {
      if (stack.id == itemId) {
        stack.count += count;
        return;
      }
    }
    zone.discoveredItems.add(ObjectStack<ItemId>(id: itemId, count: count));
  }

  List<ObjectStack<ItemId>> getCurrentZoneItems(
    PlayerData playerState,
    WorldData worldState,
  ) {
    final zone = worldState.zones[playerState.currentZoneId] ?? nullZone;
    return zone.discoveredItems;
  }

  void removeEntityFromZone(
    EntityId entityId,
    ZoneId zoneId,
    WorldData worldState,
  ) {
    final zone = worldState.zones[zoneId] ?? nullZone;
    zone.discoveredEntities.removeWhere((e) => e.id == entityId);
  }

  List<Entity> getCurrentZoneEntities(
    PlayerData playerState,
    WorldData worldState,
  ) {
    final allEnts = <Entity>[];
    final zone = worldState.zones[playerState.currentZoneId] ?? nullZone;

    allEnts.addAll(zone.permanentEntities);
    allEnts.addAll(zone.discoveredEntities);
    return allEnts;
  }
}
