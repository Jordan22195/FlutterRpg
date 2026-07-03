import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/world_data.dart';
import '../services/buff_service.dart';

class BuffController extends ChangeNotifier {
  final PlayerData _playerState;
  final BuffService _buffService;
  final ZoneBuffSystem _zoneBuffSystem;
  final WorldData _worldState;

  BuffController({
    required PlayerData playerState,
    required BuffService buffService,
    required ZoneBuffSystem zoneBuffSystem,
    required WorldData worldState,
  }) : _playerState = playerState,
       _buffService = buffService,
       _zoneBuffSystem = zoneBuffSystem,
       _worldState = worldState {
    Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    _buffService.checkBuffExpriations(_playerState.buffData);
    _zoneBuffSystem.updateZoneBuffs(_playerState.buffData, _worldState);

    notifyListeners();
  }
}
