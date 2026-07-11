import '../catalogs/item_catalog.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import 'inventory_service.dart';
import 'player_data_service.dart';

/// Shared auto-eat used by all automated combat (world encounters, the
/// action queue, and dungeons). For now it's a single fixed rule: eat one
/// equipped food when hp drops to or below [defaultThreshold] of max hp.
/// A later pass will make this per-player configurable and more robust.
class CombatAutoEatService {
  /// Eat when hp is at or below this fraction of max hp.
  static const double defaultThreshold = 0.75;

  final ItemCatalog _itemCatalog;
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;

  CombatAutoEatService({
    required ItemCatalog itemCatalog,
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
  }) : _itemCatalog = itemCatalog,
       _inventoryService = inventoryService,
       _playerDataService = playerDataService;

  /// Eats one equipped food when hp is at/below [threshold] of max hp and
  /// food is available. Returns true when it ate. A no-op when no food is
  /// equipped, the inventory is out, or hp is above the threshold.
  bool autoEat({
    required PlayerData playerState,
    required InventoryData playerInventory,
    double threshold = defaultThreshold,
  }) {
    final foodId = playerState.equipmentData.equipedFood;
    if (foodId == ItemId.NULL) return false;

    final def = _itemCatalog.definitionFor(foodId);
    if (def is! FoodItemDefinition) return false;
    if (_inventoryService.getItemCount(playerInventory, foodId) <= 0) {
      return false;
    }

    final maxHp =
        _playerDataService.getStatTotals(playerState)[SkillId.HITPOINTS] ?? 1;
    if (playerState.hitpoints > maxHp * threshold) return false;

    _inventoryService.removeItems(playerInventory, foodId, 1);
    _playerDataService.heal(def.restoreAmount, playerState);
    return true;
  }
}
