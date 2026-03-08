import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import 'package:flutter/widgets.dart';
import '../utilities/image_resolver.dart';

enum ItemId {
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
  final ItemId id;
  final String name;
  final int value;
  int count = 1;

  Item({required this.id, required this.name, required this.value});
}

class BuffItem extends Item {
  final Map<SkillId, int> skillBonus;
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
  final Map<SkillId, int> skillBonus;

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

  Item toItem(ItemId id) => Item(id: id, name: name, value: value);
}

class FoodItemDefinition extends ItemDefinition {
  int restoreAmount;
  SkillId restoreSkill;

  FoodItemDefinition({
    required super.name,
    required super.value,
    required this.restoreAmount,
    this.restoreSkill = SkillId.HITPOINTS,
    super.description,
    super.iconAsset,
    super.xpValue,
  });

  Item toItem(ItemId id) => Item(id: id, name: name, value: value);
}

class BuffItemDefinition extends ItemDefinition {
  final Map<SkillId, int> skillBonus;
  final Duration duration;

  BuffItemDefinition({
    required super.name,
    required super.value,
    required this.skillBonus,
    required this.duration,
    super.description,
    super.iconAsset,
  });

  BuffItem toItem(ItemId id) => BuffItem(
    id: id,
    name: name,
    value: value,
    skillBonus: skillBonus,
    duration: duration,
  );
}

class EquipmentItemDefition extends ItemDefinition {
  final ArmorSlots armorSlot;
  final Map<SkillId, int> skillBonus;

  EquipmentItemDefition({
    required super.name,
    required super.value,
    required this.armorSlot,
    required this.skillBonus,
    super.description,
    super.iconAsset,
  });

  EquipmentItem toItem(ItemId id) => EquipmentItem(
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

  @override
  WeaponItem toItem(ItemId id) => WeaponItem(
    id: id,
    name: name,
    value: value,
    armorSlot: armorSlot,
    skillBonus: skillBonus,
    actionInterval: actionInterval,
  );
}

class ItemCatalog {
  static void init() {
    // Register the image resolver for Items.
    EnumImageProviderLookup.register<ItemId>(ItemCatalog.imageProviderFor);
  }

