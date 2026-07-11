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
import '../data/ObjectStack.dart';
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

    // xp accrues on every damaging action, scaled by the damage done
    // todo move hardcoded multiplier somwhere else
    result.xp[e.entityType] = (5 * result.damageDone).toDouble();

    // combat also trains hitpoints, at a third of the attack xp rate
    if (e is CombatEntity) {
      result.xp[SkillId.HITPOINTS] = (5 * result.damageDone) / 3.0;
    }

    // Handle death
    if (result.enemyDied) {
      // decrement world entity count
      encounter.entity!.count--;
      if (encounter.entity!.count > 0) {
        _encounterService.respawn(encounter, e);
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
    }

    // Apply XP to player
    if (result.xp.isNotEmpty) {
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result;
  }

  /// Eats one of the equipped food items: consumes it from the player
  /// inventory and restores its heal amount, capped at max hp. Returns
  /// false (and changes nothing) when no edible food is equipped, the
  /// inventory is out, or the player is already at full health.
  bool eatEquipedFood({
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    final foodId = playerState.equipmentData.equipedFood;
    if (foodId == ItemId.NULL) return false;

    final def = _itemCatalog.definitionFor(foodId);
    if (def is! FoodItemDefinition) return false;

    if (_inventoryService.getItemCount(playerInventory, foodId) <= 0) {
      return false;
    }

    final maxHp =
        _playerDataService.getStatTotals(playerState)[SkillId.HITPOINTS] ?? 1;
    if (playerState.hitpoints >= maxHp) return false; // don't waste food

    _inventoryService.removeItems(playerInventory, foodId, 1);
    _playerDataService.heal(def.restoreAmount, playerState);
    return true;
  }

  /// Rolls the active combat entity's attack against the player and
  /// applies the damage. Returns the damage dealt.
  int executeEntityAttack({
    required PlayerData playerState,
    required EncounterData encounter,
  }) {
    final stats = _playerDataService.getStatTotals(playerState);
    final result = _encounterService.entityAttack(encounter, stats);
    _playerDataService.applyDamage(result.damageDone, playerState);

    // blocked hits award defence xp for the damage avoided
    if (result.xp.isNotEmpty) {
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result.damageDone;
  }

  /// Herbalism level required to pick [id]; 0 for non-herb entities.
  int herbRequiredLevel(EntityId id) {
    final def = _entityCatalog.getDefinitionFor(id);
    return def is HerbEntityDefinition ? def.requiredLevel : 0;
  }

  /// Whether the player's herbalism (with tool bonuses, matching the
  /// zone-gate convention) meets the herb's level requirement. True for
  /// non-herb entities.
  bool meetsHerbRequirement(PlayerData playerState, EntityId id) {
    final level =
        _playerDataService.getStatTotals(playerState)[SkillId.HERBALISM] ?? 0;
    return level >= herbRequiredLevel(id);
  }

  /// One herbalism gather tick: always succeeds, consumes one count from
  /// the herb node, and rolls yield against the herb's difficulty.
  ActionResult executeHerbalismAction({
    required PlayerData playerState,
    required EncounterData encounter,
    required WorldData worldState,
    required InventoryData playerInventory,
  }) {
    final result = ActionResult();
    final stats = _playerDataService.getStatTotals(playerState);

    if (!_encounterService.herbalismConditionsMet(playerState, encounter)) {
      return result;
    }

    final e = encounter.entity!;
    final def = _entityCatalog.getDefinitionFor(e.id);
    if (def is! HerbEntityDefinition) return result;
    if (!meetsHerbRequirement(playerState, e.id)) return result;

    final gathered = _encounterService.rollHerbYield(
      herbalismStat: stats[SkillId.HERBALISM] ?? 1,
      defence: e.defence,
    );

    // one pick consumes one herb from the node; no hp/respawn cycle
    e.count--;
    if (e.count <= 0) {
      _worldService.removeEntityFromZone(
        e.id,
        playerState.currentZoneId,
        worldState,
      );
    }

    final rolled = _dropTableService.roll(def.itemDrops);
    final drop = ObjectStack<ItemId>(id: rolled.id, count: gathered);
    result.items.add(drop);

    // add drops to inventories (player + encounter history)
    _inventoryService.addItems(playerInventory, [drop]);
    _inventoryService.addItems(encounter.itemDrops, [drop]);

    // shown as the per-action feedback number on the encounter screen
    result.damageDone = gathered;

    result.xp[SkillId.HERBALISM] =
        ((_itemCatalog.definitionFor(drop.id)?.xpValue ?? 0) * gathered)
            .toDouble();
    _playerDataService.applyXp(playerState, result.xp);

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

    // fishing spots replenish rather than deplete: a spot at 0 hp would cap
    // every damage roll at 0 and never yield another catch
    if (e.hitpoints <= 0) {
      e.hitpoints = e.maxHitPoints;
    }

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
        ((_itemCatalog.definitionFor(drop.id)?.xpValue ?? 0) * drop.count)
            .toDouble();

    // Apply XP to player
    if (result.xp.isNotEmpty) {
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result;
  }
}
