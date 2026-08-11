import 'package:flutter/foundation.dart';

import '../catalogs/dungeon_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/encounter_controller.dart';
import '../data/dungeon_run.dart';
import '../data/entity_queue.dart';
import '../data/inventory_data.dart';
import '../data/ObjectStack.dart';
import '../data/player_data.dart';
import '../data/ui_state.dart';
import '../data/world_data.dart';
import '../services/dungeon_service.dart';
import '../services/inventory_service.dart';
import '../systems/dungeon_system.dart';

/// The dungeon list screen's controller: which cards exist, which are open,
/// and what happens when one is tapped.
///
/// It owns no combat. Starting a card hands off to [EncounterController],
/// which runs it as an ordinary encounter — the dungeon's only additions
/// are the queue behind the card and the gating in front of it.
class DungeonController extends ChangeNotifier {
  final DungeonRun _run;
  final UiState _uiState;

  // controllers
  final ActionTimingController _actionTimingController;
  final EncounterController _encounterController;

  // data
  final PlayerData _playerState;
  final InventoryData _inventoryState;
  final WorldData _worldState;

  // services / systems
  final DungeonSystem _dungeonSystem;
  final DungeonService _dungeonService;
  final InventoryService _inventoryService;

  DungeonController({
    required DungeonRun dungeonRun,
    required UiState uiState,
    required ActionTimingController actionTimingController,
    required EncounterController encounterController,
    required PlayerData playerState,
    required InventoryData inventoryState,
    required WorldData worldState,
    required DungeonSystem dungeonSystem,
    required DungeonService dungeonService,
    required InventoryService inventoryService,
  }) : _run = dungeonRun,
       _uiState = uiState,
       _actionTimingController = actionTimingController,
       _encounterController = encounterController,
       _playerState = playerState,
       _inventoryState = inventoryState,
       _worldState = worldState,
       _dungeonSystem = dungeonSystem,
       _dungeonService = dungeonService,
       _inventoryService = inventoryService;

  // ---- inspect ----

  DungeonDefinition? definitionFor(DungeonId id) =>
      _dungeonSystem.definitionFor(id);

  bool get hasActiveRun => _run.active;
  DungeonId get activeDungeonId => _run.dungeonId;
  int get runningSlot => _run.runningSlot;

  /// Cards of the open run, in list order. Empty until [openDungeon].
  List<EntityQueue> get slots => _run.slots;

  EntityQueue? slotAt(int index) => _dungeonService.slotAt(_run, index);

  bool isCleared(int index) => _dungeonService.isCleared(_run, index);

  /// Everything the run has dropped so far, across every card. Reset when
  /// the run is (leaving, or dying in it).
  List<ObjectStack> runLoot() =>
      _inventoryService.getObjectStackList(_run.loot);

  /// Why card [index] can't be started, or null when it can.
  String? lockReason(int index) {
    final def = definitionFor(_run.dungeonId);
    if (def == null) return 'Unavailable';
    return _dungeonSystem.lockReason(
      run: _run,
      def: def,
      index: index,
      playerState: _playerState,
      playerInventory: _inventoryState,
    );
  }

  bool unlocked(int index) => lockReason(index) == null;

  /// Count of the entry key the player owns for [id] (0 when free).
  int keyCount(DungeonId id) {
    final def = definitionFor(id);
    if (def == null || !def.isKeyed) return 0;
    return _inventoryService.getItemCount(_inventoryState, def.keyItemId);
  }

  /// The entry key of the open dungeon, or NULL when it is free.
  ItemId get keyItemId =>
      definitionFor(_run.dungeonId)?.keyItemId ?? ItemId.NULL;

  /// This run has already paid its key.
  bool get keySpent => _run.keySpent;

  /// Whether the key gate applies to card [index] at all — a keyed
  /// dungeon's first card, before the key has been paid. True whether or
  /// not the player actually holds one, so the card can say "No key".
  bool showsKeyNote(int index) {
    final def = definitionFor(_run.dungeonId);
    return def != null && def.isKeyed && index == 0;
  }

  /// Whether starting card [index] would spend a key right now. Drives the
  /// confirm, so an irreversible charge is never silent.
  bool willSpendKey(int index) {
    return showsKeyNote(index) &&
        !_run.keySpent &&
        keyCount(_run.dungeonId) > 0;
  }

  /// Whether card [index] can be started at all — a one-shot card already
  /// cleared can't, and shouldn't offer a play button.
  bool startable(int index) {
    if (!unlocked(index)) return false;
    final slot = _dungeonService.slotAt(_run, index);
    if (slot == null) return false;
    if (!slot.cleared) return true;
    return definitionFor(_run.dungeonId)?.repeatableEntries ?? false;
  }

  /// Clearing a card runs straight into the next one instead of dropping
  /// back to the list. A preference, so it outlives the run.
  bool get autoAdvance => _uiState.dungeonAutoAdvance;

  set autoAdvance(bool value) {
    if (_uiState.dungeonAutoAdvance == value) return;
    _uiState.dungeonAutoAdvance = value;
    notifyListeners();
  }

  // ---- lifecycle ----

  /// Opens [dungeonId]'s card list, starting a run if one isn't already
  /// under way here. Called when the dungeon screen mounts, so walking out
  /// to the list and back in doesn't reset anything.
  void openDungeon(DungeonId dungeonId) {
    if (_run.active && _run.dungeonId == dungeonId) return;
    _dungeonSystem.beginRun(_run, dungeonId);
    notifyListeners();
  }

  /// Starts card [index]: pays the key if this is the first card of a keyed
  /// dungeon, refills a cleared card in a repeatable dungeon, and hands the
  /// queue to the encounter loop. Returns false when the card is locked or
  /// has nothing left to fight.
  bool startSlot(int index) {
    final def = definitionFor(_run.dungeonId);
    if (def == null || !unlocked(index)) return false;

    _dungeonSystem.spendKey(
      run: _run,
      def: def,
      index: index,
      playerInventory: _inventoryState,
    );

    if (_dungeonService.needsRefill(
      _run,
      index,
      repeatable: def.repeatableEntries,
    )) {
      _dungeonSystem.refillSlot(_run, index);
    }

    final started = _encounterController.startDungeonSlot(index);
    notifyListeners();
    return started;
  }

  /// Leaves the dungeon: the run resets, and the type's exit cost applies
  /// (a spent key stays spent, a transient entrance is consumed).
  void leaveDungeon() {
    _actionTimingController.stop();
    _dungeonSystem.endRun(
      _run,
      playerState: _playerState,
      worldState: _worldState,
    );
    notifyListeners();
  }

  /// The next card the auto-advance toggle should run after [index], or
  /// null when there isn't one.
  int? nextStartableSlot(int index) {
    for (int i = index + 1; i < _run.slots.length; i++) {
      if (unlocked(i) && !_dungeonService.slotAt(_run, i)!.cleared) return i;
    }
    return null;
  }

  /// Text for the leave confirmation, spelling out what this dungeon type
  /// charges for walking out.
  String leaveWarningFor(DungeonId id) {
    final def = definitionFor(id);
    if (def == null) return 'Your progress is lost.';
    switch (def.type) {
      case DungeonType.LANDMARK:
        return 'Your progress is lost, and the key is already spent — '
            're-entering costs another one.';
      case DungeonType.TRANSIENT:
        return 'Your progress is lost and the entrance collapses behind '
            'you — this dungeon is gone.';
      case DungeonType.ZONE:
        return 'Your progress resets to the first floor.';
    }
  }
}
