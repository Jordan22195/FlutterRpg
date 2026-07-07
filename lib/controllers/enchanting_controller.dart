import 'package:flutter/foundation.dart';

import '../catalogs/enchantment_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../data/ObjectStack.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../services/inventory_service.dart';
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

  // catalogs
  final EnchantmentCatalog _enchantmentCatalog;

  // services
  final InventoryService _inventoryService;

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
  }) : _actionTimingController = actionTimingController,
       _playerState = playerState,
       _inventoryState = inventoryState,
       _enchantmentCatalog = enchantmentCatalog,
       _inventoryService = inventoryService,
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

  List<EquipmentItem> equipmentList() {
    return List.unmodifiable(_inventoryState.equipment);
  }

  List<EnchantRecipe> recipes() => _enchantmentCatalog.recipes;

  // ---- selection (selecting only selects; Action starts the work) ----

  String get selectedRecipeId => _selectedRecipeId;

  bool get disenchantSelected => _selectedRecipeId == disenchantRecipeId;

  EnchantRecipe? get selectedRecipe =>
      _enchantmentCatalog.recipeById(_selectedRecipeId);

  EquipmentItem? get selectedTarget {
    for (final item in _inventoryState.equipment) {
      if (item.instanceId == _selectedTargetInstanceId) return item;
    }
    return null;
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
    if (!selectionReady()) return;

    // already running this bench's action: let it continue
    if (_actionTimingController.isRunningAction(doEnchantingAction)) {
      return;
    }

    _actionTimingController.stop();

    _runningTargetStackKey = selectedTarget?.stackKey ?? '';

    _actionTimingController.bindOnFireFunction(
      doEnchantingAction,
      activityIconId: EntityId.ENCHANTING_BENCH,
      activityCount: () => selectedTarget?.count ?? 0,
    );

    _actionTimingController.start();
  }

  // function bound to the action button. executes periodically: each
  // fire disenchants or enchants ONE item from the selected stack
  void doEnchantingAction() {
    final target = selectedTarget;
    if (target == null || target.stackKey != _runningTargetStackKey) {
      _actionTimingController.stop();
      notifyListeners();
      return;
    }

    if (disenchantSelected) {
      final gained = _enchantingSystem.disenchant(
        target.instanceId,
        _playerState,
        _inventoryState,
      );
      if (gained != null) {
        _inventoryService.addItems(_sessionResults, [gained]);
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
    }

    // stop when the stack ran out or the next action can't be afforded
    if (!selectionReady()) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }
}
