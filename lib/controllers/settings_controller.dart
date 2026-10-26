import 'package:flutter/foundation.dart';

import '../data/debug_settings.dart';
import 'player_data_controller.dart';

class SettingsController extends ChangeNotifier {
  final DebugSettings _debugSettings;
  final PlayerDataController _playerDataController;

  SettingsController({
    required DebugSettings debugSettings,
    required PlayerDataController playerDataController,
  }) : _debugSettings = debugSettings,
       _playerDataController = playerDataController;

  int? get maxSkillLevel => _debugSettings.maxSkillLevel;

  /// Caps every skill's level at [level]; null lifts the cap.
  void setMaxSkillLevel(int? level) {
    _debugSettings.maxSkillLevel = level == null || level < 1 ? null : level;
    notifyListeners();
    // every level readout and stat total reads through the cap, and those
    // all rebuild off player data
    _playerDataController.refresh();
  }
}
