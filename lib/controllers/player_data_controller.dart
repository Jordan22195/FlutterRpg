import 'package:flutter/foundation.dart';
import 'package:rpg/services/player_data_service.dart';
import '../data/player_data.dart';
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
  }
}
