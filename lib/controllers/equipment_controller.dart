import 'package:flutter/foundation.dart';
import '../catalogs/item_catalog.dart';
import '../data/equipment_data.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
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

  EquipmentItem? getItemInSlot(ArmorSlots slot) {
    return _equipmentService.getItemInSlot(slot, _playerState.equipmentData);
  }

  /// Combined effective bonuses from all equipped armor, weapons, and tools.
  Map<SkillId, int> getStatTotals() {
    return _equipmentService.getStatTotals(_playerState.equipmentData);
  }

  bool equipItem(EquipmentItem item) {
    final equipped = _equipmentSystem.equipItem(
      item,
      _playerState.equipmentData,
      _inventoryState,
    );
    notifyListeners();
    return equipped;
  }

  // the tool equipped for a gathering skill
  EquipmentItem? getToolForSkill(SkillId skill) {
    return _equipmentService.getToolForSkill(skill, _playerState.equipmentData);
  }

  void equipToolForSkill(SkillId skill, EquipmentItem item) {
    _equipmentSystem.equipTool(
      skill,
      item,
      _playerState.equipmentData,
      _inventoryState,
    );
    notifyListeners();
  }

  // the equipped weapon; combat entities use this as their 'tool'
  EquipmentItem? getEquipedWeapon() {
    return getItemInSlot(ArmorSlots.WEAPON_2H) ??
        getItemInSlot(ArmorSlots.WEAPON_1H);
  }

  void setEquipedFood(ItemId itemId) {
    _equipmentService.setEquipedFood(itemId, _playerState.equipmentData);
    notifyListeners();
  }

  void unequipSlot(ArmorSlots slot) {
    _equipmentSystem.unequipSlot(
      slot,
      _playerState.equipmentData,
      _inventoryState,
    );
    notifyListeners();
  }

  void unequipToolForSkill(SkillId skill) {
    _equipmentSystem.unequipTool(
      skill,
      _playerState.equipmentData,
      _inventoryState,
    );
    notifyListeners();
  }
}
