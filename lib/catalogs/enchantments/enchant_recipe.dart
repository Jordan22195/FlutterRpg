import 'package:rpg/catalogs/items/items.dart';

/// A tier of enchantment that can be applied to equipment at the
/// enchanting bench. Consumes [inputs]; grants a random enchant name and
/// a random spread of stats whose total is exactly [statTotal].
class EnchantRecipe {
  const EnchantRecipe({
    required this.id,
    required this.name,
    required this.levelRequirement,
    required this.statTotal,
    required this.inputs,
    required this.xp,
  });

  final String id;
  final String name;

  /// Required enchanting skill level.
  final int levelRequirement;

  /// Total stat points the enchant grants (spread randomly).
  final int statTotal;

  /// Materials consumed per enchant.
  final Map<ItemId, int> inputs;

  final double xp;
}
