import 'package:rpg/data/skill_data.dart';

import '../services/combat_auto_eat_service.dart';
import '../services/encounter_service.dart';
import '../services/exploration_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';
import '../catalogs/entity_catalog.dart';
import '../data/action_result.dart';
import '../data/entity_details.dart';
import '../data/player_data.dart';
import '../data/encounter_data.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';
import '../data/ObjectStack.dart';
import '../services/inventory_service.dart';
import '../catalogs/item_catalog.dart';

class EncounterSystem {
  /// XP awarded per point of damage done by damage-based skills (combat,
  /// woodcutting, mining). Also used by the explore screen to estimate a
  /// node's xp yield.
  static const double xpPerDamage = 5;

  final EncounterService _encounterService;
  final ExplorationService _explorationService;
  final PlayerDataService _playerDataService;
  final WeightedDropTableService _dropTableService;
  final InventoryService _inventoryService;
  final EntityCatalog _entityCatalog;
  final ItemCatalog _itemCatalog;
  final CombatAutoEatService _autoEatService;

  EncounterSystem({
    required EncounterService encounterService,
    required ExplorationService explorationService,
    required PlayerDataService playerDataService,
    required WeightedDropTableService dropTableService,
    required InventoryService inventoryService,
    required EntityCatalog entityCatalog,
    required ItemCatalog itemCatalog,
    required CombatAutoEatService autoEatService,
  }) : _itemCatalog = itemCatalog,
       _entityCatalog = entityCatalog,
       _inventoryService = inventoryService,
       _dropTableService = dropTableService,
       _playerDataService = playerDataService,
       _explorationService = explorationService,
       _encounterService = encounterService,
       _autoEatService = autoEatService;

