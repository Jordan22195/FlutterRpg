import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
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
    inventoryState.equipment.clear();
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

  // ---- unique equipment instances ----

  /// Adds equipment to the inventory, merging onto an existing stack when
  /// the items are identical (same base, quality, and enchant).
  void addEquipment(InventoryData inventoryState, EquipmentItem item) {
    for (final stack in inventoryState.equipment) {
      if (stack.canStackWith(item)) {
        stack.count += item.count;
        return;
      }
    }
    inventoryState.equipment.add(item);
  }

  /// Takes a single item off the stack identified by [instanceId].
  /// Returns a count-1 instance, or null when the stack doesn't exist.
  EquipmentItem? takeOneEquipment(
    InventoryData inventoryState,
    String instanceId,
  ) {
    for (final stack in inventoryState.equipment) {
      if (stack.instanceId != instanceId) continue;
      if (stack.count > 1) {
        stack.count -= 1;
        return stack.copy();
      }
      inventoryState.equipment.remove(stack);
      return stack;
    }
    return null;
  }

  void removeEquipment(InventoryData inventoryState, String instanceId) {
    inventoryState.equipment.removeWhere((e) => e.instanceId == instanceId);
  }

  List<EquipmentItem> getEquipmentForSlot(
    ArmorSlots slot,
    InventoryData inventoryState,
  ) {
    return inventoryState.equipment
        .where((e) => e.armorSlot == slot)
        .toList();
  }

  List<EquipmentItem> getEquipmentForSlotAndSkill(
    ArmorSlots slot,
    InventoryData inventoryState,
    SkillId skillId,
  ) {
    return inventoryState.equipment
        .where((e) => e.armorSlot == slot && e.skillBonus.containsKey(skillId))
        .toList();
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
