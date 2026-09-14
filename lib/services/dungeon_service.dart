import '../catalogs/entities/entities.dart';
import '../data/dungeon_run.dart';
import '../data/entity_queue.dart';

/// Reads and writes over a [DungeonRun]'s floors. Pure state manipulation —
/// no catalogs, no combat. Content and gating live in DungeonSystem; this
/// is what the encounter loop touches per tick, so it stays cheap.
class DungeonService {
  EntityQueue? slotAt(DungeonRun run, int index) {
    if (index < 0 || index >= run.slots.length) return null;
    return run.slots[index];
  }

  /// The floor the action loop is firing into, or null when the player is
  /// not in a dungeon fight.
  EntityQueue? runningSlot(DungeonRun run) {
    if (!run.active || run.runningSlot < 0) return null;
    return slotAt(run, run.runningSlot);
  }

  /// The entity of the running floor the encounter screen is showing. This
  /// is the object the encounter state should be pointing at — compare by
  /// identity, never by id: the same EntityId legitimately appears in
  /// several floors.
  EncounterEntity? runningEntity(DungeonRun run) => runningSlot(run)?.displayed;

  /// Moves the running floor to its next member and returns it, or null
  /// when that clears the floor.
  EncounterEntity? advanceRunning(DungeonRun run) =>
      runningSlot(run)?.advance();

  /// Whether starting floor [index] should rebuild its queue first: it has
  /// been fought to the end. Every floor repeats, so this is just "spent".
  bool needsRefill(DungeonRun run, int index) =>
      slotAt(run, index)?.cleared ?? false;

  void clearRunningSlot(DungeonRun run) => run.runningSlot = -1;
}
