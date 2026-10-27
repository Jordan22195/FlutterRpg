import 'package:flutter/foundation.dart';

import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/items/items.dart';
import '../controllers/encounter_controller.dart';
import '../data/ObjectStack.dart';
import '../data/dungeon_progress_data.dart';
import '../data/dungeon_run.dart';
import '../data/entity_queue.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../services/dungeon_service.dart';
import '../services/inventory_service.dart';
import '../systems/dungeon_system.dart';

/// The dungeon screen's controller: which floors a dungeon has, which are
/// open, and what happens when one is tapped.
///
/// It owns no combat. Starting a floor hands off to [EncounterController],
/// which runs it as an ordinary encounter — the dungeon's only additions are
/// the queue behind the floor and the gating in front of it.
///
/// Opening the screen enters nothing, and backing out leaves nothing. A
/// dungeon's run is the floors cleared since it was last reset — what opens
/// the floors below — and clearing every main floor once a run earns its
/// chest. Starting any other action resets the floor that was running, not
/// the run.
class DungeonController extends ChangeNotifier {
  final DungeonRun _run;
  final DungeonProgressData _progress;

  // controllers
  final EncounterController _encounterController;

  // data
  final PlayerData _playerState;
  final InventoryData _inventoryState;

  // services / systems
  final DungeonSystem _dungeonSystem;
  final DungeonService _dungeonService;
  final InventoryService _inventoryService;

  /// Floors built for a dungeon the player is only looking at. Held so the
  /// entities aren't rebuilt on every frame the screen paints.
  final Map<DungeonId, List<EntityQueue>> _previewSlots = {};

  DungeonController({
    required DungeonRun dungeonRun,
    required DungeonProgressData dungeonProgress,
    required EncounterController encounterController,
    required PlayerData playerState,
    required InventoryData inventoryState,
    required DungeonSystem dungeonSystem,
    required DungeonService dungeonService,
    required InventoryService inventoryService,
  }) : _run = dungeonRun,
       _progress = dungeonProgress,
       _encounterController = encounterController,
       _playerState = playerState,
       _inventoryState = inventoryState,
       _dungeonSystem = dungeonSystem,
       _dungeonService = dungeonService,
       _inventoryService = inventoryService;

  // ---- inspect ----

  DungeonDefinition? definitionFor(DungeonId id) => id.definition;

  bool get hasActiveRun => _run.active;
  DungeonId get activeDungeonId => _run.dungeonId;
  int get runningSlot => _run.runningSlot;

  /// Floors of the dungeon the action loop is in, in list order. Empty until
  /// a floor has been started.
  List<EntityQueue> get slots => _run.slots;

  EntityQueue? slotAt(int index) => _dungeonService.slotAt(_run, index);

  /// The floors to render for [id]: the live ones when the loop is in this
  /// dungeon, otherwise a preview built from the definition.
  ///
  /// The split is what lets you read one dungeon while a floor in another is
  /// still swinging — looking at a dungeon never touches it.
  List<EntityQueue> slotsFor(DungeonId id) {
    if (!id.isReal) return const [];
    if (_run.active && _run.dungeonId == id) return _run.slots;
    return _previewSlots.putIfAbsent(
      id,
      () => _dungeonSystem.buildSlots(id.definition),
    );
  }

  /// Whether floor [index] of [id] has been cleared this run — the unlock.
  bool isCleared(DungeonId id, int index) => _progress.hasCleared(id, index);

  /// How many times floor [index] of [id] has ever been cleared.
  int lifetimeRuns(DungeonId id, int index) => _progress.runsFor(id, index);

  /// Laps of floor [index] since it last started. Zero for any floor that is
  /// not the one the loop is in, or has been reset.
  int sessionRuns(DungeonId id, int index) {
    if (!_run.active || _run.dungeonId != id) return 0;
    return _run.sessionRuns[index] ?? 0;
  }

