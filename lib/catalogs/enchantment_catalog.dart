import '../catalogs/item_catalog.dart';

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

class EnchantmentCatalog {
  /// Suffix names an enchant can roll ("... of the Boar").
  final List<String> enchantNames = const [
    'Boar',
    'Owl',
    'Ox',
    'Wolf',
    'Bear',
    'Eagle',
    'Fox',
    'Stag',
  ];

  final List<EnchantRecipe> _recipes = const [
    EnchantRecipe(
      id: 'minor_enchant',
      name: 'Minor Enchant',
      levelRequirement: 1,
      statTotal: 2,
      inputs: {ItemId.ENCHANTING_DUST: 10},
      xp: 20,
    ),
    EnchantRecipe(
      id: 'lesser_enchant',
      name: 'Lesser Enchant',
      levelRequirement: 5,
      statTotal: 4,
      inputs: {ItemId.ENCHANTING_DUST: 20, ItemId.ENCHANTING_ESSENCE: 5},
      xp: 40,
    ),
    EnchantRecipe(
      id: 'greater_enchant',
      name: 'Greater Enchant',
      levelRequirement: 10,
      statTotal: 6,
      inputs: {ItemId.ENCHANTING_ESSENCE: 10, ItemId.ENCHANTING_RUNE: 3},
      xp: 80,
    ),
    EnchantRecipe(
      id: 'grand_enchant',
      name: 'Grand Enchant',
      levelRequirement: 20,
      statTotal: 9,
      inputs: {ItemId.ENCHANTING_RUNE: 8, ItemId.ENCHANTING_PRISM: 2},
      xp: 160,
    ),
    EnchantRecipe(
      id: 'soul_enchant',
      name: 'Soulbound Enchant',
      levelRequirement: 30,
      statTotal: 14,
      inputs: {ItemId.ENCHANTING_PRISM: 5, ItemId.SOUL_SHARD: 1},
      xp: 320,
    ),
  ];

  List<EnchantRecipe> get recipes => List.unmodifiable(_recipes);

  EnchantRecipe? recipeById(String id) {
    for (final r in _recipes) {
      if (r.id == id) return r;
    }
    return null;
  }
}
