import 'package:rpg/services/buff_service.dart';
import 'package:rpg/utilities/util.dart';
import '../catalogs/zone_catalog.dart';

import '../data/player_data.dart';
import '../data/skill_data.dart';

import 'package:flutter/foundation.dart';
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

    return totals as Map<SkillId, int>;
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

class PlayerDataController extends ChangeNotifier {}
