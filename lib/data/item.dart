import 'armor_equipment.dart';
import 'skill.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../utilities/image_resolver.dart';

enum Items {
  NULL,
  // Currency
  COINS,

  //junk
  BURNT_FOOD,

  // Materials
  LOGS,
  COPPER_ORE,
  COPPER_BAR,

  BASIC_CAMPFIRE,

  // fish
  // pond
  MINNOW,
  CARP,
  BLUEGILL,

  // river
  TROUT,
  PIKE,
  SALMON,

  // lake
  CATFISH,
  BASS,
  WHITEFISH,

  // OCEAN
  TUNA,
  SWORDFISH,
  SHARK,

  COOKED_MINNOW,
  COOKED_CARP,
  COOKED_BLUEGILL,

  // river
  COOKED_TROUT,
  COOKED_PIKE,
  COOKED_SALMON,

  // lake
  COOKED_CATFISH,
  COOKED_BASS,
  COOKED_WHITEFISH,

  // OCEAN
  COOKED_TUNA,
  COOKED_SWORDFISH,
  COOKED_SHARK,

  //Armor
  COPPER_HELMET,
  COPPER_CHESTPLATE,
  COPPER_LEGS,
  COPPER_BOOTS,
  COPPER_SHIELD,
  COPPER_GLOVES,

  //Weapons
  COPPER_DAGGER,
  COPPER_AXE,
  COPPER_PICKAXE,
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

class BuffItem extends Item {
  final Map<Skills, int> skillBonus;
  Duration duration;
  DateTime expirationTime;

  BuffItem({
    required super.id,
    required super.name,
    required super.value,
    required this.skillBonus,
    required this.duration,
  }) : expirationTime = DateTime.now().add(duration);
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

  /// XP granted when this item is obtained (e.g., fishing catch).
  /// Always non-null; if a null value is provided (e.g., from JSON/dynamic), it defaults to 0.
  final int xpValue;

  ItemDefinition({
    required this.name,
    required this.value,
    this.description,
    this.iconAsset,
    int? xpValue,
  }) : xpValue = xpValue ?? 0;

  Item toItem(Items id) => Item(id: id, name: name, value: value);
}

class FoodItemDefinition extends ItemDefinition {
  int healAmount;

  FoodItemDefinition({
    required super.name,
    required super.value,
    required this.healAmount,
    super.description,
    super.iconAsset,
    super.xpValue,
  });

  Item toItem(Items id) => Item(id: id, name: name, value: value);
}

class BuffItemDefinition extends ItemDefinition {
  final Map<Skills, int> skillBonus;
  final Duration duration;

  BuffItemDefinition({
    required super.name,
    required super.value,
    required this.skillBonus,
    required this.duration,
    super.description,
    super.iconAsset,
  });

  BuffItem toItem(Items id) => BuffItem(
    id: id,
    name: name,
    value: value,
    skillBonus: skillBonus,
    duration: duration,
  );
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
    // currency
    Items.COINS: ItemDefinition(
      name: "Coins",
      value: 1,
      iconAsset: "assets/icons/items/coins.png",
    ),

    //junk
    Items.BURNT_FOOD: ItemDefinition(
      name: "Burnt Food",
      value: 1,
      iconAsset: "assets/icons/items/burnt_food.png",
    ),

    // ore
    Items.COPPER_ORE: ItemDefinition(
      name: "Copper Ore",
      value: 3,
      iconAsset: "assets/icons/items/COPPER_ORE.png",
    ),

    // logs
    Items.LOGS: ItemDefinition(
      name: "Logs",
      value: 2,
      iconAsset: "assets/icons/items/regular_logs.png",
    ),

    // campfires
    Items.BASIC_CAMPFIRE: BuffItemDefinition(
      name: "Basic Campfire",
      value: 5,
      skillBonus: {Skills.HITPOINTS: 5},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/basic_campfire.png",
    ),

