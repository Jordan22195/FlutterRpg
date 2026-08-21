import 'package:rpg/data/skill_data.dart';

import '../services/combat_auto_eat_service.dart';
import '../services/encounter_service.dart';
import '../services/exploration_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';
import '../catalogs/entities/entities.dart';
import '../data/action_result.dart';
import '../data/entity_details.dart';
import '../data/player_data.dart';
import '../data/encounter_data.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';
import '../data/ObjectStack.dart';
import '../services/inventory_service.dart';
import '../catalogs/items/items.dart';

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
  final CombatAutoEatService _autoEatService;

  EncounterSystem({
    required EncounterService encounterService,
    required ExplorationService explorationService,
    required PlayerDataService playerDataService,
    required WeightedDropTableService dropTableService,
    required InventoryService inventoryService,
    required CombatAutoEatService autoEatService,
  }) : _inventoryService = inventoryService,
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

  /// Runs n ticks of the currently active encounter.
  /// Mutates player/world/inventories/encounterState as needed.
  ///
  /// With [offline] set the whole count is settled in one pass off average
  /// damage rather than rolled tick by tick, which is what lets a stretch of
  /// time away resolve in a single call.
  EncounterActionResult executePlayerAction({
    required PlayerData playerState,
    required EncounterData encounter,
    required WorldData worldState,
    required InventoryData playerInventory,
    // a dungeon card's queue has the next enemy step straight up, with no
    // respawn pause between them
    bool instantRespawn = false,
    int actionCount = 1,
    bool offline = false,
    DateTime? at,
  }) {
    final result = EncounterActionResult();

    final stats = _playerDataService.getStatTotals(playerState, at: at);

    if (!_encounterService.encounterConditionsMet(playerState, encounter)) {
      return result;
    }

    final e = encounter.entity!;

    if (offline) {
      // calculate average damage per action
      double avgDamage = _encounterService.playerAverageDamage(
        stats,
        playerState,
        encounter,
      );

      // calculate actions to kill
      double actionToKill = _encounterService.actionsToKill(
        e.maxHitPoints,
        avgDamage,
      );

      // calulate total enemies defeated
      // todo use the remainder to put damage on the last entity
      int enemiesToKill = (actionCount / actionToKill).floor();
      if (enemiesToKill > e.count) {
        enemiesToKill = e.count;
      }
      // roll loot on x enemies
      // roll drops: the guaranteed main drop plus any layered bonus rolls
      // (rare uniques, bulk stacks) the entity defines. a non-encounter
      // entity has no drop table and cannot be fought — guard rather than
      // cast, so bad content is an empty result instead of a crash mid-fight
      final def = e.id.definition;
      if (def is! EncounterEntityDefinition) return result;
      final drops = _dropTableService.rollMulitpleTimes(
        enemiesToKill,
        def.itemDrops,
      );
      drops.addAll(
        _dropTableService.rollBonusMulitpleTimes(enemiesToKill, def.bonusDrops),
      );

      result.items.addAll(drops);

      // add drops to inventories (player + encounter history)
      _inventoryService.addItems(playerInventory, drops);
      _inventoryService.addItems(encounter.itemDrops, drops);

      // decrement entity count by x
      encounter.entity!.count -= enemiesToKill;
      result.entitiesDefeated = [
        ObjectStack<EntityId>(id: e.id, count: enemiesToKill),
      ];

      // the actions those kills actually consumed. a batch too short to
      // finish even one kill did nothing, and says so - the loop settling
      // time away reports what happened, not what it asked for
      final spent = (enemiesToKill * actionToKill).round();
      result.actionsPerformed = spent < actionCount ? spent : actionCount;

      // reward xp
      // todo give defence xp based on stance
      result.xp[e.entityType] = xpPerDamage * enemiesToKill * e.maxHitPoints;
      if (e is CombatEntity) {
        result.xp[SkillId.HITPOINTS] = (xpPerDamage * result.damageDone) / 3.0;
      }
      // Apply XP to player
      if (result.xp.isNotEmpty) {
        _playerDataService.applyXp(playerState, result.xp);
      }

      return result;
    }

    // a swing is a swing whether or not it lands
    result.actionsPerformed = 1;

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
    // todo give defence xp based on stance

    if (e is CombatEntity) {
      result.xp[SkillId.HITPOINTS] = (xpPerDamage * result.damageDone) / 3.0;
    }

    // Handle death
    if (result.enemyDied) {
      result.entitiesDefeated = [ObjectStack<EntityId>(id: e.id, count: 1)];

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
      final def = e.id.definition;
      if (def is! EncounterEntityDefinition) return result;
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

    final def = foodId.definition;
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
    final def = id.definition;
    return def is HerbEntityDefinition ? def.requiredLevel : 0;
  }

  /// Whether the player's herbalism (with tool bonuses, matching the
  /// zone-gate convention) meets the herb's level requirement. True for
  /// non-herb entities.
  bool meetsHerbRequirement(
    PlayerData playerState,
    EntityId id, {
    DateTime? at,
  }) {
    final level =
        _playerDataService.getStatTotals(
          playerState,
          at: at,
        )[SkillId.HERBALISM] ??
        0;
    return level >= herbRequiredLevel(id);
  }

  /// Estimated xp for fully consuming ONE count of [e], mirroring the xp
  /// the actions actually award: damage-based skills accrue
  /// [xpPerDamage] per damage (one kill/fell/deplete deals the node's full
  /// hitpoints), while fishing and herbalism award the caught item's
  /// xpValue (weighted average across the drop table).
  double xpPerUnit(EncounterEntity e) {
    final def = e.id.definition;
    if (def is! EncounterEntityDefinition) return 0;

    switch (e.entityType) {
      case SkillId.FISHING:
      case SkillId.HERBALISM:
        double weightSum = 0;
        double xpSum = 0;
        for (final entry in def.itemDrops) {
          final xp = entry.id.definition.xpValue;
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
    final def = id.definition;
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
          name: e.id.definition.name,
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
  ///
  /// With [offline] set, [actionCount] picks are settled in one pass: the
  /// node gives up as many herbs as it has left, the drop table is rolled
  /// once per pick, and each pick pays the mean of its yield range rather
  /// than a fresh roll. That is the same expected haul as looping, which is
  /// what lets a stretch of time away resolve in one call.
  EncounterActionResult executeHerbalismAction({
    required PlayerData playerState,
    required EncounterData encounter,
    required WorldData worldState,
    required InventoryData playerInventory,
    int actionCount = 1,
    bool offline = false,
    DateTime? at,
  }) {
    final result = EncounterActionResult();
    final stats = _playerDataService.getStatTotals(playerState, at: at);

    if (!_encounterService.herbalismConditionsMet(playerState, encounter)) {
      return result;
    }

    final e = encounter.entity!;
    final def = e.id.definition;
    if (def is! HerbEntityDefinition) return result;
    if (!meetsHerbRequirement(playerState, e.id, at: at)) return result;

    if (offline) {
      return _settleHerbalism(
        playerState: playerState,
        encounter: encounter,
        playerInventory: playerInventory,
        def: def,
        actionCount: actionCount,
        herbalismStat: stats[SkillId.HERBALISM] ?? 1,
      );
    }

    final gathered = _encounterService.rollHerbYield(
      herbalismStat: stats[SkillId.HERBALISM] ?? 1,
      defence: e.defence,
    );

    // one pick consumes one herb from the node; no hp/respawn cycle
    e.count--;
    result.actionsPerformed = 1;

    final rolled = _dropTableService.roll(def.itemDrops);
    final drop = ObjectStack<ItemId>(id: rolled.id, count: gathered);
    result.items.add(drop);

    // add drops to inventories (player + encounter history)
    _inventoryService.addItems(playerInventory, [drop]);
    _inventoryService.addItems(encounter.itemDrops, [drop]);

    // shown as the per-action feedback number on the encounter screen
    result.damageDone = gathered;

    result.xp[SkillId.HERBALISM] = (drop.id.definition.xpValue * gathered)
        .toDouble();
    _playerDataService.applyXp(playerState, result.xp);

    return result;
  }

  /// A batch of [actionCount] picks, settled in one pass.
  ///
  /// A pick always succeeds and always costs one herb, so the node caps the
  /// batch: what it cannot pay for is where the loop would have stopped, and
  /// the controller's conditions re-check stops it there.
  EncounterActionResult _settleHerbalism({
    required PlayerData playerState,
    required EncounterData encounter,
    required InventoryData playerInventory,
    required HerbEntityDefinition def,
    required int actionCount,
    required int herbalismStat,
  }) {
    final result = EncounterActionResult();
    final e = encounter.entity!;

    final picks = actionCount < e.count ? actionCount : e.count;
    if (picks <= 0) return result;

    // one guaranteed herb plus one per successful bonus roll. across a batch
    // those rolls average out, so the mean is paid per pick instead of a
    // random draw each - the same haul, without the draws.
    final meanYield =
        1 +
        EncounterService.herbBonusRolls *
            _encounterService.chanceToHit(herbalismStat, e.defence);

    // the table is rolled once per pick; each roll's stack is then worth a
    // pick's yield, the way a single pick's stack is
    final drops = _dropTableService
        .rollMulitpleTimes(picks, def.itemDrops)
        .map(
          (stack) => ObjectStack<ItemId>(
            id: stack.id,
            count: (stack.count * meanYield).round(),
          ),
        )
        .where((stack) => stack.count > 0)
        .toList();

    e.count -= picks;
    result.actionsPerformed = picks;
    result.items.addAll(drops);

    // add drops to inventories (player + encounter history)
    _inventoryService.addItems(playerInventory, drops);
    _inventoryService.addItems(encounter.itemDrops, drops);

    double xp = 0;
    for (final drop in drops) {
      xp += drop.id.definition.xpValue * drop.count;
      result.damageDone += drop.count;
    }
    if (xp > 0) {
      result.xp[SkillId.HERBALISM] = xp;
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result;
  }

  /// One fishing cast: rolls against the spot's difficulty and, when it
  /// catches, rolls what it caught.
  ///
  /// With [offline] set, [actionCount] casts are settled in one pass: the
  /// catches are the exact expected share of the casts rather than a roll
  /// each, and the drop table is rolled once per catch. A fishing spot never
  /// runs dry, so nothing caps the batch but the casts themselves.
  EncounterActionResult executeFishingAction({
    required PlayerData playerState,
    required EncounterData encounter,
    required WorldData world,
    required InventoryData playerInventory,
    int actionCount = 1,
    bool offline = false,
    DateTime? at,
  }) {
    final result = EncounterActionResult();
    final stats = _playerDataService.getStatTotals(playerState, at: at);

    if (!_encounterService.fishingConditionsMet(playerState, encounter)) {
      return result;
    }

    final e = encounter.entity!;

    if (offline) {
      return _settleFishing(
        playerState: playerState,
        encounter: encounter,
        playerInventory: playerInventory,
        actionCount: actionCount,
        fishingStat: stats[SkillId.FISHING] ?? 1,
      );
    }

    // fishing spots replenish rather than deplete: a spot at 0 hp would cap
    // every damage roll at 0 and never yield another catch
    if (e.hitpoints <= 0) {
      e.hitpoints = e.maxHitPoints;
    }

    // a cast is a cast whether or not it catches
    result.actionsPerformed = 1;

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
    final def = e.id.definition;
    if (def is! EncounterEntityDefinition) return result;
    final drop = _dropTableService.roll(def.itemDrops);
    result.items.add(drop);

    // add drops to inventories (player + encounter history)
    _inventoryService.addItems(playerInventory, [drop]);
    _inventoryService.addItems(encounter.itemDrops, [drop]);

    result.xp[SkillId.FISHING] = (drop.id.definition.xpValue * drop.count)
        .toDouble();

    // Apply XP to player
    if (result.xp.isNotEmpty) {
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result;
  }

  /// A batch of [actionCount] casts, settled in one pass.
  ///
  /// A cast catches when its roll against the spot beats the spot, so the
  /// catches are the casts times that chance - the exact mean rather than a
  /// roll each. The spot's hitpoints are left alone: they are the cadence of
  /// a single cast, and a spot replenishes rather than depleting.
  EncounterActionResult _settleFishing({
    required PlayerData playerState,
    required EncounterData encounter,
    required InventoryData playerInventory,
    required int actionCount,
    required int fishingStat,
  }) {
    final result = EncounterActionResult();
    final e = encounter.entity!;

    // every cast is an action, whether or not it caught anything
    result.actionsPerformed = actionCount;

    final catches =
        (actionCount * _encounterService.chanceToHit(fishingStat, e.defence))
            .round();
    if (catches <= 0) return result;

    final def = e.id.definition as EncounterEntityDefinition;
    final drops = _dropTableService.rollMulitpleTimes(catches, def.itemDrops);
    result.items.addAll(drops);

    // add drops to inventories (player + encounter history)
    _inventoryService.addItems(playerInventory, drops);
    _inventoryService.addItems(encounter.itemDrops, drops);

    double xp = 0;
    for (final drop in drops) {
      xp += drop.id.definition.xpValue * drop.count;
    }
    if (xp > 0) {
      result.xp[SkillId.FISHING] = xp;
      _playerDataService.applyXp(playerState, result.xp);
    }

    return result;
  }
}
