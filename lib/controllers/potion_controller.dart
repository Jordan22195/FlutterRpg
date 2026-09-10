import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/items/items.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../services/buff_service.dart';
import '../services/inventory_service.dart';
import '../systems/potion_system.dart';
import 'action_timing_controller.dart';

/// The potions screen's controller: which potions the player has or has
/// armed, which are up, and the auto-drink toggle itself.
///
/// Its own controller rather than more on InventoryController: the toggle
/// lives on PlayerData and its drink-now rule reads the action loop, and
/// neither belongs to the bag.
class PotionController extends ChangeNotifier {
  final PlayerData _playerState;
  final InventoryData _inventoryData;
  final ActionTimingData _actionTimingState;
  final PotionSystem _potionSystem;
  final BuffService _buffService;
  final InventoryService _inventoryService;

  PotionController({
    required PlayerData playerState,
    required InventoryData inventoryData,
    required ActionTimingData actionTimingState,
    required PotionSystem potionSystem,
    required BuffService buffService,
    required InventoryService inventoryService,
  }) : _playerState = playerState,
       _inventoryData = inventoryData,
       _actionTimingState = actionTimingState,
       _potionSystem = potionSystem,
       _buffService = buffService,
       _inventoryService = inventoryService;

  /// Every potion the player holds, plus any armed to auto-drink even with
  /// none left - the toggle is still worth seeing. Catalog order, so the
  /// grid never reshuffles as stacks come and go.
  List<ItemId> potions() {
    return [
      for (final id in ItemId.values)
        if (_potionSystem.isDrinkable(id) &&
            (heldCount(id) > 0 || isAutoDrink(id)))
          id,
    ];
  }

  int heldCount(ItemId id) => _inventoryService.getItemCount(_inventoryData, id);

  bool isAutoDrink(ItemId id) => _playerState.autoDrinkPotions.contains(id);

  /// The buff [id] is putting up right now, or null when it is not.
  BuffItem? activeBuff(ItemId id) =>
      _buffService.getGlobalBuff(_playerState.buffData, id);

  /// Auto-drink only runs while an action is going, and the screen says so
  /// when it is not.
  bool get actionRunning => _actionTimingState.running;

  int get autoCount => _playerState.autoDrinkPotions.length;

  int get activeCount => potions().where((id) => activeBuff(id) != null).length;

  /// Arms or disarms [id]. Arming it mid-action drinks one on the spot if
  /// the buff is down, so the toggle is felt at once rather than a tick
  /// later; idle, it waits for the next action the way the tick does.
  void setAutoDrink(ItemId id, bool on) {
    if (on) {
      _playerState.autoDrinkPotions.add(id);
      if (actionRunning && activeBuff(id) == null) {
        _potionSystem.drink(id, _inventoryData, _playerState.buffData);
      }
    } else {
      _playerState.autoDrinkPotions.remove(id);
    }
    notifyListeners();
  }

  /// Rebuilds now: the buff tick drank one, and the counts on screen have
  /// to follow it.
  void refresh() => notifyListeners();
}
