import 'dart:math';

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
/// piece in the player's bag is the rolled [quality], the core stat each of
/// its [secondaryRolls] landed on, and the enchant rolled onto it. Those are
/// the only things stored here — retuning the base item in the catalog moves
/// every copy already in play, secondaries included, since a roll stores
/// only which stat it hit and the definition says what a roll is worth.
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

  /// The core stat each secondary roll landed on, one entry per roll; null
  /// until the piece has been rolled. See [rollSecondaries].
  List<SkillId>? _secondaryRolls;

  EquipmentItem({
    required super.id,
    Rarity? quality,
    this.enchantName = '',
    Map<SkillId, int>? enchantBonus,
    List<SkillId>? secondaryRolls,
  }) : _quality = quality,
       _secondaryRolls = secondaryRolls == null
           ? null
           : List.unmodifiable(secondaryRolls),
       enchantBonus = enchantBonus ?? {},
       instanceId = UniqueKey().toString();

  /// The core stat each of this piece's secondaries landed on — empty
  /// when it has none or has not been rolled yet. A unique's are read off
  /// its definition, never stored, so retuning them moves every copy.
  List<SkillId> get secondaryRolls =>
      definition.catalogSecondariesAt(quality) ?? _secondaryRolls ?? const [];

  /// Whether this piece is owed secondary rolls it does not carry yet: its
  /// quality rolls some and it has not been rolled at that quality. Fresh
  /// pieces from a drop, craft or shop are, until they reach an inventory
  /// (`InventoryService.addEquipment`), and so is a piece from a save made
  /// before secondaries existed.
  bool get needsSecondaryRolls =>
      definition.rollsSecondaries &&
      definition.catalogSecondaries == null &&
      quality.secondaryRolls > 0 &&
      _secondaryRolls?.length != quality.secondaryRolls;

  /// Rolls this piece's secondaries fresh: one core stat per roll its
  /// quality carries, each drawn on its own, so a legendary can land all
  /// four on one stat or spread them across four. Does nothing to a unique,
  /// whose secondaries the catalog sets.
  void rollSecondaries([Random? rng]) {
    // a unique's secondaries are the catalog's, not this piece's to roll
    if (definition.catalogSecondaries != null) return;
    final random = rng ?? Random();
    final pool = EquipmentItemDefinition.secondaryStatPool;
    final count = definition.rollsSecondaries ? quality.secondaryRolls : 0;
    _secondaryRolls = List.unmodifiable([
      for (var i = 0; i < count; i++) pool[random.nextInt(pool.length)],
    ]);
  }

  /// This stack as single pieces, each rolled on its own — a stack of
  /// rolled gear only holds pieces that rolled the same. A piece that rolls
  /// nothing, or is rolled already, comes back whole.
  List<EquipmentItem> rollEach([Random? rng]) {
    if (!needsSecondaryRolls) return [this];
    if (count <= 1) {
      rollSecondaries(rng);
      return [this];
    }
    return [
      for (var i = 0; i < count; i++)
        copy()
          ..count = 1
          ..rollSecondaries(rng),
    ];
  }

  @override
  EquipmentItemDefinition get definition =>
      id.definition as EquipmentItemDefinition;

  ArmorSlots get armorSlot => definition.armorSlot;

  /// The skill this piece is worn or wielded with, and the level in it the
  /// player needs before they can put it on. Both come off the definition —
  /// the metal sets the level, and what the piece is sets the skill — so a
  /// piece with no material behind it asks for nothing (level 0).
  SkillId get skillRequirement => definition.skillRequirement;

  int get skillLevelRequirement => definition.skillLevelRequirement;

  /// How this piece's budget is split across skills — a ratio, not stat
  /// amounts. Read-only on purpose: an instance that could write here could
  /// drift from the catalog, which is the whole thing this model exists to
  /// prevent. Per-piece stats belong in [quality] and [enchantBonus].
  Map<SkillId, int> get statWeights => Map.unmodifiable(definition.statWeights);

  /// The rung this particular piece sits on, if rarity were a step up the
  /// Fibonacci ladder rather than a multiplier on the budget.
  ///
  /// Kept deliberately: stats come off [EquipmentItemDefinition.budgetAt],
  /// which now scales the definition's rung by [Rarity.statMultiplier], so
  /// nothing in play reads this. It is the other tuning of the same idea,
  /// left here in case the ladder is worth going back to.
  int get fibLevel => definition.fibLevel + quality.rung;

  /// Rolled by crafting, drops and shop stock; falls back to whatever the
  /// definition declares for a piece that was never rolled.
  ///
  /// Setting a different quality drops the secondary rolls, which belong to
  /// the old one; the piece rolls again on its way into an inventory.
  @override
  Rarity get quality =>
      definition.fixedRarity ?? _quality ?? definition.quality;
  set quality(Rarity value) {
    if (value != quality) _secondaryRolls = null;
    _quality = value;
  }

  /// The stats this piece actually carries: its rung's primary budget split
  /// by the definition's weights, its secondary rolls, and the enchant
  /// added flat on top.
  ///
  /// The enchant is added after the split rather than folded into the
  /// budget, because it is a roll made at the bench on this one piece — it
  /// is not part of what the item is.
  Map<SkillId, int> get effectiveSkillBonus {
    final result = definition.statsAt(quality);
    final secondary = definition.secondaryStatsFor(secondaryRolls);
    for (final entry in [...secondary.entries, ...enchantBonus.entries]) {
      result[entry.key] = (result[entry.key] ?? 0) + entry.value;
    }
    return result;
  }

  /// "Bronze Helmet of the Boar". The quality is not in the name: it is the
  /// colour of the border drawn around the piece, and its own line in the
  /// info dialog.
  String get displayName {
    final suffix = enchantName.isEmpty ? '' : ' of the $enchantName';
    return '$name$suffix';
  }

  /// Identity for stacking: items that are the same in every way (base
  /// item, quality, secondary rolls, enchant name and bonus) live on one
  /// stack. The rolls are sorted, so the order they came up in is not part
  /// of the piece.
  String get stackKey {
    final bonus =
        enchantBonus.entries.map((e) => '${e.key.name}:${e.value}').toList()
          ..sort();
    final rolls = secondaryRolls.map((s) => s.name).toList()..sort();
    return '${id.name}|${quality.name}|${rolls.join(',')}|'
        '$enchantName|${bonus.join(',')}';
  }

  bool canStackWith(EquipmentItem other) => stackKey == other.stackKey;

  /// A fresh single instance with the same identity (new instanceId).
  /// Built through the catalog, so the copy is the right subclass without
  /// this having to be overridden per class.
  EquipmentItem copy() {
    final fresh = id.build() as EquipmentItem;
    fresh.quality = quality;
    fresh._secondaryRolls = _secondaryRolls;
    fresh.enchantName = enchantName;
    fresh.enchantBonus = Map.of(enchantBonus);
    return fresh;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['instanceId'] = instanceId;
    json['quality'] = quality.name;
    if (_secondaryRolls != null) {
      json['secondaryRolls'] = [for (final s in _secondaryRolls!) s.name];
    }
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
    final rawRolls = json['secondaryRolls'];
    if (rawRolls is List) {
      final byName = SkillId.values.asNameMap();
      _secondaryRolls = List.unmodifiable([
        for (final name in rawRolls)
          if (byName[name] case final SkillId stat) stat,
      ]);
    }
    // a piece saved before secondaries existed, or whose stored rolls no
    // longer match its quality, rolls them now and keeps them from here on
    if (needsSecondaryRolls) rollSecondaries();
  }
}