  static final _defs = <ItemId, ItemDefinition>{
    // currency
    ItemId.COINS: ItemDefinition(
      name: "Coins",
      value: 1,
      iconAsset: "assets/icons/items/coins.png",
    ),

    //junk
    ItemId.BURNT_FOOD: ItemDefinition(
      name: "Burnt Food",
      value: 1,
      iconAsset: "assets/icons/items/burnt_food.png",
    ),

    // ore
    ItemId.COPPER_ORE: ItemDefinition(
      name: "Copper Ore",
      value: 3,
      iconAsset: "assets/icons/items/COPPER_ORE.png",
    ),

    // logs
    ItemId.LOGS: ItemDefinition(
      name: "Logs",
      value: 2,
      iconAsset: "assets/icons/items/regular_logs.png",
    ),

    // campfires
    ItemId.BASIC_CAMPFIRE: BuffItemDefinition(
      name: "Basic Campfire",
      value: 5,
      skillBonus: {SkillId.HITPOINTS: 5},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/basic_campfire.png",
    ),

    //FISH
    ItemId.MINNOW: ItemDefinition(
      name: "Minnow",
      value: 1,
      iconAsset: "assets/icons/items/minnow.png",
      xpValue: 5,
    ),
    ItemId.CARP: ItemDefinition(
      name: "Carp",
      value: 2,
      iconAsset: "assets/icons/items/carp.png",
      xpValue: 10,
    ),
    ItemId.BLUEGILL: ItemDefinition(
      name: "Bluegill",
      value: 3,
      iconAsset: "assets/icons/items/bluegill.png",
      xpValue: 15,
    ),
    ItemId.TROUT: ItemDefinition(
      name: "Trout",
      value: 5,
      iconAsset: "assets/icons/items/trout.png",
      xpValue: 25,
    ),
    ItemId.PIKE: ItemDefinition(
      name: "Pike",
      value: 7,
      iconAsset: "assets/icons/items/pike.png",
      xpValue: 30,
    ),
    ItemId.SALMON: ItemDefinition(
      name: "Salmon",
      value: 10,
      iconAsset: "assets/icons/items/salmon.png",
      xpValue: 50,
    ),
    ItemId.CATFISH: ItemDefinition(
      name: "Catfish",
      value: 15,
      iconAsset: "assets/icons/items/catfish.png",
      xpValue: 75,
    ),
    ItemId.BASS: ItemDefinition(
      name: "Bass",
      value: 20,
      iconAsset: "assets/icons/items/bass.png",
      xpValue: 100,
    ),
    ItemId.WHITEFISH: ItemDefinition(
      name: "Whitefish",
      value: 25,
      iconAsset: "assets/icons/items/whitefish.png",
      xpValue: 125,
    ),
    ItemId.TUNA: ItemDefinition(
      name: "Tuna",
      value: 30,
      iconAsset: "assets/icons/items/tuna.png",
      xpValue: 125,
    ),
    ItemId.SWORDFISH: ItemDefinition(
      name: "Swordfish",
      value: 50,
      iconAsset: "assets/icons/items/swordfish.png",
      xpValue: 150,
    ),
    ItemId.SHARK: ItemDefinition(
      name: "Shark",
      value: 100,
      iconAsset: "assets/icons/items/shark.png",
      xpValue: 200,
    ),

    // food
    ItemId.COOKED_MINNOW: FoodItemDefinition(
      name: "Cooked Minnow",
      value: 2,
      restoreAmount: 1,
      xpValue: 10,
      iconAsset: "assets/icons/items/cooked_minnow.png",
    ),
    ItemId.COOKED_CARP: FoodItemDefinition(
      name: "Cooked Carp",
      value: 4,
      restoreAmount: 2,
      xpValue: 20,
      iconAsset: "assets/icons/items/cooked_carp.png",
    ),
    ItemId.COOKED_BLUEGILL: FoodItemDefinition(
      name: "Cooked Bluegill",
      value: 6,
      restoreAmount: 3,
      xpValue: 30,
      iconAsset: "assets/icons/items/cooked_bluegill.png",
    ),
    ItemId.COOKED_TROUT: FoodItemDefinition(
      name: "Cooked Trout",
      value: 10,
      restoreAmount: 5,
      xpValue: 50,
      iconAsset: "assets/icons/items/cooked_trout.png",
    ),
    ItemId.COOKED_PIKE: FoodItemDefinition(
      name: "Cooked Pike",
      value: 14,
      restoreAmount: 7,
      xpValue: 70,
      iconAsset: "assets/icons/items/cooked_pike.png",
    ),
    ItemId.COOKED_SALMON: FoodItemDefinition(
      name: "Cooked Salmon",
      value: 20,
      restoreAmount: 12,
      xpValue: 100,
      iconAsset: "assets/icons/items/cooked_salmon.png",
    ),
    ItemId.COOKED_CATFISH: FoodItemDefinition(
      name: "Cooked Catfish",
      value: 30,
      restoreAmount: 15,
      xpValue: 150,
      iconAsset: "assets/icons/items/cooked_catfish.png",
    ),
    ItemId.COOKED_BASS: FoodItemDefinition(
      name: "Cooked Bass",
      value: 40,
      restoreAmount: 20,
      xpValue: 200,
      iconAsset: "assets/icons/items/cooked_bass.png",
    ),
    ItemId.COOKED_WHITEFISH: FoodItemDefinition(
      name: "Cooked Whitefish",
      value: 50,
      restoreAmount: 22,
      xpValue: 250,
      iconAsset: "assets/icons/items/cooked_whitefish.png",
    ),
    ItemId.COOKED_TUNA: FoodItemDefinition(
      name: "Cooked Tuna",
      value: 60,
      restoreAmount: 25,
      xpValue: 300,
      iconAsset: "assets/icons/items/cooked_tuna.png",
    ),
    ItemId.COOKED_SWORDFISH: FoodItemDefinition(
      name: "Cooked Swordfish",
      value: 100,
      restoreAmount: 30,
      xpValue: 500,
      iconAsset: "assets/icons/items/cooked_swordfish.png",
    ),
    ItemId.COOKED_SHARK: FoodItemDefinition(
      name: "Cooked Shark",
      value: 200,
      restoreAmount: 35,
      xpValue: 1000,
      iconAsset: "assets/icons/items/cooked_shark.png",
    ),

    // bars
    ItemId.COPPER_BAR: ItemDefinition(
      name: "Copper Bar",
      value: 2,
      iconAsset: "assets/icons/items/copper_bar.png",
    ),

    //armor
    ItemId.COPPER_HELMET: EquipmentItemDefition(
      armorSlot: ArmorSlots.HEAD,
      name: "Copper Helmet",
      value: 15,
      skillBonus: {SkillId.DEFENCE: 5},
      iconAsset: "assets/icons/items/copper_helmet.png",
    ),
    ItemId.COPPER_CHESTPLATE: EquipmentItemDefition(
      armorSlot: ArmorSlots.CHEST,
      name: "Copper Chestplate",
      value: 25,
      skillBonus: {SkillId.DEFENCE: 10},
      iconAsset: "assets/icons/items/copper_chestplate.png",
    ),
    ItemId.COPPER_LEGS: EquipmentItemDefition(
      armorSlot: ArmorSlots.LEGS,
      name: "Copper Leggings",
      value: 20,
      skillBonus: {SkillId.DEFENCE: 8},
      iconAsset: "assets/icons/items/copper_legs.png",
    ),
    ItemId.COPPER_GLOVES: EquipmentItemDefition(
      armorSlot: ArmorSlots.HANDS,
      name: "Copper Gloves",
      value: 10,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/copper_gloves.png",
    ),
    ItemId.COPPER_BOOTS: EquipmentItemDefition(
      armorSlot: ArmorSlots.FEET,
      name: "Copper Boots",
      value: 10,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/copper_boots.png",
    ),
    ItemId.COPPER_SHIELD: EquipmentItemDefition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Copper Shield",
      value: 15,
      skillBonus: {SkillId.DEFENCE: 7},
      iconAsset: "assets/icons/items/copper_shield.png",
    ),

