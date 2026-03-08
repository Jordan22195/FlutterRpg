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
        stats = Util.addMap(stats, item.skillBonus) as Map<SkillId, int>;
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

  ItemId unequipSlot(ArmorSlots slot, EquipmentData equipmentState) {
    final i = equipmentState.armorEquipment[slot] ?? ItemId.NULL;
    equipmentState.armorEquipment[slot] = ItemId.NULL;
    return i;
  }

  ItemId getItemInSlot(ArmorSlots slot, EquipmentData equipmentState) {
    return equipmentState.armorEquipment[slot] ?? ItemId.NULL;
  }
}
