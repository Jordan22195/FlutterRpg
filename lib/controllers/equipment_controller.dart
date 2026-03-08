class EquipmentController {
  EquipmentController();

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

  factory EquipmentController.fromJson(Map<String, dynamic> json) {
    final equipment = EquipmentController();

    final raw = json['armorEquipment'] as Map<String, dynamic>?;

    if (raw != null) {
      for (final entry in raw.entries) {
        final slot = ArmorSlots.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => ArmorSlots.HEAD, // safe fallback
        );

        final item = ItemId.values.firstWhere(
          (e) => e.name == entry.value,
          orElse: () => ItemId.NULL,
        );

        equipment.armorEquipment[slot] = item;
      }
    }

    return equipment;
  }
}
