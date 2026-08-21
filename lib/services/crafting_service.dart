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

    return [
      for (final entry in recipe.output)
        if (entry.id == ItemId.BURNT_FOOD)
          entry.copyWith(
            // Higher burnChance means more likely to get burnt food.
            weight: calculateBurnChance(
              level: skillLevel,
              difficultyScale: recipe.levelRequirement.toDouble(),
            ),
          )
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

  double calculateBurnChance({
    required int level,
    required double difficultyScale,
    double baseBurnChance = 0.6, // 60% burn at lvl 1 for difficultyScale=1
    double slope = 0.05, // how fast skill reduces burn
    double minBurnChance = 0.01, // never completely zero (optional)
  }) {
    final raw = baseBurnChance * difficultyScale / (1 + level * slope);
    return raw.clamp(minBurnChance, 1.0);
  }
}