    //weapons
    ItemId.COPPER_AXE: WeaponItemDefition(
      armorSlot: ArmorSlots.TOOL,
      name: "Bronze Axe",
      value: 10,
      skillBonus: {SkillId.ATTACK: 2, SkillId.WOODCUTTING: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_axe.png",
    ),
    ItemId.COPPER_PICKAXE: WeaponItemDefition(
      armorSlot: ArmorSlots.TOOL,
      name: "Bronze Pickaxe",
      value: 10,
      skillBonus: {SkillId.ATTACK: 2, SkillId.MINING: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_pickaxe.png",
    ),
    ItemId.COPPER_DAGGER: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Copper Dagger",
      value: 10,
      skillBonus: {SkillId.ATTACK: 5},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/copper_dagger.png",
    ),
  };

  static Item buildItem(ItemId id) {
    final def = _defs[id];
    if (def == null) {
      return Item(id: ItemId.NULL, name: "Null", value: 0);
    }
    return def.toItem(id);
  }

  ItemDefinition? definitionFor(ItemId objectId) {
    final ret = _defs[objectId];
    return ret;
  }

  /// Returns the icon asset path (if any) for any enum-like id value.
  static String? iconAssetFor(dynamic objectId) {
    return ItemCatalog._defs[objectId]?.iconAsset;
  }

  /// Returns an ImageProvider for any enum-like id value.
  /// If no icon is configured, returns null.
  static ImageProvider? imageProviderFor(dynamic objectId) {
    final asset = iconAssetFor(objectId);
    return asset != null ? AssetImage(asset) : null;
  }
}
