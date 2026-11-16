import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../catalogs/zones/zones.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import 'firemaking_system.dart';

/// Why a reagent can't be thrown on right now. [none] means it can.
enum TendBlock {
  none,
  notAReagent,
  noFire,
  cookfire,
  level,
  noneHeld,

  /// The fire already carries a different kindling (one per fire).
  otherKindling,
}

/// Tending a fire: throwing fire reagents on a lit campfire or bonfire.
///
/// The wood sets a fire's power and the reagent picks the stat (see
/// FireItemDefinition, FireReagentDefinition). On the firepit screen a
/// reagent goes on through its recipe (fireReagentRecipes), run off the
/// action button like cooking; [tend] is the same throw for callers outside
/// the crafting loop.
class FireTendingSystem {
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;
  final FiremakingSystem _firemakingSystem;

  FireTendingSystem({
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
    required FiremakingSystem firemakingSystem,
  }) : _inventoryService = inventoryService,
       _playerDataService = playerDataService,
       _firemakingSystem = firemakingSystem;

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
    if (!fire.takesKindling(def.stat, at ?? DateTime.now())) {
      return TendBlock.otherKindling;
    }
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
  /// a caller placing one for free passes false.
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
}
