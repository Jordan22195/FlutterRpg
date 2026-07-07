import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import '../catalogs/item_catalog.dart';
import '../utilities/util.dart';

class EquipmentService {
  Map<SkillId, int> getStatTotals(EquipmentData equipmentState) {
    Map<SkillId, int> stats = {};
    for (final itemId in equipmentState.armorEquipment.values) {
      if (itemId == ItemId.NULL) continue;
      final item = ItemCatalog.buildItem(itemId);

      if (item is EquipmentItem) {
        stats = Util.addMap(stats, item.skillBonus);
      }
    }

    // each per-skill tool contributes only the bonus for the skill it
    // is equipped under (an axe's attack bonus doesn't leak into combat)
    for (final entry in equipmentState.equipedTools.entries) {
      if (entry.value == ItemId.NULL) continue;
      final item = ItemCatalog.buildItem(entry.value);
      if (item is EquipmentItem) {
        final bonus = item.skillBonus[entry.key];
        if (bonus != null) {
          stats = Util.addMap(stats, {entry.key: bonus});
        }
      }
    }
    return stats;
  }

  bool equipItem(ItemId itemId, EquipmentData equipmentState) {
    Item item = ItemCatalog.buildItem(itemId);
    if (item.id == ItemId.NULL) return false;

    if (item is WeaponItem) {
      if (item.armorSlot == ArmorSlots.WEAPON_2H) {
        equipmentState.armorEquipment[ArmorSlots.WEAPON_2H] = item.id;
        equipmentState.armorEquipment[ArmorSlots.WEAPON_1H] = ItemId.NULL;
        equipmentState.armorEquipment[ArmorSlots.OFFHAND] = ItemId.NULL;
        return true;
      } else if (item.armorSlot == ArmorSlots.WEAPON_1H) {
        equipmentState.armorEquipment[ArmorSlots.WEAPON_1H] = item.id;
        equipmentState.armorEquipment[ArmorSlots.WEAPON_2H] = ItemId.NULL;
        return true;
      } else if (item.armorSlot == ArmorSlots.OFFHAND) {
        equipmentState.armorEquipment[ArmorSlots.OFFHAND] = item.id;
        equipmentState.armorEquipment[ArmorSlots.WEAPON_2H] = ItemId.NULL;
        return true;
      } else {
        // tools (armorSlot TOOL) are equipped per skill via equipTool
        return false;
      }
      //main hand/offhand checks
    } else if (item is EquipmentItem) {
      //check equipment slot is correct
      if (equipmentState.armorEquipment.containsKey(item.armorSlot)) {
        equipmentState.armorEquipment[item.armorSlot] = item.id;
        return true;
      }
    } else {
      return false;
    }
    return false;
  }

  void setEquipedFood(ItemId itemId, EquipmentData equipmentState) {
    equipmentState.equipedFood = itemId;
  }

  // the tool equipped for a gathering skill (axe for woodcutting, ...)
  ItemId getToolForSkill(SkillId skill, EquipmentData equipmentState) {
    return equipmentState.equipedTools[skill] ?? ItemId.NULL;
  }

  void equipTool(SkillId skill, ItemId itemId, EquipmentData equipmentState) {
    equipmentState.equipedTools[skill] = itemId;
  }

  ItemId unequipSlot(ArmorSlots slot, EquipmentData equipmentState) {
    final i = equipmentState.armorEquipment[slot] ?? ItemId.NULL;
    equipmentState.armorEquipment[slot] = ItemId.NULL;
    return i;
  }

  ItemId getItemInSlot(ArmorSlots slot, EquipmentData equipmentState) {
    return equipmentState.armorEquipment[slot] ?? ItemId.NULL;
  }
}
