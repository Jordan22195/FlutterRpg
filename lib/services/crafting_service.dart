import '../data/skill_data.dart';
import '../data/crafting_state.dart';
import '../catalogs/item_catalog.dart';
import '../catalogs/recipe_catalog.dart';

class CraftingService {
  void adjustActiveRecipeDropTable(
    CraftingRecipe recipe,
    Map<SkillId, int> skillLevels,
  ) {
    final skillLevel = skillLevels[SkillId.COOKING] ?? 1;

    recipe.output.forEach((entry) {
      if (entry.id == ItemId.BURNT_FOOD) {
        final burnChance = calculateBurnChance(
          level: skillLevel,
          difficultyScale: recipe.levelRequirement
              .toDouble(), // Adjust based on recipe difficulty if needed
        );
        entry.weight =
            burnChance; // Higher burnChance means more likely to get burnt food
      }
    });
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
