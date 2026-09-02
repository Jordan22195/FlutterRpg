import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/equipment_item.dart';
import 'package:rpg/catalogs/items/definition/item_definition.dart';
import 'package:rpg/utilities/util.dart';

/// A wearable piece. Its stats are never written by hand: [fibLevel] sets
/// the size of the stat budget and [statWeights] splits that budget across
/// skills, so every piece sits on the same curve a combat entity does and a
/// tier reads the same everywhere.
class EquipmentItemDefinition extends ItemDefinition {
  final ArmorSlots armorSlot;

  /// The rung of [Util.fibonacciCache] a COMMON piece is worth. A rolled
  /// rarity walks it up the same ladder a monster's does — uncommon one
  /// rung, legendary four — so rarity buys a real step rather than a
  /// rounding error.
  final int fibLevel;

  /// How the budget is split across skills. A RATIO over their own total,
  /// not absolute amounts: only each weight's share of [totalWeight]
  /// matters, so `{ATTACK: 2, DEFENCE: 1}` and `{ATTACK: 4, DEFENCE: 2}`
  /// describe the same piece. For the stats a piece actually carries, call
  /// [statsAt] — or read [EquipmentItem.effectiveSkillBonus], which adds
  /// the enchant on top.
  final Map<SkillId, int> statWeights;

  const EquipmentItemDefinition({
    required super.name,
    required super.value,
    required this.armorSlot,
    required this.fibLevel,
    required this.statWeights,
    super.description,
    super.iconAsset,
    super.quality,
  });

  /// The scale the weights are read against.
  int get totalWeight =>
      statWeights.values.fold(0, (sum, weight) => sum + weight);

  /// The stat budget a piece of this definition carries at [rarity].
  ///
  /// A definition that declares its own [quality] has already had that
  /// step baked into its [fibLevel] by the catalog, so this takes the
  /// rarity it is asked about and nothing else.
  int budgetAt(Rarity rarity) => Util.fib(fibLevel + rarity.index);

  /// The stats a piece of this definition at [rarity] actually has.
  Map<SkillId, int> statsAt(Rarity rarity) {
    final budget = budgetAt(rarity);
    final total = totalWeight;
    return {
      for (final entry in statWeights.entries)
        entry.key: Util.weightedShare(budget, entry.value, total),
    };
  }

  @override
  EquipmentItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    ArmorSlots? armorSlot,
    int? fibLevel,
    Map<SkillId, int>? statWeights,
  }) {
    return EquipmentItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      armorSlot: armorSlot ?? this.armorSlot,
      fibLevel: fibLevel ?? this.fibLevel,
      statWeights: statWeights ?? this.statWeights,
    );
  }

  @override
  // quality is left unrolled, so the piece reads back whatever the
  // definition declares until crafting, a drop or a shop rolls one onto it
  EquipmentItem toItem(ItemId id) => EquipmentItem(id: id);
}
