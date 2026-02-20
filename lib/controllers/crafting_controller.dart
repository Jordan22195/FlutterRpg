import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/weighted_drop_table.dart';
import 'package:rpg/data/inventory.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/data/zone_location.dart';
import 'package:rpg/controllers/zone_controller.dart';

/// A single crafting recipe (inputs -> output) gated by a skill level requirement.
@immutable
class CraftingRecipe {
  const CraftingRecipe({
    required this.id,
    required this.name,
    required this.skill,
    required this.levelRequirement,
    required this.inputs,
    required this.output,
    required this.xp,
  });

  final int xp;
  final String id;
  final String name;
  final Skills skill;
  final int levelRequirement;

  /// Required inputs per craft, e.g. {Items.COPPER_ORE: 1}
  final Map<Items, int> inputs;

  /// Output stack per craft, e.g. ObjectStack(id: Items.COPPER_BAR, count: 1)
  final List<WeightedDropTableEntry> output;
}

class CraftingController extends ChangeNotifier {
  CraftingController._internal();
  static final CraftingController instance = CraftingController._internal();

  CraftingController();

  late PlayerDataController playerDataController;

  ZoneLocationId activeZoneLocation = ZoneLocationId.NULL;
  Skills activeSkill = Skills.BLACKSMITHING;
  CraftingRecipe? _activeRecipe;

  CraftingRecipe? get activeRecipe => _activeRecipe;

  Inventory craftedItems = Inventory(itemMap: {});

  void setBurntFoodWeight(String recipeId) {
    final recipe = recipeById(recipeId);
    recipe?.output.forEach((entry) {
      if (entry.id == Items.BURNT_FOOD) {
        final burnChance = calculateBurnChance(
          level: _getSkillLevel(Skills.COOKING),
          difficultyScale: recipe.levelRequirement
              .toDouble(), // Adjust based on recipe difficulty if needed
        );
        entry.weight =
            burnChance; // Higher burnChance means more likely to get burnt food
      }
    });
  }

  double calculateBurnChance({
    required int level,
    required double difficultyScale,
    double baseBurnChance = 0.6, // 60% burn at lvl 1 for difficultyScale=1
    double slope = 0.05, // how fast skill reduces burn
    double minBurnChance = 0.01, // never completely zero (optional)
  }) {
    final raw = baseBurnChance * difficultyScale / (1 + level * slope);
    return raw.clamp(minBurnChance, 1.0);
  }

