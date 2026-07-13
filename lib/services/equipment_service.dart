import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import '../catalogs/item_catalog.dart';
import '../utilities/util.dart';

class EquipmentService {
  Map<SkillId, int> getStatTotals(EquipmentData equipmentState) {
    Map<SkillId, int> stats = {};
    for (final item in equipmentState.armorEquipment.values) {
      if (item == null) continue;
      stats = Util.addMap(stats, item.effectiveSkillBonus);
    }

    // each per-skill tool contributes only the bonus for the skill it
    // is equipped under (an axe's attack bonus doesn't leak into combat)
    for (final entry in equipmentState.equipedTools.entries) {
      final item = entry.value;
      if (item == null) continue;
      final bonus = item.effectiveSkillBonus[entry.key];
      if (bonus != null) {
        stats = Util.addMap(stats, {entry.key: bonus});
      }
    }
    return stats;
  }

  /// Equips [item] into its slot, applying weapon exclusivity rules.
  /// Returns the instances displaced by the swap (so they can be put
  /// back in the inventory), or null when the item can't be equipped
  /// this way (tools go through [equipTool]).
  List<EquipmentItem>? equipItem(EquipmentItem item, EquipmentData eq) {
    final displaced = <EquipmentItem>[];

    void displace(ArmorSlots slot) {
      final old = eq.armorEquipment[slot];
      if (old != null) displaced.add(old);
      eq.armorEquipment[slot] = null;
    }

    switch (item.armorSlot) {
      case ArmorSlots.WEAPON_2H:
        displace(ArmorSlots.WEAPON_2H);
        displace(ArmorSlots.WEAPON_1H);
        displace(ArmorSlots.OFFHAND);
        eq.armorEquipment[ArmorSlots.WEAPON_2H] = item;
        return displaced;
      case ArmorSlots.WEAPON_1H:
        displace(ArmorSlots.WEAPON_1H);
        displace(ArmorSlots.WEAPON_2H);
        eq.armorEquipment[ArmorSlots.WEAPON_1H] = item;
        return displaced;
      case ArmorSlots.OFFHAND:
        displace(ArmorSlots.OFFHAND);
        displace(ArmorSlots.WEAPON_2H);
        eq.armorEquipment[ArmorSlots.OFFHAND] = item;
        return displaced;
      case ArmorSlots.TOOL:
        // tools are equipped per skill via equipTool
        return null;
      default:
        if (!eq.armorEquipment.containsKey(item.armorSlot)) return null;
        displace(item.armorSlot);
        eq.armorEquipment[item.armorSlot] = item;
        return displaced;
    }
  }

  EquipmentItem? unequipSlot(ArmorSlots slot, EquipmentData equipmentState) {
    final old = equipmentState.armorEquipment[slot];
    equipmentState.armorEquipment[slot] = null;
    return old;
  }

  EquipmentItem? getItemInSlot(ArmorSlots slot, EquipmentData equipmentState) {
    return equipmentState.armorEquipment[slot];
  }

  void setEquipedFood(ItemId itemId, EquipmentData equipmentState) {
    equipmentState.equipedFood = itemId;
  }

  // the tool equipped for a gathering skill (axe for woodcutting, ...)
  EquipmentItem? getToolForSkill(SkillId skill, EquipmentData equipmentState) {
    return equipmentState.equipedTools[skill];
  }

  /// Equips [item] as the tool for [skill]; returns the displaced tool.
  EquipmentItem? equipTool(
    SkillId skill,
    EquipmentItem item,
    EquipmentData equipmentState,
  ) {
    final old = equipmentState.equipedTools[skill];
    equipmentState.equipedTools[skill] = item;
    return old;
  }

  EquipmentItem? unequipTool(SkillId skill, EquipmentData equipmentState) {
    final old = equipmentState.equipedTools[skill];
    equipmentState.equipedTools[skill] = null;
    return old;
  }
}
