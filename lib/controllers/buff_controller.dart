import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rpg/data/player_data.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../services/buff_service.dart';

class BuffController extends ChangeNotifier {
  final PlayerData _playerState;
  final BuffService _buffService;
  late final Timer _timer;

  BuffController({
    required PlayerData playerState,
    required BuffService buffService,
  }) : _playerState = playerState,
       _buffService = buffService {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onTick() {
    _buffService.checkBuffExpriations(_playerState.buffData);
    // a burnt-out fire simply stops being a buff; its firepit renders bare
    // again on the next build
    _buffService.removeExpiredZoneBuffs(_playerState.buffData);

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
