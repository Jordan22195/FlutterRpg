import '../catalogs/items/items.dart';
import 'skill_data.dart';

enum ArmorSlots {
  HEAD,
  SHOULDER(fibOffset: 1),
  BACK,
  CHEST(fibOffset: 1),
  WAIST,
  LEGS(fibOffset: 1),
  WRIST,
  HANDS,
  FEET,
  NECK(fibOffset: 1),
  FINGER,
  FINGER_2,
  WEAPON_1H,
  WEAPON_2H,
  OFFHAND(fibOffset: 1),
  TOOL;

  /// How many rungs above its material a piece in this slot sits. Chest and
  /// legs are the major pieces and are worth a rung more than the trim; a
  /// shield is the slot you buy purely to be harder to hit, so it is worth
  /// two. The spread is the same on every ladder — the leather tiers keep it
  /// too — so it belongs to the slot rather than to any one material.
  ///
  /// Only read for a piece that takes its [EquipmentItemDefinition.fibLevel]
  /// from its material; one that states a rung outright is not offset again.
  /// The weapon and tool slots are flat, because what a weapon is worth is
  /// the weapon's business — a dagger and a greatsword share WEAPON_1H's
  /// neighbours but not its rung.
  final int fibOffset;

  const ArmorSlots({this.fibOffset = 0});
}

/// Rings are the one piece of gear with two places to put it: equipment
/// is always defined as [ArmorSlots.FINGER], and either finger can wear it.
extension ArmorSlotPairing on ArmorSlots {
  /// The slots an item defined for this slot can be worn in, in fill order.
  List<ArmorSlots> get equipTargets => this == ArmorSlots.FINGER
      ? const [ArmorSlots.FINGER, ArmorSlots.FINGER_2]
      : [this];

  /// The slot an item must be defined for to be worn here — the inverse of
  /// [equipTargets], for looking up what the inventory can put in a slot.
  ArmorSlots get itemSlot =>
      this == ArmorSlots.FINGER_2 ? ArmorSlots.FINGER : this;
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
  // legacy format (a plain ItemId name string) to an equipment instance.
  // an id the catalog has since retired resolves to null and the slot is
  // left empty, rather than taking the whole save down with it
  static EquipmentItem? _parseEquipmentValue(dynamic rawValue) {
    if (rawValue is Map<String, dynamic>) {
      try {
        return WeaponItem.equipmentFromJson(rawValue);
      } on FormatException {
        return null;
      }
    }
    if (rawValue is String) {
      final itemId = ItemId.values.asNameMap()[rawValue];
      if (itemId == null || itemId == ItemId.NULL) return null;
      final item = itemId.build();
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
