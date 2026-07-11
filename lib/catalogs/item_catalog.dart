import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'dart:convert';

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
  COPPER_SICKLE,

  // herbs (herbalism), in ascending level order
  GUAM_LEAF,
  MARRENTILL,
  TARROMIN,
  HARRALANDER,
  RANARR_WEED,
  TOADFLAX,
  IRIT_LEAF,
  AVANTOE,
  KWUARM,
  SNAPDRAGON,
  CADANTINE,
  LANTADYME,
  DWARF_WEED,
  TORSTOL,

  // farm
  CHICKEN_MEAT,
  FEATHER,
  COOKED_CHICKEN,

  // tier 2 materials
  OAK_LOGS,
  IRON_ORE,
  IRON_BAR,
  OAK_CAMPFIRE,

  // tier 2 armor
  IRON_HELMET,
  IRON_CHESTPLATE,
  IRON_LEGS,
  IRON_BOOTS,
  IRON_SHIELD,
  IRON_GLOVES,

  // tier 2 weapons
  IRON_DAGGER,
  IRON_AXE,
  IRON_PICKAXE,
  IRON_SICKLE,

  // enchanting materials, one per equipment quality tier
  ENCHANTING_DUST,
  ENCHANTING_ESSENCE,
  ENCHANTING_RUNE,
  ENCHANTING_PRISM,
  SOUL_SHARD,

  // gems (rare mining drops), in ascending tier order
  TOPAZ,
  SAPPHIRE,
  EMERALD,
  RUBY,
  DIAMOND,
  DRAGONSTONE,
  ONYX,

  // jewelry bases (blacksmithing)
  COPPER_RING,
  COPPER_NECKLACE,

  // jewelry (jewelcrafting: gem + base)
  TOPAZ_RING,
  TOPAZ_NECKLACE,
  SAPPHIRE_RING,
  SAPPHIRE_NECKLACE,
  EMERALD_RING,
  EMERALD_NECKLACE,
  RUBY_RING,
  RUBY_NECKLACE,
  DIAMOND_RING,
  DIAMOND_NECKLACE,
  DRAGONSTONE_RING,
  DRAGONSTONE_NECKLACE,
  ONYX_RING,
  ONYX_NECKLACE,
}

const Duration SlowAttackSpeed = Duration(seconds: 2);
const Duration MediumAttackSpeed = Duration(seconds: 1, milliseconds: 500);
const Duration FastAttackSpeed = Duration(seconds: 1);

/// Quality tiers for crafted equipment. Higher tiers multiply the item's
/// base stats. Crafting rolls a quality; higher crafting levels raise the
/// odds of the upper tiers.
enum ItemQuality {
  COMMON(1.0, ''),
  UNCOMMON(1.1, 'Uncommon'),
  RARE(1.2, 'Rare'),
  EPIC(1.3, 'Epic'),
  LEGENDARY(1.5, 'Legendary');

  const ItemQuality(this.statMultiplier, this.label);

  final double statMultiplier;

  /// Display prefix; empty for common.
  final String label;
}

String itemKey(dynamic enumValue) {
  if (enumValue == null) return 'null';
  if (enumValue is Enum) return enumValue.name;

  // Fallback: try to extract the suffix from "Type.value"
  final s = enumValue.toString();
  final dot = s.lastIndexOf('.');
  return (dot >= 0 && dot < s.length - 1) ? s.substring(dot + 1) : s;
}

// ---- Serialization helpers ----
Map<String, int> _skillBonusToJson(Map<SkillId, int> skillBonus) {
  return skillBonus.map((key, value) => MapEntry(key.name, value));
}

Map<SkillId, int> _skillBonusFromJson(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw == null) {
    throw FormatException('Missing "$key". Expected object.');
  }
  if (raw is! Map) {
    throw FormatException('Invalid "$key". Expected object.');
  }

  final result = <SkillId, int>{};
  for (final entry in raw.entries) {
    final rawKey = entry.key;
    final rawValue = entry.value;

    if (rawKey is! String) {
      throw FormatException('Invalid key in "$key". Expected String key.');
    }
    if (rawValue is! int) {
      throw FormatException(
        'Invalid value in "$key" for skill "$rawKey". Expected int.',
      );
    }

    final skillId = SkillId.values.firstWhere(
      (value) => value.name == rawKey,
      orElse: () =>
          throw FormatException('Invalid SkillId "$rawKey" in "$key".'),
    );

    result[skillId] = rawValue;
  }

  return result;
}

