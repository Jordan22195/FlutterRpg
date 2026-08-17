import 'package:flutter/foundation.dart';

import '../catalogs/enchantment_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../data/ObjectStack.dart';
import '../data/bound_action.dart';
import '../data/action_result.dart';
import '../data/inventory_data.dart';
import '../data/offline_progress_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/inventory_service.dart';
import '../services/offline_progress_service.dart';
import '../services/player_data_service.dart';
import '../systems/enchanting_system.dart';
import 'action_timing_controller.dart';

class EnchantingController extends ChangeNotifier {
  /// Pseudo recipe id for the disenchant action in the recipe picker.
  static const String disenchantRecipeId = 'disenchant';

  // controllers
  final ActionTimingController _actionTimingController;

  // data
  final PlayerData _playerState;
  final InventoryData _inventoryState;
  final OfflineProgressData _offlineProgressData;

  // catalogs
  final EnchantmentCatalog _enchantmentCatalog;

  // services
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;
  final OfflineProgressService _offlineProgressService;

  // systems
  final EnchantingSystem _enchantingSystem;

  // session selection: which action (enchant tier or disenchant) and
  // which inventory stack it targets
  String _selectedRecipeId = '';
  String _selectedTargetInstanceId = '';

  // identity of the stack the running action started on; enchanting can
  // hand the selected instanceId to a *different* (enchanted) stack, and
  // the loop must not silently continue onto it
  String _runningTargetStackKey = '';

  // results of the current bench session (materials gained, items
  // enchanted), shown in the screen's results grid. session-only
  final InventoryData _sessionResults = InventoryData(itemMap: {});

  EnchantingController({
    required ActionTimingController actionTimingController,
    required PlayerData playerState,
    required InventoryData inventoryState,
    required EnchantmentCatalog enchantmentCatalog,
    required InventoryService inventoryService,
    required EnchantingSystem enchantingSystem,
    required PlayerDataService playerDataService,
    required OfflineProgressData offlineProgressData,
    required OfflineProgressService offlineProgressService,
  }) : _actionTimingController = actionTimingController,
       _offlineProgressData = offlineProgressData,
       _offlineProgressService = offlineProgressService,
       _playerState = playerState,
       _inventoryState = inventoryState,
       _enchantmentCatalog = enchantmentCatalog,
       _inventoryService = inventoryService,
       _playerDataService = playerDataService,
       _enchantingSystem = enchantingSystem;

  /// Material items shown in the bench header, in tier order.
  static const List<ItemId> materials = [
    ItemId.ENCHANTING_DUST,
    ItemId.ENCHANTING_ESSENCE,
    ItemId.ENCHANTING_RUNE,
    ItemId.ENCHANTING_PRISM,
    ItemId.SOUL_SHARD,
  ];

  int materialCount(ItemId id) {
    return _inventoryService.getItemCount(_inventoryState, id);
  }

  /// Everything the bench can work on: what the player is wearing first,
  /// then the inventory's stacks. Worn gear is enchanted in place, so it
  /// leads the picker rather than having to be taken off first.
  List<EquipmentItem> equipmentList() {
    return List.unmodifiable(
      _enchantingSystem.benchTargets(_playerState, _inventoryState),
    );
  }

  /// Whether [item] is on the player rather than in the inventory, so the
  /// picker can say so.
  bool isEquipped(EquipmentItem item) {
    return _enchantingSystem.isEquipped(_playerState, item.instanceId);
  }

  List<EnchantRecipe> recipes() => _enchantmentCatalog.recipes;

  // ---- selection (selecting only selects; Action starts the work) ----

  String get selectedRecipeId => _selectedRecipeId;

  bool get disenchantSelected => _selectedRecipeId == disenchantRecipeId;

  EnchantRecipe? get selectedRecipe =>
      _enchantmentCatalog.recipeById(_selectedRecipeId);

  EquipmentItem? get selectedTarget {
    return _enchantingSystem.findTarget(
      _playerState,
      _inventoryState,
      _selectedTargetInstanceId,
    );
  }

  void selectRecipe(String recipeId) {
    _selectedRecipeId = recipeId;
    notifyListeners();
  }

  void selectTarget(EquipmentItem item) {
    _selectedTargetInstanceId = item.instanceId;
    notifyListeners();
  }

  bool recipeAvailable(EnchantRecipe recipe) {
    return _enchantingSystem.recipeRequirementsMet(
      recipe,
      _playerState,
      _inventoryState,
    );
  }

