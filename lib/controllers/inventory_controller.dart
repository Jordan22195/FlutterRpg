import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/inventory_service.dart';

class InventoryController extends ChangeNotifier {
  final InventoryData _inventoryData;

  final InventoryService _inventoryService;

  final ItemCatalog _itemCatalog;

  InventoryController({
    required InventoryData inventoryData,
    required InventoryService inventoryService,
    required ItemCatalog itemCatalog,
  }) : _inventoryData = inventoryData,
       _inventoryService = inventoryService,
       _itemCatalog = itemCatalog;

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
    return _itemCatalog.definitionFor(id);
  }

  List<ItemId> getFoodItems() {
    return _inventoryService.getFoodItemsSortedByHealing(
      _inventoryData,
      _itemCatalog,
    );
  }

  // unique equipment instances in the inventory (unequipped)
  List<EquipmentItem> getEquipmentList() {
    return List.unmodifiable(_inventoryData.equipment);
  }

  List<EquipmentItem> getSlotItemList(ArmorSlots slot) {
    return _inventoryService.getEquipmentForSlot(slot, _inventoryData);
  }

  List<EquipmentItem> getSlotItemListForSkill(ArmorSlots slot, SkillId skillId) {
    return _inventoryService.getEquipmentForSlotAndSkill(
      slot,
      _inventoryData,
      skillId,
    );
  }
}
