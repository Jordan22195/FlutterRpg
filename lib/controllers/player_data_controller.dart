import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rpg/services/player_data_service.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../catalogs/zone_catalog.dart';
import 'action_timing_controller.dart';

class PlayerDataController extends ChangeNotifier {
  final PlayerData _playerData;
  final PlayerDataService _playerDataService;
  final ActionTimingController _actionTimingController;
  late final Timer _recoveryTimer;

  PlayerDataController({
    required PlayerData playerData,
    required PlayerDataService playerDataService,
    required ActionTimingController actionTimingController,
  }) : _playerData = playerData,
       _playerDataService = playerDataService,
       _actionTimingController = actionTimingController {
    _recoveryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => tickAmbientRecovery(),
    );
  }

  @override
  void dispose() {
    _recoveryTimer.cancel();
    super.dispose();
  }

  /// Ambient stamina recovery: one second's worth of the recovery stat.
  /// Only applies while the action loop is NOT running - the loop applies
  /// recovery itself every frame, and the two must not stack.
  void tickAmbientRecovery() {
    if (_actionTimingController.isRunning) return;

    final max = _playerDataService.getMaxStamina(_playerData);
    if (_playerData.stamina >= max) return;

    _playerDataService.changeStamina(
      _playerDataService.staminaRecoveryPerSecond(_playerData),
      _playerData,
    );
    _playerDataService.applyXp(_playerData, {SkillId.RECOVERY: 10});
    notifyListeners();
  }

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

  void startXpTracker(SkillId id) {
    _playerDataService.startXpTracker(id, _playerData);
    notifyListeners();
  }

  void resetXpTracker(SkillId id) {
    _playerDataService.resetXpTracker(id, _playerData);
    notifyListeners();
  }

  bool isTrackingXp(SkillId id) {
    return _playerDataService.isTrackingXp(id, _playerData);
  }

  Duration getTrackedElapsed(SkillId id) {
    return _playerDataService.getTrackedElapsed(id, _playerData);
  }

  double getTrackedXpGained(SkillId id) {
    return _playerDataService.getTrackedXpGained(id, _playerData);
  }

  double getXpPerHour(SkillId id) {
    return _playerDataService.getXpPerHour(id, _playerData);
  }

  void debugSetSkillXp(SkillId id, double xp) {
    _playerDataService.debugSetSkillXp(id, xp, _playerData);
    notifyListeners();
  }

  double getStaminaPercent() {
    return _playerDataService.getStaminaPercent(_playerData);
  }

  double getStamina() => _playerData.stamina;

  double getMaxStamina() {
    return _playerDataService.getMaxStamina(_playerData);
  }
}
