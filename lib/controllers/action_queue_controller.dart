import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/recipe_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/action_queue_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/services/world_service.dart';

// runs queued tasks back to back through the action timing loop.
//
// each domain action already stops the timing controller when its
// conditions fail (ore depleted, out of materials, player death). the
// queue listens for that stop and advances to the next task, traveling
// back to the task's zone first when needed.
//
// a stop the queue did not cause hands control back to the player:
// - the stop button deactivates the queue (see StopPrimaryButton)
// - manually starting another action rebinds the loop; the queue sees
//   the loop running again after a stop and deactivates itself
class ActionQueueController extends ChangeNotifier {
  // nonserialized data
  final ActionQueueData _queueState = ActionQueueData();

  // controllers
  final ActionTimingController _actionTimingController;
  final EncounterController _encounterController;
  final CraftingController _craftingController;
  final WorldController _worldController;

  // data
  final PlayerData _playerState;
  final WorldData _worldState;

  // services
  final WorldService _worldService;

  // catalogs
  final EntityCatalog _entityCatalog;
  final RecipeCatalog _recipeCatalog;
  final ZoneCatalog _zoneCatalog;

  bool _wasRunning = false;
  bool _advancePending = false;

  ActionQueueController({
    required ActionTimingController actionTimingController,
    required EncounterController encounterController,
    required CraftingController craftingController,
    required WorldController worldController,
    required PlayerData playerState,
    required WorldData worldState,
    required WorldService worldService,
    required EntityCatalog entityCatalog,
    required RecipeCatalog recipeCatalog,
    required ZoneCatalog zoneCatalog,
  }) : _actionTimingController = actionTimingController,
       _encounterController = encounterController,
       _craftingController = craftingController,
       _worldController = worldController,
       _playerState = playerState,
       _worldState = worldState,
       _worldService = worldService,
       _entityCatalog = entityCatalog,
       _recipeCatalog = recipeCatalog,
       _zoneCatalog = zoneCatalog {
    _actionTimingController.addListener(_onTimingChanged);
  }

  @override
  void dispose() {
    _actionTimingController.removeListener(_onTimingChanged);
    super.dispose();
  }

  // ---- queue contents ----

  List<QueuedTask> get tasks => List.unmodifiable(_queueState.tasks);

  bool get isQueueActive => _queueState.queueActive;

  QueuedTask? get activeTask => _queueState.activeTask;

  bool isActiveTask(QueuedTask task) => _queueState.activeTask == task;

  void enqueueEncounter(EntityId entityId) {
    _queueState.tasks.add(
      QueuedTask.encounter(zoneId: _playerState.currentZoneId, entityId: entityId),
    );
    notifyListeners();
  }

  // station is the crafting entity the player is viewing when queueing
  void enqueueCraft(String recipeId) {
    _queueState.tasks.add(
      QueuedTask.craft(
        zoneId: _playerState.currentZoneId,
        entityId: _playerState.currentEntityViewId,
        recipeId: recipeId,
      ),
    );
    notifyListeners();
  }

  void enqueueExplore() {
    _queueState.tasks.add(
      QueuedTask.explore(zoneId: _playerState.currentZoneId),
    );
    notifyListeners();
  }

  void removeTaskAt(int index) {
    if (index < 0 || index >= _queueState.tasks.length) return;
    final task = _queueState.tasks.removeAt(index);

    // removing the running task stops it and moves on to the next
    if (task == _queueState.activeTask) {
      _queueState.activeTask = null;
      _actionTimingController.stop();
      if (_queueState.queueActive) {
        _startNext();
        return;
      }
    }
    notifyListeners();
  }

  void reorderTask(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final task = _queueState.tasks.removeAt(oldIndex);
    _queueState.tasks.insert(newIndex, task);
    notifyListeners();
  }

