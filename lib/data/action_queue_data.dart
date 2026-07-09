import '../catalogs/entity_catalog.dart';
import '../catalogs/zone_catalog.dart';

enum QueuedTaskType { ENCOUNTER, CRAFT, EXPLORE }

// one entry in the player's action queue. a task remembers the zone it
// was queued from so the queue can travel back to it before starting.
class QueuedTask {
  final QueuedTaskType type;
  final ZoneId zoneId;

  // encounter target, or the crafting station for CRAFT tasks
  final EntityId entityId;

  // CRAFT tasks only
  final String recipeId;

  QueuedTask.encounter({required this.zoneId, required this.entityId})
    : type = QueuedTaskType.ENCOUNTER,
      recipeId = "";

  QueuedTask.craft({
    required this.zoneId,
    required this.entityId,
    required this.recipeId,
  }) : type = QueuedTaskType.CRAFT;

  QueuedTask.explore({required this.zoneId})
    : type = QueuedTaskType.EXPLORE,
      entityId = EntityId.NULL,
      recipeId = "";
}

// in-memory queue state (not serialized into the save)
class ActionQueueData {
  final List<QueuedTask> tasks = [];

  // true while the queue is driving the action timing loop
  bool queueActive = false;

  // the task whose action is currently bound to the timing loop
  QueuedTask? activeTask;
}
