import 'armor_equipment.dart';
import 'skill.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../utilities/image_resolver.dart';

enum Items {
  NULL,
  // Currency
  COINS,

  // Materials
  LOGS,
  COPPER_ORE,
  COPPER_BAR,

  //Armor
  COPPER_HELMET,

  //Weapons
  COPPER_DAGGER,
  BRONZE_AXE,
  BRONZE_PICKAXE,
}

const Duration SlowAttackSpeed = Duration(seconds: 2);
const Duration MediumAttackSpeed = Duration(seconds: 1, milliseconds: 500);
const Duration FastAttackSpeed = Duration(seconds: 1);

String itemKey(dynamic enumValue) {
  if (enumValue == null) return 'null';
  if (enumValue is Enum) return enumValue.name;

  // Fallback: try to extract the suffix from "Type.value"
  final s = enumValue.toString();
  final dot = s.lastIndexOf('.');
  return (dot >= 0 && dot < s.length - 1) ? s.substring(dot + 1) : s;
}

class Item {
  final Items id;
  final String name;
  final int value;
  int count = 1;

  Item({required this.id, required this.name, required this.value});
}

class EquipmentItem extends Item {
  final ArmorSlots armorSlot;
  final Map<Skills, int> skillBonus;

  EquipmentItem({
    required super.id,
    required super.name,
    required super.value,
    required this.armorSlot,
    required this.skillBonus,
  });
}

class ItemDefinition {
  final String name;
  final int value;
  final String? description;

  /// Asset path like: assets/images/items/copper_ore.png
  final String? iconAsset;

  ItemDefinition({
    required this.name,
    required this.value,
    this.description,
    this.iconAsset,
  });

  Item toItem(Items id) => Item(id: id, name: name, value: value);
}

class EquipmentItemDefition extends ItemDefinition {
  final ArmorSlots armorSlot;
  final Map<Skills, int> skillBonus;

  EquipmentItemDefition({
    required super.name,
    required super.value,
    required this.armorSlot,
    required this.skillBonus,
    super.description,
    super.iconAsset,
  });

  EquipmentItem toItem(Items id) => EquipmentItem(
    id: id,
    name: name,
    value: value,
    armorSlot: armorSlot,
    skillBonus: skillBonus,
  );
}

class WeaponItem extends EquipmentItem {
  final Duration actionInterval;

  WeaponItem({
    required super.id,
    required super.name,
    required super.value,
    required super.armorSlot,
    required super.skillBonus,
    required this.actionInterval,
  });
}

class WeaponItemDefition extends EquipmentItemDefition {
  Duration actionInterval;

  WeaponItemDefition({
    required super.name,
    required super.value,
    required super.armorSlot,
    required super.skillBonus,
    required this.actionInterval,
    super.description,
    super.iconAsset,
  });

  WeaponItem toItem(Items id) => WeaponItem(
    id: id,
    name: name,
    value: value,
    armorSlot: armorSlot,
    skillBonus: skillBonus,
    actionInterval: actionInterval,
  );
}

class ItemController {
  static void init() {
    // Register the image resolver for Items.
    EnumImageProviderLookup.register<Items>(ItemController.imageProviderFor);
  }

  static final _defs = <Items, ItemDefinition>{
    Items.COINS: ItemDefinition(name: "Coins", value: 1),
    Items.COPPER_ORE: ItemDefinition(
      name: "Copper Ore",
      value: 3,
      iconAsset: "assets/icons/items/COPPER_ORE.png",
    ),
    Items.LOGS: ItemDefinition(
      name: "Logs",
      value: 2,
      iconAsset: "assets/icons/items/regular_logs.png",
    ),
    Items.COPPER_BAR: ItemDefinition(
      name: "Copper Bar",
      value: 2,
      iconAsset: "assets/icons/items/copper_bar.png",
    ),

    //armor
    Items.COPPER_HELMET: EquipmentItemDefition(
      armorSlot: ArmorSlots.HEAD,
      name: "Bronze Helmet",
      value: 15,
      skillBonus: {Skills.DEFENCE: 5},
    ),

    //weapons
    Items.BRONZE_AXE: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Bronze Axe",
      value: 10,
      skillBonus: {Skills.ATTACK: 2, Skills.WOODCUTTING: 5},
      actionInterval: MediumAttackSpeed,
    ),
    Items.BRONZE_PICKAXE: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Bronze Pickaxe",
      value: 10,
      skillBonus: {Skills.ATTACK: 2, Skills.MINING: 5},
      actionInterval: MediumAttackSpeed,
    ),
    Items.COPPER_DAGGER: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Copper Dagger",
      value: 10,
      skillBonus: {Skills.ATTACK: 5},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/copper_dagger.png",
    ),
  };

  static Item buildItem(Items id) {
    final def = _defs[id];
    if (def == null) {
      return Item(id: Items.NULL, name: "Null", value: 0);
    }
    return def.toItem(id);
  }

  static ItemDefinition? definitionFor(dynamic objectId) {
    return _defs[itemKey(objectId)];
  }

  /// Returns the icon asset path (if any) for any enum-like id value.
  static String? iconAssetFor(dynamic objectId) {
    return ItemController._defs[objectId]?.iconAsset;
  }

  /// Returns an ImageProvider for any enum-like id value.
  /// If no icon is configured, returns null.
  static ImageProvider? imageProviderFor(dynamic objectId) {
    final asset = iconAssetFor(objectId);
    return asset != null ? AssetImage(asset) : null;
  }
}
