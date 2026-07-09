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

  // the selection belonging to the crafting entity the player is viewing
  String get selectedRecipeId =>
      _craftingState.selectedRecipeByEntity[_playerState
          .currentEntityViewId] ??
      "";

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

  // items crafted during the current crafting session. stations that are
  // not the session's station show an empty list
  List<ObjectStack> craftedItems() {
    if (_craftingState.craftingEntityId != _playerState.currentEntityViewId) {
      return [];
    }
    return _inventoryService.getObjectStackList(_craftingState.craftedItems);
  }

  // unique equipment crafted during the current session (with quality)
  List<EquipmentItem> craftedEquipment() {
    if (_craftingState.craftingEntityId != _playerState.currentEntityViewId) {
      return [];
    }
    return List.unmodifiable(_craftingState.craftedItems.equipment);
  }

  // called when the player navigates to view an entity. if no crafting
  // action is running the previous session is over, so its crafted items
  // are cleared; a still-running session keeps them
  void onEntityViewChanged() {
    if (!_actionTimingController.isRunningAction(doCraftingAction)) {
      _inventoryService.clearItems(_craftingState.craftedItems);
      notifyListeners();
    }
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


  void selectRecipe(String recipeId) {
    // selections are stored per crafting entity
    _craftingState.selectedRecipeByEntity[_playerState.currentEntityViewId] =
        recipeId;

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
    final selected = selectedRecipeId;
    if (selected.isEmpty) {
      return;
    }
    startCraftingActionFor(selected, _playerState.currentEntityViewId);
  }

  // starts crafting [recipeId] at [stationEntityId] directly (used by the
  // craft button via startCraftingAction and by the action queue).
  // returns true when the action is running when this returns
  bool startCraftingActionFor(String recipeId, EntityId stationEntityId) {
    // same recipe with its action already running: let it continue.
    // (a stopped action on the same recipe falls through and restarts)
    if (recipeId == _craftingState.activeRecipeId &&
        _actionTimingController.isRunningAction(doCraftingAction)) {
      return true;
    }

    // starting a crafting action on a new selection.
    // stop the timing controller.
    _actionTimingController.stop();

    // crafting at a new station starts a new session: crafted items
    // shown in the crafting screen belong to the previous session
    if (_craftingState.craftingEntityId != stationEntityId) {
      _inventoryService.clearItems(_craftingState.craftedItems);
      _craftingState.craftingEntityId = stationEntityId;
    }

    _craftingService.setActiveRecipe(recipeId, _craftingState, _recipeCatalog);

    // check action conditions are met
    if (!_craftingSystem.recipeRequirementsMet(
      _craftingState.activeRecipeId,
      _playerState,
      _inventoryState,
      _craftingState,
    )) {
      return false;
    }

    // bind Encounter action to action timing controller.
    // icon is the crafting station; the badge counts how many more
    // crafts the inventory can support.
    _actionTimingController.bindOnFireFunction(
      doCraftingAction,
      activityIconId: stationEntityId,
      activityCount: () =>
          getMaxNumberCraftsForRecipe(_craftingState.activeRecipeId),
    );

    // start action timing
    _actionTimingController.start();
    return true;
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
