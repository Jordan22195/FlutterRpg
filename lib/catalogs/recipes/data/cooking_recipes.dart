import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Cooking. One recipe per raw food; the BURNT_FOOD entry in each
/// output table is reweighted per craft against the player's cooking level.
const List<CraftingRecipe> cookingRecipes = [
  // Cooking
  CraftingRecipe(
    id: 'cook_chicken',
    name: 'Cooked Chicken',
    skill: SkillId.COOKING,
    levelRequirement: 1,
    xp: 10,
    inputs: {ItemId.CHICKEN_MEAT: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_CHICKEN, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'cook_minnow',
    name: 'Cooked Meat',
    skill: SkillId.COOKING,
    levelRequirement: 1,
    xp: 10,

    inputs: {ItemId.MINNOW: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_MINNOW, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_carp",
    name: "Cooked Carp",
    skill: SkillId.COOKING,
    levelRequirement: 2,
    xp: 15,
    inputs: {ItemId.CARP: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_CARP, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_bluegill",
    name: "Cooked Bluegill",
    skill: SkillId.COOKING,
    levelRequirement: 3,
    xp: 20,
    inputs: {ItemId.BLUEGILL: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_BLUEGILL, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_trout",
    name: "Cooked Trout",
    skill: SkillId.COOKING,
    levelRequirement: 4,
    xp: 25,
    inputs: {ItemId.TROUT: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_TROUT, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_pike",
    name: "Cooked Pike",
    skill: SkillId.COOKING,
    levelRequirement: 5,
    xp: 30,
    inputs: {ItemId.PIKE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_PIKE, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_salmon",
    name: "Cooked Salmon",
    skill: SkillId.COOKING,
    levelRequirement: 6,
    xp: 35,
    inputs: {ItemId.SALMON: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_SALMON, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_catfish",
    name: "Cooked Catfish",
    skill: SkillId.COOKING,
    levelRequirement: 7,
    xp: 40,
    inputs: {ItemId.CATFISH: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_CATFISH, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_whitefish",
    name: "Cooked Whitefish",
    skill: SkillId.COOKING,
    levelRequirement: 8,
    xp: 45,
    inputs: {ItemId.WHITEFISH: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_WHITEFISH, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_tuna",
    name: "Cooked Tuna",
    skill: SkillId.COOKING,
    levelRequirement: 9,
    xp: 50,
    inputs: {ItemId.TUNA: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_TUNA, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_swordfish",
    name: "Cooked Swordfish",
    skill: SkillId.COOKING,
    levelRequirement: 10,
    xp: 55,
    inputs: {ItemId.SWORDFISH: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_SWORDFISH, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_shark",
    name: "Cooked Shark",
    skill: SkillId.COOKING,
    levelRequirement: 11,
    xp: 60,
    inputs: {ItemId.SHARK: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_SHARK, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
];
