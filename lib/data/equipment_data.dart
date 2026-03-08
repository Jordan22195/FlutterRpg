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
  ItemId equipedPickaxe = ItemId.NULL;
  ItemId equipedAxe = ItemId.NULL;
  ItemId equipedFood = ItemId.NULL;
}
