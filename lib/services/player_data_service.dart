import 'package:rpg/services/buff_service.dart';
import 'package:rpg/utilities/util.dart';
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
    final buffStats = _buffService.getBuffedStatTotal(playerState.buffData);

    final totals = Util.addMap(
      skillStats,
      Util.addMap(equipmentStats, buffStats),
    );

    return totals;
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
    return _skillService.percentProgressToLevelUp(getSkillData(id, playerState));
  }

  double getNextLevelXp(SkillId id, PlayerData playerState) {
    return _skillService.nextLevelXp(getSkillData(id, playerState));
  }

  double getXpToLevelUp(SkillId id, PlayerData playerState) {
    return _skillService.xpToLevelUp(getSkillData(id, playerState));
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

  void drainStamina(double stamina, PlayerData playerState) {
    playerState.stamina -= stamina;
    if (playerState.stamina < 0) {
      playerState.stamina = 0;
    }
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

  // todo
  void eatEquipedFood(PlayerData playerState) {}
}
