import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Firemaking. Fire types across the log tiers: cookfires are cheap and
/// open cooking; campfires and bonfires cost more logs and burn reagents for
/// their buffs (see FireReagentDefinition). Burning logs is the grind: these
/// recipes are where Firemaking's xp comes from.
/// Throwing a fire reagent on a lit campfire or bonfire: one per reagent,
/// run off the action button like a cooking recipe. Each buffs the
/// reagent's stat by the fire's power for the fire's reagent burn, and pays
/// the reagent's unlock level in xp (5 / 8 / 13).
final List<CraftingRecipe> fireReagentRecipes = [
  // the firepit's picked reagents, all thrown at once: what the action
  // button runs, its costs and xp the reagents' own
  const CraftingRecipe(
    id: reagentMixRecipeId,
    name: 'Kindling',
    skill: SkillId.FIREMAKING,
    levelRequirement: 1,
    inputs: {},
    output: [],
    xp: 0,
  ),
  for (final id in ItemId.values)
    if (id.definition case final FireReagentDefinition def)
      CraftingRecipe(
        id: 'tend_${id.name.toLowerCase()}',
        name: def.name,
        skill: SkillId.FIREMAKING,
        levelRequirement: def.levelRequirement,
        xp: def.levelRequirement.toDouble(),
        inputs: {id: 1},
        output: [WeightedDropTableEntry(id: id, count: 1, weight: 1)],
      ),
];

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

  // Willow (tier 3). Same log counts as the oak tier — the step up is in
  // what the fire is worth and how long it burns, not what it costs to lay.
  CraftingRecipe(
    id: 'willow_cookfire',
    name: 'Willow Cookfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 40,
    xp: 135,
    inputs: {ItemId.WILLOW_LOGS: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.WILLOW_COOKFIRE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'willow_campfire',
    name: 'Willow Campfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 45,
    xp: 330,
    inputs: {ItemId.WILLOW_LOGS: 5},
    output: [
      WeightedDropTableEntry(id: ItemId.WILLOW_CAMPFIRE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'willow_bonfire',
    name: 'Willow Bonfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 55,
    xp: 1020,
    inputs: {ItemId.WILLOW_LOGS: 15},
    output: [
      WeightedDropTableEntry(id: ItemId.WILLOW_BONFIRE, count: 1, weight: 1),
    ],
  ),

  // Bog (willow's side-grade). The same levels and log counts as willow:
  // the difference is in the fire, not what it costs to lay.
  CraftingRecipe(
    id: 'bog_cookfire',
    name: 'Bog Cookfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 40,
    xp: 135,
    inputs: {ItemId.BOG_LOGS: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.BOG_COOKFIRE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'bog_campfire',
    name: 'Bog Campfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 45,
    xp: 330,
    inputs: {ItemId.BOG_LOGS: 5},
    output: [
      WeightedDropTableEntry(id: ItemId.BOG_CAMPFIRE, count: 1, weight: 1),
    ],
  ),

  CraftingRecipe(
    id: 'bog_bonfire',
    name: 'Bog Bonfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 55,
    xp: 1020,
    inputs: {ItemId.BOG_LOGS: 15},
    output: [
      WeightedDropTableEntry(id: ItemId.BOG_BONFIRE, count: 1, weight: 1),
    ],
  ),
];
