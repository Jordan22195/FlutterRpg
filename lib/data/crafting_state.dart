import '../catalogs/recipe_catalog.dart';
import 'skill_data.dart';
import 'inventory_data.dart';

class CraftingState {
  String selectedRecipeId = "";
  CraftingRecipe activeRecipe = CraftingRecipe(
    id: "null",
    name: "null",
    skill: SkillId.NULL,
    levelRequirement: 1,
    inputs: {},
    output: [],
    xp: 0,
  );

  InventoryData craftedItems = InventoryData(itemMap: {});
}
