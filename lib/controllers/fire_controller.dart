import 'package:flutter/foundation.dart';

import '../catalogs/items/items.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/inventory_service.dart';
import '../systems/fire_tending_system.dart';
import '../systems/firemaking_system.dart';
import 'action_timing_controller.dart';

/// One reagent buff burning on the fire, for the stage's chip row.
class ReagentBuff {
  const ReagentBuff({
    required this.reagent,
    required this.stat,
    required this.value,
    required this.endsAt,
  });

  final ItemId reagent;
  final SkillId stat;
  final int value;
  final DateTime endsAt;
}

/// The firepit screen's tending: the fire being looked at, the reagents
/// burning on it, throwing one on by hand, and the auto-tend and Keep fire
/// fed switches.
///
/// Its own controller, the way potions have theirs: the switches live on
/// PlayerData and the tick reads them, and neither belongs to crafting.
class FireController extends ChangeNotifier {
  final PlayerData _playerState;
  final InventoryData _inventoryData;
  final ActionTimingData _actionTimingState;
  final FiremakingSystem _firemakingSystem;
  final FireTendingSystem _fireTendingSystem;
  final InventoryService _inventoryService;

  FireController({
    required PlayerData playerState,
    required InventoryData inventoryData,
    required ActionTimingData actionTimingState,
    required FiremakingSystem firemakingSystem,
    required FireTendingSystem fireTendingSystem,
    required InventoryService inventoryService,
  }) : _playerState = playerState,
       _inventoryData = inventoryData,
       _actionTimingState = actionTimingState,
       _firemakingSystem = firemakingSystem,
       _fireTendingSystem = fireTendingSystem,
       _inventoryService = inventoryService;

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
            value: f.power,
            endsAt: f.reagentEndsAt(stat, now)!,
          ),
    ];
  }

  /// Every reagent worth a row in the Reagents tab: held, armed, or burning.
  List<ItemId> reagentRows() {
    final burning = activeBuffs().map((b) => b.reagent).toSet();
    return [
      for (final id in FireTendingSystem.reagents)
        if (heldCount(id) > 0 || isAutoTend(id) || burning.contains(id)) id,
    ];
  }

  int heldCount(ItemId id) =>
      _inventoryService.getItemCount(_inventoryData, id);

  /// What stops [reagent] going on the fire on screen right now.
  TendBlock blockFor(ItemId reagent) {
    if (!isHere) return TendBlock.noFire;
    return _fireTendingSystem.blockFor(
      reagent,
      _playerState.currentEntityViewId,
      _playerState.currentZoneId,
      _playerState,
      _inventoryData,
    );
  }

  /// Throws one [reagent] on by hand, paying its xp. Returns whether it went.
  bool tend(ItemId reagent) {
    if (!isHere) return false;
    final thrown = _fireTendingSystem.tend(
      reagent,
      _playerState.currentEntityViewId,
      _playerState.currentZoneId,
      _playerState,
      _inventoryData,
      payXp: true,
    );
    if (thrown > 0) notifyListeners();
    return thrown > 0;
  }

  bool isAutoTend(ItemId id) => _playerState.autoTendReagents.contains(id);

  int get autoCount => _playerState.autoTendReagents.length;

  /// How long one reagent burns: on the fire on screen when it can be
  /// tended, and a campfire's otherwise, so an armed card can still say what
  /// its stack is worth while the pit is cold.
  Duration reagentDose() {
    final f = fire();
    if (f != null && f.tendable) return f.definition.reagentBurn;
    return (ItemId.BASIC_CAMPFIRE.definition as FireItemDefinition).reagentBurn;
  }

  /// Auto-tend and Keep fire fed only run while an action is going, and the
  /// tab says so when it is not.
  bool get actionRunning => _actionTimingState.running;

  /// Arms or disarms [id]. Arming it mid-action throws one on at once if
  /// its buff is down, as arming a potion drinks one; idle, it waits for the
  /// next action the way the tick does.
  void setAutoTend(ItemId id, bool on) {
    if (on) {
      _playerState.autoTendReagents.add(id);
      if (actionRunning) {
        _fireTendingSystem.autoTend(_playerState, _inventoryData);
      }
    } else {
      _playerState.autoTendReagents.remove(id);
    }
    notifyListeners();
  }

  bool get keepFireFed => _playerState.keepFireFed;

  void setKeepFireFed(bool on) {
    _playerState.keepFireFed = on;
    notifyListeners();
  }

  /// Rebuilds now: the tick spent logs or reagents.
  void refresh() => notifyListeners();
}
