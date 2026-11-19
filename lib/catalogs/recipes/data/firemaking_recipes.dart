import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Firemaking. Burning logs is the grind: these recipes are where
/// Firemaking's xp comes from.
///
/// - a cookfire is two logs, and opens cooking.
/// - a bonfire is five logs and one fire reagent, and carries the reagent's
///   stat at the wood's power (see FireItemDefinition). Every wood has one
///   per reagent. It asks for its wood's level or the reagent's, whichever
///   is higher, and pays its wood's xp plus the reagent's level.
final List<CraftingRecipe> firemakingRecipes = [
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
    id: 'maple_cookfire',
    name: 'Maple Cookfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 60,
    xp: 405,
    inputs: {ItemId.MAPLE_LOGS: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.MAPLE_COOKFIRE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'yew_cookfire',
    name: 'Yew Cookfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 72,
    xp: 1215,
    inputs: {ItemId.YEW_LOGS: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.YEW_COOKFIRE, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'magic_cookfire',
    name: 'Magic Cookfire',
    skill: SkillId.FIREMAKING,
    levelRequirement: 84,
    xp: 3645,
    inputs: {ItemId.MAGIC_LOGS: 2},
    output: [
      WeightedDropTableEntry(id: ItemId.MAGIC_COOKFIRE, count: 1, weight: 1),
    ],
  ),

  for (final id in ItemId.values)
    if (id.definition case FireItemDefinition(:final wood?, :final reagent?))
      _bonfireRecipe(id, wood, reagent),
];

/// The logs one bonfire takes, whatever the wood.
const int bonfireLogs = 5;

/// Each wood's bonfire level and xp: those of the campfire each wood laid
/// before a bonfire was one recipe per reagent.
const Map<ItemId, ({int level, double xp})> bonfireWoods = {
  ItemId.LOGS: (level: 5, xp: 40),
  ItemId.OAK_LOGS: (level: 25, xp: 110),
  ItemId.WILLOW_LOGS: (level: 45, xp: 330),
  ItemId.BOG_LOGS: (level: 45, xp: 330),
  ItemId.MAPLE_LOGS: (level: 64, xp: 990),
  ItemId.YEW_LOGS: (level: 76, xp: 2970),
  ItemId.MAGIC_LOGS: (level: 88, xp: 8910),
};

CraftingRecipe _bonfireRecipe(ItemId fire, ItemId wood, ItemId reagent) {
  final tier = bonfireWoods[wood]!;
  final reagentDef = reagent.definition as FireReagentDefinition;
  final reagentLevel = reagentDef.levelRequirement;
  return CraftingRecipe(
    id: fire.name.toLowerCase(),
    name: fire.definition.name,
    skill: SkillId.FIREMAKING,
    levelRequirement: reagentLevel > tier.level ? reagentLevel : tier.level,
    xp: tier.xp + reagentLevel,
    inputs: {wood: bonfireLogs, reagent: 1},
    output: [WeightedDropTableEntry(id: fire, count: 1, weight: 1)],
  );
}
