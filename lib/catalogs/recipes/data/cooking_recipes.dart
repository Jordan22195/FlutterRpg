import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Cooking. One recipe per raw food; the BURNT_FOOD entry in each
/// output table is reweighted per craft against the player's cooking level.
///
/// A fish cooks at the Fishing level that catches it, so whatever the line
/// brings in, the fire can take; the meats sit at the level of the creature
/// that drops them.
const List<CraftingRecipe> cookingRecipes = [
  // Each fish pays a little more than the one before it, paced so 1 to 99
  // takes about thirty days of three-second cooks with no speed boost. The
  // early fish pay more of their level's xp, so the first stretches stay
  // short, and the crayfish at 7 and sturgeon at 70 split what were long
  // waits on one fish. Meat sits with the fish that open at its level.
  // Cooking
  CraftingRecipe(
    id: 'cook_chicken',
    name: 'Cooked Chicken',
    skill: SkillId.COOKING,
    levelRequirement: 1,
    xp: 3,
    inputs: {ItemId.CHICKEN_MEAT: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_CHICKEN, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'cook_beef',
    name: 'Cooked Beef',
    skill: SkillId.COOKING,
    levelRequirement: 5,
    xp: 3,
    inputs: {ItemId.COW_MEAT: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_BEEF, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'cook_minnow',
    name: 'Cooked Meat',
    skill: SkillId.COOKING,
    levelRequirement: 1,
    xp: 2,

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
    levelRequirement: 5,
    xp: 3,
    inputs: {ItemId.CARP: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_CARP, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_crayfish",
    name: "Cooked Crayfish",
    skill: SkillId.COOKING,
    levelRequirement: 7,
    xp: 3.5,
    inputs: {ItemId.CRAYFISH: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_CRAYFISH, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_bluegill",
    name: "Cooked Bluegill",
    skill: SkillId.COOKING,
    levelRequirement: 10,
    xp: 4,
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
    levelRequirement: 15,
    xp: 5,
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
    levelRequirement: 20,
    xp: 5.5,
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
    levelRequirement: 35,
    xp: 6,
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
    levelRequirement: 45,
    xp: 6.2,
    inputs: {ItemId.CATFISH: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_CATFISH, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_bass",
    name: "Cooked Bass",
    skill: SkillId.COOKING,
    levelRequirement: 55,
    xp: 7.9,
    inputs: {ItemId.BASS: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_BASS, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_whitefish",
    name: "Cooked Whitefish",
    skill: SkillId.COOKING,
    levelRequirement: 60,
    xp: 9.6,
    inputs: {ItemId.WHITEFISH: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_WHITEFISH, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_sturgeon",
    name: "Cooked Sturgeon",
    skill: SkillId.COOKING,
    levelRequirement: 70,
    xp: 11,
    inputs: {ItemId.STURGEON: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_STURGEON, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "cook_tuna",
    name: "Cooked Tuna",
    skill: SkillId.COOKING,
    levelRequirement: 80,
    xp: 12,
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
    levelRequirement: 86,
    xp: 15.4,
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
    levelRequirement: 93,
    xp: 20.6,
    inputs: {ItemId.SHARK: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKED_SHARK, count: 1, weight: 1),
      WeightedDropTableEntry(id: ItemId.BURNT_FOOD, count: 1, weight: 1),
    ],
  ),
];
