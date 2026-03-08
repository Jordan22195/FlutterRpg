import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/skill_data.dart';

/// A single crafting recipe (inputs -> output) gated by a skill level requirement.
class CraftingRecipe {
  const CraftingRecipe({
    required this.id,
    required this.name,
    required this.skill,
    required this.levelRequirement,
    required this.inputs,
    required this.output,
    required this.xp,
  });

  final double xp;
  final String id;
  final String name;
  final SkillId skill;
  final int levelRequirement;

  /// Required inputs per craft, e.g. {Items.COPPER_ORE: 1}
  final Map<ItemId, int> inputs;

  /// Output stack per craft, e.g. ObjectStack(id: Items.COPPER_BAR, count: 1)
  final List<WeightedDropTableEntry> output;
}

class RecipeCatalog {
  // --- Recipes (start with blacksmithing examples) ---
  final List<CraftingRecipe> _recipes = [
    // Firemaking
    CraftingRecipe(
      id: 'basic_campfire',
      name: 'Basic Campfire',
      skill: SkillId.FIREMAKING,
      levelRequirement: 1,
      xp: 10,
      inputs: {ItemId.LOGS: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.BASIC_CAMPFIRE, count: 1, weight: 1),
      ],
    ),

    // Cooking
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
        WeightedDropTableEntry(
          id: ItemId.COOKED_WHITEFISH,
          count: 1,
          weight: 1,
        ),
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
        WeightedDropTableEntry(
          id: ItemId.COOKED_SWORDFISH,
          count: 1,
          weight: 1,
        ),
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

    // Blacksmithing
    CraftingRecipe(
      id: 'smelt_copper_bar',
      name: 'Copper Bar',
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 1,
      xp: 5,
      inputs: {ItemId.COPPER_ORE: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_BAR, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: 'forge_copper_dagger',
      name: 'Copper Dagger',
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 2,
      xp: 10,
      inputs: {ItemId.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_DAGGER, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: 'forge_copper_helmet',
      name: 'Copper Helmet',
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 2,
      xp: 12,
      inputs: {ItemId.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_HELMET, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: 'forge_copper_pickaxe',
      name: 'Copper Dagger',
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 2,
      xp: 15,

      inputs: {ItemId.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_PICKAXE, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_axe",
      name: "Copper Axe",
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 2,
      xp: 28,

      inputs: {ItemId.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_AXE, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_gloves",
      name: "Copper Hands",
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 3,
      xp: 20,
      inputs: {ItemId.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_GLOVES, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_legs",
      name: "Copper Legs",
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 3,
      xp: 22,
      inputs: {ItemId.COPPER_BAR: 2},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_LEGS, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_chestplate",
      name: "Copper Chestplate",
      skill: SkillId.BLACKSMITHING,
      xp: 30,
      levelRequirement: 3,
      inputs: {ItemId.COPPER_BAR: 3},
      output: [
        WeightedDropTableEntry(
          id: ItemId.COPPER_CHESTPLATE,
          count: 1,
          weight: 1,
        ),
      ],
    ),

    CraftingRecipe(
      id: "forge_copper_boots",
      name: "Copper Boots",
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 3,
      xp: 20,
      inputs: {ItemId.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_BOOTS, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_shield",
      name: "Copper Shield",
      skill: SkillId.BLACKSMITHING,
      levelRequirement: 3,
      xp: 25,
      inputs: {ItemId.COPPER_BAR: 2},
      output: [
        WeightedDropTableEntry(id: ItemId.COPPER_SHIELD, count: 1, weight: 1),
      ],
    ),
  ];

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
