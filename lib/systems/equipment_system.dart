import '../catalogs/item_catalog.dart';
import '../services/equipment_service.dart';
import '../services/inventory_service.dart';
import '../data/equipment_data.dart';
import '../data/inventory_data.dart';
import '../data/skill_data.dart';

class EquipmentSystem {
  final InventoryService _inventoryService;
  final EquipmentService _equipmentService;

  EquipmentSystem({
    required InventoryService inventoryService,
    required EquipmentService equipmentService,
  }) : _equipmentService = equipmentService,
       _inventoryService = inventoryService;

  /// Takes one item off the inventory stack and equips it; anything
  /// displaced by the swap goes back into the inventory.
  bool equipItem(
    EquipmentItem item,
    EquipmentData equipmentState,
    InventoryData inventoryState,
  ) {
    final taken = _inventoryService.takeOneEquipment(
      inventoryState,
      item.instanceId,
    );
    if (taken == null) return false;

    final displaced = _equipmentService.equipItem(taken, equipmentState);
    if (displaced == null) {
      // couldn't equip; return the item to the inventory
      _inventoryService.addEquipment(inventoryState, taken);
      return false;
    }

    for (final old in displaced) {
      _inventoryService.addEquipment(inventoryState, old);
    }
    return true;
  }

  /// Takes one item off the inventory stack and equips it as the tool
  /// for [skill]; the previous tool goes back into the inventory.
  void equipTool(
    SkillId skill,
    EquipmentItem item,
    EquipmentData equipmentState,
    InventoryData inventoryState,
  ) {
    final taken = _inventoryService.takeOneEquipment(
      inventoryState,
      item.instanceId,
    );
    if (taken == null) return;

    final old = _equipmentService.equipTool(skill, taken, equipmentState);
    if (old != null) {
      _inventoryService.addEquipment(inventoryState, old);
    }
  }

  void unequipSlot(
    ArmorSlots slot,
    EquipmentData equipmentState,
    InventoryData inventoryState,
  ) {
    final old = _equipmentService.unequipSlot(slot, equipmentState);
    if (old != null) {
      _inventoryService.addEquipment(inventoryState, old);
    }
  }
}
