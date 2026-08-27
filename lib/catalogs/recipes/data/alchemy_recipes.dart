import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Alchemy. A herb and a reagent into a potion: the herb sets the tier,
/// the reagent picks the stat.
const List<CraftingRecipe> alchemyRecipes = [
  // The minor tier, all off guam leaf. Level 1 is the pair whose reagents
  // already drop (feathers off chickens, iron off a vein), so alchemy is
  // trainable from a fresh save; the tiers above wait on reagents that
  // have no source yet.
  CraftingRecipe(
    id: 'alch_minor_speed_potion',
    name: 'Minor Speed Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 1,
    xp: 15,
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.FEATHER: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.MINOR_SPEED_POTION, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'alch_minor_defence_potion',
    name: 'Minor Defence Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 1,
    xp: 20,
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.IRON_ORE: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.MINOR_DEFENCE_POTION,
        count: 1,
        weight: 1,
      ),
    ],
  ),
  CraftingRecipe(
    id: 'alch_minor_stamina_potion',
    name: 'Minor Stamina Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 5,
    xp: 30,
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.SCALE: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.MINOR_STAMINA_POTION,
        count: 1,
        weight: 1,
      ),
    ],
  ),
  CraftingRecipe(
    id: 'alch_minor_recovery_potion',
    name: 'Minor Recovery Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 5,
    xp: 35,
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.SILK: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.MINOR_RECOVERY_POTION,
        count: 1,
        weight: 1,
      ),
    ],
  ),
  CraftingRecipe(
    id: 'alch_minor_attack_potion',
    name: 'Minor Attack Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 10,
    xp: 50,
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.VENOM: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.MINOR_ATTACK_POTION,
        count: 1,
        weight: 1,
      ),
    ],
  ),
  CraftingRecipe(
    id: 'alch_minor_strength_potion',
    name: 'Minor Strength Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 10,
    xp: 60,
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.CLAW: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.MINOR_STRENGTH_POTION,
        count: 1,
        weight: 1,
      ),
    ],
  ),
];
