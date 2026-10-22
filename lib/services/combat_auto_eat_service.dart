import '../catalogs/items/items.dart';
import '../data/auto_eat_rule.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
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

    final maxHp = _playerDataService.maxHitpoints(playerState);
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
    switchFoodIfOut(playerState, playerInventory);
    return true;
  }

  /// Once the equipped stack is spent, equips the next food in the healing
  /// order: the first one listed below it, or — when nothing heals less —
  /// the top of the list again. Returns true when it switched. Leaves the
  /// spent food equipped when there is nothing else to eat, so the next
  /// stack of it picked up is used straight away.
  ///
  /// Every path that eats calls this after it eats — auto-eat, the eat
  /// button and an offline settle alike — so a fight never stalls on an
  /// empty stack with food still in the bag.
  bool switchFoodIfOut(PlayerData playerState, InventoryData playerInventory) {
    final current = playerState.equipmentData.equipedFood;
    if (current == ItemId.NULL) return false;
    if (_inventoryService.getItemCount(playerInventory, current) > 0) {
      return false;
    }

    final carried = _inventoryService.getFoodItemsSortedByHealing(
      playerInventory,
    );
    if (carried.isEmpty) return false;
    final next = carried.firstWhere(
      (id) => InventoryService.compareFoodByHealing(id, current) > 0,
      orElse: () => carried.first,
    );
    playerState.equipmentData.equipedFood = next;
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
