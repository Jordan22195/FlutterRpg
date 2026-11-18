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

  /// The skill, and the level in it, a piece demands to be worn. The
  /// material's: a piece is gated by what it is made of.
  SkillId get skillRequirement => materialId.parameters.skillRequirement;

  /// The material's level — or, for a piece made of nothing (a boss
  /// unique), the level of the material whose rung it is worth: its own
  /// rung less [fibOffset], read off the ladder. A unique as strong as
  /// adamant asks for adamant's level. Anything at copper's rung or below
  /// stays free, and so do dev pieces ([fixedStats]) and anything marked
  /// [ungated].
  int get skillLevelRequirement {
    if (materialId != EquipmentMaterialId.NULL ||
        fixedStats != null ||
        ungated) {
      return materialId.parameters.skillLevelRequirement;
    }
    return levelRequirementForRung(fibLevel - fibOffset);
  }

  /// The level the material ladder asks for at [rung]: 0 at copper's rung
  /// or below, the top of the ladder past its end.
  static int levelRequirementForRung(int rung) {
    if (rung <= 0) return 0;
    var level = 0;
    for (final material in EquipmentMaterialId.values) {
      final p = material.parameters;
      if (p.fibLevel <= rung && p.skillLevelRequirement > level) {
        level = p.skillLevelRequirement;
      }
    }
    return level;
  }

  /// Stats a piece carries as written, at every rarity, in place of the
  /// budget split. For dev items only — nothing in the real catalog sets it.
  final Map<SkillId, int>? fixedStats;

  /// Flat points added on top of the budget split at every rarity — a set
  /// that matches its material's stats and carries something extra, the Wolf
  /// Den's speed. Not scaled by [Rarity], so it reads the same on a common
  /// piece as on a rare one.
  final Map<SkillId, int>? bonusStats;

  /// Set on a piece made of nothing that anyone may wear whatever its rung
  /// — cloth, which has no tier to be gated by. Without it a material-less
  /// piece asks for the level its rung is worth (see
  /// [skillLevelRequirement]).
  final bool ungated;

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
    this.fixedStats,
    this.bonusStats,
    this.ungated = false,
    this.catalogSecondaries,
  }) : _armorSlot = armorSlot,
       _fibLevel = fibLevel,
       _statWeights = statWeights;

  /// The rung whose fib value is the stat budget. [fibLevel] for anything
  /// worn; a weapon prices its stats off its metal alone (see
  /// [WeaponItemDefinition]).
  int get budgetRung => fibLevel;

  /// The scale the weights are read against.
  int get totalWeight =>
      statWeights.values.fold(0, (sum, weight) => sum + weight);

  /// The primary stat budget a piece of this definition carries at
  /// [rarity]: the rung's budget scaled by [Rarity.primaryMultiplier], then
  /// raised until the split actually pays out [Rarity.minPrimaryBonus] more
  /// points than common does. The secondary half of the budget is not in
  /// here — it is rolled onto each piece (see [secondaryRollValue]).
  ///
  /// Jewellery keeps the older single-multiplier ladder
  /// ([Rarity.statMultiplier]) and rolls no secondaries; see
  /// [rollsSecondaries].
  ///
  /// The floor is enforced on the stats rather than on the budget because
  /// the budget is not what the player sees: a 1.2x on a low rung can
  /// round straight back onto the common's numbers, and a rare that
  /// reads identically to a common is not a tier. The tier below is a
  /// floor too, because rounding a split across several stats can overshoot.
  ///
  /// Walking the budget up a point at a time is safe —
  /// [Util.weightedShare] never decreases as the budget grows — and on the
  /// ladders in the catalog it takes a handful of steps at most.
  ///
  /// A definition that declares its own [quality] has already had that
  /// step baked into its [fibLevel] by the catalog, so this takes the
  /// rarity it is asked about and nothing else.
  int budgetAt(Rarity rarity) {
    final base = Util.fib(budgetRung);
    // a piece with no stats to split — a weapon, whose damage is the whole
    // of what it is — has nothing for the floor below to measure, and the
    // walk up to it would never arrive
    if (statWeights.isEmpty) return base;
    return rollsSecondaries
        ? scaledBudget(
            base,
            rarity,
            _statTotalFor,
            multiplier: (r) => r.primaryMultiplier,
            minBonus: (r) => r.minPrimaryBonus,
          )
        : scaledBudget(base, rarity, _statTotalFor);
  }

  /// [base] scaled to [rarity], with the floor measured by [statTotal]: what
  /// a budget pays out once it is split. [multiplier] and [minBonus] pick
  /// the ladder; left off they are jewellery's ([Rarity.statMultiplier],
  /// [Rarity.minStatBonus]), whose onyx reads its budget as an xp percent
  /// rather than splitting it into stats.
  ///
  /// A tier that does not multiply past the one below it (gear's uncommon,
  /// which pays its step as a secondary roll) is worth exactly that tier.
  static int scaledBudget(
    int base,
    Rarity rarity,
    int Function(int budget) statTotal, {
    double Function(Rarity rarity)? multiplier,
    int Function(Rarity rarity)? minBonus,
  }) {
    final mult = multiplier ?? (r) => r.statMultiplier;
    final bonus = minBonus ?? (r) => r.minStatBonus;
    if (rarity.rung <= 0) return base;
    final below = Rarity.values[rarity.index - 1];
    final belowBudget = scaledBudget(
      base,
      below,
      statTotal,
      multiplier: mult,
      minBonus: bonus,
    );
    if (mult(rarity) <= mult(below)) return belowBudget;
    final floor = max(
      statTotal(base) + bonus(rarity),
      statTotal(belowBudget) + 1,
    );
    var budget = max(base, (base * mult(rarity)).round());
    while (statTotal(budget) < floor) {
      budget++;
    }
    return budget;
  }

  /// Whether pieces of this definition carry core-stat secondaries at
  /// uncommon and above, and scale their primary stats on gear's ladder.
  /// Everything worn does except crafted jewellery, which keeps the
  /// single-multiplier ladder, and the dev pieces whose stats are written
  /// out ([fixedStats]). Rolled at random unless [catalogSecondaries] sets
  /// them.
  bool get rollsSecondaries => fixedStats == null;

  /// The secondaries a unique carries, set here rather than rolled: one
  /// core stat per roll, in the order the tiers unlock them — an uncommon
  /// takes the first, a rare the first two, up to all four on a legendary.
  /// Each is worth [secondaryRollValue], the same as a crafted piece's
  /// random roll, so a unique is a crafted piece of its rung with its
  /// secondaries chosen for it. Null for anything that rolls at random.
  final List<SkillId>? catalogSecondaries;

  /// The secondaries a piece of this definition carries at [rarity] when
  /// they are set in the catalog, or null when they are rolled per piece.
  List<SkillId>? catalogSecondariesAt(Rarity rarity) {
    final set = catalogSecondaries;
    if (set == null || !rollsSecondaries) return null;
    return set.take(rarity.secondaryRolls).toList(growable: false);
  }

  /// The stats one secondary roll can land on: the four core stats.
  static const List<SkillId> secondaryStatPool = [
    SkillId.STAMINA,
    SkillId.SPEED,
    SkillId.STRENGTH,
    SkillId.RECOVERY,
  ];

  /// What one secondary roll is worth: [Rarity.secondaryRollShare] of the
  /// rung's common budget, and never less than a point.
  int get secondaryRollValue =>
      max(1, (Util.fib(budgetRung) * Rarity.secondaryRollShare).round());

  /// [rolls] — one core stat per roll — as the stats they add.
  Map<SkillId, int> secondaryStatsFor(List<SkillId> rolls) {
    final value = secondaryRollValue;
    final stats = <SkillId, int>{};
    for (final stat in rolls) {
      stats[stat] = (stats[stat] ?? 0) + value;
    }
    return stats;
  }

  /// A rarity this piece always wears, whatever it was rolled at, or null
  /// for the usual: the rolled quality (or the definition's) stands.
  Rarity? get fixedRarity => null;

  /// Whether rarity reaches this piece's primary stats. Off, its
  /// rarity is the colour of its border and nothing else.
  bool get rarityScalesStats => true;

  /// The primary stats a piece of this definition at [rarity] has — the
  /// split budget plus [bonusStats]. A piece's secondary rolls go on top
  /// (see `EquipmentItem.effectiveSkillBonus`).
  Map<SkillId, int> statsAt(Rarity rarity) {
    if (fixedStats != null) return {...fixedStats!};
    final stats = _statsFor(
      budgetAt(rarityScalesStats ? rarity : Rarity.COMMON),
    );
    for (final bonus in (bonusStats ?? const <SkillId, int>{}).entries) {
      stats[bonus.key] = (stats[bonus.key] ?? 0) + bonus.value;
    }
    return stats;
  }

  /// Splitting [budget] by the weights — the one place the split happens,
  /// so [budgetAt]'s floor is measured against the same numbers the player
  /// ends up reading.
  ///
  /// A hide splits its budget exactly, so its stats add up to the rung's
  /// own fib value; anything else rounds each share on its own.
  Map<SkillId, int> _statsFor(int budget) {
    if (materialId.parameters is LeatherEquipmentParameters) {
      return exactSplit(budget, statWeights);
    }
    final total = totalWeight;
    return {
      for (final entry in statWeights.entries)
        entry.key: Util.weightedShare(budget, entry.value, total),
    };
  }

  /// [budget] shared out by [weights] so the shares add up to exactly
  /// [budget]: each stat takes its whole share, and the points left over
  /// go one at a time to the largest remainders. A tie goes to attack,
  /// then to the order the weights are listed in — so leather's even
  /// split of 3 is attack 2, defence 1.
  static Map<SkillId, int> exactSplit(int budget, Map<SkillId, int> weights) {
    final total = weights.values.fold(0, (sum, weight) => sum + weight);
    if (total <= 0) return {for (final skill in weights.keys) skill: 0};

    final shares = {
      for (final entry in weights.entries)
        entry.key: budget * entry.value ~/ total,
    };
    var left = budget - shares.values.fold(0, (sum, share) => sum + share);

    final listed = weights.keys.toList();
    int remainder(SkillId skill) => budget * weights[skill]! % total;
    final byRemainder = [...listed]
      ..sort((a, b) {
        final byLeft = remainder(b).compareTo(remainder(a));
        if (byLeft != 0) return byLeft;
        if (a == SkillId.ATTACK) return -1;
        if (b == SkillId.ATTACK) return 1;
        return listed.indexOf(a).compareTo(listed.indexOf(b));
      });
    for (final skill in byRemainder) {
      if (left <= 0) break;
      shares[skill] = shares[skill]! + 1;
      left--;
    }
    return shares;
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
      fixedStats: fixedStats,
      bonusStats: bonusStats,
      ungated: ungated,
      catalogSecondaries: catalogSecondaries,
    );
  }

  @override
  // quality is left unrolled, so the piece reads back whatever the
  // definition declares until crafting, a drop or a shop rolls one onto it
  EquipmentItem toItem(ItemId id) => EquipmentItem(id: id);
}
