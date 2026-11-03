import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Alchemy. A herb and a reagent into a potion: the herb sets the tier,
/// the reagent picks the stat.
const List<CraftingRecipe> alchemyRecipes = [
  // The minor tier, all off guam leaf. Level 1 is the three whose reagents
  // already drop (feathers off chickens, minnows off the pond, iron off a
  // vein), so alchemy is
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
      WeightedDropTableEntry(
        id: ItemId.MINOR_SPEED_POTION,
        count: 1,
        weight: 1,
      ),
    ],
  ),
  CraftingRecipe(
    id: 'alch_minor_fishing_potion',
    name: 'Minor Fishing Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 1,
    xp: 15,
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.MINNOW: 1},
    output: [
      WeightedDropTableEntry(
        id: ItemId.MINOR_FISHING_POTION,
        count: 1,
        weight: 1,
      ),
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
    inputs: {ItemId.GUAM_LEAF: 1, ItemId.RAT_TAIL: 1},
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
  // The first tier above minor: harralander in place of guam leaf, with the
  // reagent that has no other use.
  CraftingRecipe(
    id: 'alch_recovery_potion',
    name: 'Recovery Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 15,
    xp: 80,
    inputs: {ItemId.HARRALANDER: 1, ItemId.GRAVE_MOSS: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.RECOVERY_POTION, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'alch_speed_potion',
    name: 'Speed Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 15,
    xp: 70,
    inputs: {ItemId.HARRALANDER: 1, ItemId.BAT_WING: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.SPEED_POTION, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'alch_attack_potion',
    name: 'Attack Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 20,
    xp: 100,
    inputs: {ItemId.HARRALANDER: 1, ItemId.FANG: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.ATTACK_POTION, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'alch_strength_potion',
    name: 'Strength Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 20,
    xp: 110,
    inputs: {ItemId.HARRALANDER: 1, ItemId.BAT_FANG: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STRENGTH_POTION, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'alch_fishing_potion',
    name: 'Fishing Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 15,
    xp: 75,
    inputs: {ItemId.HARRALANDER: 1, ItemId.CRAYFISH: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.FISHING_POTION, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'alch_defence_potion',
    name: 'Defence Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 15,
    xp: 85,
    inputs: {ItemId.HARRALANDER: 1, ItemId.IRON_BAR: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.DEFENCE_POTION, count: 1, weight: 1),
    ],
  ),
  CraftingRecipe(
    id: 'alch_stamina_potion',
    name: 'Stamina Potion',
    skill: SkillId.ALCHEMY,
    levelRequirement: 15,
    xp: 90,
    inputs: {ItemId.HARRALANDER: 1, ItemId.SLIME_OOZE: 1},
    output: [
      WeightedDropTableEntry(id: ItemId.STAMINA_POTION, count: 1, weight: 1),
    ],
  ),
];
