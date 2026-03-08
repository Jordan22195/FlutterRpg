class CraftingService {
  void adjustActiveRecipeDropTable(
    CraftingState craftinState,
    Map<SkillId, int> skillLevels,
  ) {
    final skillLevel = skillLevels[SkillId.COOKING] ?? 1;

    final recipe = craftinState.activeRecipe;
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
    craftingState.activeRecipe = catalog.recipeById(recipeId);
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