  void clearQueue() {
    _queueState.tasks.clear();
    final wasActive = _queueState.activeTask != null;
    _queueState.activeTask = null;
    _queueState.queueActive = false;
    if (wasActive) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  // ---- running the queue ----

  void startQueue() {
    if (_queueState.tasks.isEmpty) return;

    // already driving a running task: let it continue
    if (_queueState.queueActive &&
        _queueState.activeTask != null &&
        _actionTimingController.isRunning) {
      return;
    }

    _queueState.queueActive = true;
    _queueState.activeTask = null;
    _startNext();
  }

  // deactivates the queue and stops whatever action is running. tasks
  // stay in the list so the queue can be resumed from the same spot
  void stopQueue() {
    _queueState.queueActive = false;
    _queueState.activeTask = null;
    if (_actionTimingController.isRunning) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  void _onTimingChanged() {
    final running = _actionTimingController.isRunning;
    final wasRunning = _wasRunning;
    _wasRunning = running;

    if (!_queueState.queueActive || _queueState.activeTask == null) return;

    // the queue's task just stopped. advance in a microtask: if a
    // manual action started in the same call chain (stop then start),
    // the loop is running again by the time the microtask fires
    if (wasRunning && !running && !_advancePending) {
      _advancePending = true;
      scheduleMicrotask(_advance);
    }
  }

  void _advance() {
    _advancePending = false;
    if (!_queueState.queueActive || _queueState.activeTask == null) return;

    if (_actionTimingController.isRunning) {
      // another action took over the loop; the player has control now
      _queueState.queueActive = false;
      _queueState.activeTask = null;
      notifyListeners();
      return;
    }

    // the task finished naturally: drop it and start the next one
    _queueState.tasks.remove(_queueState.activeTask);
    _queueState.activeTask = null;

    // player death stops the whole queue
    if (_playerState.hitpoints <= 0) {
      _queueState.queueActive = false;
      notifyListeners();
      return;
    }

    _startNext();
  }

  // starts the first startable task, skipping tasks whose conditions
  // can't be met (missing entity, unreachable zone, no materials)
  void _startNext() {
    while (_queueState.tasks.isNotEmpty) {
      final task = _queueState.tasks.first;
      if (_tryStartTask(task)) {
        _queueState.activeTask = task;
        notifyListeners();
        return;
      }
      _queueState.tasks.removeAt(0);
    }
    _queueState.queueActive = false;
    notifyListeners();
  }

  bool _tryStartTask(QueuedTask task) {
    // tasks run in the zone they were queued from
    if (task.zoneId != _playerState.currentZoneId) {
      if (!_worldController.travelToZone(task.zoneId)) {
        return false;
      }
    }

    switch (task.type) {
      case QueuedTaskType.EXPLORE:
        _worldController.startExplore();
        return true;
      case QueuedTaskType.ENCOUNTER:
        final entity = _worldService.getEntity(
          task.entityId,
          task.zoneId,
          _worldState,
        );
        if (entity is! EncounterEntity) return false;
        return _encounterController.startEncounterActionFor(entity);
      case QueuedTaskType.CRAFT:
        return _craftingController.startCraftingActionFor(
          task.recipeId,
          task.entityId,
        );
    }
  }

  // ---- display helpers ----

  String taskTitle(QueuedTask task) {
    switch (task.type) {
      case QueuedTaskType.ENCOUNTER:
        return _entityCatalog.getDefinitionFor(task.entityId).name;
      case QueuedTaskType.CRAFT:
        return _recipeCatalog.recipeById(task.recipeId).name;
      case QueuedTaskType.EXPLORE:
        return "Explore";
    }
  }

  String taskSubtitle(QueuedTask task) {
    final zoneName = _zoneCatalog.getDefinitionFor(task.zoneId).name;
    switch (task.type) {
      case QueuedTaskType.ENCOUNTER:
        final entity = _worldService.getEntity(
          task.entityId,
          task.zoneId,
          _worldState,
        );
        final count = entity is EncounterEntity ? entity.count : 0;
        return "$zoneName · $count left";
      case QueuedTaskType.CRAFT:
        final station = _entityCatalog.getDefinitionFor(task.entityId).name;
        return "$zoneName · $station";
      case QueuedTaskType.EXPLORE:
        return zoneName;
    }
  }

  // icon id for the task tile; resolved by IconRenderer
  Enum taskIconId(QueuedTask task) {
    switch (task.type) {
      case QueuedTaskType.ENCOUNTER:
      case QueuedTaskType.CRAFT:
        return task.entityId;
      case QueuedTaskType.EXPLORE:
        return SkillId.EXPLORATION;
    }
  }
}
