import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/equipment_data.dart';
import '../catalogs/item_catalog.dart';
import '../data/inventory_data.dart';

class InventoryService {
  void addItem(InventoryData inventoryState, ItemId id) {
    inventoryState.itemMap.update(id, (count) => count + 1, ifAbsent: () => 1);
  }

  void addItems(InventoryData inventoryState, List<ObjectStack> items) {
    for (final item in items) {
      if (item.count <= 0) continue;
      inventoryState.itemMap.update(
        item.id,
        (count) => count + item.count,
        ifAbsent: () => item.count,
      );
    }
  }

  void removeItems(InventoryData inventoryState, ItemId id, int count) {
    if (count <= 0) return;

    final currentCount = inventoryState.itemMap[id] ?? 0;
    final newCount = currentCount - count;

    if (newCount > 0) {
      inventoryState.itemMap[id] = newCount;
    } else {
      inventoryState.itemMap.remove(id);
    }
  }

  void clearItems(InventoryData inventoryState) {
    inventoryState.itemMap.clear();
  }

  int getItemCount(InventoryData inventoryState, ItemId id) {
    return inventoryState.itemMap[id] ?? 0;
  }

  // get list of food items sorted by healing amount
  List<ItemId> getFoodItemsSortedByHealing(
    InventoryData inventoryState,
    ItemCatalog itemCatalog,
  ) {
    List<ItemId> foodItems = [];
    for (MapEntry entry in inventoryState.itemMap.entries) {
      final def = itemCatalog.definitionFor(entry.key);
      if (def is FoodItemDefinition) {
        foodItems.add(entry.key);
      }
    }
    foodItems.sort((a, b) {
      final defA = itemCatalog.definitionFor(a) as FoodItemDefinition;
      final defB = itemCatalog.definitionFor(b) as FoodItemDefinition;
      return defB.restoreAmount.compareTo(defA.restoreAmount);
    });
    return foodItems;
  }

  List<ItemId> getItemsListForEquipmentSlot(
    ArmorSlots slot,
    InventoryData inventoryState,
    ItemCatalog itemCatalog,
  ) {
    // This is a placeholder implementation. You can replace it with actual logic based on your game's design.
    List<ItemId> itemsForSlot = [];
    for (MapEntry entry in inventoryState.itemMap.entries) {
      final def = itemCatalog.definitionFor(entry.key);
      if (def is EquipmentItemDefition && def.armorSlot == slot) {
        itemsForSlot.add(entry.key);
      }
    }
    return itemsForSlot;
  }

  void addOtherInventory(InventoryData destInv, InventoryData sourceInv) {
    final iList = getObjectStackList(sourceInv);
    addItems(destInv, iList);
  }

  List<ObjectStack> getObjectStackList(InventoryData inventoryState) {
    List<ObjectStack> ret = [];
    for (final pair in inventoryState.itemMap.entries) {
      ret.add(ObjectStack(id: pair.key, count: pair.value));
    }
    return ret;
  }
}
