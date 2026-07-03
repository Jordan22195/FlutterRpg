import 'package:flutter/foundation.dart';
import 'package:rpg/services/player_data_service.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../catalogs/zone_catalog.dart';

class PlayerDataController extends ChangeNotifier {
  final PlayerData _playerData;
  final PlayerDataService _playerDataService;

  PlayerDataController({
    required PlayerData playerData,
    required PlayerDataService playerDataService,
  }) : _playerData = playerData,
       _playerDataService = playerDataService;

  void setCurrentZone(ZoneId id) {
    _playerDataService.setCurrentZone(id, _playerData);
    notifyListeners();
  }

  int getSkillLevel(SkillId id) {
    return _playerDataService.getSkillLevel(id, _playerData);
  }

  double getSkillXp(SkillId id) {
    return _playerDataService.getSkillXp(id, _playerData);
  }

  double getSkillProgress(SkillId id) {
    return _playerDataService.getSkillProgress(id, _playerData);
  }

  double getNextLevelXp(SkillId id) {
    return _playerDataService.getNextLevelXp(id, _playerData);
  }

  double getXpToLevelUp(SkillId id) {
    return _playerDataService.getXpToLevelUp(id, _playerData);
  }

  double getStaminaPercent() {
    return _playerDataService.getStaminaPercent(_playerData);
  }
}
