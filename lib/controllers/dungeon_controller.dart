import 'package:flutter/foundation.dart';

import '../catalogs/dungeon_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/action_timing_controller.dart';
import '../data/action_result.dart';
import '../data/dungeon_run.dart';
import '../data/inventory_data.dart';
import '../data/ObjectStack.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import '../systems/dungeon_system.dart';

/// Status of a floor for the run screen's floor list.
enum FloorStatus { cleared, current, upcoming }

/// Drives a dungeon run through the action-timing loop. A cousin of
/// EncounterController: it owns the run, binds one auto-advancing combat
/// action to the loop, and runs enemy attacks per frame. Fights flow
/// pack→pack and floor→floor without the player re-pressing anything;
/// clearing a floor in a repeatable dungeon pauses for the loop/continue
/// choice.
class DungeonController extends ChangeNotifier {
  final DungeonRun _run;

  // controllers
  final ActionTimingController _actionTimingController;

  // data
  final PlayerData _playerState;
  final InventoryData _inventoryState;

  // catalogs
  final EntityCatalog _entityCatalog;

  // services / systems
  final DungeonSystem _dungeonSystem;
  final PlayerDataService _playerDataService;
  final InventoryService _inventoryService;

  ActionResult latestActionResult = ActionResult();
  int actionSequence = 0;

  int latestEntityDamage = 0;
  int entityAttackSequence = 0;
  DateTime? _lastEntityAttackAt;

  DungeonController({
    required DungeonRun dungeonRun,
    required ActionTimingController actionTimingController,
    required PlayerData playerState,
    required InventoryData inventoryState,
    required EntityCatalog entityCatalog,
    required DungeonSystem dungeonSystem,
    required PlayerDataService playerDataService,
    required InventoryService inventoryService,
  }) : _run = dungeonRun,
       _actionTimingController = actionTimingController,
       _playerState = playerState,
       _inventoryState = inventoryState,
       _entityCatalog = entityCatalog,
       _dungeonSystem = dungeonSystem,
       _playerDataService = playerDataService,
       _inventoryService = inventoryService;

  // ---- run lifecycle ----

  /// Begins a run at [dungeonId] (consuming a key if the dungeon is keyed)
  /// and starts the auto-advancing action loop. Returns false when entry
  /// isn't allowed (no key, level gate, or a run already in progress).
  bool enterDungeon(DungeonId dungeonId) {
    final started = _dungeonSystem.enterDungeon(
      run: _run,
      dungeonId: dungeonId,
      playerState: _playerState,
      playerInventory: _inventoryState,
    );
    if (!started) return false;
    _lastEntityAttackAt = null;
    _bindAndStart();
    notifyListeners();
    return true;
  }

  /// Abandons the run. For a keyed dungeon the key is already spent.
  void leaveDungeon() {
    _dungeonSystem.leaveDungeon(_run);
    _actionTimingController.stop();
    notifyListeners();
  }

  /// Re-runs the just-cleared floor (repeatable dungeons).
  void loopFloor() {
    _dungeonSystem.loopFloor(_run);
    _lastEntityAttackAt = null;
    if (_run.active && !_run.awaitingFloorChoice) _bindAndStart();
    notifyListeners();
  }

