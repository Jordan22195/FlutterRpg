import '../catalogs/recipe_catalog.dart';
import '../data/skill.dart';
import 'inventory_data.dart';

class CraftingState {
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
