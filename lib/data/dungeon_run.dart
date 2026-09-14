import 'entity_queue.dart';
import '../catalogs/dungeons/dungeons.dart';

/// Live state of a dungeon: the floors built from the definition, and which
/// one the action loop is firing into.
///
/// Serialized with the save so a running floor survives app close (resume in
/// place). Nothing here is progress — what you have permanently unlocked
/// lives in DungeonProgressData. This is only "which floor is live right
/// now", and starting any other action resets it.
///
/// The floors hold live [EntityQueue]s of real entities, so hp and counts
/// serialize for free and the existing combat services operate on them
/// directly.
class DungeonRun {
  bool active;
  DungeonId dungeonId;

  /// One queue per floor, in definition order.
  List<EntityQueue> slots;

  /// The floor the action loop is currently running, or -1 for none. Only
  /// ever one at a time: starting a floor stops whatever was running.
  int runningSlot;

  /// Laps completed since each floor last started, by floor index. Reset for
  /// a floor when it is started fresh or reset; serialized, because a floor
  /// that keeps looping with the app closed is still the floor you started.
  Map<int, int> sessionRuns;

  DungeonRun({
    this.active = false,
    this.dungeonId = DungeonId.NULL,
    List<EntityQueue>? slots,
    this.runningSlot = -1,
    Map<int, int>? sessionRuns,
  }) : slots = slots ?? [],
       sessionRuns = sessionRuns ?? {};

  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'dungeonId': dungeonId.name,
      'slots': slots.map((s) => s.toJson()).toList(),
      'runningSlot': runningSlot,
      'sessionRuns': {
        for (final entry in sessionRuns.entries)
          entry.key.toString(): entry.value,
      },
    };
  }

  /// Tolerant by design: a save written before floors became permanent
  /// carries cleared/keySpent/loot fields that mean nothing here, and yields
  /// an inactive run rather than failing the load.
  factory DungeonRun.fromJson(Map<String, dynamic> json) {
    final rawDungeonId = json['dungeonId'];
    final dungeonId = rawDungeonId is String
        ? DungeonId.values.firstWhere(
            (d) => d.name == rawDungeonId,
            orElse: () => DungeonId.NULL,
          )
        : DungeonId.NULL;

    final rawSlots = json['slots'];
    final slots = <EntityQueue>[];
    if (rawSlots is List) {
      for (final raw in rawSlots) {
        if (raw is Map<String, dynamic>) slots.add(EntityQueue.fromJson(raw));
      }
    }

    final rawRunningSlot = json['runningSlot'];

    final sessionRuns = <int, int>{};
    final rawSessionRuns = json['sessionRuns'];
    if (rawSessionRuns is Map) {
      for (final entry in rawSessionRuns.entries) {
        final index = int.tryParse('${entry.key}');
        final count = entry.value;
        if (index == null || count is! int || count <= 0) continue;
        sessionRuns[index] = count;
      }
    }

    return DungeonRun(
      // a run with no floors is not a run, whatever the flag says
      active: json['active'] == true && slots.isNotEmpty,
      dungeonId: dungeonId,
      slots: slots,
      runningSlot: rawRunningSlot is int && rawRunningSlot < slots.length
          ? rawRunningSlot
          : -1,
      sessionRuns: sessionRuns,
    );
  }
}
