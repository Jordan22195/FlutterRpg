import 'package:rpg/data/skill_data.dart';

import '../services/encounter_service.dart';
import '../services/world_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';
import '../services/inventory_service';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog';
import '../data/action_result.dart';
import '../data/player_data.dart';
import '../data/encounter_data.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';

class EncounterSystem {
  final EncounterService encounterService;
  final WorldService worldService;
  final PlayerDataService playerDataService;
  final WeightedDropTableService dropTableService;
  final InventoryService inventoryService;
  final EntityCatalog entityCatalog;
  final ItemCatalog itemCatalog;

  EncounterSystem({
    required this.encounterService,
    required this.worldService,
    required this.playerDataService,
    required this.dropTableService,
    required this.inventoryService,
    required this.entityCatalog,
    required this.itemCatalog,
  });

  /// Runs exactly ONE tick of the currently active encounter.
  /// Mutates player/world/inventories/encounterState as needed.
  ActionResult executePlayerAction({
    required Map<SkillId, int> stats,
    required PlayerData player,
    required EncounterData encounter,
    required WorldData world,
    required InventoryData playerInventory,
  }) {
    final result = ActionResult();

    if (!encounterService.encounterConditionsMet(player, encounter)) {
      return result;
    }

    final e = encounter.entity!;

    // do damage
    final r = encounterService.resolvePlayerDamage(stats, player, encounter);
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
        encounterService.respawn(encounter);
      }

      // todo - count is now in the entity object. make this function
      //  remmove the entity if the count is 0.
      worldService.decrimentEncounterEntity(world, e);

      // roll drops
      final entries = entityCatalog.getDefinitionFor(e.id).itemDrops;
      final drop = dropTableService.roll(entries);
      result.items.add(drop);

      // add drops to inventories (player + encounter history)
      inventoryService.addItems(playerInventory, [drop]);
      inventoryService.addItems(encounter.itemDrops, [drop]);

      // todo move hardcoded multiplier somwhere else
      result.xp[e.entityType] = (5 * result.damageDone).toDouble();
    }

    // Apply XP to player
    if (result.xp.isNotEmpty) {
      playerDataService.applyXp(player, result.xp);
    }

    return result;
  }

  ActionResult executeFishingAction({
    required Map<SkillId, int> stats,
    required PlayerData player,
    required EncounterData encounter,
    required WorldData world,
    required InventoryData playerInventory,
  }) {
    final result = ActionResult();

    if (!encounterService.fishingConditionsMet(player, encounter)) {
      return result;
    }

    final e = encounter.entity!;

    // do damage
    final r = encounterService.resolvePlayerDamage(stats, player, encounter);
    result.damageDone = r.damageDone;
    result.enemyDied = r.enemyDied;

    if (result.damageDone <= 0) {
      return result; // miss/no progress this tick
    }

    // roll drops
    final entries = entityCatalog.getDefinitionFor(e.id).itemDrops;
    final drop = dropTableService.roll(entries);
    result.items.add(drop);

    // add drops to inventories (player + encounter history)
    inventoryService.addItems(playerInventory, [drop]);
    inventoryService.addItems(encounter.itemDrops, [drop]);

    result.xp[SkillId.FISHING] =
        itemCatalog.definitionFor(drop.id)?.xpValue ?? 0 * drop.count;

    // Apply XP to player
    if (result.xp.isNotEmpty) {
      playerDataService.applyXp(player, result.xp);
    }

    return result;
  }
}
