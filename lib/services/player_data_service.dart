import 'dart:math';

import 'package:rpg/services/buff_service.dart';
import 'package:rpg/utilities/util.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/zones/zones.dart';

import '../data/player_data.dart';
import '../data/skill_data.dart';

import '../services/equipment_service.dart';
import '../services/skill_service.dart';

class PlayerDataService {
  final BuffService _buffService;
  final EquipmentService _equipmentService;
  final SkillService _skillService;

  PlayerDataService({
    required BuffService buffService,
    required EquipmentService equpmentService,
    required SkillService skillService,
  }) : _buffService = buffService,
       _skillService = skillService,
       _equipmentService = equpmentService;

  // player data service is the excepiton of services not talkting to other services
  // becuase of the stat total calculation. Player data service will use buff, skill, and equipment
  // services to get stat totals.
  /// The player's stats as they stood at [at], defaulting to now. Only the
  /// buff half of the total moves with the clock, and only an offline settle
  /// asks about any instant but this one: it replays each segment of the gap
  /// against the buffs that were up for it.
  Map<SkillId, int> getStatTotals(PlayerData playerState, {DateTime? at}) {
    Map<SkillId, int> skillStats = {};
    for (final s in playerState.skillData.entries) {
      skillStats[s.key] = _skillService.getLevel(s.value);
    }
    final equipmentStats = _equipmentService.getStatTotals(
      playerState.equipmentData,
    );
    final buffStats = _buffService.getBuffedStatTotal(
      playerState.buffData,
      playerState.currentZoneId,
      at: at,
    );

    final totals = Util.addMap(
      skillStats,
      Util.addMap(equipmentStats, buffStats),
    );
    // a strength stance raises the stat it is spent on. the idle share is
    // always on and the boost bar buys the rest, composed rather than taken
    // as the larger of the two - competing is what left the bottom of the
    // bar doing nothing until it beat standing still.
    //
    // only the skill half is scaled. multiplying the geared total meant a
    // stance was worth more the better your equipment, which is where most
    // of the old overpowering lived. strength itself is left alone so it
    // can't compound on itself.
    if (playerState.skillBoost != SkillId.SPEED &&
        playerState.skillBoost != SkillId.STRENGTH) {
      final bonus = boostStatBonus(totals[SkillId.STRENGTH] ?? 0);
      // boostMultiplier is 1 + fill * bonus, so the fill is already in it
      final scale =
          1 +
          bonus * kBoostIdleShare +
          (playerState.boostMultiplier - 1) * (1 - kBoostIdleShare);

      final base = skillStats[playerState.skillBoost] ?? 0;
      final gear = (totals[playerState.skillBoost] ?? 0) - base;
      totals[playerState.skillBoost] = (base * scale).round() + gear;
    }

    return totals;
  }

  void setBoostMultiplier(double boostValue, PlayerData playerState) {
    playerState.boostMultiplier = boostValue;
  }

  /// The skill the action loop's boost trains: speed in the fast stance,
  /// strength in every other. Every activity that runs the loop trains it,
  /// not just the ones that offer a stance picker.
  SkillId getBoostSkill(PlayerData playerState) {
    return boostTrainedSkill(playerState.skillBoost);
  }

  /// The stance is stored as the skill the action loop boosts.
  void setStance(Stance stance, PlayerData playerState) {
    playerState.stance = stance;
    if (stance == Stance.strong) {
      // the strong stance spends strength on whatever the open entity is
      // worked with - mining on a rock, woodcutting on a tree
      final definition = playerState.currentEntityViewId.definition;
      // a bench, a shop or no entity at all has no skill to lend the boost
      // to. strength stands in, and getStatTotals leaves it unscaled so it
      // can't compound on itself
      playerState.skillBoost = definition is EncounterEntityDefinition
          ? definition.entityType
          : SkillId.STRENGTH;
    } else if (stance == Stance.defensive) {
      playerState.skillBoost = SkillId.DEFENCE;
    } else if (stance == Stance.offensive) {
      playerState.skillBoost = SkillId.ATTACK;
    } else {
      playerState.skillBoost = SkillId.SPEED;
    }
  }

  /// Null when the boosted skill isn't one of the stance skills.
  Stance? getStance(PlayerData playerState) {
    return playerState.stance;
  }

  /// Called when an encounter starts: an entity that doesn't offer the
  /// current stance (fishing and herbalism offer none at all) drops the
  /// player back to fast.
  void coerceStanceFor(EncounterEntity entity, PlayerData playerState) {
    final allowed = stancesForEntity(entity);
    final current = getStance(playerState);
    if (current != null && allowed.contains(current)) return;
    resetStanceToFast(playerState);
  }

  /// Called when an activity that offers no stance at all starts: exploring
  /// and bench work. Only encounters coerce their own stance, so without
  /// this the stance a fight or a rock left behind keeps boosting the wrong
  /// skill — and keeps the action at its unreduced interval — for the whole
  /// session, with no picker on screen to put it back.
  void resetStanceToFast(PlayerData playerState) {
    playerState.skillBoost = SkillId.SPEED;
    playerState.stance = Stance.fast;
  }