  /// The floor [id]'s list is about, which it draws open: the one the loop
  /// is in, else the first never cleared, else the last. -1 for a dungeon
  /// with no floors.
  int currentFloor(DungeonId id) {
    final count = slotsFor(id).length;
    if (count == 0) return -1;
    if (_run.active && _run.dungeonId == id && _run.runningSlot >= 0) {
      return _run.runningSlot;
    }
    for (int i = 0; i < count; i++) {
      if (!_progress.hasCleared(id, i)) return i;
    }
    return count - 1;
  }

  /// Why floor [index] of [id] can't be started, or null when it can.
  String? lockReason(DungeonId id, int index) {
    if (!id.isReal) return 'Unavailable';
    return _dungeonSystem.lockReason(
      dungeonId: id,
      def: id.definition,
      index: index,
      progress: _progress,
      playerState: _playerState,
      playerInventory: _inventoryState,
    );
  }

  bool unlocked(DungeonId id, int index) => lockReason(id, index) == null;

  /// Whether floor [index] can be started. Every floor repeats now, so an
  /// unlocked floor is always runnable.
  bool startable(DungeonId id, int index) => unlocked(id, index);

  /// Count of the entry key the player owns for [id] (0 when free).
  int keyCount(DungeonId id) {
    final def = id.definition;
    if (!id.isReal || !def.isKeyed) return 0;
    return _inventoryService.getItemCount(_inventoryState, def.keyItemId);
  }

  /// The entry key of [id], or NULL when it is free.
  ItemId keyItemId(DungeonId id) => id.definition.keyItemId;

  /// This dungeon's key has already been paid — once paid, for good.
  bool keyPaid(DungeonId id) => _progress.keyPaid(id);

  /// Whether the key gate applies to floor [index] at all — a keyed
  /// dungeon's first floor, before the key has been paid. True whether or
  /// not the player actually holds one, so the floor can say "No key".
  bool showsKeyNote(DungeonId id, int index) =>
      id.isReal && id.definition.isKeyed && index == 0;

  /// Whether starting floor [index] would spend a key right now. Drives the
  /// confirm, so an irreversible charge is never silent.
  bool willSpendKey(DungeonId id, int index) {
    return showsKeyNote(id, index) && !keyPaid(id) && keyCount(id) > 0;
  }

  // ---- run: loop mode, reset, chest ----

  /// Whether [id] is set to Loop dungeon rather than Loop floor.
  bool loopsDungeon(DungeonId id) => _progress.loopsDungeon(id);

  /// Switches [id] between Loop floor and Loop dungeon. Takes effect the
  /// next time a floor clears, running or not.
  void setLoopDungeon(DungeonId id, bool on) {
    _progress.setLoopDungeon(id, on);
    notifyListeners();
  }

  /// Sends [id] back to its first floor: stops a floor of it that is
  /// running, relocks every floor below the first, and lets the chest be
  /// earned again. The paid key and chests waiting to be claimed stay.
  void resetDungeon(DungeonId id) {
    if (!id.isReal) return;
    _encounterController.stopDungeonFloor(id);
    _dungeonSystem.resetDungeon(_progress, _run, id);
    _previewSlots.remove(id);
    notifyListeners();
  }

  /// Main floors of [id], and how many of them are cleared this run.
  int mainFloorCount(DungeonId id) =>
      id.isReal ? id.definition.mainFloors.length : 0;
  int mainFloorsCleared(DungeonId id) =>
      _dungeonSystem.mainFloorsCleared(_progress, id);

  /// Whether this run's chest has been earned — claimed or not.
  bool chestEarned(DungeonId id) => _progress.chestEarnedThisRun(id);

  /// Chests of [id] earned and not yet claimed.
  int chestsWaiting(DungeonId id) => _progress.chestsWaiting(id);

  /// Opens up to [max] chests of [id] waiting to be claimed (all when null),
  /// into the bag. Returns what came out, merged by item.
  List<ObjectStack<ItemId>> claimChests(DungeonId id, {int? max}) {
    final loot = _dungeonSystem.openChests(
      progress: _progress,
      id: id,
      playerInventory: _inventoryState,
      max: max,
    );
    notifyListeners();
    return loot;
  }

