import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/services/buff_service.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../data/crafting_state.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';
import '../catalogs/recipe_catalog.dart';
import '../catalogs/zone_catalog.dart';
import '../services/player_data_service.dart';
import '../services/crafting_service.dart';
import '../services/inventory_service.dart';
import '../services/weighted_drop_table_service.dart';
import '../services/world_service.dart';

class CraftingSystem {
  // catalogs
  final RecipeCatalog _recipeCatalog;
  final EntityCatalog _entityCatalog;

  // services
  final PlayerDataService _playerDataService;
  final CraftingService _craftingService;
  final InventoryService _inventoryService;
  final WeightedDropTableService _weightedDropTableService;
  final WorldService _worldService;
  final BuffService _buffService;

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
    required BuffData buffData,
    required BuffService buffService,
    required EntityCatalog entityCatalog,
  }) : _recipeCatalog = recipeCatalog,
       _playerDataService = playerDataService,
       _craftingService = craftingService,
       _inventoryService = inventoryService,
       _weightedDropTableService = weightedDropTableService,
       _worldService = worldService,
       _entityCatalog = entityCatalog,
       _buffService = buffService;

  void craftActiveRecipeOnce(
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState,
    BuffData buffState,
    WorldData worldState,
  ) {
    final r = craftingState.activeRecipe;

    if (!checkRecipeLevelRequirement(r.id, playerState)) {
      return;
    }

    // Check again
    if (craftableCount(r.id, inventoryState) <= 0) return;

    // Consume inputs
    for (final entry in r.inputs.entries) {
      _inventoryService.removeItems(inventoryState, entry.key, entry.value);
    }

    adjustDropTable(r.id, craftingState, playerState);

    final craftedItemObjectStack = _weightedDropTableService.roll(r.output);

    // if the crafted item is a fire, update fire buff
    if (r.skill == SkillId.FIREMAKING) {
      craftFire(craftedItemObjectStack.id, playerState, buffState, worldState);
    } else {
      _inventoryService.addItems(inventoryState, [craftedItemObjectStack]);
    }

    _playerDataService.applyXp(playerState, {r.skill: r.xp});
  }

  void craftFire(
    ItemId id,
    PlayerData playerState,
    BuffData buffState,
    WorldData worldState,
  ) {
    // create the buff item
    final fire = ItemCatalog.buildItem(id) as ZoneBuffItem;
    fire.zoneId = playerState.currentZoneId;
    // add to zone buff data
    _buffService.setZoneBuff(fire, buffState, playerState.currentZoneId);

    // create associated entity
    // add entity to zone
    _worldService.addEntityToCurrentZone(
      fire.entityId,
      1,
      _entityCatalog,
      playerState,
      worldState,
    );
  }

  // right now just scales drop chance for burnt food
  // todo expand on this for all recipies and crafting qualities
  void adjustDropTable(
    String recipeId,
    CraftingState craftingState,
    PlayerData playerState,
  ) {
    final skillLevels = _playerDataService.getStatTotals(playerState);
    _craftingService.adjustActiveRecipeDropTable(craftingState, skillLevels);
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

  bool checkRecipeLevelRequirement(String recipeId, PlayerData playerState) {
    final r = _recipeCatalog.recipeById(recipeId);
    final skillLevel =
        _playerDataService.getStatTotals(playerState)[r.skill] ?? 0;
    if (skillLevel < r.levelRequirement) return false;
    return true;
  }

  bool recipeRequirementsMet(
    String recipeId,
    PlayerData playerState,
    InventoryData inventoryState,
    CraftingState craftingState,
  ) {
    return (checkRecipeLevelRequirement(recipeId, playerState) &&
        craftableCount(recipeId, inventoryState) > 0);
  }
}