  ObjectStack<ItemId>? previewDisenchant(EquipmentItem item) {
    return _enchantingSystem.previewDisenchant(item, _playerState);
  }

  // ---- session results ----

  List<ObjectStack> sessionResults() {
    return _inventoryService.getObjectStackList(_sessionResults);
  }

  List<EquipmentItem> sessionEquipment() {
    return List.unmodifiable(_sessionResults.equipment);
  }

  // called when the player navigates to view an entity. if the bench
  // action is not running the session is over, so its results clear
  void onEntityViewChanged() {
    if (!_actionTimingController.isRunningAction(doEnchantingAction)) {
      _inventoryService.clearItems(_sessionResults);
      notifyListeners();
    }
  }

  // whether the current selection could perform at least one action
  bool selectionReady() {
    final target = selectedTarget;
    if (target == null) return false;
    if (disenchantSelected) return true;
    final recipe = selectedRecipe;
    return recipe != null && recipeAvailable(recipe);
  }

  // ---- the periodic action ----

  // fires a single time when the action button is pressed
  void startEnchantingAction() {
    startEnchantingActionFor(_selectedRecipeId, _selectedTargetInstanceId);
  }

  /// Starts the bench on [recipeId] against [targetInstanceId] directly.
  /// The selection lives only on this controller, so a resume has to put it
  /// back before it can start anything. Returns true when the action is
  /// running when this returns.
  bool startEnchantingActionFor(String recipeId, String targetInstanceId) {
    _selectedRecipeId = recipeId;
    _selectedTargetInstanceId = targetInstanceId;
    if (!selectionReady()) return false;

    // already running this bench's action: let it continue
    if (_actionTimingController.isRunningAction(doEnchantingAction)) {
      return true;
    }

    _actionTimingController.stop();

    _runningTargetStackKey = selectedTarget?.stackKey ?? '';

    // the bench offers no stance and shows no picker, so one carried in
    // from an encounter starts fast here
    _playerDataService.resetStanceToFast(_playerState);

    _actionTimingController.bindOnFireFunction(
      doEnchantingAction,
      activityIconId: EntityId.ENCHANTING_BENCH,
      activityCount: () => selectedTarget?.count ?? 0,
      // bench work is done by hand, so it runs at the default interval
      actionSkill: SkillId.ENCHANTING,
      boundAction: BoundAction.enchant(
        recipeId: recipeId,
        targetInstanceId: targetInstanceId,
      ),
    );

    _actionTimingController.start();
    return true;
  }

  /// How far the bench is through its current action, 0..1 — zero unless
  /// enchanting is the action running.
  double enchantProgress() {
    if (!_actionTimingController.isRunningAction(doEnchantingAction))
      return 0.0;
    return _actionTimingController.actionProgress;
  }

  /// The interval the bench's timer fills over: live while enchanting, and
  /// what starting here would cost otherwise.
  Duration enchantInterval() {
    if (_actionTimingController.isRunningAction(doEnchantingAction)) {
      return _actionTimingController.getCurrentActionDuration();
    }
    return _actionTimingController.idleActionDurationFor(SkillId.ENCHANTING);
  }

  // function bound to the action button. executes periodically: each
  // fire disenchants or enchants ONE item from the selected stack
  void doEnchantingAction(int count) {
    final target = selectedTarget;
    if (target == null || target.stackKey != _runningTargetStackKey) {
      _actionTimingController.stop();
      notifyListeners();
      return;
    }

    // what this fire produced, reported when the timing system is settling
    // time away and ignored otherwise
    final result = ActionResult();

    if (disenchantSelected) {
      final gained = _enchantingSystem.disenchant(
        target.instanceId,
        _playerState,
        _inventoryState,
      );
      if (gained != null) {
        _inventoryService.addItems(_sessionResults, [gained]);
        result.items.add(gained);
      }
    } else {
      final recipe = selectedRecipe;
      final enchanted = recipe == null
          ? null
          : _enchantingSystem.enchant(
              recipe.id,
              target.instanceId,
              _playerState,
              _inventoryState,
            );
      if (enchanted == null) {
        _actionTimingController.stop();
        notifyListeners();
        return;
      }
      // session grid gets its own copy: sharing one object between two
      // inventories would double-count when stacks merge
      _inventoryService.addEquipment(_sessionResults, enchanted.copy());
      result.equipment.add(enchanted);
    }

    _offlineProgressService.record(_offlineProgressData, result);

    // stop when the stack ran out or the next action can't be afforded
    if (!selectionReady()) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }
}
