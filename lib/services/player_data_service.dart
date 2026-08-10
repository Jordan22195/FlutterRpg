import 'dart:math';

import 'package:rpg/services/buff_service.dart';
import 'package:rpg/utilities/util.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/zone_catalog.dart';

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
  Map<SkillId, int> getStatTotals(PlayerData playerState) {
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
    );

    final totals = Util.addMap(
      skillStats,
      Util.addMap(equipmentStats, buffStats),
    );
    // a strength based stance raises the stats strength lends itself to by
    // 1% per point of strength. each stat scales from its own total, and
    // strength itself is left alone so it can't compound on itself.
    if (playerState.skillBoost != SkillId.SPEED &&
        playerState.skillBoost != SkillId.STRENGTH) {
      // 1% per strengh stat
      final strengthScale = 1 + 0.01 * (totals[SkillId.STRENGTH] ?? 0);

      final newBaseStat = (totals[playerState.skillBoost] ?? 0) * strengthScale;
      final newBoostStat =
          (totals[playerState.skillBoost] ?? 0) * playerState.boostMultiplier;

      totals[playerState.skillBoost] = max(newBaseStat, newBoostStat).round();
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
  void setStance(
    Stance stance,
    PlayerData playerState,
    EntityCatalog entityCatalog,
  ) {
    playerState.stance = stance;
    if (stance == Stance.strong) {
      // the strong stance spends strength on whatever the open entity is
      // worked with - mining on a rock, woodcutting on a tree
      final definition = entityCatalog.getDefinitionFor(
        playerState.currentEntityViewId,
      );
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
  double getMaxStamina(PlayerData playerState) {
    final staminaStat = getStatTotals(playerState)[SkillId.STAMINA] ?? 1;
    return 10.0 * (staminaStat < 1 ? 1 : staminaStat);
  }

  double getStaminaPercent(PlayerData playerState) {
    final max = getMaxStamina(playerState);
    if (max <= 0) return 0;
    return (playerState.stamina / max).clamp(0.0, 1.0);
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
  static const double staminaRecoveryPerStat = 0.1;

  // the passive stamina regeneration rate from the recovery stat
  double staminaRecoveryPerSecond(PlayerData playerState) {
    final recoveryStat = getStatTotals(playerState)[SkillId.RECOVERY] ?? 1;
    return staminaRecoveryPerStat * recoveryStat;
  }

  // clamped stamina adjustment: positive recovers, negative drains
  void changeStamina(double delta, PlayerData playerState) {
    final max = getMaxStamina(playerState);
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
