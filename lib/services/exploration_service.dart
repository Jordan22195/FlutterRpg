import 'dart:math';

import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/ObjectStack.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import 'inventory_service.dart';
import 'weighted_drop_table_service.dart';
import '../catalogs/zones/zones.dart';

class ExplorationService {
  // zone item finds are stored as an InventoryData, so stacking and
  // clearing go through the same service the player inventory uses
  final InventoryService _inventoryService;

  ExplorationService({InventoryService? inventoryService})
    : _inventoryService = inventoryService ?? InventoryService();

  /// Exploration levels above a zone's own level that each add one whole
  /// extra find per explore. The single knob for how much outlevelling a
  /// zone pays — lower means faster scaling.
  static const double levelsPerExtraFind = 10.0;

  Zone nullZone = Zone(
    id: ZoneId.NULL,
    name: "",
    discoveredEntities: [],
    permanentEntities: [],
  );

  // ---- exploration math ----

  /// Average number of things one explore turns up, uncapped: 1.00 at the
  /// zone's own level and climbing linearly from there. Never below 1.00,
  /// since the zone's entry gate means the player is never under-levelled
  /// for it. This is also exactly the number the zone detail screen shows.
  double findsPerExplore(int explorationLevel, int zoneLevel) {
    final over = (explorationLevel - zoneLevel) / levelsPerExtraFind;
    return 1.0 + (over < 0 ? 0.0 : over);
  }

  /// One explore's find count. The whole part is guaranteed and the
  /// fractional part is the chance of one more, so the mean over many
  /// rolls is exactly [findsPerExplore].
  int rollFindCount(int explorationLevel, int zoneLevel, {Random? rng}) {
    final finds = findsPerExplore(explorationLevel, zoneLevel);
    final guaranteed = finds.floor();
    final remainder = finds - guaranteed;
    return guaranteed + ((rng ?? Random()).nextDouble() < remainder ? 1 : 0);
  }

  /// An entry's share of its table: what fraction of finds it accounts for.
  double findChance<T>(
    WeightedDropTableEntry<T> entry,
    List<WeightedDropTableEntry<T>> unlocked,
  ) {
    final total = unlocked.fold<double>(0, (sum, e) => sum + e.weight);
    if (total <= 0) return 0;
    return entry.weight / total;
  }

  /// Exploration xp for discovering [entry], splitting the zone's
  /// [xpPerExplore] pool inversely to drop weight:
  ///
  ///   xp_i = xpPerExplore * W / (n * w_i)
  ///
  /// so a find that happens half as often is worth twice as much, and the
  /// expected xp of a single explore stays exactly [xpPerExplore] whatever
  /// the table contains. That is what lets rares be added to a zone
  /// without re-balancing its xp rate.
  double xpForFind<T>(
    WeightedDropTableEntry<T> entry,
    List<WeightedDropTableEntry<T>> unlocked,
    double xpPerExplore,
  ) {
    if (unlocked.isEmpty || entry.weight <= 0) return 0;
    final total = unlocked.fold<double>(0, (sum, e) => sum + e.weight);
    return xpPerExplore * total / (unlocked.length * entry.weight);
  }

  // ---- zone drop tables ----

  /// The current zone's discoverable entities the player has unlocked.
  /// [explorationLevel] gates individual entries, so a zone's rarer finds
  /// simply are not in the table until the player has earned them.
  List<WeightedDropTableEntry<EntityId>> getZoneEntityDropTableEntries(
    PlayerData playerState,
    int explorationLevel,
  ) {
    final zone = playerState.currentZoneId.definition;
    return WeightedDropTableService.availableAt(
      zone.discoverableEntities,
      explorationLevel,
    );
  }

  List<WeightedDropTableEntry<ItemId>> getZoneItemDropTableEntries(
    PlayerData playerState,
    int explorationLevel,
  ) {
    final zone = playerState.currentZoneId.definition;
    return WeightedDropTableService.availableAt(
      zone.discoverableItems,
      explorationLevel,
    );
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
      final newEnt = entityId.build();

      if (newEnt is EncounterEntity) {
        newEnt.count = entityCount;
      }

      zone.discoveredEntities.add(newEnt);
    } else if (e is EncounterEntity) {
      e.count += entityCount;
    }
  }

  /// Adds every stack in [items] to the current zone's explore find list,
  /// merging onto existing stacks. NULL ids are the drop table's "found
  /// nothing" entry and are skipped — a batch roll almost always contains
  /// one, and it must not stop the real finds behind it from landing.
  /// Returns true when anything was added, so the caller knows whether to
  /// credit the player inventory too.
  bool addItemsToCurrentZone(
    List<ObjectStack<ItemId>> items,
    PlayerData playerState,
    WorldData worldState,
  ) {
    final zone = worldState.zones[playerState.currentZoneId];
    if (zone == null) return false;

    var added = false;
    for (final i in items) {
      if (i.id == ItemId.NULL || i.count <= 0) continue;

      _inventoryService.addItems(zone.discoveredItems, [i]);
      added = true;
    }
    return added;
  }

  /// Adds [count] of [itemId] to the current zone's explore find list,
  /// merging onto an existing stack. NULL ids are the drop table's "found
  /// nothing" entry and are ignored. Returns true when something was added,
  /// so the caller knows whether to credit the player inventory too.
  bool addItemToCurrentZone(
    ItemId itemId,
    int count,
    PlayerData playerState,
    WorldData worldState,
  ) {
    if (itemId == ItemId.NULL || count <= 0) return false;

    final zone = worldState.zones[playerState.currentZoneId];
    if (zone == null) return false;

    _inventoryService.addItems(zone.discoveredItems, [
      ObjectStack<ItemId>(id: itemId, count: count),
    ]);
    return true;
  }

  /// The current zone's explore finds, as grid-ready stacks.
  List<ObjectStack> getCurrentZoneItems(
    PlayerData playerState,
    WorldData worldState,
  ) {
    final zone = worldState.zones[playerState.currentZoneId] ?? nullZone;
    return _inventoryService.getObjectStackList(zone.discoveredItems);
  }

  /// Empties the current zone's explore finds, ending its session display.
  void clearCurrentZoneItems(PlayerData playerState, WorldData worldState) {
    final zone = worldState.zones[playerState.currentZoneId];
    if (zone == null) return;
    _inventoryService.clearItems(zone.discoveredItems);
  }

  /// dev/testing helper: forces [entityId]'s remaining count in the
  /// player's current zone. A node raised off zero gets its hitpoints back
  /// too — at 0 hp every damage roll caps at 0 and it could never be
  /// depleted again.
  void setEntityCount(
    EntityId entityId,
    int count,
    PlayerData playerState,
    WorldData worldState,
  ) {
    final entity = getEntity(entityId, playerState.currentZoneId, worldState);
    if (entity is! EncounterEntity) return;

    entity.count = count < 0 ? 0 : count;
    if (entity.count > 0 && entity.hitpoints <= 0) {
      entity.hitpoints = entity.maxHitPoints;
    }
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
    return getZoneEntities(playerState.currentZoneId, worldState);
  }

  /// What's standing in [zoneId] right now — its permanent fixtures plus
  /// whatever exploring there has turned up so far. Takes the zone rather
  /// than reading the player's, so the map can show a place without the
  /// player having to be in it.
  List<Entity> getZoneEntities(ZoneId zoneId, WorldData worldState) {
    final allEnts = <Entity>[];
    final zone = worldState.zones[zoneId] ?? nullZone;

    allEnts.addAll(zone.permanentEntities);
    allEnts.addAll(zone.discoveredEntities);
    return allEnts;
  }
}
