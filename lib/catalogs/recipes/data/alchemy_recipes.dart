import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Alchemy. A herb and a reagent into a potion: the herb sets the tier, the
/// reagent's family picks the skill. A potion has no rarity, so every brew
/// rolls the crafting quality table and pays a good roll out in extra
/// potions, the way a smelt pays extra bars. design/ALCHEMY_POTIONS.md is
/// the whole design.
final List<CraftingRecipe> alchemyRecipes = [
  // the ladder, one recipe per potion, derived from its PotionDefinition
  for (final id in ItemId.values)
    if (id.definition case final PotionDefinition def) _brew(id, def),
  ..._craftingPotionRecipes,
];

/// A ladder potion's recipe id: `alch_` and the item id, which is what every
/// potion's recipe was called before the ladder, so a saved bound action
/// keeps pointing at the same brew.
String alchemyRecipeId(ItemId potion) => 'alch_${potion.name.toLowerCase()}';

CraftingRecipe _brew(ItemId id, PotionDefinition def) => CraftingRecipe(
  id: alchemyRecipeId(id),
  name: def.name,
  skill: SkillId.ALCHEMY,
  levelRequirement: def.levelRequirement,
  xp: def.brewXp.toDouble(),
  inputs: {def.herb: 1, def.reagent: 1},
  output: [WeightedDropTableEntry(id: id, count: 1, weight: 1)],
  rollsBonusOutput: true,
);

/// The crafting-skill potions brewed before the ladder. Crafting potions are
/// held off until each crafting skill has its own reagent; until then these
/// keep their old reagent and brew from their tier's core herb.
const List<CraftingRecipe> _craftingPotionRecipes = [
  CraftingRecipe(
    id: 'alch_minor_cooking_potion',
    name: 'Minor Cooking Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 5,
    xp: 30,
    inputs: {ItemId.MEADOWSWEET: 1, ItemId.LILY_PAD: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.MINOR_COOKING_POTION,
        count: 1,
        weight: 1,
      ),
    ],
    rollsBonusOutput: true,
  ),
  CraftingRecipe(
    id: 'alch_cooking_potion',
    name: 'Cooking Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 20,
    xp: 110,
    inputs: {ItemId.REEDMINT: 1, ItemId.FRESHWATER_MUSSEL: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.COOKING_POTION, count: 1, weight: 1),
    ],
    rollsBonusOutput: true,
  ),
  CraftingRecipe(
    id: 'alch_smiths_potion',
    name: "Smith's Potion",
    skill: SkillId.ALCHEMY,
    levelRequirement: 32,
    xp: 160,
    inputs: {ItemId.SILT_LILY: 1, ItemId.MITHRIL_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.SMITHS_POTION, count: 1, weight: 1),
    ],
    rollsBonusOutput: true,
  ),
  CraftingRecipe(
    id: 'alch_alchemists_potion',
    name: "Alchemist's Potion",
    skill: SkillId.ALCHEMY,
    levelRequirement: 32,
    xp: 160,
    inputs: {ItemId.SILT_LILY: 1, ItemId.VENOM_GLAND: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.ALCHEMISTS_POTION, count: 1, weight: 1),
    ],
    rollsBonusOutput: true,
  ),
];
