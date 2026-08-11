import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/recipe_catalog.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/services/crafting_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import '../systems/crafting_system.dart';
import '../systems/firemaking_system.dart';
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
  final PlayerDataService _playerDataService;

  // systems
  final CraftingSystem _craftingSystem;
  final FiremakingSystem _firemakingSystem;

  CraftingController({
    required ActionTimingController actionTimingController,
    required InventoryData inventoryData,
    required InventoryService inventoryService,
    required CraftingSystem craftingSystem,
    required FiremakingSystem firemakingSystem,
    required WorldData worldState,
    required BuffData buffState,
    required CraftingService craftingService,
    required CraftingState craftingState,
    required PlayerData playerState,
    required RecipeCatalog reciepeCatalog,
    required EntityCatalog entityCatalog,
    required PlayerDataService playerDataService,
  }) : _actionTimingController = actionTimingController,
       _playerDataService = playerDataService,
       _firemakingSystem = firemakingSystem,
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

  // the selection the viewed station holds for [skill]. a station offering
  // several skills keeps one selection per skill.
  String selectedRecipeIdFor(SkillId skill) {
    return _craftingState.selectedRecipeByEntity[_playerState
            .currentEntityViewId]?[skill] ??
        "";
  }

  // the selection belonging to the crafting entity the player is viewing,
  // for that station's own skill
  String get selectedRecipeId =>
      selectedRecipeIdFor(getCraftingEntitySkillId());

  String get activeRecipeId => _craftingState.activeRecipeId;

  CraftingRecipe getRecipe(String recipeId) {
    return _recipeCatalog.recipeById(recipeId);
  }

  // recipes for the crafting entity the player is viewing
  List<CraftingRecipe> availableRecipes() {
    return availableRecipesFor(getCraftingEntitySkillId());
  }

  List<CraftingRecipe> availableRecipesFor(SkillId skill) {
    if (skill == SkillId.NULL) {
      return _recipeCatalog.recipes;
    }
    return _recipeCatalog.recipesForSkill(skill);
  }

  /// True when the station on screen is the one the crafting session
  /// belongs to. Keyed on the zone as well as the id: the same firepit id
  /// stands in several zones, and only the one being worked owns the
  /// session's output and progress.
  bool _isViewingSessionStation() {
    return _craftingState.craftingEntityId ==
            _playerState.currentEntityViewId &&
        _craftingState.craftingZoneId == _playerState.currentZoneId;
  }

  // items crafted during the current crafting session. stations that are
  // not the session's station show an empty list
  List<ObjectStack> craftedItems() {
    if (!_isViewingSessionStation()) {
      return [];
    }
    return _inventoryService.getObjectStackList(_craftingState.craftedItems);
  }

  // unique equipment crafted during the current session (with quality)
  List<EquipmentItem> craftedEquipment() {
    if (!_isViewingSessionStation()) {
      return [];
    }
    return List.unmodifiable(_craftingState.craftedItems.equipment);
  }

  /// True when the crafting loop is running at the station on screen. A
  /// craft running at a different bench is not this screen's.
  bool _isCraftingHere() {
    return _isViewingSessionStation() &&
        _actionTimingController.isRunningAction(doCraftingAction);
  }

  /// How far this station is through its current craft, 0..1 — zero unless
  /// the craft running is this station's.
  double craftProgress() {
    if (!_isCraftingHere()) return 0.0;
    return _actionTimingController.actionProgress;
  }

  /// The interval the station's timer fills over: live while it is the one
  /// working, and what starting a craft here would cost otherwise.
  Duration craftInterval() {
    if (_isCraftingHere()) {
      return _actionTimingController.getCurrentActionDuration();
    }
    // crafting is done by hand, so nothing equipped sets the pace
    return _actionTimingController.idleActionDurationFor(null);
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
    // selections are stored per crafting entity, then per skill. the skill
    // comes from the recipe, so callers never have to pass it.
    final skill = _recipeCatalog.recipeById(recipeId).skill;
    (_craftingState.selectedRecipeByEntity[_playerState.currentEntityViewId] ??=
            {})[skill] =
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
    // a different station — or the same station in a different zone — is a
    // new session, so the previous one's output is cleared
    if (_craftingState.craftingEntityId != stationEntityId ||
        _craftingState.craftingZoneId != _playerState.currentZoneId) {
      _inventoryService.clearItems(_craftingState.craftedItems);
      _craftingState.craftingEntityId = stationEntityId;
      _craftingState.craftingZoneId = _playerState.currentZoneId;
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

    // bench work offers no stance, and this screen has no picker to put one
    // back, so a stance carried in from an encounter starts fast here
    _playerDataService.resetStanceToFast(_playerState);

    // bind Encounter action to action timing controller.
    // icon is the crafting station; the badge counts how many more
    // crafts the inventory can support.
    _actionTimingController.bindOnFireFunction(
      doCraftingAction,
      activityIconId: stationEntityId,
      activityCount: () =>
          getMaxNumberCraftsForRecipe(_craftingState.activeRecipeId),
      // crafting is done at the station by hand: nothing is equipped to
      // set the pace, so it runs at the default interval
      actionSkill: null,
    );

    // start action timing
    _actionTimingController.start();
    return true;
  }

  int getMaxNumberCraftsForRecipe(String recipeId) {
    return _craftingSystem.craftableCount(recipeId, _inventoryState);
  }

  /// Whether the player's level in the recipe's skill meets its requirement.
  /// A recipe that fails this can never be crafted, so the picker locks it.
  bool meetsRecipeLevelRequirement(String recipeId) {
    return _craftingSystem.checkRecipeLevelRequirement(recipeId, _playerState);
  }

  /// Whether the inventory holds enough of every input for a single craft.
  /// Unlike the level requirement this is a temporary shortfall, so the
  /// recipe stays selectable and is only flagged.
  bool hasMaterialsForRecipe(String recipeId) {
    return getMaxNumberCraftsForRecipe(recipeId) > 0;
  }

  /// The crafting station the player is looking at.
  EntityId get stationEntityId => _playerState.currentEntityViewId;

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

  // ---- firepits ----

  /// The fire burning in the firepit being viewed, or null when it is cold.
  FireItem? activeFire() {
    return _firemakingSystem.activeFire(
      _playerState.currentEntityViewId,
      _playerState.currentZoneId,
      _buffState,
    );
  }

  /// Whether the viewed firepit's fire can cook on it.
  bool canCook() => activeFire()?.canCook ?? false;

  /// Puts out the viewed firepit's fire. A cooking action running on it stops
  /// on its next tick, when its requirements re-check fails.
  void putOutFire() {
    _firemakingSystem.extinguish(
      _playerState.currentEntityViewId,
      _playerState.currentZoneId,
      _buffState,
    );
    notifyListeners();
  }
}
