import '../catalogs/item_catalog.dart';

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
    ArmorSlots.TOOL: ItemId.NULL,
  };
  ItemId equipedPickaxe = ItemId.NULL;
  ItemId equipedAxe = ItemId.NULL;
  ItemId equipedFood = ItemId.NULL;

  Map<String, dynamic> toJson() {
    return {
      'armorEquipment': armorEquipment.map(
        (slot, itemId) => MapEntry(slot.name, itemId.name),
      ),
      'equipedPickaxe': equipedPickaxe.name,
      'equipedAxe': equipedAxe.name,
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

      final itemId = ItemId.values.firstWhere(
        (i) => i.name == rawItem,
        orElse: () => throw FormatException('Invalid ItemId value "$rawItem".'),
      );

      armorEquipment[slot] = itemId;
    }

    final rawPickaxe = json['equipedPickaxe'];
    final rawAxe = json['equipedAxe'];
    final rawFood = json['equipedFood'];

    if (rawPickaxe is! String) {
      throw FormatException('Missing or invalid "equipedPickaxe".');
    }

    if (rawAxe is! String) {
      throw FormatException('Missing or invalid "equipedAxe".');
    }

    if (rawFood is! String) {
      throw FormatException('Missing or invalid "equipedFood".');
    }

    return EquipmentData()
      ..armorEquipment = armorEquipment
      ..equipedPickaxe = ItemId.values.firstWhere(
        (i) => i.name == rawPickaxe,
        orElse: () =>
            throw FormatException('Invalid ItemId value "$rawPickaxe".'),
      )
      ..equipedAxe = ItemId.values.firstWhere(
        (i) => i.name == rawAxe,
        orElse: () => throw FormatException('Invalid ItemId value "$rawAxe".'),
      )
      ..equipedFood = ItemId.values.firstWhere(
        (i) => i.name == rawFood,
        orElse: () => throw FormatException('Invalid ItemId value "$rawFood".'),
      );
  }
}
