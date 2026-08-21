import 'dart:math';

import '../catalogs/enchantments/enchantments.dart';
import '../data/action_result.dart';
import '../catalogs/items/items.dart';
import '../data/ObjectStack.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/enchanting_service.dart';
import '../services/equipment_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';

class EnchantingSystem {
  final EnchantingService _enchantingService;
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;
  final EquipmentService _equipmentService;
  final EnchantmentCatalog _enchantmentCatalog;

  EnchantingSystem({
    required EnchantingService enchantingService,
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
    required EquipmentService equipmentService,
    required EnchantmentCatalog enchantmentCatalog,
  }) : _enchantingService = enchantingService,
       _inventoryService = inventoryService,
       _playerDataService = playerDataService,
       _equipmentService = equipmentService,
       _enchantmentCatalog = enchantmentCatalog;

  EquipmentItem? _findInstance(InventoryData inventory, String instanceId) {
    for (final item in inventory.equipment) {
      if (item.instanceId == instanceId) return item;
    }
    return null;
  }

  /// The bench works on worn gear as well as stock, so every lookup has to
  /// check both: equipping takes an item out of the inventory entirely.
  EquipmentItem? _findEquipped(PlayerData playerState, String instanceId) {
    return _equipmentService.findEquippedInstance(
      instanceId,
      playerState.equipmentData,
    );
  }

  /// Every instance the bench can act on: what the player is wearing first,
  /// then the inventory's stacks.
  List<EquipmentItem> benchTargets(
    PlayerData playerState,
    InventoryData inventory,
  ) {
    return [
      ..._equipmentService.equippedItems(playerState.equipmentData),
      ...inventory.equipment,
    ];
  }

  /// Whether [instanceId] is on the player rather than in the inventory.
  bool isEquipped(PlayerData playerState, String instanceId) {
    return _findEquipped(playerState, instanceId) != null;
  }

  /// The bench's view of one instance, wherever it lives.
  EquipmentItem? findTarget(
    PlayerData playerState,
    InventoryData inventory,
    String instanceId,
  ) {
    return _findEquipped(playerState, instanceId) ??
        _findInstance(inventory, instanceId);
  }

  int _enchantingLevel(PlayerData playerState, {DateTime? at}) {
    return _playerDataService.getStatTotals(
          playerState,
          at: at,
        )[SkillId.ENCHANTING] ??
        1;
  }

  int _statTotal(EquipmentItem item) {
    return item.effectiveSkillBonus.values.fold(0, (a, b) => a + b);
  }

  /// The materials disenchanting [item] would yield right now.
  ObjectStack<ItemId> previewDisenchant(
    EquipmentItem item,
    PlayerData playerState, {
    DateTime? at,
  }) {
    return ObjectStack(
      id: _enchantingService.materialForQuality(item.quality),
      count: _enchantingService.disenchantYield(
        _statTotal(item),
        _enchantingLevel(playerState, at: at),
      ),
    );
  }

  /// Destroys ONE item from the stack and adds its materials to the
  /// inventory. An empty result means the stack was gone.
  ///
  /// The xp comes back on the result rather than only landing on the player,
  /// because a settle reports what its actions produced and this is the one
  /// action whose xp a caller cannot work out for itself - it is rolled from
  /// the item that has just been consumed.
  EncounterActionResult disenchant(
    String instanceId,
    PlayerData playerState,
    InventoryData inventory, {
    DateTime? at,
  }) {
    final result = EncounterActionResult();
    // worn gear is consumed straight off the player: the slot empties,
    // since the instance stops existing
    final item =
        _equipmentService.removeEquippedInstance(
          instanceId,
          playerState.equipmentData,
        ) ??
        _inventoryService.takeOneEquipment(inventory, instanceId);
    if (item == null) return result;

    final gained = previewDisenchant(item, playerState, at: at);

    _inventoryService.addItems(inventory, [gained]);
    result.items.add(gained);
    result.actionsPerformed = 1;
    result.xp = {SkillId.ENCHANTING: _statTotal(item) * 2.0};
    _playerDataService.applyXp(playerState, result.xp);
    return result;
  }

  bool recipeRequirementsMet(
    EnchantRecipe recipe,
    PlayerData playerState,
    InventoryData inventory, {
    DateTime? at,
  }) {
    if (_enchantingLevel(playerState, at: at) < recipe.levelRequirement) {
      return false;
    }
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
  /// as its own stack, and comes back on the result; an empty result means
  /// the enchant did not happen.
  EncounterActionResult enchant(
    String recipeId,
    String instanceId,
    PlayerData playerState,
    InventoryData inventory, {
    Random? rng,
    DateTime? at,
  }) {
    final result = EncounterActionResult();
    final recipe = _enchantmentCatalog.recipeById(recipeId);
    if (recipe == null) return result;

    final equipped = _findEquipped(playerState, instanceId);
    if (equipped == null && _findInstance(inventory, instanceId) == null) {
      return result;
    }
    if (!recipeRequirementsMet(recipe, playerState, inventory, at: at)) {
      return result;
    }

    // worn gear is enchanted in place and stays on the player: taking it
    // out to the inventory and back would unequip it mid-action
    final item =
        equipped ?? _inventoryService.takeOneEquipment(inventory, instanceId);
    if (item == null) return result;

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
    if (equipped == null) {
      _inventoryService.addEquipment(inventory, item);
    }

    result.equipment.add(item);
    result.actionsPerformed = 1;
    result.xp = {SkillId.ENCHANTING: recipe.xp};
    _playerDataService.applyXp(playerState, result.xp);
    return result;
  }
}
