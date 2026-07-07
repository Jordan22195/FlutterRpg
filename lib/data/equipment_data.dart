import '../catalogs/item_catalog.dart';
import 'skill_data.dart';

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

class EquipmentData {
  EquipmentData();
  // todo change this to use item instances
  Map<ArmorSlots, ItemId> armorEquipment = {
    ArmorSlots.HEAD: ItemId.NULL,
    ArmorSlots.SHOULDER: ItemId.NULL,
    ArmorSlots.NECK: ItemId.NULL,
    ArmorSlots.CHEST: ItemId.NULL,
    ArmorSlots.WAIST: ItemId.NULL,
    ArmorSlots.LEGS: ItemId.NULL,
    ArmorSlots.HANDS: ItemId.NULL,
    ArmorSlots.WRIST: ItemId.NULL,
    ArmorSlots.FINGER: ItemId.NULL,
    ArmorSlots.WEAPON_1H: ItemId.NULL,
    ArmorSlots.WEAPON_2H: ItemId.NULL,
    ArmorSlots.OFFHAND: ItemId.NULL,
  };

  // one tool per gathering skill (woodcutting axe, mining pickaxe, ...).
  // combat entities use the weapon slots in armorEquipment instead
  Map<SkillId, ItemId> equipedTools = {};

  ItemId equipedFood = ItemId.NULL;

  Map<String, dynamic> toJson() {
    return {
      'armorEquipment': armorEquipment.map(
        (slot, itemId) => MapEntry(slot.name, itemId.name),
      ),
      'equipedTools': equipedTools.map(
        (skill, itemId) => MapEntry(skill.name, itemId.name),
      ),
      'equipedFood': equipedFood.name,
    };
  }

  factory EquipmentData.fromJson(Map<String, dynamic> json) {
    final rawArmor = json['armorEquipment'];

    if (rawArmor is! Map) {
      throw FormatException(
        'Missing or invalid "armorEquipment". Expected object.',
      );
    }

    final armorEquipment = <ArmorSlots, ItemId>{};

    for (final entry in rawArmor.entries) {
      final rawSlot = entry.key;
      final rawItem = entry.value;

      if (rawSlot is! String) {
        throw FormatException('Invalid armor slot key. Expected String.');
      }

      if (rawItem is! String) {
        throw FormatException(
          'Invalid item id for slot "$rawSlot". Expected String.',
        );
      }

      final slot = ArmorSlots.values.firstWhere(
        (s) => s.name == rawSlot,
        orElse: () =>
            throw FormatException('Invalid ArmorSlots value "$rawSlot".'),
      );

      // migration: the legacy shared TOOL slot is dropped; tools are
      // now tracked per skill in equipedTools
      if (slot == ArmorSlots.TOOL) continue;

      final itemId = ItemId.values.firstWhere(
        (i) => i.name == rawItem,
        orElse: () => throw FormatException('Invalid ItemId value "$rawItem".'),
      );

      armorEquipment[slot] = itemId;
    }

    // tolerated when missing: older saves predate per-skill tools
    // (and stored legacy "equipedPickaxe"/"equipedAxe", which are dropped)
    final equipedTools = <SkillId, ItemId>{};
    final rawTools = json['equipedTools'];
    if (rawTools is Map) {
      for (final entry in rawTools.entries) {
        final skill = SkillId.values.asNameMap()[entry.key];
        final itemId = ItemId.values.asNameMap()[entry.value];
        if (skill != null && itemId != null) {
          equipedTools[skill] = itemId;
        }
      }
    }

    final rawFood = json['equipedFood'];

    if (rawFood is! String) {
      throw FormatException('Missing or invalid "equipedFood".');
    }

    return EquipmentData()
      ..armorEquipment = armorEquipment
      ..equipedTools = equipedTools
      ..equipedFood = ItemId.values.firstWhere(
        (i) => i.name == rawFood,
        orElse: () => throw FormatException('Invalid ItemId value "$rawFood".'),
      );
  }
}
