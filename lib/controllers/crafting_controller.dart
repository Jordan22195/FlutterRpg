import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/recipe_catalog.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/ObjectStack.dart';
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
  final EntityCatalog _entityCatalog;

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
    required EntityCatalog entityCatalog,
  }) : _actionTimingController = actionTimingController,
       _inventoryState = inventoryData,
       _inventoryService = inventoryService,
       _craftingSystem = craftingSystem,
       _worldState = worldState,
       _craftingService = craftingService,
       _playerState = playerState,
       _recipeCatalog = reciepeCatalog,
       _craftingState = craftingState,
       _entityCatalog = entityCatalog,
       _buffState = buffState;

  int getItemCountInPlayerInventory(ItemId itemId) {
    return _inventoryService.getItemCount(_inventoryState, itemId);
  }

  String get selectedRecipeId => _craftingState.selectedRecipeId;

  String get activeRecipeId => _craftingState.activeRecipeId;

  CraftingRecipe getRecipe(String recipeId) {
    return _recipeCatalog.recipeById(recipeId);
  }

  // recipes for the crafting entity the player is viewing
  List<CraftingRecipe> availableRecipes() {
    final skill = getCraftingEntitySkillId();
    if (skill == SkillId.NULL) {
      return _recipeCatalog.recipes;
    }
    return _recipeCatalog.recipesForSkill(skill);
  }

  List<ObjectStack> craftedItems() {
    return _inventoryService.getObjectStackList(_craftingState.craftedItems);
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
    if (!_craftingSystem.recipeRequirementsMet(
      _craftingState.activeRecipeId,
      _playerState,
      _inventoryState,
      _craftingState,
    )) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }


  // each crafting entity is going to have its own seleted reciepe so there is going to need to be a state for every crafting entity. 
  void selectRecipe(String recipeId) {
    //service sets active recipe in crafting state
    _craftingState.selectedRecipeId = recipeId;

    // player can view a recipe while crafting another
    // active recipe is what is being crafted.
    // selected recipe is what is being viewed

    // recipe becomes selected when tapped in the screen
    // recipe becomes active when action button is pressed

    notifyListeners();
  }

  // todo move this logic to the enoucnter system
  // fires a single time when action button is pressed
  // binds doEncounterAction to the periodic loop
  void startCraftingAction() {
    if (_craftingState.selectedRecipeId == _craftingState.activeRecipeId) {
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
    if (!_craftingSystem.recipeRequirementsMet(
      _craftingState.activeRecipeId,
      _playerState,
      _inventoryState,
      _craftingState,
    )) {
      return;
    }

    // bind Encounter action to action timing controller.
    // icon is the crafting station the player is viewing; the badge counts
    // how many more crafts the inventory can support.
    _actionTimingController.bindOnFireFunction(
      doCraftingAction,
      activityIconId: _playerState.currentEntityViewId,
      activityCount: () =>
          getMaxNumberCraftsForRecipe(_craftingState.activeRecipeId),
    );

    // start action timing
    _actionTimingController.start();
  }

  int getMaxNumberCraftsForRecipe(String recipeId) {
    return _craftingSystem.craftableCount(recipeId, _inventoryState);
  }

  SkillId getCraftingEntitySkillId() {
    final entityId = _playerState.currentEntityViewId;
    final def = _entityCatalog.getDefinitionFor(entityId);
    if (def is CraftingEntityDefinition) {
      return def.craftingSkill;
    }
    return SkillId.NULL;
  }

  String skillName() {
    return getCraftingEntitySkillId().name;
  }

  String entityIconAsset() {
    return _entityCatalog
        .getDefinitionFor(_playerState.currentEntityViewId)
        .iconAsset;
  }
}
