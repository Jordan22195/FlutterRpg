import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/inventory.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/skill.dart';

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
  });

  final String id;
  final String name;
  final Skills skill;
  final int levelRequirement;

  /// Required inputs per craft, e.g. {Items.COPPER_ORE: 1}
  final Map<Items, int> inputs;

  /// Output stack per craft, e.g. ObjectStack(id: Items.COPPER_BAR, count: 1)
  final ObjectStack output;
}

class CraftingController extends ChangeNotifier {
  CraftingController._internal();
  static final CraftingController instance = CraftingController._internal();

  late PlayerDataController playerDataController;

  Skills activeSkill = Skills.BLACKSMITHING;
  CraftingRecipe? _activeRecipe;

  CraftingRecipe? get activeRecipe => _activeRecipe;

  // --- Recipes (start with blacksmithing examples) ---
  final List<CraftingRecipe> _recipes = [
    CraftingRecipe(
      id: 'smelt_copper_bar',
      name: 'Copper Bar',
      skill: Skills.BLACKSMITHING,
      levelRequirement: 1,
      inputs: {Items.COPPER_ORE: 1},
      output: ObjectStack(id: Items.COPPER_BAR, count: 1),
    ),
    CraftingRecipe(
      id: 'forge_copper_dagger',
      name: 'Copper Dagger',
      skill: Skills.BLACKSMITHING,
      levelRequirement: 2,
      inputs: {Items.COPPER_BAR: 1},
      output: ObjectStack(id: Items.COPPER_DAGGER, count: 1),
    ),
  ];

  List<CraftingRecipe> getVisibleRecipesForActiveSkill() {
    final level = _getSkillLevel(activeSkill);
    // Per your requirement: locked recipes are hidden.
    return _recipes
        .where((r) => r.skill == activeSkill && level >= r.levelRequirement)
        .toList();
  }

  void initForSkill({
    required Skills skill,
    required PlayerDataController controller,
  }) {
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

    // Add output
    _addItems(r.output.id, r.output.count);

    // Award XP (simple starter formula)
    // You can tune this later per recipe, per tier, etc.
    final xp = 5 * r.levelRequirement;
    playerDataController.addXp(r.skill, xp);

    playerDataController.saveAppData();
    notifyListeners();
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
      return playerDataController.getSkill(skill).getLevel();
    } catch (_) {
      // fallback: if getSkill isn’t available for non-combat skills yet
      final d = playerDataController.data;
      final s = d?.skills[skill];
      return s?.getLevel() ?? 1;
    }
  }

  void _addItems(Items id, int count) {
    _inventory.addItems(id, count);
  }

  void _removeItems(Items id, int count) {
    if (count <= 0) return;
    _inventory.removeItems(id, count);
  }
}