  SkillData getSkillData(SkillId id, PlayerData playerState) {
    return playerState.skillData[id] ?? SkillData(name: id.name, xp: 0);
  }

  int getSkillLevel(SkillId id, PlayerData playerState) {
    return _skillService.getLevel(getSkillData(id, playerState));
  }

  double getSkillXp(SkillId id, PlayerData playerState) {
    return getSkillData(id, playerState).xp;
  }

  double getSkillProgress(SkillId id, PlayerData playerState) {
    return _skillService.percentProgressToLevelUp(
      getSkillData(id, playerState),
    );
  }

  double getNextLevelXp(SkillId id, PlayerData playerState) {
    return _skillService.nextLevelXp(getSkillData(id, playerState));
  }

  double getXpToLevelUp(SkillId id, PlayerData playerState) {
    return _skillService.xpToLevelUp(getSkillData(id, playerState));
  }

  void startXpTracker(SkillId id, PlayerData playerState) {
    _skillService.startXpTracking(getSkillData(id, playerState));
  }

  void resetXpTracker(SkillId id, PlayerData playerState) {
    _skillService.resetXpTracking(getSkillData(id, playerState));
  }

  bool isTrackingXp(SkillId id, PlayerData playerState) {
    return _skillService.isTrackingXp(getSkillData(id, playerState));
  }

  Duration getTrackedElapsed(SkillId id, PlayerData playerState) {
    return _skillService.trackedElapsed(getSkillData(id, playerState));
  }

  double getTrackedXpGained(SkillId id, PlayerData playerState) {
    return _skillService.trackedXpGained(getSkillData(id, playerState));
  }

  double getXpPerHour(SkillId id, PlayerData playerState) {
    return _skillService.xpPerHour(getSkillData(id, playerState));
  }

  void debugSetSkillXp(SkillId id, double xp, PlayerData playerState) {
    _skillService.setXp(xp, getSkillData(id, playerState));
  }

  // each point of stamina skill adds 10 to the stamina bar
  double getMaxStamina(PlayerData playerState, {DateTime? at}) {
    final staminaStat =
        getStatTotals(playerState, at: at)[SkillId.STAMINA] ?? 1;
    return 10.0 * (staminaStat < 1 ? 1 : staminaStat);
  }

  double getStaminaPercent(PlayerData playerState) {
    final max = getMaxStamina(playerState);
    if (max <= 0) return 0;
    return (playerState.stamina / max).clamp(0.0, 1.0);
  }

  /// Puts hp at [hp] outright, clamped to the pool. An offline settle
  /// resolves a whole stretch of a fight at once and writes the hp it
  /// arrived at, rather than replaying every hit and heal through
  /// [applyDamage] and [heal].
  void setHitpoints(int hp, PlayerData playerState, {DateTime? at}) {
    final maxHp = getStatTotals(playerState, at: at)[SkillId.HITPOINTS] ?? 1;
    playerState.hitpoints = hp.clamp(0, maxHp);
  }

  void applyDamage(int damage, PlayerData playerState) {
    playerState.hitpoints -= damage;
    if (playerState.hitpoints < 0) {
      playerState.hitpoints = 0;
    }
  }

  // restore hitpoints, capped at the player's max hp stat
  void heal(int amount, PlayerData playerState) {
    if (amount <= 0) return;
    final maxHp = getStatTotals(playerState)[SkillId.HITPOINTS] ?? 1;
    playerState.hitpoints += amount;
    if (playerState.hitpoints > maxHp) {
      playerState.hitpoints = maxHp;
    }
  }

  /// Stamina recovered per second per point of the recovery stat.
  static const double staminaRecoveryPerStat = 0.5;

  // the passive stamina regeneration rate from the recovery stat
  double staminaRecoveryPerSecond(PlayerData playerState, {DateTime? at}) {
    final recoveryStat =
        getStatTotals(playerState, at: at)[SkillId.RECOVERY] ?? 1;
    return staminaRecoveryPerStat * recoveryStat;
  }

  // clamped stamina adjustment: positive recovers, negative drains
  void changeStamina(double delta, PlayerData playerState, {DateTime? at}) {
    final max = getMaxStamina(playerState, at: at);
    playerState.stamina = (playerState.stamina + delta).clamp(0.0, max);
  }

  void setCurrentZone(ZoneId id, PlayerData playerState) {
    playerState.currentZoneId = id;
  }

  ZoneId getCurrentZone(PlayerData playerState) {
    return playerState.currentZoneId;
  }

  void applyXp(PlayerData playerState, Map<SkillId, double> xp) {
    for (final exp in xp.entries) {
      _skillService.addXp(
        exp.value,
        playerState.skillData[exp.key] ?? SkillData(name: "error", xp: 1),
      );
    }
  }
}