    //FISH
    Items.MINNOW: ItemDefinition(
      name: "Minnow",
      value: 1,
      iconAsset: "assets/icons/items/minnow.png",
      xpValue: 5,
    ),
    Items.CARP: ItemDefinition(
      name: "Carp",
      value: 2,
      iconAsset: "assets/icons/items/carp.png",
      xpValue: 10,
    ),
    Items.BLUEGILL: ItemDefinition(
      name: "Bluegill",
      value: 3,
      iconAsset: "assets/icons/items/bluegill.png",
      xpValue: 15,
    ),
    Items.TROUT: ItemDefinition(
      name: "Trout",
      value: 5,
      iconAsset: "assets/icons/items/trout.png",
      xpValue: 25,
    ),
    Items.PIKE: ItemDefinition(
      name: "Pike",
      value: 7,
      iconAsset: "assets/icons/items/pike.png",
      xpValue: 30,
    ),
    Items.SALMON: ItemDefinition(
      name: "Salmon",
      value: 10,
      iconAsset: "assets/icons/items/salmon.png",
      xpValue: 50,
    ),
    Items.CATFISH: ItemDefinition(
      name: "Catfish",
      value: 15,
      iconAsset: "assets/icons/items/catfish.png",
      xpValue: 75,
    ),
    Items.BASS: ItemDefinition(
      name: "Bass",
      value: 20,
      iconAsset: "assets/icons/items/bass.png",
      xpValue: 100,
    ),
    Items.WHITEFISH: ItemDefinition(
      name: "Whitefish",
      value: 25,
      iconAsset: "assets/icons/items/whitefish.png",
      xpValue: 125,
    ),
    Items.TUNA: ItemDefinition(
      name: "Tuna",
      value: 30,
      iconAsset: "assets/icons/items/tuna.png",
      xpValue: 125,
    ),
    Items.SWORDFISH: ItemDefinition(
      name: "Swordfish",
      value: 50,
      iconAsset: "assets/icons/items/swordfish.png",
      xpValue: 150,
    ),
    Items.SHARK: ItemDefinition(
      name: "Shark",
      value: 100,
      iconAsset: "assets/icons/items/shark.png",
      xpValue: 200,
    ),

    // food
    Items.COOKED_MINNOW: FoodItemDefinition(
      name: "Cooked Minnow",
      value: 2,
      healAmount: 1,
      xpValue: 10,
      iconAsset: "assets/icons/items/cooked_minnow.png",
    ),
    Items.COOKED_CARP: FoodItemDefinition(
      name: "Cooked Carp",
      value: 4,
      healAmount: 2,
      xpValue: 20,
      iconAsset: "assets/icons/items/cooked_carp.png",
    ),
    Items.COOKED_BLUEGILL: FoodItemDefinition(
      name: "Cooked Bluegill",
      value: 6,
      healAmount: 3,
      xpValue: 30,
      iconAsset: "assets/icons/items/cooked_bluegill.png",
    ),
    Items.COOKED_TROUT: FoodItemDefinition(
      name: "Cooked Trout",
      value: 10,
      healAmount: 5,
      xpValue: 50,
      iconAsset: "assets/icons/items/cooked_trout.png",
    ),
    Items.COOKED_PIKE: FoodItemDefinition(
      name: "Cooked Pike",
      value: 14,
      healAmount: 7,
      xpValue: 70,
      iconAsset: "assets/icons/items/cooked_pike.png",
    ),
    Items.COOKED_SALMON: FoodItemDefinition(
      name: "Cooked Salmon",
      value: 20,
      healAmount: 12,
      xpValue: 100,
      iconAsset: "assets/icons/items/cooked_salmon.png",
    ),
    Items.COOKED_CATFISH: FoodItemDefinition(
      name: "Cooked Catfish",
      value: 30,
      healAmount: 15,
      xpValue: 150,
      iconAsset: "assets/icons/items/cooked_catfish.png",
    ),
    Items.COOKED_BASS: FoodItemDefinition(
      name: "Cooked Bass",
      value: 40,
      healAmount: 20,
      xpValue: 200,
      iconAsset: "assets/icons/items/cooked_bass.png",
    ),
    Items.COOKED_WHITEFISH: FoodItemDefinition(
      name: "Cooked Whitefish",
      value: 50,
      healAmount: 22,
      xpValue: 250,
      iconAsset: "assets/icons/items/cooked_whitefish.png",
    ),
    Items.COOKED_TUNA: FoodItemDefinition(
      name: "Cooked Tuna",
      value: 60,
      healAmount: 25,
      xpValue: 300,
      iconAsset: "assets/icons/items/cooked_tuna.png",
    ),
    Items.COOKED_SWORDFISH: FoodItemDefinition(
      name: "Cooked Swordfish",
      value: 100,
      healAmount: 30,
      xpValue: 500,
      iconAsset: "assets/icons/items/cooked_swordfish.png",
    ),
    Items.COOKED_SHARK: FoodItemDefinition(
      name: "Cooked Shark",
      value: 200,
      healAmount: 35,
      xpValue: 1000,
      iconAsset: "assets/icons/items/cooked_shark.png",
    ),