  // --- Recipes (start with blacksmithing examples) ---
  final List<CraftingRecipe> _recipes = [
    // Firemaking
    CraftingRecipe(
      id: 'basic_campfire',
      name: 'Basic Campfire',
      skill: Skills.FIREMAKING,
      levelRequirement: 1,
      xp: 10,
      inputs: {Items.LOGS: 1},
      output: [
        WeightedDropTableEntry(id: Items.BASIC_CAMPFIRE, count: 1, weight: 1),
      ],
    ),

    // Cooking
    CraftingRecipe(
      id: 'cook_minnow',
      name: 'Cooked Meat',
      skill: Skills.COOKING,
      levelRequirement: 1,
      xp: 10,

      inputs: {Items.MINNOW: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_MINNOW, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_carp",
      name: "Cooked Carp",
      skill: Skills.COOKING,
      levelRequirement: 2,
      xp: 15,
      inputs: {Items.CARP: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_CARP, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_bluegill",
      name: "Cooked Bluegill",
      skill: Skills.COOKING,
      levelRequirement: 3,
      xp: 20,
      inputs: {Items.BLUEGILL: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_BLUEGILL, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_trout",
      name: "Cooked Trout",
      skill: Skills.COOKING,
      levelRequirement: 4,
      xp: 25,
      inputs: {Items.TROUT: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_TROUT, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_pike",
      name: "Cooked Pike",
      skill: Skills.COOKING,
      levelRequirement: 5,
      xp: 30,
      inputs: {Items.PIKE: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_PIKE, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_salmon",
      name: "Cooked Salmon",
      skill: Skills.COOKING,
      levelRequirement: 6,
      xp: 35,
      inputs: {Items.SALMON: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_SALMON, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_catfish",
      name: "Cooked Catfish",
      skill: Skills.COOKING,
      levelRequirement: 7,
      xp: 40,
      inputs: {Items.CATFISH: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_CATFISH, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_whitefish",
      name: "Cooked Whitefish",
      skill: Skills.COOKING,
      levelRequirement: 8,
      xp: 45,
      inputs: {Items.WHITEFISH: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_WHITEFISH, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_tuna",
      name: "Cooked Tuna",
      skill: Skills.COOKING,
      levelRequirement: 9,
      xp: 50,
      inputs: {Items.TUNA: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_TUNA, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_swordfish",
      name: "Cooked Swordfish",
      skill: Skills.COOKING,
      levelRequirement: 10,
      xp: 55,
      inputs: {Items.SWORDFISH: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_SWORDFISH, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "cook_shark",
      name: "Cooked Shark",
      skill: Skills.COOKING,
      levelRequirement: 11,
      xp: 60,
      inputs: {Items.SHARK: 1},
      output: [
        WeightedDropTableEntry(id: Items.COOKED_SHARK, count: 1, weight: 1),
        WeightedDropTableEntry(id: Items.BURNT_FOOD, count: 1, weight: 1),
      ],
    ),

    // Blacksmithing
    CraftingRecipe(
      id: 'smelt_copper_bar',
      name: 'Copper Bar',
      skill: Skills.BLACKSMITHING,
      levelRequirement: 1,
      xp: 5,
      inputs: {Items.COPPER_ORE: 1},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_BAR, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: 'forge_copper_dagger',
      name: 'Copper Dagger',
      skill: Skills.BLACKSMITHING,
      levelRequirement: 2,
      xp: 10,
      inputs: {Items.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_DAGGER, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: 'forge_copper_helmet',
      name: 'Copper Helmet',
      skill: Skills.BLACKSMITHING,
      levelRequirement: 2,
      xp: 12,
      inputs: {Items.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_HELMET, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: 'forge_copper_pickaxe',
      name: 'Copper Dagger',
      skill: Skills.BLACKSMITHING,
      levelRequirement: 2,
      xp: 15,

      inputs: {Items.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_PICKAXE, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_axe",
      name: "Copper Axe",
      skill: Skills.BLACKSMITHING,
      levelRequirement: 2,
      xp: 28,

      inputs: {Items.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_AXE, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_gloves",
      name: "Copper Hands",
      skill: Skills.BLACKSMITHING,
      levelRequirement: 3,
      xp: 20,
      inputs: {Items.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_GLOVES, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_legs",
      name: "Copper Legs",
      skill: Skills.BLACKSMITHING,
      levelRequirement: 3,
      xp: 22,
      inputs: {Items.COPPER_BAR: 2},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_LEGS, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_chestplate",
      name: "Copper Chestplate",
      skill: Skills.BLACKSMITHING,
      xp: 30,
      levelRequirement: 3,
      inputs: {Items.COPPER_BAR: 3},
      output: [
        WeightedDropTableEntry(
          id: Items.COPPER_CHESTPLATE,
          count: 1,
          weight: 1,
        ),
      ],
    ),

    CraftingRecipe(
      id: "forge_copper_boots",
      name: "Copper Boots",
      skill: Skills.BLACKSMITHING,
      levelRequirement: 3,
      xp: 20,
      inputs: {Items.COPPER_BAR: 1},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_BOOTS, count: 1, weight: 1),
      ],
    ),
    CraftingRecipe(
      id: "forge_copper_shield",
      name: "Copper Shield",
      skill: Skills.BLACKSMITHING,
      levelRequirement: 3,
      xp: 25,
      inputs: {Items.COPPER_BAR: 2},
      output: [
        WeightedDropTableEntry(id: Items.COPPER_SHIELD, count: 1, weight: 1),
      ],
    ),
  ];

  CraftingRecipe? recipeById(String recipeId) {
    try {
      return _recipes.firstWhere((r) => r.id == recipeId);
    } catch (_) {
      return null;
    }
  }

  List<CraftingRecipe> getVisibleRecipesForActiveSkill() {
    return _recipes.where((r) => r.skill == activeSkill).toList();
  }

  void initForSkill({
    required Skills skill,
    required PlayerDataController controller,
  }) {
    craftedItems.clear();
    playerDataController = controller;
    activeSkill = skill;

    // If current recipe isn't valid for this skill or is locked, choose first available.
    final visible = getVisibleRecipesForActiveSkill();
    if (visible.isEmpty) {
      _activeRecipe = null;
    } else if (_activeRecipe == null ||
        _activeRecipe!.skill != skill ||
        _getSkillLevel(skill) < _activeRecipe!.levelRequirement) {
      _activeRecipe = visible.first;
    }
    notifyListeners();
  }

  void selectRecipe(CraftingRecipe recipe) {
    _activeRecipe = recipe;
    notifyListeners();
  }

  // --- UI helpers ---
  int getPlayerCount(Items itemId) {
    final inv = _inventory;
    final stack = inv.itemMap[itemId];
    return stack ?? 0;
  }

  int craftableCount(CraftingRecipe recipe) {
    // Minimum across all inputs
    int? min;
    for (final entry in recipe.inputs.entries) {
      final have = getPlayerCount(entry.key);
      final perCraft = entry.value <= 0 ? 1 : entry.value;
      final can = have ~/ perCraft;
      min = (min == null) ? can : (can < min ? can : min);
    }
    return min ?? 0;
  }

  // --- Craft action ---
  bool canCraftActive() {
    final r = _activeRecipe;
    if (r == null) return false;
    if (_getSkillLevel(r.skill) < r.levelRequirement) return false;
    return craftableCount(r) > 0;
  }

  void craftOnce() {
    final r = _activeRecipe;
    if (r == null) return;

    if (_getSkillLevel(r.skill) < r.levelRequirement) {
      return;
    }

    // Check again
    if (craftableCount(r) <= 0) return;

    // Consume inputs
    for (final entry in r.inputs.entries) {
      _removeItems(entry.key, entry.value);
    }

    if (activeSkill == Skills.FIREMAKING) {
      // Add campfire to zone if crafting a firemaking recipe
      final fire = ItemController.buildItem(r.output.first.id) as BuffItem;
      ZoneController.addCampfireToCurrentZone(fire);
      BuffController.instance.setCampfireBuff(fire);
    } else {
      if (activeSkill == Skills.COOKING) {
        setBurntFoodWeight(r.id);
      }
      final output = WeightedDropTable.roll(r.output);
      _addItems(output.id, output.count);
    }

    // Award XP (simple starter formula)
    // You can tune this later per recipe, per tier, etc.
    final xp = r.xp;
    SkillController.instance.getSkill(r.skill).addXp(xp);

    playerDataController.refresh();
    notifyListeners();
  }

  int calcMaxNumberCraftsForRecipe(String recipeId) {
    final recipe = recipeById(recipeId);
    if (recipe == null) return 0;
    return craftableCount(recipe);
  }

  // --- Internals ---
  Inventory get _inventory {
    final d = playerDataController.data;
    if (d == null) {
      throw StateError(
        'CraftingController used before PlayerDataController data loaded. '
        'Await ensureLoaded() before initForSkill().',
      );
    }
    return d.inventory;
  }

  int _getSkillLevel(Skills skill) {
    // Prefer using your controller helper if it exists:
    // playerDataController.getSkill(skill).getLevel() ... etc
    // Here we use existing pattern from encounter: controller.getSkill(skill)
    try {
      return SkillController.instance.getSkill(skill).getLevel();
    } catch (_) {
      // fallback: if getSkill isn’t available for non-combat skills yet
      final s = SkillController.instance.getSkill(skill);
      return s.getLevel();
    }
  }

  void _addItems(Items id, int count) {
    _inventory.addItems(id, count);
    craftedItems.addItems(id, count);
  }

  void _removeItems(Items id, int count) {
    if (count <= 0) return;
    _inventory.removeItems(id, count);
  }
}
