import '../catalogs/items/items.dart';
import '../data/auto_eat_rule.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import 'inventory_service.dart';
import 'player_data_service.dart';

/// Shared auto-eat used by all automated combat (world encounters, the
/// action queue, and dungeons): eat one equipped food when hp drops to or
/// below the player's [AutoEatRule] threshold.
///
/// The rule lives on the player, and the pieces of it the offline settle
/// needs are exposed here rather than reimplemented there - a replayed
/// fight has to eat on exactly the terms a live one does.
class CombatAutoEatService {
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;

  CombatAutoEatService({
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
  }) : _inventoryService = inventoryService,
       _playerDataService = playerDataService;

  /// Eats one equipped food when [rule] says to and food is available,
  /// defaulting to the player's own rule. Returns true when it ate. A no-op
  /// when no food is equipped, the inventory is out, or hp is above the
  /// threshold.
  bool autoEat({
    required PlayerData playerState,
    required InventoryData playerInventory,
    AutoEatRule? rule,
  }) {
    final food = equippedFood(playerState);
    if (food == null) return false;
    if (availableFood(playerState, playerInventory) <= 0) return false;

    final maxHp =
        _playerDataService.getStatTotals(playerState)[SkillId.HITPOINTS] ?? 1;
    if (!shouldEat(
      hitpoints: playerState.hitpoints,
      maxHp: maxHp,
      rule: rule ?? playerState.autoEatRule,
    )) {
      return false;
    }

    _inventoryService.removeItems(
      playerInventory,
      playerState.equipmentData.equipedFood,
      1,
    );
    _playerDataService.heal(food.restoreAmount, playerState);
    return true;
  }

  /// The rule itself, stated once so a replay can apply it without eating
  /// through the inventory one item at a time.
  bool shouldEat({
    required int hitpoints,
    required int maxHp,
    required AutoEatRule rule,
  }) {
    return hitpoints <= maxHp * rule.threshold;
  }

  /// The equipped food, or null when nothing edible is equipped.
  FoodItemDefinition? equippedFood(PlayerData playerState) {
    final foodId = playerState.equipmentData.equipedFood;
    if (foodId == ItemId.NULL) return null;
    final def = foodId.definition;
    return def is FoodItemDefinition ? def : null;
  }

  /// How many of the equipped food the player is carrying.
  int availableFood(PlayerData playerState, InventoryData inventory) {
    final foodId = playerState.equipmentData.equipedFood;
    if (foodId == ItemId.NULL) return 0;
    return _inventoryService.getItemCount(inventory, foodId);
  }
}
