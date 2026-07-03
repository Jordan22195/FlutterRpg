import 'package:flutter/foundation.dart';
import '../catalogs/item_catalog.dart';
import '../data/equipment_data.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../services/equipment_service.dart';
import '../systems/equipment_system.dart';

class EquipmentController extends ChangeNotifier {
  // data
  final PlayerData _playerState;
  final InventoryData _inventoryState;

  // services
  final EquipmentService _equipmentService;

  // systems
  final EquipmentSystem _equipmentSystem;

  EquipmentController({
    required PlayerData playerState,
    required InventoryData inventoryState,
    required EquipmentService equipmentService,
    required EquipmentSystem equipmentSystem,
  }) : _playerState = playerState,
       _inventoryState = inventoryState,
       _equipmentService = equipmentService,
       _equipmentSystem = equipmentSystem;

  ItemId getItemInSlot(ArmorSlots slot) {
    return _equipmentService.getItemInSlot(slot, _playerState.equipmentData);
  }

  bool equipItem(ItemId itemId) {
    final equipped = _equipmentService.equipItem(
      itemId,
      _playerState.equipmentData,
    );
    notifyListeners();
    return equipped;
  }

  void unequipSlot(ArmorSlots slot) {
    _equipmentSystem.unequipSlot(
      slot,
      _playerState.equipmentData,
      _inventoryState,
    );
    notifyListeners();
  }
}
