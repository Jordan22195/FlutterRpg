import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../catalogs/recipes/crafting_recipe.dart';
import '../catalogs/recipes/data/firemaking_recipes.dart';
import '../catalogs/zones/zones.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/buff_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import 'firemaking_system.dart';

/// Why a reagent can't be thrown on right now. [none] means it can.
enum TendBlock { none, notAReagent, noFire, cookfire, level, noneHeld }

/// Tending a fire: throwing fire reagents on a lit campfire or bonfire, and
/// the two switches that keep one going while the player does something else
/// in the zone.
///
/// The wood sets a fire's power and the reagent picks the stat (see
/// FireItemDefinition, FireReagentDefinition). Burning logs is Firemaking's
/// grind; a reagent thrown by hand pays a little xp on top, and the switches
/// pay none - they are upkeep paid for in materials, not a way to level.
class FireTendingSystem {
  final BuffService _buffService;
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;
  final FiremakingSystem _firemakingSystem;
  final List<CraftingRecipe> _fireRecipes;

  FireTendingSystem({
    required BuffService buffService,
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
    required FiremakingSystem firemakingSystem,
    List<CraftingRecipe>? fireRecipes,
  }) : _buffService = buffService,
       _inventoryService = inventoryService,
       _playerDataService = playerDataService,
       _firemakingSystem = firemakingSystem,
       _fireRecipes = fireRecipes ?? firemakingRecipes;

  /// Every fire reagent, in catalog order.
  static final List<ItemId> reagents = [
    for (final id in ItemId.values)
      if (id.definition is FireReagentDefinition) id,
  ];

  static bool isReagent(ItemId id) => id.definition is FireReagentDefinition;

  static FireReagentDefinition? reagentDefinition(ItemId id) {
    final def = id.definition;
    return def is FireReagentDefinition ? def : null;
  }

  /// The reagent that buffs [stat], or null when none does.
  static ItemId? reagentFor(SkillId stat) {
    for (final id in reagents) {
      if (reagentDefinition(id)!.stat == stat) return id;
    }
    return null;
  }

  /// The xp one reagent thrown by hand pays: its unlock level, so a reagent
  /// unlocked at 5 / 8 / 13 pays 5 / 8 / 13.
  static double tendXp(ItemId reagent) =>
      (reagentDefinition(reagent)?.levelRequirement ?? 0).toDouble();

  /// What stops [reagent] going on the fire in [firepitId], if anything.
  TendBlock blockFor(
    ItemId reagent,
    EntityId firepitId,
    ZoneId zoneId,
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
  }) {
    final def = reagentDefinition(reagent);
    if (def == null) return TendBlock.notAReagent;
    final fire = _firemakingSystem.activeFire(
      firepitId,
      zoneId,
      playerState.buffData,
      at: at,
    );
    if (fire == null) return TendBlock.noFire;
    if (!fire.tendable) return TendBlock.cookfire;
    final level = _playerDataService.getSkillLevel(
      SkillId.FIREMAKING,
      playerState,
    );
    if (level < def.levelRequirement) return TendBlock.level;
    if (_inventoryService.getItemCount(inventoryState, reagent) <= 0) {
      return TendBlock.noneHeld;
    }
    return TendBlock.none;
  }

  /// Throws up to [count] of [reagent] on the fire in [firepitId] and
  /// returns how many went on. [payXp] is for a reagent thrown by hand;
  /// the auto-tend switch throws without it.
  int tend(
    ItemId reagent,
    EntityId firepitId,
    ZoneId zoneId,
    PlayerData playerState,
    InventoryData inventoryState, {
    int count = 1,
    bool payXp = false,
    DateTime? at,
  }) {
    if (count <= 0) return 0;
    final block = blockFor(
      reagent,
      firepitId,
      zoneId,
      playerState,
      inventoryState,
      at: at,
    );
    if (block != TendBlock.none) return 0;

    final held = _inventoryService.getItemCount(inventoryState, reagent);
    final thrown = count < held ? count : held;
    final fire = _firemakingSystem.activeFire(
      firepitId,
      zoneId,
      playerState.buffData,
      at: at,
    )!;

    _inventoryService.removeItems(inventoryState, reagent, thrown);
    fire.tend(
      reagentDefinition(reagent)!.stat,
      at ?? DateTime.now(),
      count: thrown,
    );
    if (payXp) {
      _playerDataService.applyXp(playerState, {
        SkillId.FIREMAKING: tendXp(reagent) * thrown,
      });
    }
    return thrown;
  }

  /// The light recipe that makes [fireId] - what Keep fire fed spends.
  CraftingRecipe? recipeFor(ItemId fireId) {
    for (final recipe in _fireRecipes) {
      if (recipe.output.any((o) => o.id == fireId)) return recipe;
    }
    return null;
  }

  /// Adds one more lay of logs to [fire] when it is about to go out: it ends
  /// at or before [at] plus [within]. Pays the recipe's logs but no xp.
  /// Returns whether it was fed.
  bool feed(
    FireItem fire,
    PlayerData playerState,
    InventoryData inventoryState, {
    required DateTime at,
    Duration within = Duration.zero,
  }) {
    if (fire.expirationTime.isAfter(at.add(within))) return false;
    final recipe = recipeFor(fire.id);
    if (recipe == null) return false;
    final level = _playerDataService.getSkillLevel(
      SkillId.FIREMAKING,
      playerState,
    );
    if (level < recipe.levelRequirement) return false;
    for (final entry in recipe.inputs.entries) {
      if (_inventoryService.getItemCount(inventoryState, entry.key) <
          entry.value) {
        return false;
      }
    }
    for (final entry in recipe.inputs.entries) {
      _inventoryService.removeItems(inventoryState, entry.key, entry.value);
    }
    _firemakingSystem.lightOrExtend(
      fire.id,
      fire.ownerEntityId,
      fire.zoneId,
      playerState.buffData,
      at: at,
    );
    return true;
  }

  /// Runs both switches over every fire in the player's zone at [at]:
  /// Keep fire fed first, so a fire on its last moment is still lit for its
  /// reagents, then one of each armed reagent whose buff is down.
  ///
  /// [feedWithin] is how far ahead a fire counts as about to go out. The
  /// live tick runs once a second and passes a second; an offline settle
  /// cuts its segments on the instant a fire runs out, so it passes none.
  ///
  /// Returns whether anything was spent, so a screen showing the bag can
  /// follow it.
  bool autoTend(
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
    Duration feedWithin = Duration.zero,
  }) {
    final now = at ?? DateTime.now();
    final zoneId = playerState.currentZoneId;
    var spent = false;
    final fires = _buffService
        .getZoneBuffs(playerState.buffData, zoneId)
        .whereType<FireItem>()
        .toList();
    for (final fire in fires) {
      if (playerState.keepFireFed &&
          feed(
            fire,
            playerState,
            inventoryState,
            at: now,
            within: feedWithin,
          )) {
        spent = true;
      }
      // the live fire, after any feed: a different instance would only be
      // there if feeding relit it, and it never does that
      for (final reagent in reagents) {
        if (!playerState.autoTendReagents.contains(reagent)) continue;
        final stat = reagentDefinition(reagent)!.stat;
        if (fire.reagentActive(stat, now)) continue;
        final thrown = tend(
          reagent,
          fire.ownerEntityId,
          zoneId,
          playerState,
          inventoryState,
          at: now,
        );
        if (thrown > 0) spent = true;
      }
    }
    return spent;
  }
}