ItemId _parseItemId(String rawValue, {String fieldName = 'id'}) {
  return ItemId.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () =>
        throw FormatException('Invalid ItemId "$rawValue" for "$fieldName".'),
  );
}

SkillId _parseSkillId(String rawValue, {String fieldName = 'skillId'}) {
  return SkillId.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () =>
        throw FormatException('Invalid SkillId "$rawValue" for "$fieldName".'),
  );
}

ZoneId _parseZoneId(String rawValue, {String fieldName = 'zoneId'}) {
  return ZoneId.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () =>
        throw FormatException('Invalid ZoneId "$rawValue" for "$fieldName".'),
  );
}

EntityId _parseEntityId(String rawValue, {String fieldName = 'entityId'}) {
  return EntityId.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () =>
        throw FormatException('Invalid EntityId "$rawValue" for "$fieldName".'),
  );
}

ArmorSlots _parseArmorSlot(String rawValue, {String fieldName = 'armorSlot'}) {
  return ArmorSlots.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () => throw FormatException(
      'Invalid ArmorSlot "$rawValue" for "$fieldName".',
    ),
  );
}

Duration _durationFromMilliseconds(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Missing or invalid "$key". Expected int.');
  }
  return Duration(milliseconds: value);
}

DateTime _dateTimeFromJson(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Missing or invalid "$key". Expected String.');
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Invalid DateTime for "$key": "$value".');
  }
  return parsed;
}

class Item {
  final ItemId id;
  final String name;
  final int value;
  int count = 1;

  Item({required this.id, required this.name, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'runtimeType': 'Item',
      'id': id.name,
      'name': name,
      'value': value,
      'count': count,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    final rawValue = json['value'];
    final rawCount = json['count'];

    if (rawId is! String) {
      throw FormatException('Missing or invalid "id". Expected String.');
    }
    if (rawName is! String) {
      throw FormatException('Missing or invalid "name". Expected String.');
    }
    if (rawValue is! int) {
      throw FormatException('Missing or invalid "value". Expected int.');
    }
    if (rawCount is! int) {
      throw FormatException('Missing or invalid "count". Expected int.');
    }

    final item = Item(id: _parseItemId(rawId), name: rawName, value: rawValue);
    item.count = rawCount;
    return item;
  }
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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'BuffItem';
    json['skillBonus'] = _skillBonusToJson(skillBonus);
    json['durationMs'] = duration.inMilliseconds;
    json['expirationTime'] = expirationTime.toIso8601String();
    return json;
  }

  factory BuffItem.fromJson(Map<String, dynamic> json) {
    final baseItem = Item.fromJson(json);

    final item = BuffItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      skillBonus: _skillBonusFromJson(json, 'skillBonus'),
      duration: _durationFromMilliseconds(json, 'durationMs'),
    );

    item.count = baseItem.count;
    item.expirationTime = _dateTimeFromJson(json, 'expirationTime');
    return item;
  }
}

class ZoneBuffItem extends BuffItem {
  ZoneId zoneId;
  final EntityId entityId;
  ZoneBuffItem({
    required super.id,
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    this.zoneId = ZoneId.NULL,
    required this.entityId,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'ZoneBuffItem';
    json['zoneId'] = zoneId.name;
    json['entityId'] = entityId.name;
    return json;
  }

  factory ZoneBuffItem.fromJson(Map<String, dynamic> json) {
    final baseItem = BuffItem.fromJson(json);

    final rawZoneId = json['zoneId'];
    final rawEntityId = json['entityId'];

    if (rawZoneId is! String) {
      throw FormatException('Missing or invalid "zoneId". Expected String.');
    }
    if (rawEntityId is! String) {
      throw FormatException('Missing or invalid "entityId". Expected String.');
    }

    final item = ZoneBuffItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      skillBonus: Map<SkillId, int>.from(baseItem.skillBonus),
      duration: baseItem.duration,
      zoneId: _parseZoneId(rawZoneId),
      entityId: _parseEntityId(rawEntityId),
    );

    item.count = baseItem.count;
    item.expirationTime = baseItem.expirationTime;
    return item;
  }
}

class EquipmentItem extends Item {
  final ArmorSlots armorSlot;

  /// Base stats from the item definition; quality/enchant scale on top.
  final Map<SkillId, int> skillBonus;