  /// Re-reads everything the floor cards show. The key count comes from the
  /// bag, which other controllers change without this one hearing about it.
  void refresh() => notifyListeners();

  // ---- lifecycle ----

  /// Enters floor [index] of [id]: opens it on the encounter screen without
  /// starting it — the action button does that, through [startViewedFloor].
  /// Pays the key if this is a keyed dungeon's first floor and it is still
  /// owed, since entering is what the key buys. Returns a token for
  /// [leaveSlot], or null when the floor is locked or holds nothing.
  ///
  /// Whatever is running carries on: entering touches nothing but the view.
  Object? enterSlot(DungeonId id, int index) {
    if (!id.isReal || !unlocked(id, index)) return null;
    final floors = slotsFor(id);
    if (index < 0 || index >= floors.length) return null;
    final floor = floors[index];
    if (floor.displayed == null) return null;

    _dungeonSystem.spendKey(
      dungeonId: id,
      def: id.definition,
      index: index,
      progress: _progress,
      playerInventory: _inventoryState,
    );

    final token = _encounterController.viewDungeonFloor(id, index, floor);
    notifyListeners();
    return token;
  }

  /// Closes the floor [enterSlot] opened, once its screen is gone. The
  /// floor keeps running if it was started; only the view goes.
  void leaveSlot(Object token) => _encounterController.closeDungeonFloor(token);

  /// Starts the floor open on screen — the action button's press. False,
  /// starting nothing, when no floor is open or it is already the one
  /// running: the button fires on every press to boost, and restarting a
  /// running floor would send it back to the top each time.
  bool startViewedFloor() {
    final floor = _encounterController.floorToStart;
    if (floor == null) return false;
    return startSlot(floor.id, floor.index);
  }

  /// Starts floor [index] of [id]: pays the key if this is the first ever
  /// start of a keyed dungeon's first floor, refills a spent floor, and
  /// hands the queue to the encounter loop. Returns false when the floor is
  /// locked or has nothing left to fight.
  ///
  /// This is a floor tap: a fresh start, so the floor's lap count begins
  /// again. A floor clearing into its next lap never comes through here —
  /// the encounter tick hands those over in place.
  bool startSlot(DungeonId id, int index) {
    if (!id.isReal || !unlocked(id, index)) return false;

    // a tap is a fresh start: whatever floor was running - here or in
    // another dungeon - is walked away from, and goes back to the top
    _encounterController.releaseDungeonFloor();
    if (!_run.active || _run.dungeonId != id) {
      _dungeonSystem.beginRun(_run, id);
    }
    _run.sessionRuns.remove(index);

    return _start(id, index);
  }

  /// Puts the loop back on the floor a relaunch found it in. Not a fresh
  /// start: the queue stands where the offline settle left it, and the
  /// floor's laps carry on being counted from where they were.
  bool resumeSlot(int index) {
    if (!_run.active || !unlocked(_run.dungeonId, index)) return false;
    return _start(_run.dungeonId, index);
  }

  bool _start(DungeonId id, int index) {
    _dungeonSystem.spendKey(
      dungeonId: id,
      def: id.definition,
      index: index,
      progress: _progress,
      playerInventory: _inventoryState,
    );

    if (_dungeonService.needsRefill(_run, index)) {
      _dungeonSystem.refillSlot(_run, index);
    }

    final started = _encounterController.startDungeonSlot(index);
    notifyListeners();
    return started;
  }

  /// Sends the running floor back to the top and lets it go. What starting
  /// another action costs, and what dying in a dungeon costs.
  void resetRunningFloor() {
    final index = _run.runningSlot;
    if (index < 0) return;
    _dungeonSystem.resetSlot(_run, index);
    _dungeonService.clearRunningSlot(_run);
    notifyListeners();
  }
}
