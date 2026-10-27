import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/entities/entities.dart';
import '../data/dungeon_progress_data.dart';
import '../data/dungeon_run.dart';
import '../data/entity_queue.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../data/item_drop_type.dart';
import '../data/ObjectStack.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';
import '../catalogs/items/items.dart';

/// Content and gating for dungeons: building a dungeon's floors from a
/// definition, deciding which floors are open, paying the entry key,
/// resetting a floor that has been walked away from or a whole run, where a
/// cleared floor's loop goes next, and the full-clear chest.
///
/// Deliberately does NOT fight anything. A floor's encounter runs through
/// EncounterController/EncounterSystem like any other encounter — this
/// system only decides what is in the floors and when you may open one.
class DungeonSystem {
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;
  final WeightedDropTableService _dropTableService;

  DungeonSystem({
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
    required WeightedDropTableService dropTableService,
  }) : _inventoryService = inventoryService,
       _playerDataService = playerDataService,
       _dropTableService = dropTableService;

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

  /// Brings a run loaded from a save in line with its dungeon's current
  /// definition. The run serializes its floors' members, so a definition
  /// edited after the save was written would otherwise keep showing the old
  /// floors until the run was left. A floor whose name or roster no longer
  /// matches is rebuilt fresh; floors added to the definition are appended,
  /// floors removed from it are dropped. A floor that still matches keeps
  /// its hp and counts, so an untouched dungeon resumes exactly in place.
  void reconcileRun(DungeonRun run) {
    if (!run.active || !run.dungeonId.isReal) return;
    final def = run.dungeonId.definition;

    final slots = <EntityQueue>[];
    for (int i = 0; i < def.entries.length; i++) {
      final fresh = _buildSlot(def, i);
      final saved = i < run.slots.length ? run.slots[i] : null;
      if (saved != null && _matches(saved, fresh)) {
        slots.add(saved);
        continue;
      }
      slots.add(fresh);
      run.sessionRuns.remove(i);
    }
    run.slots = slots;
    run.sessionRuns.removeWhere((index, _) => index >= slots.length);
    if (run.runningSlot >= slots.length) run.runningSlot = -1;
  }