  /// Auto-eats one equipped food when hp is low (shared rule). Used during
  /// automated combat (manual encounters and queued encounters both run
  /// through the timing loop). Returns true when it ate.
  bool autoEat({
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    return _autoEatService.autoEat(
      playerState: playerState,
      playerInventory: playerInventory,
    );
  }

  /// Runs exactly ONE tick of the currently active encounter.
  /// Mutates player/world/inventories/encounterState as needed.
  ActionResult executePlayerAction({
    required PlayerData playerState,
    required EncounterData encounter,
    required WorldData worldState,
    required InventoryData playerInventory,
    // a dungeon card's queue has the next enemy step straight up, with no
    // respawn pause between them
    bool instantRespawn = false,
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
    result.xp[e.entityType] = xpPerDamage * result.damageDone;

    // combat also trains hitpoints, at a third of the attack xp rate
    if (e is CombatEntity) {
      result.xp[SkillId.HITPOINTS] = (xpPerDamage * result.damageDone) / 3.0;
    }

    // Handle death
    if (result.enemyDied) {
      // decrement world entity count
      encounter.entity!.count--;
      if (encounter.entity!.count > 0) {
        _encounterService.respawn(encounter, e, instant: instantRespawn);
      } else {
        //_explorationService.removeEntityFromZone(
        //  e.id,
        //  playerState.currentZoneId,
        //  worldState,
        //);
      }

      // roll drops: the guaranteed main drop plus any layered bonus rolls
      // (rare uniques, bulk stacks) the entity defines
      final def =
          _entityCatalog.getDefinitionFor(e.id) as EncounterEntityDefinition;
      final drops = <ObjectStack<ItemId>>[
        _dropTableService.roll(def.itemDrops),
        ..._dropTableService.rollBonus(def.bonusDrops),
      ];
      result.items.addAll(drops);

      // add drops to inventories (player + encounter history)
      _inventoryService.addItems(playerInventory, drops);
      _inventoryService.addItems(encounter.itemDrops, drops);
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

  /// Estimated xp for fully consuming ONE count of [e], mirroring the xp
  /// the actions actually award: damage-based skills accrue
  /// [xpPerDamage] per damage (one kill/fell/deplete deals the node's full
  /// hitpoints), while fishing and herbalism award the caught item's
  /// xpValue (weighted average across the drop table).
  double xpPerUnit(EncounterEntity e) {
    final def = _entityCatalog.getDefinitionFor(e.id);
    if (def is! EncounterEntityDefinition) return 0;

    switch (e.entityType) {
      case SkillId.FISHING:
      case SkillId.HERBALISM:
        double weightSum = 0;
        double xpSum = 0;
        for (final entry in def.itemDrops) {
          final xp = _itemCatalog.definitionFor(entry.id)?.xpValue ?? 0;
          weightSum += entry.weight;
          xpSum += entry.weight * xp * entry.count;
        }
        return weightSum <= 0 ? 0 : xpSum / weightSum;
      default:
        return xpPerDamage * def.hitpoints;
    }
  }

  /// Assembles the entity details snapshot the info popup renders: the
  /// entity's own stats, its drop table with per-kill probabilities, and
  /// the to-hit rolls both ways against the player's current stats.
  EntityDetails buildEntityDetails({
    required PlayerData playerState,
    required EncounterEntity entity,
  }) {
    final stats = _playerDataService.getStatTotals(playerState);
    final playerSkill = stats[entity.entityType] ?? 0;
    final playerDefence = stats[SkillId.DEFENCE] ?? 1;

    // the player's roll against the entity's difficulty. for damage-based
    // skills this is the to-hit chance; for herbs it is the chance each
    // bonus-yield roll succeeds
    final playerHitChance = _encounterService.chanceToHit(
      playerSkill,
      entity.defence,
    );

    final combat = entity is CombatEntity ? entity : null;

    return EntityDetails(
      entity: entity,
      requiredLevel: herbRequiredLevel(entity.id),
      xpPerUnit: xpPerUnit(entity),
      playerSkillLevel: playerSkill,
      playerDefence: playerDefence,
      playerMaxHp: stats[SkillId.HITPOINTS] ?? 1,
      playerHitChance: playerHitChance,
      playerMaxHit: _encounterService.computeMaxHit(
        attack: playerSkill,
        defense: entity.defence,
      ),
      entityHitChance: combat == null
          ? 0
          : _encounterService.chanceToHit(combat.attack, playerDefence),
      entityMaxHit: combat == null
          ? 0
          : _encounterService.computeMaxHit(
              attack: combat.attack,
              defense: playerDefence,
            ),
      // one guaranteed herb plus one per successful bonus roll
      expectedYield: entity.entityType == SkillId.HERBALISM
          ? 1 + EncounterService.herbBonusRolls * playerHitChance
          : 0,
      drops: _buildDropChances(entity.id),
    );
  }

  /// The entity's drop table as per-kill probabilities: the main table
  /// always yields exactly one pick, and each layered bonus roll
  /// contributes its own pick with its own firing chance.
  List<EntityDropChance> _buildDropChances(EntityId id) {
    final def = _entityCatalog.getDefinitionFor(id);
    if (def is! EncounterEntityDefinition) return const [];

    return [
      ..._dropRows(def.itemDrops, rollChance: 1.0, bonus: false),
      for (final roll in def.bonusDrops)
        ..._dropRows(roll.entries, rollChance: roll.chance, bonus: true),
    ];
  }

  List<EntityDropChance> _dropRows(
    List<WeightedDropTableEntry<ItemId>> entries, {
    required double rollChance,
    required bool bonus,
  }) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.weight);
    if (total <= 0) return const [];

    final rows = [
      for (final e in entries)
        EntityDropChance(
          itemId: e.id,
          name: _itemCatalog.definitionFor(e.id)?.name ?? e.id.name,
          chance: rollChance * (e.weight / total),
          minCount: e.count,
          maxCount: e.highCount > e.count ? e.highCount : e.count,
          bonus: bonus,
        ),
    ];
    // commonest first, so the chase drops sit at the bottom of the table
    rows.sort((a, b) => b.chance.compareTo(a.chance));
    return rows;
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
