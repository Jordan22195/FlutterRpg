import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/item_quality.dart';
import 'package:rpg/catalogs/items/model/item.dart';

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
      quality =
          ItemQuality.values.asNameMap()[rawQuality] ?? ItemQuality.COMMON;
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
