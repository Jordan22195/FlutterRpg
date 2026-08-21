import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/recipes/data/blacksmithing_recipes.dart';
import 'package:rpg/catalogs/recipes/data/cooking_recipes.dart';
import 'package:rpg/catalogs/recipes/data/firemaking_recipes.dart';
import 'package:rpg/catalogs/recipes/data/jewelcrafting_recipes.dart';

class RecipeCatalog {
  /// Every recipe, in skill order. The per-skill lists are the content;
  /// this is just their concatenation.
  static const List<CraftingRecipe> _recipes = [
    ...firemakingRecipes,
    ...cookingRecipes,
    ...blacksmithingRecipes,
    ...jewelcraftingRecipes,
  ];

  List<CraftingRecipe> get recipes => List.unmodifiable(_recipes);

  List<CraftingRecipe> recipesForSkill(SkillId skill) {
    return _recipes.where((r) => r.skill == skill).toList();
  }

  CraftingRecipe recipeById(String recipeId) {
    try {
      return _recipes.firstWhere((r) => r.id == recipeId);
    } catch (_) {
      return CraftingRecipe(
        id: "id",
        name: "name",
        skill: SkillId.NULL,
        levelRequirement: 0,
        inputs: {},
        output: [],
        xp: 0,
      );
    }
  }
}
