import '../catalogs/items/items.dart';
import '../catalogs/zones/zones.dart';
import '../data/action_result.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../data/world_data.dart';
import '../data/zone_details.dart';
import '../services/exploration_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';

/// Owns the explore action: resolving what a zone can currently yield,
/// rolling it, and paying out xp and loot. Sits above the services because
/// one explore touches world, player, skill and inventory state at once.
class ExplorationSystem {
  final ExplorationService _explorationService;
  final PlayerDataService _playerDataService;
  final WeightedDropTableService _dropTableService;
  final InventoryService _inventoryService;

  ExplorationSystem({
    required ExplorationService explorationService,
    required PlayerDataService playerDataService,
    required WeightedDropTableService dropTableService,
    required InventoryService inventoryService,
  }) : _explorationService = explorationService,
       _playerDataService = playerDataService,
       _dropTableService = dropTableService,
       _inventoryService = inventoryService;

  /// The player's Exploration level including gear and buffs, matching the
  /// convention every other level gate in the game uses.
  int explorationLevel(PlayerData playerState, {DateTime? at}) {
    return _playerDataService.getStatTotals(
          playerState,
          at: at,
        )[SkillId.EXPLORATION] ??
        1;
  }

  /// Runs [numTimesToExplore] explore actions in the player's current zone,
  /// defaulting to one.
  ///
  /// One explore rolls [ExplorationService.rollFindCount] finds; each find
  /// rolls the zone's unlocked entity table and its unlocked item table.
  /// Only the first find of an explore pays exploration xp, so outlevelling
  /// a zone multiplies its loot without touching its xp rate.
  ///
  /// With [offline] set the whole batch is settled in a single pass: the
  /// find count is the exact mean rather than a per-explore roll, and each
  /// table is rolled through [WeightedDropTableService.rollMulitpleTimes].
  /// That pays the same xp and the same expected loot as looping, which is
  /// what lets hours of offline progress resolve in one call.
  ExploreResult explore({
    required PlayerData playerState,
    required WorldData worldState,
    required InventoryData playerInventory,
    int numTimesToExplore = 1,
    bool offline = false,
    DateTime? at,
  }) {
    final result = ExploreResult();
    final zone = playerState.currentZoneId.definition;
    final level = explorationLevel(playerState, at: at);

    final entityEntries = _explorationService.getZoneEntityDropTableEntries(
      playerState,
      level,
    );
    final itemEntries = _explorationService.getZoneItemDropTableEntries(
      playerState,
      level,
    );

    // a zone with nothing left to find (town zones, or everything still
    // locked) yields nothing rather than rolling an empty table
    if (entityEntries.isEmpty) return result;

    result.actionsPerformed = numTimesToExplore;

    if (offline) {
      result.findCount =
          (_explorationService.findsPerExplore(level, zone.explorationLevel) *
                  numTimesToExplore)
              .floor();
    } else {
      result.findCount = _explorationService.rollFindCount(
        level,
        zone.explorationLevel,
      );
    }

    if (offline) {
      // both tables are rolled once per FIND, not once per explore - the
      // same as the loop below. an outlevelled zone yields several finds an
      // explore, and batching must not quietly drop them.
      result.entities.addAll(
        _dropTableService.rollMulitpleTimes(result.findCount, entityEntries),
      );
      // add new entities to the zone.
      for (final ent in result.entities) {
        _explorationService.addEntityToCurrentZone(
          ent.id,
          ent.count,
          playerState,
          worldState,
        );
      }
      // one explore's worth of xp per explore. the loop below splits the
      // pool inversely to drop weight, which averages to exactly this.
      result.xp = zone.xpPerExplore * numTimesToExplore;

      // zones without an item table yield nothing; rolling an empty table
      // has no meaningful result
      if (itemEntries.isNotEmpty) {
        // the item table carries a NULL "found nothing" entry, so a batch
        // roll of it is mostly nothing. it is dropped rather than reported.
        final rolledItems = _dropTableService
            .rollMulitpleTimes(result.findCount, itemEntries)
            .where((i) => i.id != ItemId.NULL && i.count > 0)
            .toList();

        // add items to zone
        final found = _explorationService.addItemsToCurrentZone(
          rolledItems,
          playerState,
          worldState,
        );
        // a find is kept by the player; the zone list is just the session's
        // running tally of what this explore turned up
        if (found) {
          _inventoryService.addItems(playerInventory, rolledItems);
          result.items.addAll(rolledItems);
        }
      }
    } else {
      for (var find = 0; find < result.findCount; find++) {
        final rolled = _dropTableService.roll(entityEntries);
        _explorationService.addEntityToCurrentZone(
          rolled.id,
          rolled.count,
          playerState,
          worldState,
        );
        result.entities.add(rolled);

        // only the first find is worth xp, which is what keeps a zone's
        // xp/hr flat however far the player has outlevelled it
        if (find == 0) {
          final entry = entityEntries.firstWhere((e) => e.id == rolled.id);
          result.xp = _explorationService.xpForFind(
            entry,
            entityEntries,
            zone.xpPerExplore,
          );
        }

        // zones without an item table yield nothing; rolling an empty table
        // has no meaningful result
        if (itemEntries.isEmpty) continue;

        final rolledItem = _dropTableService.roll(itemEntries);
        // the item table has a null item entry so item are not found
        // on every explore action. exploration services checks for null item
        // id before adding it to the inventory
        final found = _explorationService.addItemToCurrentZone(
          rolledItem.id,
          rolledItem.count,
          playerState,
          worldState,
        );
        // a find is kept by the player; the zone list is just the session's
        // running tally of what this explore turned up
        if (found) {
          _inventoryService.addItems(playerInventory, [rolledItem]);
          result.items.add(rolledItem);
        }
      }
    }

    if (result.xp > 0) {
      _playerDataService.applyXp(playerState, {SkillId.EXPLORATION: result.xp});
    }

    return result;
  }

