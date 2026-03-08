class CraftingSystem {
  // data
  final PlayerData _playerState;
  final InventoryData _inventoryData;
  final CraftingState _craftingState;
  final WorldData _worldState;

  // catalogs
  final RecipeCatalog _recipeCatalog;
  final ZoneCatalog _zoneCatalog;

  // services
  final PlayerDataService _playerDataService;
  final CraftingService _craftingService;
  final InventoryService _inventoryService;
  final WeightedDropTableService _weightedDropTableService;
  final WorldService _worldService;

  CraftingSystem({
    required PlayerData playerState,
    required InventoryData inventoryData,
    required CraftingState craftingState,
    required WorldData worldState,
    required RecipeCatalog recipeCatalog,
    required ZoneCatalog zoneCatalog,
    required PlayerDataService playerDataService,
    required CraftingService craftingService,
    required InventoryService inventoryService,
    required WeightedDropTableService weightedDropTableService,
    required WorldService worldService,
  }) : _playerState = playerState,
       _inventoryData = inventoryData,
       _craftingState = craftingState,
       _worldState = worldState,
       _recipeCatalog = recipeCatalog,
       _zoneCatalog = zoneCatalog,
       _playerDataService = playerDataService,
       _craftingService = craftingService,
       _inventoryService = inventoryService,
       _weightedDropTableService = weightedDropTableService,
       _worldService = worldService;

  void craftActiveRecipeOnce() {
    final r = _craftingState.activeRecipe;

    if (!checkRecipeLevelRequirement(r.id)) {
      return;
    }

    // Check again
    if (craftableCount(r.id) <= 0) return;

    // Consume inputs
    for (final entry in r.inputs.entries) {
      _inventoryService.removeItems(_inventoryData, entry.key, entry.value);
    }

    adjustDropTable(r.id);

    final craftedItemObjectStack = _weightedDropTableService.roll(r.output);

    // if the crafted item is a fire, update fire buff
    if (r.skill == SkillId.FIREMAKING) {
      final fire = ItemCatalog.buildItem(craftedItemObjectStack.id) as BuffItem;
      // todo change this to use buff service
      _worldService.addCampfireToCurrentZone(
        fire,
        _playerState,
        _worldState,
        _zoneCatalog,
      );
    } else {
      _inventoryService.addItems(_inventoryData, [craftedItemObjectStack]);
    }

    _playerDataService.applyXp(_playerState, {r.skill: r.xp});
  }

  // right now just scales drop chance for burnt food
  // todo expand on this for all recipies and crafting qualities
  adjustDropTable(String recipeId) {
    final skillLevels = _playerDataService.getStatTotals(_playerState);
    _craftingService.adjustActiveRecipeDropTable(_craftingState, skillLevels);
  }

  int craftableCount(String recipeId) {
    final recipe = _recipeCatalog.recipeById(recipeId);
    // Minimum across all inputs
    int? min;
    for (final entry in recipe.inputs.entries) {
      final have = _inventoryService.getItemCount(_inventoryData, entry.key);
      final perCraft = entry.value <= 0 ? 1 : entry.value;
      final can = have ~/ perCraft;
      min = (min == null) ? can : (can < min ? can : min);
    }
    return min ?? 0;
  }

  bool checkRecipeLevelRequirement(String recipeId) {
    final r = _recipeCatalog.recipeById(recipeId);
    final skillLevel =
        _playerDataService.getStatTotals(_playerState)[r.skill] ?? 0;
    if (skillLevel < r.levelRequirement) return false;
    return true;
  }
}
