import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/entities/entities.dart';
import '../data/dungeon_progress_data.dart';
import '../data/dungeon_run.dart';
import '../data/entity_queue.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';

/// Content and gating for dungeons: building a dungeon's floors from a
/// definition, deciding which floors are open, paying the entry key, and
/// resetting a floor that has been walked away from.
///
/// Deliberately does NOT fight anything. A floor's encounter runs through
/// EncounterController/EncounterSystem like any other encounter — this
/// system only decides what is in the floors and when you may open one.
class DungeonSystem {
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;

  DungeonSystem({
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
  }) : _inventoryService = inventoryService,
       _playerDataService = playerDataService;

  DungeonDefinition? definitionFor(DungeonId id) => id.definition;

  // ---- floor lifecycle ----

  /// Points the run at [dungeonId], building a fresh queue for every floor.
  /// A run already on this dungeon is left alone, so walking out to the
  /// floor list and in again doesn't wipe the floor you are fighting.
  ///
  /// Only ever reached by starting a floor — opening the list doesn't enter
  /// anything, which is what lets you read another dungeon while one runs.
  void beginRun(DungeonRun run, DungeonId dungeonId) {
    if (run.active && run.dungeonId == dungeonId) return;
    if (!dungeonId.isReal) return;
    final def = dungeonId.definition;

    run.active = true;
    run.dungeonId = dungeonId;
    run.slots = buildSlots(def);
    run.runningSlot = -1;
    run.sessionRuns = {};
  }

  /// Every floor of [def] as a fresh queue. Used to build a run, and to
  /// render a dungeon the player is only looking at.
  List<EntityQueue> buildSlots(DungeonDefinition def) => [
    for (int i = 0; i < def.entries.length; i++) _buildSlot(def, i),
  ];

  /// Rebuilds one floor's queue from the definition — a floor being fought
  /// again. Permanent progress is untouched: it lives on the progress data,
  /// not here.
  void refillSlot(DungeonRun run, int index) {
    if (!run.dungeonId.isReal || index < 0 || index >= run.slots.length) {
      return;
    }
    final def = run.dungeonId.definition;
    run.slots[index] = _buildSlot(def, index);
  }

  /// Sends floor [index] back to the top: the queue rebuilds and its lap
  /// count starts over. What starting any other action costs you.
  void resetSlot(DungeonRun run, int index) {
    if (index < 0) return;
    refillSlot(run, index);
    run.sessionRuns.remove(index);
  }

  /// Books one clear of floor [index]: the permanent unlock, the lifetime
  /// count the floor card shows, and the lap count for this stretch.
  void recordFloorCleared(
    DungeonProgressData progress,
    DungeonRun run,
    int index,
  ) {
    if (!run.dungeonId.isReal || index < 0) return;
    progress.recordRun(run.dungeonId, index);
    run.sessionRuns[index] = (run.sessionRuns[index] ?? 0) + 1;
  }

  /// Prepares floor [index] to be fought and hands back the member to start
  /// on, or null when there is nothing in it to fight — including a refill
  /// that produced an empty floor, which would otherwise clear again the
  /// moment it started and loop at no cost.
  EncounterEntity? openSlot(DungeonRun run, int index) {
    if (!run.dungeonId.isReal || index < 0 || index >= run.slots.length) {
      return null;
    }
    if (run.slots[index].cleared) refillSlot(run, index);
    final member = run.slots[index].current;
    if (member == null || member.count <= 0) return null;
    return member;
  }

  // ---- gating ----

  /// Whether floor [index] can be started right now.
  bool unlocked({
    required DungeonId dungeonId,
    required DungeonDefinition def,
    required int index,
    required DungeonProgressData progress,
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    return lockReason(
          dungeonId: dungeonId,
          def: def,
          index: index,
          progress: progress,
          playerState: playerState,
          playerInventory: playerInventory,
        ) ==
        null;
  }

  /// Why floor [index] can't be started, or null when it can. The string is
  /// what the floor card renders next to its lock.
  String? lockReason({
    required DungeonId dungeonId,
    required DungeonDefinition def,
    required int index,
    required DungeonProgressData progress,
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    if (index < 0 || index >= def.entries.length) return 'Unavailable';

    if (!_meetsLevel(def, playerState)) {
      return 'Requires ${_skillName(def.requiredSkill)} ${def.requiredLevel}';
    }

    // the entry key gates the first floor only, and only until it is paid —
    // once, ever. after that the dungeon is open for good
    if (index == 0 && def.isKeyed && !progress.keyPaid(dungeonId)) {
      final keyName = def.keyItemId.definition.name;
      if (_inventoryService.getItemCount(playerInventory, def.keyItemId) <= 0) {
        return 'Requires $keyName';
      }
    }

    final entry = def.entries[index];
    if (!entry.requiresPrevious || index == 0) return null;
    if (progress.hasCleared(dungeonId, index - 1)) return null;
    return 'Complete ${def.entries[index - 1].name} to unlock';
  }

  /// Pays the entry key the first time floor 0 is started, and only that
  /// time. Safe to call on any floor: only a keyed dungeon's first one
  /// charges.
  void spendKey({
    required DungeonId dungeonId,
    required DungeonDefinition def,
    required int index,
    required DungeonProgressData progress,
    required InventoryData playerInventory,
  }) {
    if (index != 0 || !def.isKeyed || progress.keyPaid(dungeonId)) return;
    if (_inventoryService.getItemCount(playerInventory, def.keyItemId) <= 0) {
      return;
    }
    _inventoryService.removeItems(playerInventory, def.keyItemId, 1);
    progress.markKeyPaid(dungeonId);
  }

  // ---- internals ----

  EntityQueue _buildSlot(DungeonDefinition def, int index) {
    final entry = def.entries[index];
    final members = <EncounterEntity>[];
    for (final ref in entry.entities) {
      final entity = ref.entityId.build();
      // a floor can only hold something that depletes: anything else would
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

  String _skillName(SkillId skill) {
    final raw = skill.name;
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}