  /// Descends to the next floor, or finishes after the boss floor.
  void continueFloor() {
    _dungeonSystem.continueFloor(_run);
    _lastEntityAttackAt = null;
    if (_run.active && !_run.awaitingFloorChoice) {
      _bindAndStart();
    } else {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  void _bindAndStart() {
    _actionTimingController.stop();
    _actionTimingController.bindOnFireFunction(
      doDungeonAction,
      activityIconId: _run.dungeonId,
      activityCount: () => _run.fight.entity?.count ?? 0,
    );
    _actionTimingController.start();
  }

  /// Resumes the action loop for a run restored from a save (e.g. app was
  /// closed mid-run). Safe to call when there's no active/live run.
  void resumeIfRunning() {
    if (!_run.active || _run.awaitingFloorChoice) return;
    if (_run.fight.entity == null) return;
    _lastEntityAttackAt = null;
    _bindAndStart();
    notifyListeners();
  }

  // ---- the loop ----

  void doDungeonAction() {
    latestActionResult = _dungeonSystem.executeDungeonAction(
      run: _run,
      playerState: _playerState,
      playerInventory: _inventoryState,
    );
    actionSequence++;

    // heal between hits when hp runs low and food is equipped
    _dungeonSystem.autoEat(
      playerState: _playerState,
      playerInventory: _inventoryState,
    );

    // stop the loop when the run can't take another tick: paused for a
    // floor choice, completed, player down, or (defensively) inactive
    if (!_dungeonSystem.runConditionsMet(_run, _playerState)) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  /// Per-frame hook (wired in GameSessionFactory): drives enemy attacks on
  /// the enemy's own interval while the dungeon action is running.
  void onActionTimingFrame() {
    if (!_actionTimingController.isRunningAction(doDungeonAction)) {
      _lastEntityAttackAt = null;
      return;
    }
    final entity = _run.fight.entity;
    if (entity is! CombatEntity || _run.awaitingFloorChoice) return;

    final now = DateTime.now();
    _lastEntityAttackAt ??= now;

    final interval = Duration(
      milliseconds: (entity.attackInterval * 1000).round(),
    );
    if (now.difference(_lastEntityAttackAt!) < interval) return;
    _lastEntityAttackAt = now;

    latestEntityDamage = _dungeonSystem.executeEnemyAttack(
      run: _run,
      playerState: _playerState,
    );
    entityAttackSequence++;

    // react to the hit: auto-eat, and end the run on death
    _dungeonSystem.autoEat(
      playerState: _playerState,
      playerInventory: _inventoryState,
    );
    if (_playerState.hitpoints <= 0) {
      _dungeonSystem.leaveDungeon(_run);
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  // ---- inspect (read-only, no run required) ----

  DungeonDefinition? definitionFor(DungeonId id) =>
      _dungeonSystem.definitionFor(id);

  bool canEnter(DungeonId id) => _dungeonSystem.canEnter(
    run: _run,
    dungeonId: id,
    playerState: _playerState,
    playerInventory: _inventoryState,
  );

  /// Count of the entry key the player owns for [id] (0 if the dungeon is
  /// free to enter).
  int keyCount(DungeonId id) {
    final def = _dungeonSystem.definitionFor(id);
    if (def == null || !def.isKeyed) return 0;
    return _inventoryService.getItemCount(_inventoryState, def.keyItemId);
  }

  /// The distinct items the boss can drop, for the inspect reward preview.
  List<ItemId> bossRewardItemIds(DungeonId id) {
    final def = _dungeonSystem.definitionFor(id);
    if (def == null) return const [];
    final bossDef = _entityCatalog.getDefinitionFor(def.bossEntityId);
    if (bossDef is! EncounterEntityDefinition) return const [];
    final ids = <ItemId>{
      ...bossDef.itemDrops.map((e) => e.id),
      for (final roll in bossDef.bonusDrops) ...roll.entries.map((e) => e.id),
    };
    return ids.toList();
  }

  // ---- active run state ----

  bool get hasActiveRun => _run.active;
  bool get awaitingFloorChoice => _run.awaitingFloorChoice;
  DungeonId get activeDungeonId => _run.dungeonId;
  DungeonDefinition? get activeDefinition =>
      _dungeonSystem.definitionFor(_run.dungeonId);

  int get currentFloorIndex => _run.floorIndex;

  String get currentFloorName {
    final def = activeDefinition;
    if (def == null || _run.floorIndex >= def.floors.length) return '';
    return def.floors[_run.floorIndex].name;
  }

  /// True when the run is paused after clearing the final (boss) floor of a
  /// repeatable dungeon — the choice is loop-the-boss or finish.
  bool get atBossFloorChoice {
    final def = activeDefinition;
    if (def == null) return false;
    return _run.awaitingFloorChoice &&
        _run.floorIndex + 1 >= def.floors.length;
  }

  FloorStatus floorStatus(int floorIndex) {
    if (!_run.active) return FloorStatus.upcoming;
    if (floorIndex < _run.floorIndex) return FloorStatus.cleared;
    if (floorIndex == _run.floorIndex) {
      return _run.awaitingFloorChoice
          ? FloorStatus.cleared
          : FloorStatus.current;
    }
    return FloorStatus.upcoming;
  }

  EncounterEntity? get currentEntity => _run.fight.entity;

  double currentEntityHealthPercent() {
    final e = _run.fight.entity;
    if (e == null || e.maxHitPoints <= 0) return 0;
    return (e.hitpoints / e.maxHitPoints).clamp(0.0, 1.0);
  }

  List<ObjectStack> runLoot() =>
      _inventoryService.getObjectStackList(_run.loot);

  ItemId getEquipedFoodItemId() {
    return _playerState.equipmentData.equipedFood;
  }

  int getEquipedFoodItemCount() {
    final id = _playerState.equipmentData.equipedFood;
    return _inventoryService.getItemCount(_inventoryState, id);
  }

  Map<SkillId, int> getPlayerStats() =>
      _playerDataService.getStatTotals(_playerState);

  int getPlayerHp() => _playerState.hitpoints;
}