  /// Unique per instance so individual pieces of equipment can be
  /// tracked, equipped, and enchanted independently.
  String instanceId;

  ItemQuality quality;

  /// Enchant suffix, e.g. "Boar" -> "... of the Boar". Empty when the
  /// item is not enchanted. Only equipment (armor/weapons) can carry one.
  String enchantName;
  Map<SkillId, int> enchantBonus;

  EquipmentItem({
    required super.id,
    required super.name,
    required super.value,
    required this.armorSlot,
    required this.skillBonus,
    this.quality = ItemQuality.COMMON,
    this.enchantName = '',
    Map<SkillId, int>? enchantBonus,
  }) : enchantBonus = enchantBonus ?? {},
       instanceId = UniqueKey().toString();

  /// Stats after quality scaling and enchant bonus.
  Map<SkillId, int> get effectiveSkillBonus {
    final result = <SkillId, int>{};
    for (final entry in skillBonus.entries) {
      result[entry.key] = (entry.value * quality.statMultiplier).round();
    }
    for (final entry in enchantBonus.entries) {
      result[entry.key] = (result[entry.key] ?? 0) + entry.value;
    }
    return result;
  }

  /// "Epic Bronze Helmet of the Boar"
  String get displayName {
    final prefix = quality.label.isEmpty ? '' : '${quality.label} ';
    final suffix = enchantName.isEmpty ? '' : ' of the $enchantName';
    return '$prefix$name$suffix';
  }

  /// Identity for stacking: items that are the same in every way (base
  /// item, quality, enchant name and bonus) live on one stack.
  String get stackKey {
    final bonus =
        enchantBonus.entries.map((e) => '${e.key.name}:${e.value}').toList()
          ..sort();
    return '${id.name}|${quality.name}|$enchantName|${bonus.join(',')}';
  }

  bool canStackWith(EquipmentItem other) => stackKey == other.stackKey;

  /// A fresh single instance with the same identity (new instanceId).
  EquipmentItem copy() {
    return EquipmentItem(
      id: id,
      name: name,
      value: value,
      armorSlot: armorSlot,
      skillBonus: Map.of(skillBonus),
      quality: quality,
      enchantName: enchantName,
      enchantBonus: Map.of(enchantBonus),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'EquipmentItem';
    json['armorSlot'] = armorSlot.name;
    json['skillBonus'] = _skillBonusToJson(skillBonus);
    json['instanceId'] = instanceId;
    json['quality'] = quality.name;
    json['enchantName'] = enchantName;
    json['enchantBonus'] = _skillBonusToJson(enchantBonus);
    return json;
  }

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    final baseItem = Item.fromJson(json);
    final rawArmorSlot = json['armorSlot'];

    if (rawArmorSlot is! String) {
      throw FormatException('Missing or invalid "armorSlot". Expected String.');
    }

    final item = EquipmentItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      armorSlot: _parseArmorSlot(rawArmorSlot),
      skillBonus: _skillBonusFromJson(json, 'skillBonus'),
    );

    item.count = baseItem.count;
    item.readInstanceFieldsFromJson(json);
    return item;
  }

  /// Restores instance fields (tolerating their absence in older saves).
  void readInstanceFieldsFromJson(Map<String, dynamic> json) {
    final rawInstanceId = json['instanceId'];
    if (rawInstanceId is String && rawInstanceId.isNotEmpty) {
      instanceId = rawInstanceId;
    }
    final rawQuality = json['quality'];
    if (rawQuality is String) {
      quality = ItemQuality.values.asNameMap()[rawQuality] ??
          ItemQuality.COMMON;
    }
    final rawEnchantName = json['enchantName'];
    if (rawEnchantName is String) {
      enchantName = rawEnchantName;
    }
    if (json['enchantBonus'] is Map) {
      enchantBonus = _skillBonusFromJson(json, 'enchantBonus');
    }
  }
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

  @override
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

  @override
  BuffItem toItem(ItemId id) => BuffItem(
    id: id,
    name: name,
    value: value,
    skillBonus: skillBonus,
    duration: duration,
  );
}

class ZoneBuffItemDefinition extends BuffItemDefinition {
  final EntityId entityId;

  ZoneBuffItemDefinition({
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    required this.entityId,
    super.description,
    super.iconAsset,
  });

