import '../catalogs/items/items.dart';
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
  /// displaced by the swap goes back into the inventory. [toSlot] picks
  /// between the slots the item accepts (which ring finger it goes on).
  ///
  /// [skillLevels] are the player's levels earned from xp, which the piece's
  /// own requirement is checked against before anything moves — a refused
  /// equip leaves the inventory exactly as it was.
  bool equipItem(
    EquipmentItem item,
    EquipmentData equipmentState,
    InventoryData inventoryState, {
    required Map<SkillId, int> skillLevels,
    ArmorSlots? toSlot,
  }) {
    if (!_equipmentService.meetsRequirement(item, skillLevels)) return false;

    final taken = _inventoryService.takeOneEquipment(
      inventoryState,
      item.instanceId,
    );
    if (taken == null) return false;

    final displaced = _equipmentService.equipItem(
      taken,
      equipmentState,
      toSlot: toSlot,
    );
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
  /// for [skill]; the previous tool goes back into the inventory. Gated on
  /// the tool's own requirement the same way [equipItem] is — a mithril
  /// pickaxe asks for a miner, not a fighter. False when it was refused.
  bool equipTool(
    SkillId skill,
    EquipmentItem item,
    EquipmentData equipmentState,
    InventoryData inventoryState, {
    required Map<SkillId, int> skillLevels,
  }) {
    if (!_equipmentService.meetsRequirement(item, skillLevels)) return false;

    final taken = _inventoryService.takeOneEquipment(
      inventoryState,
      item.instanceId,
    );
    if (taken == null) return false;

    final old = _equipmentService.equipTool(skill, taken, equipmentState);
    if (old != null) {
      _inventoryService.addEquipment(inventoryState, old);
    }
    return true;
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

  void unequipTool(
    SkillId skill,
    EquipmentData equipmentState,
    InventoryData inventoryState,
  ) {
    final old = _equipmentService.unequipTool(skill, equipmentState);
    if (old != null) {
      _inventoryService.addEquipment(inventoryState, old);
    }
  }
}
