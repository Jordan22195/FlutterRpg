import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Jewelcrafting. Bars into bases, then bases plus gems into jewellery.
const List<CraftingRecipe> jewelcraftingRecipes = [
  // The bases. Every gem recipe below consumes one of these, so they sit at
  // level 1 — the gem is what gates a piece, not the band it goes into.
  // These replace the old 'forge_copper_ring'/'forge_copper_necklace', which
  // were Blacksmithing recipes taking copper bars and named for copper while
  // quietly outputting the gold bases.
  CraftingRecipe(
    id: 'jc_gold_ring',
    name: 'Gold Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 1,
    xp: 15,
    inputs: {ItemId.GOLD_BAR: 1},
    output: [WeightedDropTableEntry(id: ItemId.GOLD_RING, count: 1, weight: 1)],
  ),
  CraftingRecipe(
    id: 'jc_gold_necklace',
    name: 'Gold Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 1,
    xp: 20,
    inputs: {ItemId.GOLD_BAR: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.GOLD_NECKLACE, count: 1, weight: 1),
    ],
  ),

  // Jewelcrafting: set a gem into a ring or necklace base.
  // gem tiers gate the level requirement, runescape style
  CraftingRecipe(
    id: 'jc_topaz_ring',
    name: 'Topaz Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 1,
    xp: 20,
    inputs: {ItemId.TOPAZ: 1, ItemId.GOLD_RING: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.TOPAZ_RING, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_topaz_necklace',
    name: 'Topaz Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 1,
    xp: 25,
    inputs: {ItemId.TOPAZ: 1, ItemId.GOLD_NECKLACE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.TOPAZ_NECKLACE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_sapphire_ring',
    name: 'Sapphire Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 5,
    xp: 30,
    inputs: {ItemId.SAPPHIRE: 1, ItemId.GOLD_RING: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.SAPPHIRE_RING, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_sapphire_necklace',
    name: 'Sapphire Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 5,
    xp: 35,
    inputs: {ItemId.SAPPHIRE: 1, ItemId.GOLD_NECKLACE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.SAPPHIRE_NECKLACE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_emerald_ring',
    name: 'Emerald Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 10,
    xp: 40,
    inputs: {ItemId.EMERALD: 1, ItemId.GOLD_RING: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.EMERALD_RING, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_emerald_necklace',
    name: 'Emerald Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 10,
    xp: 45,
    inputs: {ItemId.EMERALD: 1, ItemId.GOLD_NECKLACE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.EMERALD_NECKLACE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_ruby_ring',
    name: 'Ruby Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 15,
    xp: 50,
    inputs: {ItemId.RUBY: 1, ItemId.GOLD_RING: 1},
    output: [WeightedDropTableEntry(id: ItemId.RUBY_RING, count: 1, weight: 1)],
  ),
  CraftingRecipe(
    id: 'jc_ruby_necklace',
    name: 'Ruby Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 15,
    xp: 55,
    inputs: {ItemId.RUBY: 1, ItemId.GOLD_NECKLACE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.RUBY_NECKLACE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_diamond_ring',
    name: 'Diamond Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 20,
    xp: 65,
    inputs: {ItemId.DIAMOND: 1, ItemId.GOLD_RING: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.DIAMOND_RING, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_diamond_necklace',
    name: 'Diamond Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 20,
    xp: 70,
    inputs: {ItemId.DIAMOND: 1, ItemId.GOLD_NECKLACE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.DIAMOND_NECKLACE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_dragonstone_ring',
    name: 'Dragonstone Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 25,
    xp: 80,
    inputs: {ItemId.DRAGONSTONE: 1, ItemId.GOLD_RING: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.DRAGONSTONE_RING, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'jc_dragonstone_necklace',
    name: 'Dragonstone Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 25,
    xp: 85,
    inputs: {ItemId.DRAGONSTONE: 1, ItemId.GOLD_NECKLACE: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.DRAGONSTONE_NECKLACE,
        count: 1,
        weight: 1,
      ),
    ],
  ),
  CraftingRecipe(
    id: 'jc_onyx_ring',
    name: 'Onyx Ring',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 30,
    xp: 100,
    inputs: {ItemId.ONYX: 1, ItemId.GOLD_RING: 1},
    output: [WeightedDropTableEntry(id: ItemId.ONYX_RING, count: 1, weight: 1)],
  ),
  CraftingRecipe(
    id: 'jc_onyx_necklace',
    name: 'Onyx Necklace',
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: 30,
    xp: 110,
    inputs: {ItemId.ONYX: 1, ItemId.GOLD_NECKLACE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.ONYX_NECKLACE, count: 1, weight: 1),
    ],
  ),
];
