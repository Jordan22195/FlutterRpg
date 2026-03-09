import 'package:rpg/data/skill_data.dart';

import '../services/encounter_service.dart';
import '../services/world_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';
import '../catalogs/entity_catalog.dart';
import '../data/action_result.dart';
import '../data/player_data.dart';
import '../data/encounter_data.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';
import '../services/inventory_service.dart';
import '../catalogs/item_catalog.dart';

class EncounterSystem {
  final EncounterService _encounterService;
  final WorldService _worldService;
  final PlayerDataService _playerDataService;
  final WeightedDropTableService _dropTableService;
  final InventoryService _inventoryService;
  final EntityCatalog _entityCatalog;
  final ItemCatalog _itemCatalog;

  EncounterSystem({
    required EncounterService encounterService,
    required WorldService worldService,
    required PlayerDataService playerDataService,
    required WeightedDropTableService dropTableService,
    required InventoryService inventoryService,
    required EntityCatalog entityCatalog,
    required ItemCatalog itemCatalog,
  }) : _itemCatalog = itemCatalog,
       _entityCatalog = entityCatalog,
       _inventoryService = inventoryService,
       _dropTableService = dropTableService,
       _playerDataService = playerDataService,
       _worldService = worldService,
       _encounterService = encounterService;

  /// Runs exactly ONE tick of the currently active encounter.
  /// Mutates player/world/inventories/encounterState as needed.
  ActionResult executePlayerAction({
    required PlayerData playerState,
    required EncounterData encounter,
    required WorldData worldState,
    required InventoryData playerInventory,
  }) {
    final result = ActionResult();

    final stats = _playerDataService.getStatTotals(playerState);

    if (!_encounterService.encounterConditionsMet(playerState, encounter)) {
      return result;
    }

    final e = encounter.entity!;

    // do damage
    final r = _encounterService.resolvePlayerDamage(
      stats,
      playerState,
      encounter,
    );
    result.damageDone = r.damageDone;
    result.enemyDied = r.enemyDied;

    if (result.damageDone <= 0) {
      return result; // miss/no progress this tick
    }

    // Handle death
    if (result.enemyDied) {
      // decrement world entity count
      encounter.entity!.count--;
      if (encounter.entity!.count > 0) {
        _encounterService.respawn(encounter);
      } else {
        _worldService.removeEntityFromZone(
          e.id,
          playerState.currentZoneId,
          worldState,
        );
      }

      // roll drops
      final entries =
          (_entityCatalog.getDefinitionFor(e.id) as EncounterEntityDefinition)
              .itemDrops;
      final drop = _dropTableService.roll(entries);
      result.items.add(drop);

      // add drops to inventories (player + encounter history)
      _inventoryService.addItems(playerInventory, [drop]);
      _inventoryService.addItems(encounter.itemDrops, [drop]);

      // todo move hardcoded multiplier somwhere else
      result.xp[e.entityType] = (5 * result.damageDone).toDouble();
    }

    // Apply XP to player
    if (result.xp.isNotEmpty) {
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result;
  }

  ActionResult executeFishingAction({
    required PlayerData playerState,
    required EncounterData encounter,
    required WorldData world,
    required InventoryData playerInventory,
  }) {
    final result = ActionResult();
    final stats = _playerDataService.getStatTotals(playerState);

    if (!_encounterService.fishingConditionsMet(playerState, encounter)) {
      return result;
    }

    final e = encounter.entity!;

    // do damage
    final r = _encounterService.resolvePlayerDamage(
      stats,
      playerState,
      encounter,
    );
    result.damageDone = r.damageDone;
    result.enemyDied = r.enemyDied;

    if (result.damageDone <= 0) {
      return result; // miss/no progress this tick
    }

    // roll drops
    final entries =
        (_entityCatalog.getDefinitionFor(e.id) as EncounterEntityDefinition)
            .itemDrops;
    final drop = _dropTableService.roll(entries);
    result.items.add(drop);

    // add drops to inventories (player + encounter history)
    _inventoryService.addItems(playerInventory, [drop]);
    _inventoryService.addItems(encounter.itemDrops, [drop]);

    result.xp[SkillId.FISHING] =
        (_itemCatalog.definitionFor(drop.id)?.xpValue ?? 0 * drop.count)
            as double;

    // Apply XP to player
    if (result.xp.isNotEmpty) {
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result;
  }
}
