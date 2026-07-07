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

  /// Equipped unique equipment instances by slot; null = empty slot.
  Map<ArmorSlots, EquipmentItem?> armorEquipment = {
    for (final slot in ArmorSlots.values)
      if (slot != ArmorSlots.TOOL) slot: null,
  };

  /// One tool instance per gathering skill (woodcutting axe, mining
  /// pickaxe, ...). Combat uses the weapon slots in armorEquipment.
  Map<SkillId, EquipmentItem?> equipedTools = {};

  ItemId equipedFood = ItemId.NULL;

  Map<String, dynamic> toJson() {
    return {
      'armorEquipment': {
        for (final entry in armorEquipment.entries)
          if (entry.value != null) entry.key.name: entry.value!.toJson(),
      },
      'equipedTools': {
        for (final entry in equipedTools.entries)
          if (entry.value != null) entry.key.name: entry.value!.toJson(),
      },
      'equipedFood': equipedFood.name,
    };
  }

  // resolves either the new instance format (item json object) or the
  // legacy format (a plain ItemId name string) to an equipment instance
  static EquipmentItem? _parseEquipmentValue(dynamic rawValue) {
    if (rawValue is Map<String, dynamic>) {
      return WeaponItem.equipmentFromJson(rawValue);
    }
    if (rawValue is String) {
      final itemId = ItemId.values.asNameMap()[rawValue];
      if (itemId == null || itemId == ItemId.NULL) return null;
      final item = ItemCatalog.buildItem(itemId);
      return item is EquipmentItem ? item : null;
    }
    return null;
  }

  factory EquipmentData.fromJson(Map<String, dynamic> json) {
    final data = EquipmentData();

    final rawArmor = json['armorEquipment'];
    if (rawArmor is Map) {
      for (final entry in rawArmor.entries) {
        final slot = ArmorSlots.values.asNameMap()[entry.key];
        if (slot == null || slot == ArmorSlots.TOOL) continue;
        final item = _parseEquipmentValue(entry.value);
        if (item != null) {
          data.armorEquipment[slot] = item;
        }
      }
    }

    final rawTools = json['equipedTools'];
    if (rawTools is Map) {
      for (final entry in rawTools.entries) {
        final skill = SkillId.values.asNameMap()[entry.key];
        if (skill == null) continue;
        final item = _parseEquipmentValue(entry.value);
        if (item != null) {
          data.equipedTools[skill] = item;
        }
      }
    }

    final rawFood = json['equipedFood'];
    if (rawFood is String) {
      data.equipedFood = ItemId.values.asNameMap()[rawFood] ?? ItemId.NULL;
    }

    return data;
  }
}
