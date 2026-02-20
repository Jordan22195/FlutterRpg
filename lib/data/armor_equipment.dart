import 'package:rpg/data/inventory.dart';

import 'item.dart';
import 'skill.dart';

enum ArmorSlots {
  HEAD,
  SHOULDER,
  CHEST,
  WAIST,
  LEGS,
  WRIST,
  HANDS,
  FEET,
  NECK,
  FINGER,
  WEAPON_1H,
  WEAPON_2H,
  OFFHAND,
  TOOL,
}

class ArmorEquipment {
  ArmorEquipment();

  Map<ArmorSlots, Items> armorEquipment = {
    ArmorSlots.HEAD: Items.NULL,
    ArmorSlots.SHOULDER: Items.NULL,
    ArmorSlots.NECK: Items.NULL,
    ArmorSlots.CHEST: Items.NULL,
    ArmorSlots.WAIST: Items.NULL,
    ArmorSlots.LEGS: Items.NULL,
    ArmorSlots.HANDS: Items.NULL,
    ArmorSlots.WRIST: Items.NULL,
    ArmorSlots.FINGER: Items.NULL,
    ArmorSlots.WEAPON_1H: Items.NULL,
    ArmorSlots.WEAPON_2H: Items.NULL,
    ArmorSlots.OFFHAND: Items.NULL,
  };

  Map<String, dynamic> toJson() {
    return {
      'armorEquipment': armorEquipment.map(
        (slot, item) => MapEntry(
          slot.name, // ArmorSlots enum → string
          item.name, // Items enum → string
        ),
      ),
    };
  }

  factory ArmorEquipment.fromJson(Map<String, dynamic> json) {
    final equipment = ArmorEquipment();

    final raw = json['armorEquipment'] as Map<String, dynamic>?;

    if (raw != null) {
      for (final entry in raw.entries) {
        final slot = ArmorSlots.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => ArmorSlots.HEAD, // safe fallback
        );

        final item = Items.values.firstWhere(
          (e) => e.name == entry.value,
          orElse: () => Items.NULL,
        );

        equipment.armorEquipment[slot] = item;
      }
    }

    return equipment;
  }

  int getStatTotal(Skills skill) {
    int total = 0;
    for (final itemId in armorEquipment.values) {
      if (itemId == Items.NULL) continue;
      final item = ItemController.buildItem(itemId);
      if (item is EquipmentItem) {
        total += item.skillBonus[skill] ?? 0;
      }
    }
    return total;
  }

  Items getItemInSlot(ArmorSlots slot) {
    return armorEquipment[slot] ?? Items.NULL;
  }

  void unequipItem(ArmorSlots slot, Inventory inv) {
    Items i = Items.NULL;
    if (armorEquipment.containsKey(slot)) {
      i = armorEquipment[slot] ?? Items.NULL;
    }
    if (i != Items.NULL) {
      inv.addItems(i, 1);
    }
  }

  bool equipItem(Items itemId) {
    Item item = ItemController.buildItem(itemId);
    if (item.id == Items.NULL) return false;

    if (item is WeaponItem) {
      if (item.armorSlot == ArmorSlots.WEAPON_2H) {
        armorEquipment[ArmorSlots.WEAPON_2H] = item.id;
        armorEquipment[ArmorSlots.WEAPON_1H] = Items.NULL;
        armorEquipment[ArmorSlots.OFFHAND] = Items.NULL;
        return true;
      } else if (item.armorSlot == ArmorSlots.WEAPON_1H) {
        armorEquipment[ArmorSlots.WEAPON_1H] = item.id;
        armorEquipment[ArmorSlots.WEAPON_2H] = Items.NULL;
        return true;
      } else if (item.armorSlot == ArmorSlots.OFFHAND) {
        armorEquipment[ArmorSlots.OFFHAND] = item.id;
        armorEquipment[ArmorSlots.WEAPON_2H] = Items.NULL;
        return true;
      } else {
        return false;
      }
      //main hand/offhand checks
    } else if (item is EquipmentItem) {
      //check equipment slot is correct
      if (armorEquipment.containsKey(item.armorSlot)) {
        armorEquipment[item.armorSlot] = item.id;
        return true;
      }
    } else {
      return false;
    }
    return false;
  }
}
