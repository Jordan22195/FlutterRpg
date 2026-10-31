import 'ObjectStack.dart';
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

  // ---- the lap being fought, as watched live. none of it is serialized:
  // a lap a relaunch comes back into was not watched from its start, so it
  // has no time or damage to stand against a best ----

  /// Whether every action of the current lap so far fired live, from its
  /// first. Only a watched lap's time and damage are worth recording.
  bool lapWatched = false;

  /// Time the loop has spent running on the current lap — stops and pauses
  /// don't count, so a lap reads as fighting time, not wall clock.
  Duration lapTime = Duration.zero;

  /// Damage the player has taken on the current lap.
  int lapDamageTaken = 0;

  /// What the current lap has dropped, merged by item: [lapLoot] from the
  /// floor's ordinary members, [lapBossLoot] from its boss.
  List<ObjectStack> lapLoot = [];
  List<ObjectStack> lapBossLoot = [];

  /// Starts a fresh lap. [watched] is false for a lap that begins with the
  /// app closed.
  void beginLap({required bool watched}) {
    lapWatched = watched;
    lapTime = Duration.zero;
    lapDamageTaken = 0;
    lapLoot = [];
    lapBossLoot = [];
  }

  /// Adds [items] to the current lap's loot — the boss's, when [boss].
  void addLapLoot(List<ObjectStack> items, {bool boss = false}) {
    final into = boss ? lapBossLoot : lapLoot;
    for (final item in items) {
      if (item.count <= 0) continue;
      final existing = into.where((s) => s.id == item.id).firstOrNull;
      if (existing != null) {
        existing.count += item.count;
      } else {
        into.add(ObjectStack(id: item.id, count: item.count));
      }
    }
  }

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
