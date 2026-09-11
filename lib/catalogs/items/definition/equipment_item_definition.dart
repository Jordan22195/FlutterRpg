import 'dart:math';

import 'package:rpg/catalogs/items/definition/equipment_material.dart';
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
  /// Set by anything that is only ever worn in one place. A weapon leaves it
  /// off and takes [defaultSlot] from its type instead, so read [armorSlot].
  final ArmorSlots? _armorSlot;

  /// Where the piece is worn.
  ArmorSlots get armorSlot => _armorSlot ?? defaultSlot;

  /// The slot a piece that names none falls back to. Nothing but a weapon
  /// has one — armour is defined by where it is worn, so leaving the slot
  /// off an armour definition is a mistake rather than a shorthand.
  ArmorSlots get defaultSlot => throw StateError(
    '$name states no armorSlot, and is not the kind of piece that can take '
    'one from its type',
  );

  /// What the piece is made of. It is the default source of both
  /// [fibLevel] and [statWeights], so a piece that sits squarely on its
  /// material's rung declares the material and nothing else.
  final EquipmentMaterialId materialId;

  /// Set only when a piece departs from its material's rung — a chestplate
  /// is worth more than a helmet of the same metal — and read through
  /// [fibLevel], never directly.
  final int? _fibLevel;

  /// Set only when a piece splits its budget differently from its
  /// material, and read through [statWeights], never directly.
  final Map<SkillId, int>? _statWeights;

  /// The rung of [Util.fibonacciCache] a COMMON piece is worth. Rarity no
  /// longer walks this rung up the ladder — it scales the budget the rung
  /// buys instead (see [budgetAt]) — so this is the whole of what the base
  /// item is worth.
  ///
  /// Comes from [materialId], stepped up by [ArmorSlots.fibOffset] so a
  /// chestplate outranks the helmet of the same metal, unless the definition
  /// passed a `fibLevel` of its own — which wins whole, offset included.
  int get fibLevel => _fibLevel ?? materialId.parameters.fibLevel + fibOffset;

  /// How many rungs over its material this piece sits. The slot's spread for
  /// armour; a weapon adds what its shape is worth on top.
  int get fibOffset => armorSlot.fibOffset;

  /// How the budget is split across skills. A RATIO over their own total,
  /// not absolute amounts: only each weight's share of [totalWeight]
  /// matters, so `{ATTACK: 2, DEFENCE: 1}` and `{ATTACK: 4, DEFENCE: 2}`
  /// describe the same piece. For the stats a piece actually carries, call
  /// [statsAt] — or read [EquipmentItem.effectiveSkillBonus], which adds
  /// the enchant on top.
  ///
  /// Comes from [materialId] — metal defends, leather splits attack and
  /// defence — unless the definition passed `statWeights` of its own.
  Map<SkillId, int> get statWeights => _statWeights ?? defaultStatWeights;

  /// The split a piece that states none falls back to. Its material's, for
  /// anything worn; a weapon splits by what it is rather than what it is
  /// made of, so it overrides this.
  Map<SkillId, int> get defaultStatWeights => materialId.parameters.statWeight;

  /// The skill, and the level in it, a piece demands to be worn. Always
  /// the material's: a piece is gated by what it is made of.
  SkillId get skillRequirement => materialId.parameters.skillRequirement;

  int get skillLevelRequirement => materialId.parameters.skillLevelRequirement;

  const EquipmentItemDefinition({
    required super.name,
    required super.value,
    ArmorSlots? armorSlot,
    this.materialId = EquipmentMaterialId.NULL,
    int? fibLevel,
    Map<SkillId, int>? statWeights,
    super.description,
    super.iconAsset,
    super.quality,
  }) : _armorSlot = armorSlot,
       _fibLevel = fibLevel,
       _statWeights = statWeights;

  /// The scale the weights are read against.
  int get totalWeight =>
      statWeights.values.fold(0, (sum, weight) => sum + weight);

  /// The stat budget a piece of this definition carries at [rarity]: the
  /// rung's budget scaled by [Rarity.statMultiplier], then raised until
  /// the split actually pays out [Rarity.minStatBonus] more points than
  /// common does.
  ///
  /// The floor is enforced on the stats rather than on the budget because
  /// the budget is not what the player sees: a 1.2x on a low rung can
  /// round straight back onto the common's numbers, and an uncommon that
  /// reads identically to a common is not a tier. The tier below is a
  /// floor too, because rounding a split across several stats can overshoot
  /// — an uncommon that landed on +2 would otherwise be matched exactly by
  /// the rare that only owes +2.
  ///
  /// Walking the budget up a point at a time is safe —
  /// [Util.weightedShare] never decreases as the budget grows — and on the
  /// ladders in the catalog it takes a handful of steps at most.
  ///
  /// A definition that declares its own [quality] has already had that
  /// step baked into its [fibLevel] by the catalog, so this takes the
  /// rarity it is asked about and nothing else.
  int budgetAt(Rarity rarity) {
    final base = Util.fib(fibLevel);
    if (rarity == Rarity.COMMON) return base;

    final below = Rarity.values[rarity.index - 1];
    final floor = max(
      _statTotalFor(base) + rarity.minStatBonus,
      _statTotalFor(budgetAt(below)) + 1,
    );
    var budget = max(base, (base * rarity.statMultiplier).round());
    while (_statTotalFor(budget) < floor) {
      budget++;
    }
    return budget;
  }

  /// The stats a piece of this definition at [rarity] actually has.
  Map<SkillId, int> statsAt(Rarity rarity) => _statsFor(budgetAt(rarity));

  /// Splitting [budget] by the weights — the one place the split happens,
  /// so [budgetAt]'s floor is measured against the same numbers the player
  /// ends up reading.
  Map<SkillId, int> _statsFor(int budget) {
    final total = totalWeight;
    return {
      for (final entry in statWeights.entries)
        entry.key: Util.weightedShare(budget, entry.value, total),
    };
  }

  int _statTotalFor(int budget) =>
      _statsFor(budget).values.fold(0, (sum, stat) => sum + stat);

  @override
  EquipmentItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    ArmorSlots? armorSlot,
    EquipmentMaterialId? materialId,
    int? fibLevel,
    Map<SkillId, int>? statWeights,
  }) {
    return EquipmentItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      armorSlot: armorSlot ?? _armorSlot,
      materialId: materialId ?? this.materialId,
      fibLevel: fibLevel ?? _fibLevel,
      statWeights: statWeights ?? _statWeights,
    );
  }

  @override
  // quality is left unrolled, so the piece reads back whatever the
  // definition declares until crafting, a drop or a shop rolls one onto it
  EquipmentItem toItem(ItemId id) => EquipmentItem(id: id);
}
