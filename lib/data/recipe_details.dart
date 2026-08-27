import '../catalogs/items/items.dart';
import '../catalogs/recipes/recipes.dart';
import 'skill_data.dart';

/// One outcome a craft can roll, as a probability.
///
/// Two kinds of row share this shape, and exactly one of [itemId] /
/// [quality] is set on each: an output row names the item the craft can
/// produce (which is how cooking states its burn chance), a quality row
/// names the tier a piece of equipment can come out at.
class RecipeOutcomeChance {
  final String label;

  /// Set on an output row; null on a quality row.
  final ItemId? itemId;

  /// Set on a quality row; null on an output row.
  final Rarity? quality;

  /// Probability this outcome lands on one craft (0..1).
  final double chance;

  final int minCount;
  final int maxCount;

  const RecipeOutcomeChance({
    required this.label,
    this.itemId,
    this.quality,
    required this.chance,
    this.minCount = 1,
    this.maxCount = 1,
  });

  /// True when the stack size varies (count..highCount).
  bool get hasCountRange => maxCount > minCount;
}

/// One input line: what a single craft costs, and what the inventory holds.
class RecipeMaterial {
  final ItemId itemId;
  final String name;
  final int required;
  final int held;

  const RecipeMaterial({
    required this.itemId,
    required this.name,
    required this.required,
    required this.held,
  });

  /// True when there isn't enough on hand for even one craft.
  bool get isShort => held < required;
}

/// Snapshot of everything the bench panel's info tab shows for one recipe:
/// what it makes, what it costs, and the odds behind the craft. Built by
/// [CraftingSystem.buildRecipeDetails].
class RecipeDetails {
  final CraftingRecipe recipe;

  /// The level the craft is actually judged at: base skill plus equipment
  /// plus buffs, which is what the quality roll reads. Displaying the bare
  /// skill level here would disagree with [outcomes].
  final int effectiveSkillLevel;

  /// How many of this recipe the inventory can currently pay for.
  final int craftableCount;

  final List<RecipeMaterial> materials;

  /// The quality tiers when [rollsQuality], otherwise the output table.
  final List<RecipeOutcomeChance> outcomes;

  /// Whether this recipe produces equipment, which is the only thing that
  /// rolls a quality tier.
  final bool rollsQuality;

  const RecipeDetails({
    required this.recipe,
    required this.effectiveSkillLevel,
    required this.craftableCount,
    required this.materials,
    required this.outcomes,
    required this.rollsQuality,
  });

  SkillId get skill => recipe.skill;

  /// False for the catalog's blank miss recipe, which is what an unset or
  /// unknown selection resolves to. Nothing should be drawn for it.
  bool get isReal => recipe.output.isNotEmpty;

  /// Whether there is anything worth tabulating: a single certain output
  /// (a bar, a fire) has no odds to state.
  bool get hasOdds => outcomes.length > 1;

  /// Whether every input is covered for at least one craft.
  bool get hasMaterials => materials.every((m) => !m.isShort);
}
