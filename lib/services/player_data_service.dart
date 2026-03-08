import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/utilities/interval_runner.dart';
import 'package:rpg/controllers/momentum_loop_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/catalogs/location_catalog.dart';
import '../catalogs/zone_catalog.dart';

import '../data/player_data.dart';
import 'file_manager_service.dart';
import '../catalogs/entity_catalog.dart';
import '../data/skill_data.dart';
import '../catalogs/item_catalog.dart';

import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';

// player data service is going to the excepiton of services not talkting to other services
// becuase of the stat total calculation. Player data service will use buff, skill, and equipment
// services to get stat totals.

class PlayerStatSystem {
  final BuffService _buffService;
  final EquipmentService _equipmentService;
  final SkillService _skillService;

  Map<SkillId, int> addStats(Map<SkillId, int> a, Map<SkillId, int> b) {
    final totals = <SkillId, int>{};

    final keys = <SkillId>{...a.keys, ...b.keys};

    for (final key in keys) {
      final aVal = a[key] ?? 0;
      final bVal = b[key] ?? 0;
      totals[key] = aVal + bVal;
    }

    return totals;
  }

  Map<SkillId, int> getStatTotals(PlayerData playerState) {
    final skillStats = _skillService.getStatTotals(playerState.skillData);
    final equipmentStats = _equipmentService.getStatTotals(
      playerState.equipmentData,
    );
    final buffStats = _buffService.getStatTotals(playerState.buffData);

    final totals = addStats(skillStats, addStats(equipmentStats, buffStats));

    return totals;
  }
}

class PlayerDataService {
  void setCurrentZone(ZoneId id, PlayerData playerState) {
    playerState.currentZoneId = id;
  }

  void getCurrentZone(PlayerData playerState) {
    return playerState.currentZoneId;
  }

  void applyXp(PlayerData playerState, Map<SkillId, double> xp) {}

  void eatEquipedFood(PlayerData playerState) {}
}

class PlayerDataController extends ChangeNotifier {}
