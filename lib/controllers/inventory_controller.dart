import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/systems/potion_system.dart';

class InventoryController extends ChangeNotifier {
  final InventoryData _inventoryData;
  final BuffData _buffState;

  final InventoryService _inventoryService;
  final PotionSystem _potionSystem;

  InventoryController({
    required InventoryData inventoryData,
    required BuffData buffState,
    required InventoryService inventoryService,
    required PotionSystem potionSystem,
  }) : _inventoryData = inventoryData,
       _buffState = buffState,
       _inventoryService = inventoryService,
       _potionSystem = potionSystem;

  // inventory data is mutated by other domains (encounter drops, crafting,
  // equipment). those controllers are wired to call this in GameSessionFactory
  void refresh() {
    notifyListeners();
  }

  List<ObjectStack> getObjectStackList() {
    return _inventoryService.getObjectStackList(_inventoryData);
  }

  int getItemCount(ItemId id) {
    return _inventoryService.getItemCount(_inventoryData, id);
  }

  // dev/testing helper: force a stack to a specific count
  void devSetItemCount(ItemId id, int count) {
    _inventoryService.setItemCount(_inventoryData, id, count);
    notifyListeners();
  }

  int getEquipmentCount(EquipmentItem item) {
    return _inventoryService.getEquipmentCount(_inventoryData, item);
  }

  // dev/testing helper: force the equipment stack matching this item's
  // identity to a specific count
  void devSetEquipmentCount(EquipmentItem item, int count) {
    _inventoryService.setEquipmentCount(_inventoryData, item, count);
    notifyListeners();
  }

  ItemDefinition? getItemDefinition(ItemId id) {
    return id.definition;
  }

  /// Whether [id] is a potion at all — true for something drinkable in
  /// principle, whether or not the player is holding one.
  bool isDrinkable(ItemId id) => _potionSystem.isDrinkable(id);

  /// Drinks one [id] out of the inventory, putting its buff up. False when
  /// [id] is not a potion or there is none left to drink.
  bool drinkPotion(ItemId id) {
    final drank = _potionSystem.drink(id, _inventoryData, _buffState);
    if (drank) notifyListeners();
    return drank;
  }

  List<ItemId> getFoodItems() {
    return _inventoryService.getFoodItemsSortedByHealing(_inventoryData);
  }

  // unique equipment instances in the inventory (unequipped)
  List<EquipmentItem> getEquipmentList() {
    return List.unmodifiable(_inventoryData.equipment);
  }

  List<EquipmentItem> getSlotItemList(ArmorSlots slot) {
    return _inventoryService.getEquipmentForSlot(slot, _inventoryData);
  }

  List<EquipmentItem> getSlotItemListForSkill(
    ArmorSlots slot,
    SkillId skillId,
  ) {
    return _inventoryService.getEquipmentForSlotAndSkill(
      slot,
      _inventoryData,
      skillId,
    );
  }
}
