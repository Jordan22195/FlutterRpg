import '../data/skill_data.dart';
import '../data/crafting_state.dart';
import '../catalogs/items/items.dart';
import '../catalogs/recipes/recipes.dart';
import 'weighted_drop_table_service.dart';

class CraftingService {
  /// The recipe's output table with the burn entry reweighted for the
  /// player's cooking level. Returns a new list: the recipe belongs to the
  /// catalog and is shared by every caller, so reweighting in place would
  /// leave the last crafter's burn odds baked into it for everyone.
  List<WeightedDropTableEntry<ItemId>> adjustActiveRecipeDropTable(
    CraftingRecipe recipe,
    Map<SkillId, int> skillLevels,
  ) {
    final skillLevel = skillLevels[SkillId.COOKING] ?? 1;
    final burn = calculateBurnChance(
      level: skillLevel,
      requiredLevel: recipe.levelRequirement,
    );

    // the burn line's weight is set against everything else on the table,
    // so that burning comes up [burn] of the time — the weight is not the
    // chance itself, which against a cooked line of weight 1 would read 50%
    // as 33%
    final rest = recipe.output
        .where((entry) => entry.id != ItemId.BURNT_FOOD)
        .fold<double>(0, (sum, entry) => sum + entry.weight);

    return [
      for (final entry in recipe.output)
        if (entry.id == ItemId.BURNT_FOOD)
          entry.copyWith(weight: rest * burn / (1 - burn))
        else
          entry,
    ];
  }

  bool setActiveRecipe(
    String recipeId,
    CraftingState craftingState,
    RecipeCatalog catalog,
  ) {
    // todo check requirements
    craftingState.activeRecipeId = catalog.recipeById(recipeId).id;
    return true;
  }

  /// How likely one cook of a recipe asking for [requiredLevel] is to burn
  /// at cooking [level] (fire bonuses included): [burnAtRequirement] at the
  /// recipe's own level, falling in a straight line to [minBurnChance]
  /// [burnStopMargin] levels past it. Measured from the requirement, so a
  /// hard recipe is no more hopeless at 99 than an easy one at 21 — what
  /// counts is how far past it the cook is.
  double calculateBurnChance({
    required int level,
    required int requiredLevel,
    double burnAtRequirement = 0.5,
    int burnStopMargin = 20,
    double minBurnChance = 0.01, // never completely zero
  }) {
    final margin = (level - requiredLevel).clamp(0, burnStopMargin);
    final chance = burnAtRequirement * (1 - margin / burnStopMargin);
    return chance.clamp(minBurnChance, burnAtRequirement);
  }
}