  @override
  ZoneBuffItem toItem(ItemId id) => ZoneBuffItem(
    id: id,
    name: name,
    value: value,
    skillBonus: skillBonus,
    duration: duration,
    entityId: entityId,
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

  @override
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
    super.quality,
    super.enchantName,
    super.enchantBonus,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'WeaponItem';
    json['actionIntervalMs'] = actionInterval.inMilliseconds;
    return json;
  }

  factory WeaponItem.fromJson(Map<String, dynamic> json) {
    final baseItem = EquipmentItem.fromJson(json);

    final item = WeaponItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      armorSlot: baseItem.armorSlot,
      skillBonus: Map<SkillId, int>.from(baseItem.skillBonus),
      actionInterval: _durationFromMilliseconds(json, 'actionIntervalMs'),
    );

    item.count = baseItem.count;
    item.readInstanceFieldsFromJson(json);
    return item;
  }

  /// Parses an equipment instance, dispatching on the serialized type.
  static EquipmentItem equipmentFromJson(Map<String, dynamic> json) {
    return json['runtimeType'] == 'WeaponItem'
        ? WeaponItem.fromJson(json)
        : EquipmentItem.fromJson(json);
  }

  @override
  WeaponItem copy() {
    return WeaponItem(
      id: id,
      name: name,
      value: value,
      armorSlot: armorSlot,
      skillBonus: Map.of(skillBonus),
      actionInterval: actionInterval,
      quality: quality,
      enchantName: enchantName,
      enchantBonus: Map.of(enchantBonus),
    );
  }
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
    ItemId.IRON_ORE: ItemDefinition(
      name: "Iron Ore",
      value: 6,
      iconAsset: "assets/icons/items/iron_ore.png",
    ),

    // logs
    ItemId.LOGS: ItemDefinition(
      name: "Logs",
      value: 2,
      iconAsset: "assets/icons/items/regular_logs.png",
    ),
    ItemId.OAK_LOGS: ItemDefinition(
      name: "Oak Logs",
      value: 5,
      iconAsset: "assets/icons/items/oak_logs.png",
    ),

    // campfires
    ItemId.BASIC_CAMPFIRE: ZoneBuffItemDefinition(
      name: "Basic Campfire",
      value: 5,
      skillBonus: {SkillId.HITPOINTS: 5},
      duration: Duration(minutes: 1),
      entityId: EntityId.BASIC_CAMPIRE,
      iconAsset: "assets/icons/items/basic_campfire.png",
    ),
    ItemId.OAK_CAMPFIRE: ZoneBuffItemDefinition(
      name: "Oak Campfire",
      value: 12,
      skillBonus: {SkillId.HITPOINTS: 10},
      duration: Duration(minutes: 3),
      entityId: EntityId.OAK_CAMPFIRE,
      iconAsset: "assets/icons/items/basic_campfire.png",
    ),

    // enchanting materials (from disenchanting equipment)
    ItemId.ENCHANTING_DUST: ItemDefinition(
      name: "Enchanting Dust",
      value: 1,
      description: "Disenchanted from common equipment.",
      iconAsset: "assets/icons/items/enchanting_dust.png",
    ),
    ItemId.ENCHANTING_ESSENCE: ItemDefinition(
      name: "Enchanting Essence",
      value: 4,
      description: "Disenchanted from uncommon equipment.",
      iconAsset: "assets/icons/items/enchanting_essence.png",
    ),
    ItemId.ENCHANTING_RUNE: ItemDefinition(
      name: "Enchanting Rune",
      value: 15,
      description: "Disenchanted from rare equipment.",
      iconAsset: "assets/icons/items/enchanting_rune.png",
    ),
    ItemId.ENCHANTING_PRISM: ItemDefinition(
      name: "Enchanting Prism",
      value: 50,
      description: "Disenchanted from epic equipment.",
      iconAsset: "assets/icons/items/enchanting_prism.png",
    ),
    ItemId.SOUL_SHARD: ItemDefinition(
      name: "Soul Shard",
      value: 200,
      description: "Disenchanted from legendary equipment.",
      iconAsset: "assets/icons/items/soul_shard.png",
    ),

    // gems (rare mining drops)
    ItemId.TOPAZ: ItemDefinition(
      name: "Topaz",
      value: 20,
      iconAsset: "assets/icons/items/topaz.png",
    ),
    ItemId.SAPPHIRE: ItemDefinition(
      name: "Sapphire",
      value: 40,
      iconAsset: "assets/icons/items/sapphire.png",
    ),
    ItemId.EMERALD: ItemDefinition(
      name: "Emerald",
      value: 60,
      iconAsset: "assets/icons/items/emerald.png",
    ),
    ItemId.RUBY: ItemDefinition(
      name: "Ruby",
      value: 90,
      iconAsset: "assets/icons/items/ruby.png",
    ),
    ItemId.DIAMOND: ItemDefinition(
      name: "Diamond",
      value: 130,
      iconAsset: "assets/icons/items/diamond.png",
    ),
    ItemId.DRAGONSTONE: ItemDefinition(
      name: "Dragonstone",
      value: 200,
      iconAsset: "assets/icons/items/dragonstone.png",
    ),
    ItemId.ONYX: ItemDefinition(
      name: "Onyx",
      value: 350,
      iconAsset: "assets/icons/items/onyx.png",
    ),

    // jewelry bases (blacksmithing); plain stackable crafting components
    // that gems are set into at the jewelcrafting bench
    ItemId.COPPER_RING: ItemDefinition(
      name: "Copper Ring",
      value: 8,
      description: "A plain band, ready for a gem.",
      iconAsset: "assets/icons/items/copper_ring.png",
    ),
    ItemId.COPPER_NECKLACE: ItemDefinition(
      name: "Copper Necklace",
      value: 16,
      description: "A plain chain, ready for a gem.",
      iconAsset: "assets/icons/items/copper_necklace.png",
    ),

    // jewelry (jewelcrafting): high stats relative to armor of the tier
    ItemId.TOPAZ_RING: EquipmentItemDefition(
      armorSlot: ArmorSlots.FINGER,
      name: "Topaz Ring",
      value: 40,
      skillBonus: {SkillId.RECOVERY: 4},
      iconAsset: "assets/icons/items/topaz_ring.png",
    ),
    ItemId.TOPAZ_NECKLACE: EquipmentItemDefition(
      armorSlot: ArmorSlots.NECK,
      name: "Topaz Necklace",
      value: 55,
      skillBonus: {SkillId.RECOVERY: 6},
      iconAsset: "assets/icons/items/topaz_necklace.png",
    ),
    ItemId.SAPPHIRE_RING: EquipmentItemDefition(
      armorSlot: ArmorSlots.FINGER,
      name: "Sapphire Ring",
      value: 70,
      skillBonus: {SkillId.STAMINA: 5},
      iconAsset: "assets/icons/items/sapphire_ring.png",
    ),
    ItemId.SAPPHIRE_NECKLACE: EquipmentItemDefition(
      armorSlot: ArmorSlots.NECK,
      name: "Sapphire Necklace",
      value: 90,
      skillBonus: {SkillId.STAMINA: 7},
      iconAsset: "assets/icons/items/sapphire_necklace.png",
    ),
    ItemId.EMERALD_RING: EquipmentItemDefition(
      armorSlot: ArmorSlots.FINGER,
      name: "Emerald Ring",
      value: 100,
      skillBonus: {SkillId.SPEED: 5},
      iconAsset: "assets/icons/items/emerald_ring.png",
    ),
    ItemId.EMERALD_NECKLACE: EquipmentItemDefition(
      armorSlot: ArmorSlots.NECK,
      name: "Emerald Necklace",
      value: 130,
      skillBonus: {SkillId.SPEED: 7},
      iconAsset: "assets/icons/items/emerald_necklace.png",
    ),
    ItemId.RUBY_RING: EquipmentItemDefition(
      armorSlot: ArmorSlots.FINGER,
      name: "Ruby Ring",
      value: 150,
      skillBonus: {SkillId.HITPOINTS: 6},
      iconAsset: "assets/icons/items/ruby_ring.png",
    ),
    ItemId.RUBY_NECKLACE: EquipmentItemDefition(
      armorSlot: ArmorSlots.NECK,
      name: "Ruby Necklace",
      value: 190,
      skillBonus: {SkillId.HITPOINTS: 9},
      iconAsset: "assets/icons/items/ruby_necklace.png",
    ),
    ItemId.DIAMOND_RING: EquipmentItemDefition(
      armorSlot: ArmorSlots.FINGER,
      name: "Diamond Ring",
      value: 220,
      skillBonus: {SkillId.DEFENCE: 8},
      iconAsset: "assets/icons/items/diamond_ring.png",
    ),
    ItemId.DIAMOND_NECKLACE: EquipmentItemDefition(
      armorSlot: ArmorSlots.NECK,
      name: "Diamond Necklace",
      value: 280,
      skillBonus: {SkillId.DEFENCE: 12},
      iconAsset: "assets/icons/items/diamond_necklace.png",
    ),
    ItemId.DRAGONSTONE_RING: EquipmentItemDefition(
      armorSlot: ArmorSlots.FINGER,
      name: "Dragonstone Ring",
      value: 330,
      skillBonus: {SkillId.ATTACK: 9},
      iconAsset: "assets/icons/items/dragonstone_ring.png",
    ),
    ItemId.DRAGONSTONE_NECKLACE: EquipmentItemDefition(
      armorSlot: ArmorSlots.NECK,
      name: "Dragonstone Necklace",
      value: 420,
      skillBonus: {SkillId.ATTACK: 13},
      iconAsset: "assets/icons/items/dragonstone_necklace.png",
    ),
    ItemId.ONYX_RING: EquipmentItemDefition(
      armorSlot: ArmorSlots.FINGER,
      name: "Onyx Ring",
      value: 550,
      skillBonus: {SkillId.ATTACK: 6, SkillId.DEFENCE: 6, SkillId.HITPOINTS: 6},
      iconAsset: "assets/icons/items/onyx_ring.png",
    ),
    ItemId.ONYX_NECKLACE: EquipmentItemDefition(
      armorSlot: ArmorSlots.NECK,
      name: "Onyx Necklace",
      value: 700,
      skillBonus: {SkillId.ATTACK: 9, SkillId.DEFENCE: 9, SkillId.HITPOINTS: 9},
      iconAsset: "assets/icons/items/onyx_necklace.png",
    ),

    // farm
    ItemId.CHICKEN_MEAT: ItemDefinition(
      name: "Chicken Meat",
      value: 2,
      iconAsset: "assets/icons/items/chicken_meat.png",
    ),
    ItemId.FEATHER: ItemDefinition(
      name: "Feather",
      value: 1,
      iconAsset: "assets/icons/items/feather.png",
    ),
    ItemId.COOKED_CHICKEN: FoodItemDefinition(
      name: "Cooked Chicken",
      value: 4,
      restoreAmount: 3,
      xpValue: 10,
      iconAsset: "assets/icons/items/cooked_chicken.png",
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

    // HERBS (herbalism -> alchemy ingredients), ascending level order
    ItemId.GUAM_LEAF: ItemDefinition(
      name: "Guam Leaf",
      value: 1,
      iconAsset: "assets/icons/items/guam_leaf.png",
      xpValue: 5,
    ),
    ItemId.MARRENTILL: ItemDefinition(
      name: "Marrentill",
      value: 2,
      iconAsset: "assets/icons/items/marrentill.png",
      xpValue: 8,
    ),
    ItemId.TARROMIN: ItemDefinition(
      name: "Tarromin",
      value: 3,
      iconAsset: "assets/icons/items/tarromin.png",
      xpValue: 12,
    ),
    ItemId.HARRALANDER: ItemDefinition(
      name: "Harralander",
      value: 5,
      iconAsset: "assets/icons/items/harralander.png",
      xpValue: 18,
    ),
    ItemId.RANARR_WEED: ItemDefinition(
      name: "Ranarr Weed",
      value: 12,
      iconAsset: "assets/icons/items/ranarr_weed.png",
      xpValue: 24,
    ),
    ItemId.TOADFLAX: ItemDefinition(
      name: "Toadflax",
      value: 10,
      iconAsset: "assets/icons/items/toadflax.png",
      xpValue: 30,
    ),
    ItemId.IRIT_LEAF: ItemDefinition(
      name: "Irit Leaf",
      value: 12,
      iconAsset: "assets/icons/items/irit_leaf.png",
      xpValue: 40,
    ),
    ItemId.AVANTOE: ItemDefinition(
      name: "Avantoe",
      value: 15,
      iconAsset: "assets/icons/items/avantoe.png",
      xpValue: 48,
    ),
    ItemId.KWUARM: ItemDefinition(
      name: "Kwuarm",
      value: 18,
      iconAsset: "assets/icons/items/kwuarm.png",
      xpValue: 55,
    ),
    ItemId.SNAPDRAGON: ItemDefinition(
      name: "Snapdragon",
      value: 25,
      iconAsset: "assets/icons/items/snapdragon.png",
      xpValue: 62,
    ),
    ItemId.CADANTINE: ItemDefinition(
      name: "Cadantine",
      value: 22,
      iconAsset: "assets/icons/items/cadantine.png",
      xpValue: 70,
    ),
    ItemId.LANTADYME: ItemDefinition(
      name: "Lantadyme",
      value: 24,
      iconAsset: "assets/icons/items/lantadyme.png",
      xpValue: 74,
    ),
    ItemId.DWARF_WEED: ItemDefinition(
      name: "Dwarf Weed",
      value: 26,
      iconAsset: "assets/icons/items/dwarf_weed.png",
      xpValue: 78,
    ),
    ItemId.TORSTOL: ItemDefinition(
      name: "Torstol",
      value: 40,
      iconAsset: "assets/icons/items/torstol.png",
      xpValue: 85,
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
    ItemId.IRON_BAR: ItemDefinition(
      name: "Iron Bar",
      value: 8,
      iconAsset: "assets/icons/items/iron_bar.png",
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

    // iron armor (tier 2)
    ItemId.IRON_HELMET: EquipmentItemDefition(
      armorSlot: ArmorSlots.HEAD,
      name: "Iron Helmet",
      value: 30,
      skillBonus: {SkillId.DEFENCE: 10},
      iconAsset: "assets/icons/items/iron_helmet.png",
    ),
    ItemId.IRON_CHESTPLATE: EquipmentItemDefition(
      armorSlot: ArmorSlots.CHEST,
      name: "Iron Chestplate",
      value: 50,
      skillBonus: {SkillId.DEFENCE: 20},
      iconAsset: "assets/icons/items/iron_chestplate.png",
    ),
    ItemId.IRON_LEGS: EquipmentItemDefition(
      armorSlot: ArmorSlots.LEGS,
      name: "Iron Leggings",
      value: 40,
      skillBonus: {SkillId.DEFENCE: 16},
      iconAsset: "assets/icons/items/iron_legs.png",
    ),
    ItemId.IRON_GLOVES: EquipmentItemDefition(
      armorSlot: ArmorSlots.HANDS,
      name: "Iron Gloves",
      value: 20,
      skillBonus: {SkillId.DEFENCE: 6},
      iconAsset: "assets/icons/items/iron_gloves.png",
    ),
    ItemId.IRON_BOOTS: EquipmentItemDefition(
      armorSlot: ArmorSlots.FEET,
      name: "Iron Boots",
      value: 20,
      skillBonus: {SkillId.DEFENCE: 6},
      iconAsset: "assets/icons/items/iron_boots.png",
    ),
    ItemId.IRON_SHIELD: EquipmentItemDefition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Iron Shield",
      value: 30,
      skillBonus: {SkillId.DEFENCE: 14},
      iconAsset: "assets/icons/items/iron_shield.png",
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
    ItemId.COPPER_SICKLE: WeaponItemDefition(
      armorSlot: ArmorSlots.TOOL,
      name: "Copper Sickle",
      value: 10,
      skillBonus: {SkillId.ATTACK: 2, SkillId.HERBALISM: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_sickle.png",
    ),
    ItemId.COPPER_DAGGER: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Copper Dagger",
      value: 10,
      skillBonus: {SkillId.ATTACK: 5},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/copper_dagger.png",
    ),

    // iron weapons and tools (tier 2)
    ItemId.IRON_AXE: WeaponItemDefition(
      armorSlot: ArmorSlots.TOOL,
      name: "Iron Axe",
      value: 25,
      skillBonus: {SkillId.ATTACK: 4, SkillId.WOODCUTTING: 10},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/iron_axe.png",
    ),
    ItemId.IRON_PICKAXE: WeaponItemDefition(
      armorSlot: ArmorSlots.TOOL,
      name: "Iron Pickaxe",
      value: 25,
      skillBonus: {SkillId.ATTACK: 4, SkillId.MINING: 10},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/iron_pickaxe.png",
    ),
    ItemId.IRON_SICKLE: WeaponItemDefition(
      armorSlot: ArmorSlots.TOOL,
      name: "Iron Sickle",
      value: 25,
      skillBonus: {SkillId.ATTACK: 4, SkillId.HERBALISM: 10},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/iron_sickle.png",
    ),
    ItemId.IRON_DAGGER: WeaponItemDefition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Iron Dagger",
      value: 25,
      skillBonus: {SkillId.ATTACK: 10},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/iron_dagger.png",
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
