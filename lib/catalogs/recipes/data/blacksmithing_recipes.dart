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
    id: 'forge_copper_sickle',
    name: 'Copper Sickle',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 2,
    xp: 2,
    inputs: {ItemId.COPPER_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COPPER_SICKLE, count: 1, weight: 1),
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
    id: 'forge_iron_sickle',
    name: 'Iron Sickle',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 11,
    xp: 5,
    inputs: {ItemId.IRON_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.IRON_SICKLE, count: 1, weight: 1),
    ],
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

  // ── STEEL (tier 3) ──────────────────────────────────────────────
  // Steel is an alloy, so its bar is the one that takes two inputs: coal off
  // the tier 3 vein plus iron ORE, not an iron bar. Smelting the iron first
  // would make steel cost a second trip through the furnace for nothing —
  // ore and coal go in together, the way the iron bar's own recipe works.
  // Gear levels are the iron spread shifted up a tier, and the bar counts
  // per piece are unchanged.
  CraftingRecipe(
    id: 'smelt_steel_bar',
    name: 'Steel Bar',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 20,
    xp: 3,
    inputs: {ItemId.COAL: 1, ItemId.IRON_ORE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_BAR, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_dagger',
    name: 'Steel Dagger',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 20,
    xp: 5,
    inputs: {ItemId.STEEL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_DAGGER, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_pickaxe',
    name: 'Steel Pickaxe',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 21,
    xp: 5,
    inputs: {ItemId.STEEL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_PICKAXE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_axe',
    name: 'Steel Axe',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 21,
    xp: 5,
    inputs: {ItemId.STEEL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_AXE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_helmet',
    name: 'Steel Helmet',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 22,
    xp: 5,
    inputs: {ItemId.STEEL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_HELMET, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_gloves',
    name: 'Steel Gloves',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 23,
    xp: 5,
    inputs: {ItemId.STEEL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_GLOVES, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_sickle',
    name: 'Steel Sickle',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 21,
    xp: 5,
    inputs: {ItemId.STEEL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_SICKLE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_boots',
    name: 'Steel Boots',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 25,
    xp: 5,
    inputs: {ItemId.STEEL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_BOOTS, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_legs',
    name: 'Steel Legs',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 27,
    xp: 10,
    inputs: {ItemId.STEEL_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_LEGS, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_chestplate',
    name: 'Steel Chestplate',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 30,
    xp: 15,
    inputs: {ItemId.STEEL_BAR: 3},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_CHESTPLATE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_steel_shield',
    name: 'Steel Shield',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 32,
    xp: 10,
    inputs: {ItemId.STEEL_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.STEEL_SHIELD, count: 1, weight: 1),
    ],
  ),

  // ── GOLD (tier 3, jewellery line) ───────────────────────────────
  // Gold is too soft for armour: its bar exists to be turned into ring and
  // necklace bases by Jewelcrafting, not forged into gear here.
  CraftingRecipe(
    id: 'smelt_gold_bar',
    name: 'Gold Bar',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 25,
    xp: 4,
    inputs: {ItemId.GOLD_ORE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.GOLD_BAR, count: 1, weight: 1),
    ],
  ),

  // ── MITHRIL (tier 4) ────────────────────────────────────────────
  // Like steel, mithril is smelted with coal rather than from a bar of
  // something else — ore and coal go in together, so the tier costs one
  // trip through the furnace and not two. Two coal to steel's one, so a
  // tier 4 bar is dearer than the tier 3 one. Gear levels are the steel
  // spread shifted up a tier; bar counts per piece are unchanged.
  CraftingRecipe(
    id: 'smelt_mithril_bar',
    name: 'Mithril Bar',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 40,
    xp: 8,
    inputs: {ItemId.COAL: 2, ItemId.MITHRIL_ORE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_BAR, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_dagger',
    name: 'Mithril Dagger',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 40,
    xp: 10,
    inputs: {ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_DAGGER, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_pickaxe',
    name: 'Mithril Pickaxe',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 41,
    xp: 10,
    inputs: {ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_PICKAXE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_axe',
    name: 'Mithril Axe',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 41,
    xp: 10,
    inputs: {ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_AXE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_sickle',
    name: 'Mithril Sickle',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 41,
    xp: 10,
    inputs: {ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_SICKLE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_helmet',
    name: 'Mithril Helmet',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 42,
    xp: 10,
    inputs: {ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_HELMET, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_gloves',
    name: 'Mithril Gloves',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 43,
    xp: 10,
    inputs: {ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_GLOVES, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_boots',
    name: 'Mithril Boots',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 45,
    xp: 10,
    inputs: {ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_BOOTS, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_legs',
    name: 'Mithril Leggings',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 47,
    xp: 20,
    inputs: {ItemId.MITHRIL_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_LEGS, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_chestplate',
    name: 'Mithril Chestplate',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 50,
    xp: 30,
    inputs: {ItemId.MITHRIL_BAR: 3},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_CHESTPLATE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'forge_mithril_shield',
    name: 'Mithril Shield',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 52,
    xp: 20,
    inputs: {ItemId.MITHRIL_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.MITHRIL_SHIELD, count: 1, weight: 1),
    ],
  ),
];
