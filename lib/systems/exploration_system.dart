import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../catalogs/zone_catalog.dart';
import '../data/ObjectStack.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../data/world_data.dart';
import '../data/zone_details.dart';
import '../services/exploration_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';

/// What one explore action turned up.
class ExploreResult {
  /// Entities discovered, in the order they were found.
  final List<ObjectStack<EntityId>> entities = [];

  /// Items found, already credited to the player and the zone tally.
  final List<ObjectStack<ItemId>> items = [];

  /// Exploration xp awarded. Only the first find is worth xp, so this is
  /// the xp of [entities].first and nothing else.
  double xp = 0;

  /// How many finds the action rolled — 1 plus whatever the player's
  /// exploration level over the zone earned.
  int findCount = 0;
}

/// Owns the explore action: resolving what a zone can currently yield,
/// rolling it, and paying out xp and loot. Sits above the services because
/// one explore touches world, player, skill and inventory state at once.
class ExplorationSystem {
  final ExplorationService _explorationService;
  final PlayerDataService _playerDataService;
  final WeightedDropTableService _dropTableService;
  final InventoryService _inventoryService;
  final EntityCatalog _entityCatalog;
  final ItemCatalog _itemCatalog;
  final ZoneCatalog _zoneCatalog;

  ExplorationSystem({
    required ExplorationService explorationService,
    required PlayerDataService playerDataService,
    required WeightedDropTableService dropTableService,
    required InventoryService inventoryService,
    required EntityCatalog entityCatalog,
    required ItemCatalog itemCatalog,
    required ZoneCatalog zoneCatalog,
  }) : _explorationService = explorationService,
       _playerDataService = playerDataService,
       _dropTableService = dropTableService,
       _inventoryService = inventoryService,
       _entityCatalog = entityCatalog,
       _itemCatalog = itemCatalog,
       _zoneCatalog = zoneCatalog;

  /// The player's Exploration level including gear and buffs, matching the
  /// convention every other level gate in the game uses.
  int explorationLevel(PlayerData playerState) {
    return _playerDataService.getStatTotals(playerState)[SkillId.EXPLORATION] ??
        1;
  }

  /// Runs exactly ONE explore action in the player's current zone.
  ///
  /// Rolls [ExplorationService.rollFindCount] finds; each find rolls the
  /// zone's unlocked entity table and its unlocked item table. Only the
  /// first find pays exploration xp, so outlevelling a zone multiplies its
  /// loot without touching its xp rate.
  ExploreResult explore({
    required PlayerData playerState,
    required WorldData worldState,
    required InventoryData playerInventory,
  }) {
    final result = ExploreResult();
    final zone = _zoneCatalog.getDefinitionFor(playerState.currentZoneId);
    final level = explorationLevel(playerState);

    final entityEntries = _explorationService.getZoneEntityDropTableEntries(
      playerState,
      _zoneCatalog,
      level,
    );
    final itemEntries = _explorationService.getZoneItemDropTableEntries(
      playerState,
      _zoneCatalog,
      level,
    );

    // a zone with nothing left to find (town zones, or everything still
    // locked) yields nothing rather than rolling an empty table
    if (entityEntries.isEmpty) return result;

    result.findCount = _explorationService.rollFindCount(
      level,
      zone.explorationLevel,
    );

    for (var find = 0; find < result.findCount; find++) {
      final rolled = _dropTableService.roll(entityEntries);
      _explorationService.addEntityToCurrentZone(
        rolled.id,
        rolled.count,
        _entityCatalog,
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
    final zone = _zoneCatalog.getDefinitionFor(zoneId);
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
      final def = _entityCatalog.getDefinitionFor(entry.id);
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
      final def = _itemCatalog.definitionFor(entry.id);
      final locked = level < entry.unlockLevel;
      items.add(
        ZoneDiscovery(
          name: def?.name ?? entry.id.name,
          iconAsset: def?.iconAsset ?? '',
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
