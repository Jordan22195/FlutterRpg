import 'dart:math';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Jewelcrafting: a gem set into a gold base. The bases themselves are
/// forged by Blacksmithing (`forge_gold_ring`, `forge_gold_necklace`).
final List<CraftingRecipe> jewelcraftingRecipes = [
  // Set a gem into a gold base: one recipe per jewellery id, so every
  // gem x cut x setting is its own entry in the recipe picker.
  for (final id in ItemId.values)
    if (id.definition case final JewelleryDefinition def) _setGem(id, def),
];

/// XP for setting a gem at [level]: doubles every 14 levels where the xp
/// table doubles every 7, so the crafts each level asks for climb gently
/// rather than exploding. Ring and necklace pay the same; the gold base
/// they are set into pays its own.
double jewelcraftingXpAt(int level) =>
    (20 * pow(2, level / 14)).roundToDouble();

/// The recipe id for a piece. Round cuts keep the ids the gem recipes had
/// before cuts existed (`jc_ruby_ring`), because a saved bound action holds
/// the id and an unknown one loses the binding.
String jewelcraftingRecipeId(JewelleryDefinition def) {
  final gem = def.gem.name.toLowerCase();
  final setting = def.setting.name.toLowerCase();
  if (def.cut == GemCut.ROUND) return 'jc_${gem}_$setting';
  return 'jc_${gem}_${def.cut.name.toLowerCase()}_$setting';
}

CraftingRecipe _setGem(ItemId id, JewelleryDefinition def) {
  final level = def.gem.levelFor(def.cut);
  return CraftingRecipe(
    id: jewelcraftingRecipeId(def),
    name: def.name,
    skill: SkillId.JEWELCRAFTING,
    levelRequirement: level,
    xp: jewelcraftingXpAt(level),
    inputs: {def.gem.gemItem: 1, def.setting.goldBase: 1},
    output: [WeightedDropTableEntry(id: id, count: 1, weight: 1)],
  );
}
