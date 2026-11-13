import 'package:flutter/foundation.dart';

import '../catalogs/items/items.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../systems/fire_tending_system.dart';
import '../systems/firemaking_system.dart';

/// One reagent buff burning on the fire, for the stage's rings.
class ReagentBuff {
  const ReagentBuff({
    required this.reagent,
    required this.stat,
    required this.value,
    required this.endsAt,
    required this.fullness,
  });

  final ItemId reagent;
  final SkillId stat;
  final int value;
  final DateTime endsAt;

  /// Its time left out of the fire's, 0 to 1.
  final double fullness;
}

/// The fire on the firepit screen and the reagent buffs burning on it.
///
/// Reagents go on through their recipes, off the action button (see
/// CraftingController); this only reads what they have built up.
class FireController extends ChangeNotifier {
  final PlayerData _playerState;
  final FiremakingSystem _firemakingSystem;

  FireController({
    required PlayerData playerState,
    required FiremakingSystem firemakingSystem,
  }) : _playerState = playerState,
       _firemakingSystem = firemakingSystem;

  /// The fire in the firepit on screen, or null when it is cold.
  FireItem? fire() => _firemakingSystem.activeFire(
    _playerState.currentEntityViewId,
    _playerState.currentZoneViewId,
    _playerState.buffData,
  );

  /// A fire a zone away is looked at, not tended.
  bool get isHere =>
      _playerState.currentZoneViewId == _playerState.currentZoneId;

  /// The reagent buffs burning on the fire on screen, in stat order.
  List<ReagentBuff> activeBuffs() {
    final f = fire();
    if (f == null || !f.tendable) return const [];
    final now = DateTime.now();
    return [
      for (final stat in f.activeReagentStats(now))
        if (FireTendingSystem.reagentFor(stat) case final reagent?)
          ReagentBuff(
            reagent: reagent,
            stat: stat,
            value: f.powerAt(now),
            endsAt: f.reagentEndsAt(stat, now)!,
            fullness: f.reagentFullness(stat, now),
          ),
    ];
  }

  /// Rebuilds now: a craft changed the fire.
  void refresh() => notifyListeners();
}
