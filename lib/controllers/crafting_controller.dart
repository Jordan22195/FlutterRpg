import 'package:flutter/foundation.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import '../systems/crafting_system.dart';

class CraftingController extends ChangeNotifier {
  // data
  final InventoryData _inventoryState;

  //services
  final InventoryService _inventoryService;

  // systems
  final CraftingSystem _craftingSystem;

  CraftingController({
    required InventoryData inventoryData,
    required InventoryService inventoryService,
    required CraftingSystem craftingSystem,
  }) : _inventoryState = inventoryData,
       _inventoryService = inventoryService,
       _craftingSystem = craftingSystem;

  // --- UI helpers ---
  int getItemCountInPlayerInventory(ItemId itemId) {
    return _inventoryService.getItemCount(_inventoryState, itemId);
  }

  // function bound to action button. executes periodically.
  void doCraftingAction() {
    notifyListeners();
  }

  int getMaxNumberCraftsForRecipe(String recipeId) {
    return _craftingSystem.craftableCount(recipeId);
  }
}
