import 'dart:math';

import '../catalogs/enchantment_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../data/ObjectStack.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/enchanting_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';

class EnchantingSystem {
  final EnchantingService _enchantingService;
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;
  final EnchantmentCatalog _enchantmentCatalog;

  EnchantingSystem({
    required EnchantingService enchantingService,
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
    required EnchantmentCatalog enchantmentCatalog,
  }) : _enchantingService = enchantingService,
       _inventoryService = inventoryService,
       _playerDataService = playerDataService,
       _enchantmentCatalog = enchantmentCatalog;

  EquipmentItem? _findInstance(InventoryData inventory, String instanceId) {
    for (final item in inventory.equipment) {
      if (item.instanceId == instanceId) return item;
    }
    return null;
  }

  int _enchantingLevel(PlayerData playerState) {
    return _playerDataService.getStatTotals(playerState)[SkillId.ENCHANTING] ??
        1;
  }

  int _statTotal(EquipmentItem item) {
    return item.effectiveSkillBonus.values.fold(0, (a, b) => a + b);
  }

  /// The materials disenchanting [item] would yield right now.
  ObjectStack<ItemId> previewDisenchant(
    EquipmentItem item,
    PlayerData playerState,
  ) {
    return ObjectStack(
      id: _enchantingService.materialForQuality(item.quality),
      count: _enchantingService.disenchantYield(
        _statTotal(item),
        _enchantingLevel(playerState),
      ),
    );
  }

  /// Destroys ONE item from the stack and adds its materials to the
  /// inventory. Returns what was gained, or null if the stack is gone.
  ObjectStack<ItemId>? disenchant(
    String instanceId,
    PlayerData playerState,
    InventoryData inventory,
  ) {
    final item = _inventoryService.takeOneEquipment(inventory, instanceId);
    if (item == null) return null;

    final gained = previewDisenchant(item, playerState);

    _inventoryService.addItems(inventory, [gained]);
    _playerDataService.applyXp(playerState, {
      SkillId.ENCHANTING: _statTotal(item) * 2.0,
    });
    return gained;
  }

  bool recipeRequirementsMet(
    EnchantRecipe recipe,
    PlayerData playerState,
    InventoryData inventory,
  ) {
    if (_enchantingLevel(playerState) < recipe.levelRequirement) return false;
    for (final input in recipe.inputs.entries) {
      if (_inventoryService.getItemCount(inventory, input.key) < input.value) {
        return false;
      }
    }
    return true;
  }

  /// Takes ONE item off the stack, consumes the recipe's materials, and
  /// applies a random enchant (random name, random stat spread with the
  /// recipe's fixed total). The enchanted item returns to the inventory
  /// as its own stack. Returns the enchanted item, or null on failure.
  EquipmentItem? enchant(
    String recipeId,
    String instanceId,
    PlayerData playerState,
    InventoryData inventory, {
    Random? rng,
  }) {
    final recipe = _enchantmentCatalog.recipeById(recipeId);
    if (recipe == null) return null;

    if (_findInstance(inventory, instanceId) == null) return null;
    if (!recipeRequirementsMet(recipe, playerState, inventory)) return null;

    final item = _inventoryService.takeOneEquipment(inventory, instanceId);
    if (item == null) return null;

    for (final input in recipe.inputs.entries) {
      _inventoryService.removeItems(inventory, input.key, input.value);
    }

    final random = rng ?? Random();
    final name = _enchantmentCatalog
        .enchantNames[random.nextInt(_enchantmentCatalog.enchantNames.length)];
    _enchantingService.applyRandomEnchant(
      item,
      name,
      recipe.statTotal,
      rng: random,
    );
    _inventoryService.addEquipment(inventory, item);

    _playerDataService.applyXp(playerState, {SkillId.ENCHANTING: recipe.xp});
    return item;
  }
}
