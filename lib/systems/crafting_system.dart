import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/buff_data.dart';
import '../data/action_result.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../data/crafting_state.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';
import '../catalogs/recipes/recipes.dart';
import '../services/player_data_service.dart';
import '../services/crafting_service.dart';
import '../services/inventory_service.dart';
import '../services/weighted_drop_table_service.dart';
import 'firemaking_system.dart';

class CraftingSystem {
  // catalogs
  final RecipeCatalog _recipeCatalog;

  // services
  final PlayerDataService _playerDataService;
  final CraftingService _craftingService;
  final InventoryService _inventoryService;
  final WeightedDropTableService _weightedDropTableService;

  // systems
  final FiremakingSystem _firemakingSystem;

  CraftingSystem({
    required PlayerData playerState,
    required InventoryData inventoryData,
    required CraftingState craftingState,
    required WorldData worldState,
    required RecipeCatalog recipeCatalog,
    required PlayerDataService playerDataService,
    required CraftingService craftingService,
    required InventoryService inventoryService,
    required WeightedDropTableService weightedDropTableService,
    required FiremakingSystem firemakingSystem,
  }) : _recipeCatalog = recipeCatalog,
       _playerDataService = playerDataService,
       _craftingService = craftingService,
       _inventoryService = inventoryService,
       _weightedDropTableService = weightedDropTableService,
       _firemakingSystem = firemakingSystem;

  /// Crafts the active recipe, once by default and [craftCount] times when a
  /// stretch of time away is being settled in one go. Returns what it
  /// produced so callers can report it. An empty result means nothing was
  /// made - the level, the materials or the fire were not there.
  ///
  /// With [offline] set the whole batch is settled in a single pass: every
  /// craft's inputs are consumed at once, and the output table is rolled
  /// through [WeightedDropTableService.rollMulitpleTimes] rather than once
  /// per craft. That pays the same xp and the same expected output as
  /// looping, which is what lets hours of offline progress resolve in one
  /// call - and it holds for a batch of one, so a settle can measure its own
  /// rate off a single deterministic craft.
  ///
  /// [at] is the instant being crafted at, which for a settle is the segment
  /// being replayed rather than the wall clock hours later. It is what the
  /// cooking fire is judged against.
  ///
  /// The batch is capped at what the inventory can actually pay for, so a
  /// long stretch away crafts until the materials run out rather than on
  /// credit - which is exactly where the loop would have stopped.
  EncounterActionResult craftActiveRecipe(
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState,
    BuffData buffState,
    WorldData worldState, {
    int craftCount = 1,
    bool offline = false,
    DateTime? at,
  }) {
    final result = EncounterActionResult();
    final r = _recipeCatalog.recipeById(craftingState.activeRecipeId);

    if (!checkRecipeLevelRequirement(r.id, playerState, at: at)) {
      return result;
    }

    // cooking needs a fire that can cook, at the moment being crafted. a
    // live craft asks about now; a settle asks about the segment it is
    // replaying, when the fire may still have been burning.
    if (!_cookingConditionsMet(r, craftingState, playerState, at)) {
      return result;
    }

    // Check again
    final craftable = craftableCount(r.id, inventoryState);
    final crafts = craftCount < craftable ? craftCount : craftable;
    if (crafts <= 0) return result;

    // Consume inputs, a whole batch's worth at a time
    for (final entry in r.inputs.entries) {
      _inventoryService.removeItems(
        inventoryState,
        entry.key,
        entry.value * crafts,
      );
    }

    final outputTable = adjustDropTable(r.id, playerState, at: at);

    // one stack per distinct output. a live craft still rolls its own stack
    // size rather than taking the table's mean, so nothing about normal
    // play changes.
    final rolled = offline
        ? _weightedDropTableService.rollMulitpleTimes(crafts, outputTable)
        : [_weightedDropTableService.roll(outputTable)];

    for (final craftedItemObjectStack in rolled) {
      if (craftedItemObjectStack.count <= 0) continue;

      // a fire is not an item: it becomes a buff on the firepit being worked
      // at. that is the session's station, not whatever the player happens to
      // be looking at — crafting keeps running after you navigate away.
      if (r.skill == SkillId.FIREMAKING) {
        _firemakingSystem.lightOrExtend(
          craftedItemObjectStack.id,
          craftingState.craftingEntityId,
          playerState.currentZoneId,
          buffState,
          count: craftedItemObjectStack.count,
        );
        continue;
      }

      // equipment takes its own path: it is a unique instance carrying a
      // rolled quality, and never stacks with a plain item
      if (craftedItemObjectStack.id.build() is EquipmentItem) {
        _addCraftedEquipment(
          craftedItemObjectStack.id,
          craftedItemObjectStack.count,
          r,
          craftingState,
          playerState,
          inventoryState,
          result,
          offline: offline,
          at: at,
        );
      } else {
        _inventoryService.addItems(inventoryState, [craftedItemObjectStack]);
        _inventoryService.addItems(craftingState.craftedItems, [
          craftedItemObjectStack,
        ]);
        result.items.add(craftedItemObjectStack);
      }
    }

    result.actionsPerformed = crafts;
    result.xp = {r.skill: r.xp * crafts};
    _playerDataService.applyXp(playerState, result.xp);
    return result;
  }

