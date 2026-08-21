import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Firemaking. Fire types across the log tiers: cookfires are cheap
/// and open cooking, campfires and bonfires cost more logs for a bigger
/// combat buff.
const List<CraftingRecipe> firemakingRecipes = [
  // Firemaking. three fire types across two log tiers: cookfires are cheap
  // and open cooking, campfires and bonfires cost more logs for a bigger
  // combat buff. the 'basic_campfire' and 'oak_campfire' ids are kept from
  // the original two recipes so saved recipe selections stay valid.
  CraftingRecipe(
    id: 'cookfire',
    name: 'Cookfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 1,
    xp: 15,
    inputs: {ItemId.LOGS: 2},
    output: [WeightedDropTableEntry(id: ItemId.COOKFIRE, count: 1, weight: 1)],
  ),

  CraftingRecipe(
    id: 'basic_campfire',
    name: 'Campfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 5,
    xp: 40,
    inputs: {ItemId.LOGS: 5},
    output: [
      WeightedDropTableEntry(id: ItemId.BASIC_CAMPFIRE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'bonfire',
    name: 'Bonfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 15,
    xp: 130,
    inputs: {ItemId.LOGS: 15},
    output: [WeightedDropTableEntry(id: ItemId.BONFIRE, count: 1, weight: 1)],
  ),

  CraftingRecipe(
    id: 'oak_cookfire',
    name: 'Oak Cookfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 20,
    xp: 45,
    inputs: {ItemId.OAK_LOGS: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.OAK_COOKFIRE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'oak_campfire',
    name: 'Oak Campfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 25,
    xp: 110,
    inputs: {ItemId.OAK_LOGS: 5},
    output: [
      WeightedDropTableEntry(id: ItemId.OAK_CAMPFIRE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'oak_bonfire',
    name: 'Oak Bonfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 35,
    xp: 340,
    inputs: {ItemId.OAK_LOGS: 15},
    output: [
      WeightedDropTableEntry(id: ItemId.OAK_BONFIRE, count: 1, weight: 1),
    ],
  ),
];
