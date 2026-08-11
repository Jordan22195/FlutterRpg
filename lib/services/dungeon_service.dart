import '../catalogs/entity_catalog.dart';
import '../data/dungeon_run.dart';
import '../data/entity_queue.dart';

/// Reads and writes over a [DungeonRun]'s cards. Pure state manipulation —
/// no catalogs, no combat. Content and gating live in DungeonSystem; this
/// is what the encounter loop touches per tick, so it stays cheap.
class DungeonService {
  EntityQueue? slotAt(DungeonRun run, int index) {
    if (index < 0 || index >= run.slots.length) return null;
    return run.slots[index];
  }

  /// The card the action loop is firing into, or null when the player is
  /// not in a dungeon fight.
  EntityQueue? runningSlot(DungeonRun run) {
    if (!run.active || run.runningSlot < 0) return null;
    return slotAt(run, run.runningSlot);
  }

  /// The entity of the running card the encounter screen is showing. This
  /// is the object the encounter state should be pointing at — compare by
  /// identity, never by id: the same EntityId legitimately appears in
  /// several cards.
  EncounterEntity? runningEntity(DungeonRun run) => runningSlot(run)?.displayed;

  /// Moves the running card to its next member and returns it, or null
  /// when that clears the card.
  EncounterEntity? advanceRunning(DungeonRun run) => runningSlot(run)?.advance();

  bool isCleared(DungeonRun run, int index) => run.cleared.contains(index);

  void markCleared(DungeonRun run, int index) {
    if (index < 0 || run.cleared.contains(index)) return;
    run.cleared.add(index);
  }

  /// Whether starting card [index] should rebuild its queue first: it has
  /// been fought to the end and the dungeon allows refighting.
  bool needsRefill(DungeonRun run, int index, {required bool repeatable}) {
    final slot = slotAt(run, index);
    if (slot == null) return false;
    if (!slot.cleared) return false;
    return repeatable;
  }

  void clearRunningSlot(DungeonRun run) => run.runningSlot = -1;
}
