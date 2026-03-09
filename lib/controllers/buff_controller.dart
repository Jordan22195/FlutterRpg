import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rpg/data/world_data.dart';
import '../data/buff_data.dart';
import '../services/buff_service.dart';

class BuffController extends ChangeNotifier {
  final BuffData _buffState;
  final BuffService _buffService;
  final ZoneBuffSystem _zoneBuffSystem;
  final WorldData _worldState;

  BuffController({
    required BuffData buffState,
    required BuffService buffService,
    required ZoneBuffSystem zoneBuffSystem,
    required WorldData worldState,
  }) : _buffState = buffState,
       _buffService = buffService,
       _zoneBuffSystem = zoneBuffSystem,
       _worldState = worldState {
    Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    _buffService.checkBuffExpriations(_buffState);
    _zoneBuffSystem.updateZoneBuffs(_buffState, _worldState);

    notifyListeners();
  }
}
