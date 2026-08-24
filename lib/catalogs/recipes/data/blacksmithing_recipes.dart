import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Blacksmithing. Smelting ore into bars, then bars into armour and
/// weapons.
const List<CraftingRecipe> blacksmithingRecipes = [
  // Blacksmithing
  CraftingRecipe(
    id: 'smelt_copper_bar',
    name: 'Copper Bar',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 1,
    xp: 1,
    inputs: {ItemId.COPPER_ORE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_BAR, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_copper_dagger',
    name: 'Copper Dagger',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 1,
    xp: 2,
    inputs: {ItemId.COPPER_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_DAGGER, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_copper_pickaxe',
    name: 'Copper Pickaxe',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 2,
    xp: 2,

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
    xp: 2,

    inputs: {ItemId.COPPER_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_AXE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_copper_helmet',
    name: 'Copper Helmet',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 4,
    xp: 2,
    inputs: {ItemId.COPPER_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_HELMET, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: "forge_copper_gloves",
    name: "Copper Hands",
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 6,
    xp: 2,
    inputs: {ItemId.COPPER_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_GLOVES, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "forge_copper_boots",
    name: "Copper Boots",
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 7,
    xp: 2,
    inputs: {ItemId.COPPER_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_BOOTS, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "forge_copper_legs",
    name: "Copper Legs",
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 8,
    xp: 4,
    inputs: {ItemId.COPPER_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_LEGS, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: "forge_copper_chestplate",
    name: "Copper Chestplate",
    skill: SkillId.BLACKSMITHING,
    xp: 10,
    levelRequirement: 3,
    inputs: {ItemId.COPPER_BAR: 3},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_CHESTPLATE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: "forge_copper_shield",
    name: "Copper Shield",
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 11,
    xp: 4,
    inputs: {ItemId.COPPER_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_SHIELD, count: 1, weight: 1),
    ],
  ),

  // Blacksmithing - jewelry bases
  CraftingRecipe(
    id: 'forge_copper_ring',
    name: 'Copper Ring',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 4,
    xp: 15,
    inputs: {ItemId.COPPER_BAR: 1},
    output: [WeightedDropTableEntry(id: ItemId.GOLD_RING, count: 1, weight: 1)],
  ),
  CraftingRecipe(
    id: 'forge_copper_necklace',
    name: 'Copper Necklace',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 4,
    xp: 20,
    inputs: {ItemId.COPPER_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.GOLD_NECKLACE, count: 1, weight: 1),
    ],
  ),

  // Blacksmithing - iron (tier 2)
  CraftingRecipe(
    id: 'smelt_iron_bar',
    name: 'Iron Bar',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 10,
    xp: 5,
    inputs: {ItemId.IRON_ORE: 1},
    output: [WeightedDropTableEntry(id: ItemId.IRON_BAR, count: 1, weight: 1)],
  ),
  CraftingRecipe(
    id: 'forge_iron_dagger',
    name: 'Iron Dagger',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 10,
    xp: 5,
    inputs: {ItemId.IRON_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_DAGGER, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_iron_pickaxe',
    name: 'Iron Pickaxe',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 11,
    xp: 5,
    inputs: {ItemId.IRON_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_PICKAXE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_iron_axe',
    name: 'Iron Axe',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 11,
    xp: 5,
    inputs: {ItemId.IRON_BAR: 1},
    output: [WeightedDropTableEntry(id: ItemId.IRON_AXE, count: 1, weight: 1)],
  ),
  CraftingRecipe(
    id: 'forge_iron_helmet',
    name: 'Iron Helmet',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 12,
    xp: 5,
    inputs: {ItemId.IRON_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_HELMET, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'forge_iron_gloves',
    name: 'Iron Gloves',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 13,
    xp: 5,
    inputs: {ItemId.IRON_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_GLOVES, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_iron_boots',
    name: 'Iron Boots',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 15,
    xp: 5,
    inputs: {ItemId.IRON_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_BOOTS, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_iron_legs',
    name: 'Iron Leggings',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 17,
    xp: 10,
    inputs: {ItemId.IRON_BAR: 2},
    output: [WeightedDropTableEntry(id: ItemId.IRON_LEGS, count: 1, weight: 1)],
  ),

  CraftingRecipe(
    id: 'forge_iron_chestplate',
    name: 'Iron Chestplate',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 20,
    xp: 15,
    inputs: {ItemId.IRON_BAR: 3},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_CHESTPLATE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_iron_shield',
    name: 'Iron Shield',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 22,
    xp: 10,
    inputs: {ItemId.IRON_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_SHIELD, count: 1, weight: 1),
    ],
  ),
];
