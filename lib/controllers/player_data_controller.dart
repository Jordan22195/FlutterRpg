import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rpg/services/player_data_service.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../catalogs/zones/zones.dart';
import 'action_timing_controller.dart';

class PlayerDataController extends ChangeNotifier {
  final PlayerData _playerData;
  final PlayerDataService _playerDataService;
  final ActionTimingController _actionTimingController;
  // the stance is resolved against the entity the player has open, so
  // setting one needs the catalog to look that entity up
  late final Timer _heartbeatTimer;

  PlayerDataController({
    required PlayerData playerData,
    required PlayerDataService playerDataService,
    required ActionTimingController actionTimingController,
  }) : _playerData = playerData,
       _playerDataService = playerDataService,
       _actionTimingController = actionTimingController {
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer.cancel();
    super.dispose();
  }

  /// The once-a-second heartbeat: applies ambient recovery, then republishes
  /// player data whether or not anything recovered.
  ///
  /// The action loop trains speed/stamina/recovery continuously without going
  /// through this controller, so the unconditional notify is what keeps live
  /// readouts - skill xp bars, the xp trackers' elapsed clock and xp/hr -
  /// ticking. Discrete xp (combat, gathering, crafting) arrives sooner: those
  /// controllers are wired to [refresh] in GameSessionFactory.
  void _tick() {
    tickAmbientRecovery();
    notifyListeners();
  }

  /// Ambient stamina recovery: one second's worth of the recovery stat.
  /// Only applies while the action loop is NOT running - the loop applies
  /// recovery itself every frame, and the two must not stack.
  /// [_tick] does the notifying for this.
  void tickAmbientRecovery() {
    if (_actionTimingController.isRunning) return;

    final max = _playerDataService.getMaxStamina(_playerData);
    if (_playerData.stamina >= max) return;

    _playerDataService.changeStamina(
      _playerDataService.staminaRecoveryPerSecond(_playerData),
      _playerData,
    );
    _playerDataService.applyXp(_playerData, {SkillId.RECOVERY: 10});
  }

  /// Player data is mutated by other domains (combat xp, gathering and
  /// crafting xp, dungeon rewards, equipment stat changes). Those controllers
  /// are wired to call this in GameSessionFactory so skill readouts rebuild as
  /// soon as the xp lands.
  void refresh() {
    notifyListeners();
  }

  void setCurrentZone(ZoneId id) {
    _playerDataService.setCurrentZone(id, _playerData);
    notifyListeners();
  }

  /// The active combat stance, or null when the boosted skill isn't one of
  /// the stance skills.
  Stance? getStance() {
    return _playerDataService.getStance(_playerData);
  }

  /// The skill the action loop's boost is currently training - speed when
  /// running fast, strength in the strong stance.
  SkillId getBoostSkill() {
    return _playerDataService.getBoostSkill(_playerData);
  }

  void setStance(Stance stance) {
    _playerDataService.setStance(stance, _playerData);
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