  /// Everything the zone detail screen shows for [zoneId]: the zone's own
  /// gates, the player's standing in it, and every discovery it holds —
  /// including the ones still locked, so the screen can show what the
  /// skill still has to offer here.
  ZoneDetails buildZoneDetails(PlayerData playerState, ZoneId zoneId) {
    final zone = zoneId.definition;
    final level = explorationLevel(playerState);

    final unlockedEntities = WeightedDropTableService.availableAt(
      zone.discoverableEntities,
      level,
    );
    final unlockedItems = WeightedDropTableService.availableAt(
      zone.discoverableItems,
      level,
    );

    final entities = <ZoneDiscovery>[];
    for (final entry in zone.discoverableEntities) {
      final def = entry.id.definition;
      final locked = level < entry.unlockLevel;
      entities.add(
        ZoneDiscovery(
          name: def.name,
          iconAsset: def.iconAsset,
          unlockLevel: entry.unlockLevel,
          locked: locked,
          chance: locked
              ? 0
              : _explorationService.findChance(entry, unlockedEntities),
          xp: locked
              ? 0
              : _explorationService.xpForFind(
                  entry,
                  unlockedEntities,
                  zone.xpPerExplore,
                ),
          minCount: entry.count,
          maxCount: entry.highCount > entry.count
              ? entry.highCount
              : entry.count,
        ),
      );
    }

    final items = <ZoneDiscovery>[];
    for (final entry in zone.discoverableItems) {
      // the NULL entry is the table's "found nothing" filler, not content
      if (entry.id == ItemId.NULL) continue;
      final def = entry.id.definition;
      final locked = level < entry.unlockLevel;
      items.add(
        ZoneDiscovery(
          name: def.name,
          iconAsset: def.iconAsset ?? '',
          unlockLevel: entry.unlockLevel,
          locked: locked,
          chance: locked
              ? 0
              : _explorationService.findChance(entry, unlockedItems),
          // found items pay no exploration xp
          xp: 0,
          minCount: entry.count,
          maxCount: entry.highCount > entry.count
              ? entry.highCount
              : entry.count,
        ),
      );
    }

    // baseline entries first, then in the order they unlock
    int byUnlock(ZoneDiscovery a, ZoneDiscovery b) =>
        a.unlockLevel.compareTo(b.unlockLevel);
    entities.sort(byUnlock);
    items.sort(byUnlock);

    return ZoneDetails(
      zone: zone,
      explorationLevel: level,
      findsPerExplore: _explorationService.findsPerExplore(
        level,
        zone.explorationLevel,
      ),
      entities: entities,
      items: items,
    );
  }
}
