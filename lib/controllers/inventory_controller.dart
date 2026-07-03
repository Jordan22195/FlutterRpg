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

  List<ObjectStack> getObjectStackList() {
    return _inventoryService.getObjectStackList(_inventoryData);
  }

  int getItemCount(ItemId id) {
    return _inventoryService.getItemCount(_inventoryData, id);
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

  List<ItemId> getSlotItemList(ArmorSlots slot) {
    return _inventoryService.getItemsListForEquipmentSlot(
      slot,
      _inventoryData,
      _itemCatalog,
    );
  }

  List<ItemId> getSlotItemListForSkill(ArmorSlots slot, SkillId skillId) {
    return _inventoryService.getItemsListForEquipmentSlotAndSkill(
      slot,
      _inventoryData,
      _itemCatalog,
      skillId,
    );
  }
}