  /// Whether [saved] is a partly fought copy of [fresh]: the same members in
  /// the same order, with nothing waiting holding more than the definition
  /// gives it now.
  bool _matches(EntityQueue saved, EntityQueue fresh) {
    if (saved.name != fresh.name) return false;
    if (saved.members.length != fresh.members.length) return false;
    for (int i = 0; i < fresh.members.length; i++) {
      final had = saved.members[i];
      final now = fresh.members[i];
      if (had.id != now.id) return false;
      // the live member may be part way through its count; the ones behind
      // it have not been touched, so they must match exactly
      if (i > saved.index && had.count != now.count) return false;
      if (i == saved.index && had.count > now.count) return false;
    }
    return true;
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

  /// Books one clear of floor [index]: this run's unlock, the lifetime
  /// count the floor card shows, and the lap count for this stretch — and,
  /// the first time this run every main floor stands cleared, the chest.
  void recordFloorCleared(
    DungeonProgressData progress,
    DungeonRun run,
    int index,
  ) {
    final id = run.dungeonId;
    if (!id.isReal || index < 0) return;
    progress.recordRun(id, index);
    run.sessionRuns[index] = (run.sessionRuns[index] ?? 0) + 1;
    if (fullyCleared(progress, id)) progress.earnChest(id);
  }

  /// Every main floor of [id] cleared this run. Floors beside the path
  /// don't count.
  bool fullyCleared(DungeonProgressData progress, DungeonId id) {
    if (!id.isReal) return false;
    final main = id.definition.mainFloors;
    return main.isNotEmpty && main.every((i) => progress.hasCleared(id, i));
  }

  /// Main floors of [id] cleared this run — the chest's "1 / 3".
  int mainFloorsCleared(DungeonProgressData progress, DungeonId id) {
    if (!id.isReal) return 0;
    return id.definition.mainFloors
        .where((i) => progress.hasCleared(id, i))
        .length;
  }

  /// Where the loop goes once floor [index] of the running dungeon has
  /// just been cleared (and booked). Loop floor, and any floor beside the
  /// path, goes round the same floor again. Loop dungeon runs on into the
  /// next main floor; off the last one the run resets — the chest it just
  /// earned stays waiting — and comes back round to the first.
  int nextFloorAfterClear(
    DungeonProgressData progress,
    DungeonRun run,
    int index,
  ) {
    final id = run.dungeonId;
    if (!id.isReal || !progress.loopsDungeon(id)) return index;
    final def = id.definition;
    if (!def.isMainFloor(index)) return index;
    final next = def.nextMainFloor(index);
    if (next != null) return next;
    progress.resetRun(id);
    return def.mainFloors.first;
  }

  /// Back to the first floor: this run's clears and its chest go, and every
  /// floor of a run in this dungeon is rebuilt fresh. The caller stops a
  /// floor that was running first. The paid key and chests still waiting to
  /// be claimed are kept.
  void resetDungeon(
    DungeonProgressData progress,
    DungeonRun run,
    DungeonId id,
  ) {
    if (!id.isReal) return;
    progress.resetRun(id);
    if (!run.active || run.dungeonId != id) return;
    run.slots = buildSlots(id.definition);
    run.runningSlot = -1;
    run.sessionRuns = {};
  }

  // ---- chest ----

  /// What one of [def]'s chests rolls: its own table when it has one,
  /// otherwise a stand-in — a guaranteed purse of coins that grows with the
  /// floors, and a one-in-four pick from the floors' bosses' own drops.
  List<DropRoll> chestRollsFor(DungeonDefinition def) {
    if (def.chestRolls.isNotEmpty) return def.chestRolls;
    final floors = def.mainFloors.length;
    final bossTables = <ItemDropType>[];
    for (final entry in def.entries) {
      if (entry.entities.isEmpty) continue;
      final bossDef = entry.entities.last.entityId.definition;
      if (bossDef is! CombatEntityDefinition || !bossDef.isDungeonBoss) {
        continue;
      }
      if (bossDef.itemDrops.isNotEmpty) {
        bossTables.add(NestedDrop(bossDef.itemDrops));
      }
      for (final roll in bossDef.bonusDrops) {
        bossTables.addAll(roll.entries);
      }
    }
    return [
      DropRoll(
        entries: [
          ItemDropType(
            id: ItemId.COINS,
            lowCount: 50 * floors,
            highCount: 100 * floors,
          ),
        ],
      ),
      if (bossTables.isNotEmpty) DropRoll(chance: 0.25, entries: bossTables),
    ];
  }

  /// Opens up to [max] chests of [id] waiting to be claimed (all of them
  /// when null), paying what they roll into [playerInventory]. Returns what
  /// came out, merged by item; empty when nothing was waiting.
  List<ObjectStack<ItemId>> openChests({
    required DungeonProgressData progress,
    required DungeonId id,
    required InventoryData playerInventory,
    int? max,
  }) {
    if (!id.isReal) return const [];
    final count = progress.takeChests(id, max: max);
    if (count <= 0) return const [];

    final rolled = _dropTableService.rollBonusMulitpleTimes(
      count,
      chestRollsFor(id.definition),
    );
    final totals = <ItemId, int>{};
    for (final drop in rolled) {
      final item = drop.id.id;
      if (drop.count <= 0 || item == ItemId.NULL) continue;
      final built = item.build();
      if (built is EquipmentItem) {
        // equipment arrives at the quality its line names, as a kill's does
        built.quality = drop.id.rarity;
        built.count = drop.count;
        _inventoryService.addEquipment(playerInventory, built);
      } else {
        _inventoryService.addItems(playerInventory, [
          ObjectStack<ItemId>(id: item, count: drop.count),
        ]);
      }
      totals[item] = (totals[item] ?? 0) + drop.count;
    }
    return [
      for (final entry in totals.entries)
        ObjectStack<ItemId>(id: entry.key, count: entry.value),
    ];
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

    // a chained floor waits on the main floor above it, walking past any
    // floor beside the path in between
    if (!def.isMainFloor(index)) return null;
    final previous = def.previousMainFloor(index);
    if (previous == null || progress.hasCleared(dungeonId, previous)) {
      return null;
    }
    return 'Complete ${def.entries[previous].name} to unlock';
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
