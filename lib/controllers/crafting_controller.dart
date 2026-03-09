import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/recipe_catalog.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/services/crafting_service.dart';
import '../services/inventory_service.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import '../systems/crafting_system.dart';
import '../data/player_data.dart';
import '../data/crafting_state.dart';
import '../data/world_data.dart';
import '../data/buff_data.dart';

class CraftingController extends ChangeNotifier {
  // controllers
  final ActionTimingController _actionTimingController;

  // data
  final PlayerData _playerState;
  final InventoryData _inventoryState;
  final CraftingState _craftingState;
  final WorldData _worldState;
  final BuffData _buffState;

  // catalogs
  final RecipeCatalog _recipeCatalog;

  //services
  final InventoryService _inventoryService;
  final CraftingService _craftingService;

  // systems
  final CraftingSystem _craftingSystem;

  CraftingController({
    required ActionTimingController actionTimingController,
    required InventoryData inventoryData,
    required InventoryService inventoryService,
    required CraftingSystem craftingSystem,
    required WorldData worldState,
    required BuffData buffState,
    required CraftingService craftingService,
    required CraftingState craftingState,
    required PlayerData playerState,
    required RecipeCatalog reciepeCatalog,
  }) : _actionTimingController = actionTimingController,
       _inventoryState = inventoryData,
       _inventoryService = inventoryService,
       _craftingSystem = craftingSystem,
       _worldState = worldState,
       _craftingService = craftingService,
       _playerState = playerState,
       _recipeCatalog = reciepeCatalog,
       _craftingState = craftingState,
       _buffState = buffState;

  int getItemCountInPlayerInventory(ItemId itemId) {
    return _inventoryService.getItemCount(_inventoryState, itemId);
  }

  // function bound to action button. executes periodically.
  void doCraftingAction() {
    _craftingSystem.craftActiveRecipeOnce(
      _craftingState,
      _playerState,
      _inventoryState,
      _buffState,
      _worldState,
    );
    if (_craftingSystem.recipeRequirementsMet(
      _craftingState.activeRecipe.id,
      _playerState,
      _inventoryState,
      _craftingState,
    )) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  void selectRecipe(String recipeId) {
    //service sets active recipe in crafting state
    _craftingState.selectedRecipeId = recipeId;

    // player can view a recipe while crafting another
    // active recipe is what is being crafted.
    // selected recipe is what is being viewed

    // recipe becomes selected when tapped in the screen
    // recipe becomes active when action button is pressed
  }

  // todo move this logic to the enoucnter system
  // fires a single time when action button is pressed
  // binds doEncounterAction to the periodic loop
  void startEncounterAction() {
    if (_craftingState.selectedRecipeId == _craftingState.activeRecipe.id) {
      return;
    }

    // if selected != active recipe, then starting a crafting
    // action on a new selection. stop the timing controller.
    _actionTimingController.stop();
    _craftingService.setActiveRecipe(
      _craftingState.selectedRecipeId,
      _craftingState,
      _recipeCatalog,
    );

    // check action conditions are met
    if (_craftingSystem.recipeRequirementsMet(
      _craftingState.activeRecipe.id,
      _playerState,
      _inventoryState,
      _craftingState,
    )) {
      return;
    }

    // bind Encounter action to action timing controller
    _actionTimingController.bindOnFireFunction(doCraftingAction);

    // start action timing
    _actionTimingController.start();
  }

  int getMaxNumberCraftsForRecipe(String recipeId) {
    return _craftingSystem.craftableCount(recipeId, _inventoryState);
  }
}
