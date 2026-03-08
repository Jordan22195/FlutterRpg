import '../services/equipment_service.dart';

class EquipmentSystem {
  final InventoryService _inventoryService;
  final EquipmentService _equipmentService;

  EquipmentSystem({
    required InventoryService inventoryService,
    required EquipmentService equipmentService,
  }) : _equipmentService = equipmentService,
       _inventoryService = inventoryService;

  void unequipSlot(
    ArmorSlots slot,
    EquipmentData equipmentState,
    InventoryData inventoryState,
  ) {
    final itemId = _equipmentService.unequipSlot(slot, equipmentState);

    _inventoryService.addItem(inventoryState, itemId);
  }
}
