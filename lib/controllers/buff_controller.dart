import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rpg/data/player_data.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../services/buff_service.dart';
import '../systems/offline_progress_system.dart';
import 'action_timing_controller.dart';

class BuffController extends ChangeNotifier {
  final PlayerData _playerState;
  final ActionTimingData _actionTimingState;
  final BuffService _buffService;
  final OfflineProgressSystem _offlineProgressSystem;
  late final Timer _timer;

  BuffController({
    required PlayerData playerState,
    required ActionTimingData actionTimingState,
    required BuffService buffService,
    required OfflineProgressSystem offlineProgressSystem,
  }) : _playerState = playerState,
       _actionTimingState = actionTimingState,
       _buffService = buffService,
       _offlineProgressSystem = offlineProgressSystem {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onTick() {
    // a settle replays the gap segment by segment and expires buffs at the
    // instant they actually ran out, so the sweep stands down for it: a fire
    // that burnt out an hour into the gap has to still be readable when the
    // replay reaches the hour it was burning in. the rebuild below still
    // runs, so a firepit goes cold on screen the moment the settle says so.
    if (!_offlineProgressSystem.settlePending(
      _playerState,
      _actionTimingState,
    )) {
      _buffService.checkBuffExpriations(_playerState.buffData);
      // a burnt-out fire simply stops being a buff; its firepit renders bare
      // again on the next build
      _buffService.removeExpiredZoneBuffs(_playerState.buffData);
    }

    notifyListeners();
  }

  /// Rebuilds the buff widgets now rather than on the next tick. Lighting or
  /// putting out a fire changes the buff list immediately, and waiting up to
  /// a second to show it reads as the tap not registering.
  void refresh() => notifyListeners();

  List<BuffItem> getGlobalBuffs() {
    return _buffService.getGlobalBuffs(_playerState.buffData);
  }

  List<ZoneBuffItem> getCurrentZoneBuffs() {
    return _buffService.getZoneBuffs(
      _playerState.buffData,
      _playerState.currentZoneId,
    );
  }

  // the buff owned by [ownerEntityId] in the player's current zone — for a
  // firepit, the fire burning in it. null when the owner has none.
  ZoneBuffItem? getZoneBuffFor(EntityId ownerEntityId) {
    return _buffService.getZoneBuff(
      _playerState.buffData,
      _playerState.currentZoneId,
      ownerEntityId,
    );
  }

  DateTime? getZoneBuffExpiration(EntityId ownerEntityId) {
    return getZoneBuffFor(ownerEntityId)?.expirationTime;
  }
}
