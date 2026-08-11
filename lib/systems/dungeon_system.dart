import '../catalogs/dungeon_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../data/dungeon_run.dart';
import '../data/entity_queue.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../data/world_data.dart';
import '../services/exploration_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';

/// Content and gating for dungeons: building a run's cards from a
/// definition, deciding which cards are open, paying the entry key, and
/// tearing the run down on leave.
///
/// Deliberately does NOT fight anything. A dungeon card's encounter runs
/// through EncounterController/EncounterSystem like any other encounter —
/// this system only decides what is in the cards and when you may open one.
class DungeonSystem {
  final DungeonCatalog _dungeonCatalog;
  final EntityCatalog _entityCatalog;
  final ItemCatalog _itemCatalog;
  final ExplorationService _explorationService;
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;

  DungeonSystem({
    required DungeonCatalog dungeonCatalog,
    required EntityCatalog entityCatalog,
    required ItemCatalog itemCatalog,
    required ExplorationService explorationService,
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
  }) : _dungeonCatalog = dungeonCatalog,
       _entityCatalog = entityCatalog,
       _itemCatalog = itemCatalog,
       _explorationService = explorationService,
       _inventoryService = inventoryService,
       _playerDataService = playerDataService;

  DungeonDefinition? definitionFor(DungeonId id) =>
      _dungeonCatalog.getDefinitionFor(id);

  // ---- run lifecycle ----

  /// Opens [dungeonId], building a fresh card for every entry. A run that
  /// is already on this dungeon is left alone, so walking back out to the
  /// card list and in again doesn't wipe progress — only an explicit leave
  /// (or a death) does.
  void beginRun(DungeonRun run, DungeonId dungeonId) {
    if (run.active && run.dungeonId == dungeonId) return;
    final def = _dungeonCatalog.getDefinitionFor(dungeonId);
    if (def == null) return;

    run.active = true;
    run.dungeonId = dungeonId;
    run.slots = [
      for (int i = 0; i < def.entries.length; i++) _buildSlot(def, i),
    ];
    run.cleared = [];
    run.runningSlot = -1;
    run.keySpent = false;
    _inventoryService.clearItems(run.loot);
  }

  /// Rebuilds one card's queue from the definition — a repeatable card
  /// being fought again. The cleared mark stays: it is what keeps the next
  /// card open.
  void refillSlot(DungeonRun run, int index) {
    final def = _dungeonCatalog.getDefinitionFor(run.dungeonId);
    if (def == null || index < 0 || index >= run.slots.length) return;
    run.slots[index] = _buildSlot(def, index);
  }

  /// Ends the run and applies what leaving this dungeon type costs. A
  /// transient dungeon's entrance is consumed; a keyed dungeon's key was
  /// already spent, so re-entry costs another one.
  void endRun(
    DungeonRun run, {
    required PlayerData playerState,
    required WorldData worldState,
  }) {
    final def = _dungeonCatalog.getDefinitionFor(run.dungeonId);
    if (def != null && def.type == DungeonType.TRANSIENT) {
      _consumeEntrance(def.id, playerState, worldState);
    }

    run.active = false;
    run.dungeonId = DungeonId.NULL;
    run.slots = [];
    run.cleared = [];
    run.runningSlot = -1;
    run.keySpent = false;
    _inventoryService.clearItems(run.loot);
  }

  // ---- gating ----

  /// Whether card [index] can be started right now.
  bool unlocked({
    required DungeonRun run,
    required DungeonDefinition def,
    required int index,
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    return lockReason(
          run: run,
          def: def,
          index: index,
          playerState: playerState,
          playerInventory: playerInventory,
        ) ==
        null;
  }

  /// Why card [index] can't be started, or null when it can. The string is
  /// what the card renders next to its lock.
  String? lockReason({
    required DungeonRun run,
    required DungeonDefinition def,
    required int index,
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    if (index < 0 || index >= def.entries.length) return 'Unavailable';

    if (!_meetsLevel(def, playerState)) {
      return 'Requires ${_skillName(def.requiredSkill)} ${def.requiredLevel}';
    }

    // the entry key gates the first card only, and only until it is paid
    if (index == 0 && def.isKeyed && !run.keySpent) {
      final keyName =
          _itemCatalog.definitionFor(def.keyItemId)?.name ?? 'a key';
      if (_inventoryService.getItemCount(playerInventory, def.keyItemId) <= 0) {
        return 'Requires $keyName';
      }
    }

    final entry = def.entries[index];
    if (!entry.requiresPrevious || index == 0) return null;
    if (run.cleared.contains(index - 1)) return null;
    return 'Complete ${def.entries[index - 1].name} to unlock';
  }

  /// Pays the entry key the first time card 0 is started. Safe to call on
  /// any card: only a keyed dungeon's first card charges.
  void spendKey({
    required DungeonRun run,
    required DungeonDefinition def,
    required int index,
    required InventoryData playerInventory,
  }) {
    if (index != 0 || !def.isKeyed || run.keySpent) return;
    if (_inventoryService.getItemCount(playerInventory, def.keyItemId) <= 0) {
      return;
    }
    _inventoryService.removeItems(playerInventory, def.keyItemId, 1);
    run.keySpent = true;
  }

  // ---- internals ----

  EntityQueue _buildSlot(DungeonDefinition def, int index) {
    final entry = def.entries[index];
    final members = <EncounterEntity>[];
    for (final ref in entry.entities) {
      final entity = _entityCatalog.buildEntity(ref.entityId);
      // a card can only hold something that depletes: anything else would
      // never clear, and the drop roll on kill casts to an encounter
      // definition unguarded
      if (entity is! EncounterEntity || entity is FishingEntity) continue;
      entity.count = ref.count;
      members.add(entity);
    }
    return EntityQueue(name: entry.name, members: members);
  }

  bool _meetsLevel(DungeonDefinition def, PlayerData playerState) {
    if (def.requiredSkill == SkillId.NULL || def.requiredLevel <= 0) {
      return true;
    }
    final level =
        _playerDataService.getStatTotals(playerState)[def.requiredSkill] ?? 0;
    return level >= def.requiredLevel;
  }

  /// Removes the zone entrance that opened [dungeonId]. Transient dungeons
  /// are found by exploring, and are spent by being run.
  void _consumeEntrance(
    DungeonId dungeonId,
    PlayerData playerState,
    WorldData worldState,
  ) {
    for (final id in EntityId.values) {
      final def = _entityCatalog.getDefinitionFor(id);
      if (def is DungeonEntityDefinition && def.dungeonId == dungeonId) {
        _explorationService.removeEntityFromZone(
          id,
          playerState.currentZoneId,
          worldState,
        );
      }
    }
  }

  String _skillName(SkillId skill) {
    final raw = skill.name;
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}
