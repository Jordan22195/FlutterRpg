import 'package:flutter/foundation.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/item.dart';

/// How much each rarity scales a piece of equipment's base stats.
///
/// Equipment is the only thing that reads a multiplier off the ladder — an
/// entity's rarity is cosmetic — so it lives here rather than on [Rarity]
/// itself. Every rarity has an entry; [statMultiplierFor] is the way to
/// read it, so a tier added to the enum without one falls back to 1.0
/// instead of throwing.
const Map<Rarity, double> rarityStatMultiplier = {
  Rarity.COMMON: 1.0,
  Rarity.UNCOMMON: 1.1,
  Rarity.RARE: 1.2,
  Rarity.EPIC: 1.3,
  Rarity.LEGENDARY: 1.5,
};

const Map<Rarity, int> rarityStatMinBonus = {
  Rarity.COMMON: 0,
  Rarity.UNCOMMON: 1,
  Rarity.RARE: 2,
  Rarity.EPIC: 3,
  Rarity.LEGENDARY: 5,
};

/// The stat multiplier for [rarity], defaulting to the identity.
double statMultiplierFor(Rarity rarity) => rarityStatMultiplier[rarity] ?? 1.0;

class EquipmentItem extends Item {
  final ArmorSlots armorSlot;

  /// Base stats from the item definition; quality/enchant scale on top.
  final Map<SkillId, int> skillBonus;

  /// Unique per instance so individual pieces of equipment can be
  /// tracked, equipped, and enchanted independently.
  String instanceId;

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
    super.quality = Rarity.COMMON,
    this.enchantName = '',
    Map<SkillId, int>? enchantBonus,
  }) : enchantBonus = enchantBonus ?? {},
       instanceId = UniqueKey().toString();

  /// Stats after quality scaling and enchant bonus.
  ///
  /// Each base stat is scaled by the quality's multiplier and then floored at
  /// that quality's [rarityStatMinBonus], so a rarer item is never worth less
  /// than its tier promises — scaling alone rounds a +1 stat straight back to
  /// +1 at every tier below legendary.
  Map<SkillId, int> get effectiveSkillBonus {
    final result = <SkillId, int>{};
    final floor = rarityStatMinBonus[quality] ?? 0;
    for (final entry in skillBonus.entries) {
      final scaled = (entry.value * statMultiplierFor(quality)).round();
      result[entry.key] = scaled > floor ? scaled : floor;
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
    json['skillBonus'] = skillBonusToJson(skillBonus);
    json['instanceId'] = instanceId;
    json['quality'] = quality.name;
    json['enchantName'] = enchantName;
    json['enchantBonus'] = skillBonusToJson(enchantBonus);
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
      armorSlot: parseArmorSlot(rawArmorSlot),
      skillBonus: skillBonusFromJson(json, 'skillBonus'),
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
      quality = Rarity.values.asNameMap()[rawQuality] ?? Rarity.COMMON;
    }
    final rawEnchantName = json['enchantName'];
    if (rawEnchantName is String) {
      enchantName = rawEnchantName;
    }
    if (json['enchantBonus'] is Map) {
      enchantBonus = skillBonusFromJson(json, 'enchantBonus');
    }
  }
}
