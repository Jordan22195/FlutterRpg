import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// A single crafting recipe (inputs -> output) gated by a skill level requirement.
class CraftingRecipe {
  const CraftingRecipe({
    required this.id,
    required this.name,
    required this.skill,
    required this.levelRequirement,
    required this.inputs,
    required this.output,
    required this.xp,
    this.rollsBonusOutput = false,
  });

  final double xp;
  final String id;
  final String name;
  final SkillId skill;
  final int levelRequirement;

  /// Required inputs per craft, e.g. {Items.COPPER_ORE: 1}
  final Map<ItemId, int> inputs;

  /// Output stack per craft, e.g. ObjectStack(id: Items.COPPER_BAR, count: 1)
  final List<WeightedDropTableEntry<ItemId>> output;

  /// Rolls the crafting quality table like equipment does, but pays the tier
  /// out as extra output instead of a rarity: common makes one craft's
  /// worth, legendary five. For outputs with no rarity of their own - bars.
  final bool rollsBonusOutput;
}