  /// Whether a cooking recipe has its fire at [at]. Anything that is not
  /// cooking is unconditionally true - it is worked at a bench.
  bool _cookingConditionsMet(
    CraftingRecipe recipe,
    CraftingState craftingState,
    PlayerData playerState,
    DateTime? at,
  ) {
    if (recipe.skill != SkillId.COOKING) return true;
    return _firemakingSystem.canCookAt(
      craftingState.craftingEntityId,
      playerState.currentZoneId,
      playerState.buffData,
      at: at,
    );
  }

  /// Builds [count] crafted copies of equipment [itemId] into the player's
  /// inventory, the session grid and [result].
  ///
  /// Equipment is a unique instance with a rolled quality, so a batch rolls
  /// the quality table [count] times and builds one instance per tier that
  /// came up - the same pieces the loop would produce, and the same stacks
  /// they merge into, without a random draw each.
  void _addCraftedEquipment(
    ItemId itemId,
    int count,
    CraftingRecipe recipe,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState,
    EncounterActionResult result, {
    required bool offline,
    DateTime? at,
  }) {
    // higher crafting levels raise the odds of the upper tiers
    final skillLevel =
        _playerDataService.getStatTotals(playerState, at: at)[recipe.skill] ??
        1;
    final entries = _qualityEntries(skillLevel, recipe.levelRequirement);
    final tiers = offline
        ? _weightedDropTableService.rollMulitpleTimes(count, entries)
        : [_weightedDropTableService.roll(entries)];

    for (final tier in tiers) {
      if (tier.count <= 0) continue;
      // every inventory gets its own instance: sharing one object between
      // two of them would double-count when stacks merge
      for (final target in [inventoryState, craftingState.craftedItems]) {
        final piece = itemId.build() as EquipmentItem;
        piece.quality = tier.id;
        piece.count = tier.count;
        _inventoryService.addEquipment(target, piece);
      }
      final reported = itemId.build() as EquipmentItem;
      reported.quality = tier.id;
      reported.count = tier.count;
      result.equipment.add(reported);
    }
  }

  /// Rolls the quality tier for a crafted piece of equipment. Common is
  /// always the most likely outcome; levels above the recipe requirement
  /// shift weight toward the higher tiers.
  ItemQuality rollQuality(int skillLevel, int levelRequirement) {
    return _weightedDropTableService
        .roll(_qualityEntries(skillLevel, levelRequirement))
        .id;
  }

  /// The quality table a craft at [skillLevel] rolls against. Handed out as
  /// a table rather than a single roll so a batch can settle every piece it
  /// made in one pass.
  List<WeightedDropTableEntry<ItemQuality>> _qualityEntries(
    int skillLevel,
    int levelRequirement,
  ) {
    final levelBonus = (skillLevel - levelRequirement).clamp(0, 99).toDouble();
    return [
      WeightedDropTableEntry<ItemQuality>(id: ItemQuality.COMMON, weight: 100),
      WeightedDropTableEntry<ItemQuality>(
        id: ItemQuality.UNCOMMON,
        weight: 10 + levelBonus,
      ),
      WeightedDropTableEntry<ItemQuality>(
        id: ItemQuality.RARE,
        weight: 4 + levelBonus * 0.5,
      ),
      WeightedDropTableEntry<ItemQuality>(
        id: ItemQuality.EPIC,
        weight: 1.5 + levelBonus * 0.25,
      ),
      WeightedDropTableEntry<ItemQuality>(
        id: ItemQuality.LEGENDARY,
        weight: 0.5 + levelBonus * 0.1,
      ),
    ];
  }

  // right now just scales drop chance for burnt food
  // todo expand on this for all recipies and crafting qualities
  List<WeightedDropTableEntry<ItemId>> adjustDropTable(
    String recipeId,
    PlayerData playerState, {
    DateTime? at,
  }) {
    // the cooking level the burn chance reads includes the fire's own bonus,
    // so a settle has to ask for it at the segment the fire was burning in
    final skillLevels = _playerDataService.getStatTotals(playerState, at: at);
    final recipe = _recipeCatalog.recipeById(recipeId);
    return _craftingService.adjustActiveRecipeDropTable(recipe, skillLevels);
  }

  int craftableCount(String recipeId, InventoryData inventoryData) {
    final recipe = _recipeCatalog.recipeById(recipeId);
    // Minimum across all inputs
    int? min;
    for (final entry in recipe.inputs.entries) {
      final have = _inventoryService.getItemCount(inventoryData, entry.key);
      final perCraft = entry.value <= 0 ? 1 : entry.value;
      final can = have ~/ perCraft;
      min = (min == null) ? can : (can < min ? can : min);
    }
    return min ?? 0;
  }

  bool checkRecipeLevelRequirement(
    String recipeId,
    PlayerData playerState, {
    DateTime? at,
  }) {
    final r = _recipeCatalog.recipeById(recipeId);
    final skillLevel =
        _playerDataService.getStatTotals(playerState, at: at)[r.skill] ?? 0;
    if (skillLevel < r.levelRequirement) return false;
    return true;
  }

  bool recipeRequirementsMet(
    String recipeId,
    PlayerData playerState,
    InventoryData inventoryState,
    CraftingState craftingState, {
    DateTime? at,
  }) {
    if (!checkRecipeLevelRequirement(recipeId, playerState, at: at)) {
      return false;
    }
    if (craftableCount(recipeId, inventoryState) <= 0) return false;

    // cooking needs a fire that can cook. checking it here is what stops a
    // running cook loop the moment the fire burns out, via the requirements
    // re-check in CraftingController.doCraftingAction
    final r = _recipeCatalog.recipeById(recipeId);
    if (!_cookingConditionsMet(r, craftingState, playerState, at)) return false;

    return true;
  }
}
