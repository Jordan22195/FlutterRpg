import 'package:flutter/foundation.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/definition/equipment_item_definition.dart';
import 'package:rpg/catalogs/items/model/item.dart';

/// A wearable piece.
///
/// Its slot, its rung on the Fibonacci ladder and the weights that split
/// that rung's budget all come off the definition; what is unique to the
/// piece in the player's bag is the rolled [quality] and the enchant rolled
/// onto it. Those are the only things stored here — retuning the base item
/// in the catalog moves every copy already in play.
class EquipmentItem extends Item {
  /// Unique per instance so individual pieces of equipment can be
  /// tracked, equipped, and enchanted independently.
  String instanceId;

  /// Enchant suffix, e.g. "Boar" -> "... of the Boar". Empty when the
  /// item is not enchanted. Only equipment (armor/weapons) can carry one.
  String enchantName;

  /// The enchant's stat roll. Genuinely per-instance: no definition can
  /// supply it, because it is rolled fresh at the bench.
  Map<SkillId, int> enchantBonus;

  /// The rolled quality, or null when this piece has never been rolled and
  /// simply is whatever quality its definition declares.
  Rarity? _quality;

  EquipmentItem({
    required super.id,
    Rarity? quality,
    this.enchantName = '',
    Map<SkillId, int>? enchantBonus,
  }) : _quality = quality,
       enchantBonus = enchantBonus ?? {},
       instanceId = UniqueKey().toString();

  @override
  EquipmentItemDefinition get definition =>
      id.definition as EquipmentItemDefinition;

  ArmorSlots get armorSlot => definition.armorSlot;

  /// How this piece's budget is split across skills — a ratio, not stat
  /// amounts. Read-only on purpose: an instance that could write here could
  /// drift from the catalog, which is the whole thing this model exists to
  /// prevent. Per-piece stats belong in [quality] and [enchantBonus].
  Map<SkillId, int> get statWeights => Map.unmodifiable(definition.statWeights);

  /// The rung this particular piece sits on: the definition's, walked up by
  /// whatever rarity was rolled onto it.
  int get fibLevel => definition.fibLevel + quality.index;

  /// Rolled by crafting, drops and shop stock; falls back to whatever the
  /// definition declares for a piece that was never rolled.
  @override
  Rarity get quality => _quality ?? definition.quality;
  set quality(Rarity value) => _quality = value;

  /// The stats this piece actually carries: its rung's budget split by the
  /// definition's weights, with the enchant added flat on top.
  ///
  /// The enchant is added after the split rather than folded into the
  /// budget, because it is a roll made at the bench on this one piece — it
  /// is not part of what the item is.
  Map<SkillId, int> get effectiveSkillBonus {
    final result = definition.statsAt(quality);
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
  /// Built through the catalog, so the copy is the right subclass without
  /// this having to be overridden per class.
  EquipmentItem copy() {
    final fresh = id.build() as EquipmentItem;
    fresh.quality = quality;
    fresh.enchantName = enchantName;
    fresh.enchantBonus = Map.of(enchantBonus);
    return fresh;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['instanceId'] = instanceId;
    json['quality'] = quality.name;
    json['enchantName'] = enchantName;
    json['enchantBonus'] = skillBonusToJson(enchantBonus);
    return json;
  }

  /// Restores instance fields (tolerating their absence in older saves).
  void readInstanceFieldsFromJson(Map<String, dynamic> json) {
    final rawInstanceId = json['instanceId'];
    if (rawInstanceId is String && rawInstanceId.isNotEmpty) {
      instanceId = rawInstanceId;
    }
    final rawQuality = json['quality'];
    if (rawQuality is String) {
      _quality = Rarity.values.asNameMap()[rawQuality] ?? Rarity.COMMON;
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