    // bars
    Items.COPPER_BAR: ItemDefinition(
      name: "Copper Bar",
      value: 2,
      iconAsset: "assets/icons/items/copper_bar.png",
    ),

    //armor
    Items.COPPER_HELMET: EquipmentItemDefition(
      armorSlot: ArmorSlots.HEAD,
      name: "Copper Helmet",
      value: 15,
      skillBonus: {Skills.DEFENCE: 5},
      iconAsset: "assets/icons/items/copper_helmet.png",
    ),
    Items.COPPER_CHESTPLATE: EquipmentItemDefition(
      armorSlot: ArmorSlots.CHEST,
      name: "Copper Chestplate",
      value: 25,
      skillBonus: {Skills.DEFENCE: 10},
      iconAsset: "assets/icons/items/copper_chestplate.png",
    ),
    Items.COPPER_LEGS: EquipmentItemDefition(
      armorSlot: ArmorSlots.LEGS,
      name: "Copper Leggings",
      value: 20,
      skillBonus: {Skills.DEFENCE: 8},
      iconAsset: "assets/icons/items/copper_legs.png",
    ),
    Items.COPPER_GLOVES: EquipmentItemDefition(
      armorSlot: ArmorSlots.HANDS,
      name: "Copper Gloves",
      value: 10,
      skillBonus: {Skills.DEFENCE: 3},
      iconAsset: "assets/icons/items/copper_gloves.png",
    ),
    Items.COPPER_BOOTS: EquipmentItemDefition(
      armorSlot: ArmorSlots.FEET,
      name: "Copper Boots",
      value: 10,
      skillBonus: {Skills.DEFENCE: 3},
      iconAsset: "assets/icons/items/copper_boots.png",
    ),
    Items.COPPER_SHIELD: EquipmentItemDefition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Copper Shield",
      value: 15,
      skillBonus: {Skills.DEFENCE: 7},
      iconAsset: "assets/icons/items/copper_shield.png",
    ),

    //weapons
    Items.COPPER_AXE: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Bronze Axe",
      value: 10,
      skillBonus: {Skills.ATTACK: 2, Skills.WOODCUTTING: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_axe.png",
    ),
    Items.COPPER_PICKAXE: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Bronze Pickaxe",
      value: 10,
      skillBonus: {Skills.ATTACK: 2, Skills.MINING: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_pickaxe.png",
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

  static ItemDefinition? definitionFor(Items objectId) {
    print("Looking up definition for objectId: $objectId");
    final ret = _defs[objectId];
    print("Definition lookup result for $objectId: ${ret?.name ?? 'null'}");
    return ret;
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
