import 'dart:math';

import 'package:rpg/data/skill_data.dart';

import '../services/combat_auto_eat_service.dart';
import '../services/encounter_service.dart';
import '../services/exploration_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';
import '../catalogs/entities/entities.dart';
import '../data/action_result.dart';
import '../data/auto_eat_rule.dart';
import '../data/entity_details.dart';
import '../data/player_data.dart';
import '../data/encounter_data.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';
import '../data/swing_profile.dart';
import '../data/ObjectStack.dart';
import '../services/inventory_service.dart';
import '../catalogs/items/items.dart';

class EncounterSystem {
  /// XP awarded per point of damage done by damage-based skills (combat,
  /// woodcutting, mining). Also used by the explore screen to estimate a
  /// node's xp yield.
  static const double xpPerDamage = 2;

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
    AutoEatRule? rule,
  }) {
    return _autoEatService.autoEat(
      playerState: playerState,
      playerInventory: playerInventory,
      rule: rule,
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
    Duration? span,
    // tests only, so a run of live swings can be reproduced and held up
    // against the batch that is meant to match it
    Random? rng,
  }) {
    final result = EncounterActionResult();

    final stats = _playerDataService.getStatTotals(playerState, at: at);

    if (!_encounterService.encounterConditionsMet(playerState, encounter)) {
      return result;
    }

    final e = encounter.entity!;

    if (offline) {
      // how the player's swings land on this entity. null means they cannot
      // scratch it - the loop still swings for the whole stretch, it just
      // never lands a kill, so the batch is charged its actions and pays
      // nothing.
      final swing = _encounterService.playerSwingProfile(
        stats,
        playerState,
        encounter,
      );
      // a pool of nothing is not a fight anyone can model: live, every swing
      // caps at the target's 0 hitpoints and "kills" it. bad content, so
      // charge the stretch and pay nothing rather than settle a landslide.
      if (swing == null || e.maxHitPoints <= 0) {
        result.actionsPerformed = actionCount;
        return result;
      }

      // the enemy swings back for as long as the fight lasts, which is
      // however much of the stretch the player spends fighting: the whole
      // of it, or up to the moment the last one drops
      final playerInterval = span == null || actionCount <= 0
          ? 0.0
          : (span.inMicroseconds / 1e6) / actionCount;
      // clearing the group means finishing the one already standing - which
      // an earlier segment may have left part-damaged - and then every one
      // behind it from full. actions only land on the interval, so the last
      // one arrives on a whole action.
      final hitsToClear =
          swing.hitsToRemove(e.hitpoints) +
          (e.count - 1) * swing.hitsToRemove(e.maxHitPoints);
      final timeToClear =
          swing.actionsForHits(hitsToClear).ceil() * playerInterval;
      final window = playerInterval <= 0
          ? 0.0
          : (timeToClear < span!.inMicroseconds / 1e6
                ? timeToClear
                : span.inMicroseconds / 1e6);

      var elapsed = window;
      if (window > 0 && e is CombatEntity) {
        elapsed = _settleIncomingDamage(
          playerState: playerState,
          playerInventory: playerInventory,
          entity: e,
          stats: stats,
          seconds: window,
          result: result,
        );
      }

      // actions are what the elapsed time bought: a fight cut short by the
      // player's death pays only for the part they were alive for
      int actions = playerInterval <= 0
          ? actionCount
          : (elapsed / playerInterval).floor();
      if (actions > actionCount) actions = actionCount;

      final fight = _spendHits(swing, e, actions);
      final enemiesToKill = fight.kills;

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
      if (enemiesToKill > 0) {
        result.entitiesDefeated = [
          ObjectStack<EntityId>(id: e.id, count: enemiesToKill),
        ];
      }

      // what the batch actually did. the loop settling time away credits
      // only the time these actions were worth, so this has to stay
      // proportional to the stretch they covered.
      result.actionsPerformed = actions;
      // the hitpoints the fight took off, which is what the entity's own
      // bar has lost. xp is paid on [FightOutcome.damageForXp] instead - see
      // there for why the two differ.
      result.damageDone = fight.hitpointsRemoved;

      // reward xp
      result.xp.addAll(_damageXp(e, playerState, fight.damageForXp));
      if (e is CombatEntity) {
        result.xp[SkillId.HITPOINTS] = (xpPerDamage * fight.damageForXp) / 3.0;
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
      rng: rng,
    );
    result.damageDone = r.damageDone;
    result.enemyDied = r.enemyDied;

    if (result.damageDone <= 0) {
      return result; // miss/no progress this tick
    }

    // xp accrues on every damaging action, scaled by the damage done
    result.xp.addAll(_damageXp(e, playerState, result.damageDone.toDouble()));

    // combat also trains hitpoints, at a third of the attack xp rate
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

  /// Spends [actions] worth of swings on [e], taking its hitpoints down and
  /// stepping the next one up as each drops.
  ///
  /// The entity's own [EncounterEntity.hitpoints] is the carry between
  /// segments. A settle cuts the window at every buff expiry and level-up
  /// (see [OfflineProgressSystem]), and a fight that was halfway through
  /// something when the cut landed has to still be halfway through it on the
  /// other side - otherwise every boundary quietly heals whatever was
  /// standing, and on a long-lived entity that is most of the damage.
  ///
  /// Two damage numbers come back because they answer different questions.
  /// `hitpointsRemoved` is what the bars actually lost, in whole hitpoints.
  /// `damageForXp` is the same damage with its fraction kept, because an
  /// action worth half a point has to pay half a point of xp: a batch too
  /// small to move an integer hitpoint - the single-action probe the settle
  /// loop opens with - would otherwise report no xp at all, and the loop
  /// reads that back as a rate of zero and stops predicting level-ups for
  /// the rest of the window.
  ///
  /// Neither of them pays for overkill. A kill is worth the pool it emptied
  /// and nothing more, however far past it the swing would have rolled -
  /// which is the same cap [EncounterService.calculateAttackDamage] applies
  /// live.
  ({int kills, int hitpointsRemoved, double damageForXp}) _spendHits(
    SwingProfile swing,
    EncounterEntity e,
    int actions,
  ) {
    var hitsLeft = swing.hitsForActions(actions);
    var damageForXp = 0.0;
    var kills = 0;
    var removed = 0;

    // finish the one already standing, which an earlier segment may have
    // left part-damaged. it pays for the pool it emptied and not a point
    // more - the hit that finishes something is worth what was left of it,
    // however hard it swings.
    final hitsToFinish = swing.hitsToRemove(e.hitpoints);
    if (e.count > 0 && hitsToFinish > 0 && hitsLeft >= hitsToFinish) {
      hitsLeft -= hitsToFinish;
      removed += e.hitpoints;
      damageForXp += e.hitpoints;
      kills++;
      e.hitpoints = e.maxHitPoints;
    }

    // then whole ones from full, which is arithmetic rather than a loop
    final hitsPerKill = swing.hitsToRemove(e.maxHitPoints);
    if (kills < e.count && hitsPerKill > 0) {
      var more = (hitsLeft / hitsPerKill).floor();
      if (more > e.count - kills) more = e.count - kills;
      if (more > 0) {
        hitsLeft -= more * hitsPerKill;
        removed += more * e.maxHitPoints;
        damageForXp += more * e.maxHitPoints;
        kills += more;
      }
    }

    // and whatever is left chips at the next one without finishing it. it
    // has to stop a hitpoint short: a pool taken to zero here would be a
    // kill this batch never counted or rolled loot for.
    if (kills < e.count && hitsLeft > 0) {
      final pool = e.hitpoints.toDouble();
      final chip = hitsLeft * swing.damagePerHit;
      damageForXp += chip < pool ? chip : pool;
      var applied = chip.floor();
      if (applied >= e.hitpoints) applied = e.hitpoints - 1;
      if (applied > 0) {
        e.hitpoints -= applied;
        removed += applied;
      }
    }

    return (kills: kills, hitpointsRemoved: removed, damageForXp: damageForXp);
  }

  /// Runs the enemy's side of a batched fight over [seconds] and applies what
  /// it came to: the damage taken, the food eaten keeping up with it, the
  /// defence xp the blocks paid, and whether it killed the player.
  ///
  /// Returns the seconds actually fought, which is the whole window unless
  /// the player died partway through it - the caller pays actions and kills
  /// for that stretch and no more.
  double _settleIncomingDamage({
    required PlayerData playerState,
    required InventoryData playerInventory,
    required CombatEntity entity,
    required Map<SkillId, int> stats,
    required double seconds,
    required EncounterActionResult result,
  }) {
    final maxHp = stats[SkillId.HITPOINTS] ?? 1;
    final defence = stats[SkillId.DEFENCE] ?? 1;
    final food = _autoEatService.equippedFood(playerState);

    final outcome = _encounterService.resolveIncomingDamage(
      hitpoints: playerState.hitpoints,
      maxHp: maxHp,
      eatThreshold: playerState.autoEatRule.threshold,
      foodCount: food == null
          ? 0
          : _autoEatService.availableFood(playerState, playerInventory),
      restoreAmount: food?.restoreAmount ?? 0,
      enemyAttack: entity.attack,
      playerDefence: defence,
      attackInterval: entity.attackInterval,
      seconds: seconds,
    );

    if (outcome.foodEaten > 0) {
      _inventoryService.removeItems(
        playerInventory,
        playerState.equipmentData.equipedFood,
        outcome.foodEaten,
      );
    }
    _playerDataService.setHitpoints(outcome.hitpoints, playerState);

    result.playerDied = outcome.died;
    return outcome.elapsed;
  }

  /// Where a point of damage's xp lands, at [xpPerDamage] a point.
  ///
  /// A fight pays the stance that fought it: offensive trains the weapon
  /// skill, defensive trains defence, and anything else splits the two
  /// evenly. The total is the same either way - a stance decides where the
  /// xp goes, not how much of it there is - so a player who wants defence
  /// trains it by fighting defensively rather than by waiting to be missed.
  ///
  /// Only combat is routed. A tree pays woodcutting whatever the stance,
  /// because there is no second skill to give half of it to.
  Map<SkillId, double> _damageXp(
    EncounterEntity entity,
    PlayerData playerState,
    double damage,
  ) {
    final total = xpPerDamage * damage;
    if (entity is! CombatEntity) return {entity.entityType: total};

    switch (playerState.stance) {
      case Stance.offensive:
        return {entity.entityType: total};
      case Stance.defensive:
        return {SkillId.DEFENCE: total};
      default:
        return {entity.entityType: total / 2, SkillId.DEFENCE: total / 2};
    }
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
