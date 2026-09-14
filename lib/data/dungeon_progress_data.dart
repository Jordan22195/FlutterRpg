import '../catalogs/dungeons/dungeons.dart';

/// What the player has permanently done in dungeons: how many times each
/// floor has been cleared, and which entry keys have been paid.
///
/// Deliberately separate from [DungeonRun], which is only ever "which floor
/// is live right now" and is reset by starting something else. Nothing here
/// is ever reset — a floor cleared once is unlocked forever, and a key paid
/// once opens its dungeon for good.
///
/// Unlock state is derived rather than stored: a floor with a run count is a
/// floor you have cleared, which is what keeps the floor below it open.
class DungeonProgressData {
  /// Lifetime clears, per dungeon, per floor index.
  final Map<DungeonId, Map<int, int>> runs;

  /// Dungeons whose entry key has been paid.
  final Set<DungeonId> keysPaid;

  DungeonProgressData({
    Map<DungeonId, Map<int, int>>? runs,
    Set<DungeonId>? keysPaid,
  }) : runs = runs ?? {},
       keysPaid = keysPaid ?? {};

  /// How many times [floor] of [id] has ever been cleared.
  int runsFor(DungeonId id, int floor) => runs[id]?[floor] ?? 0;

  /// Whether [floor] of [id] has ever been cleared — the permanent unlock.
  bool hasCleared(DungeonId id, int floor) => runsFor(id, floor) > 0;

  /// Records one clear of [floor].
  void recordRun(DungeonId id, int floor) {
    if (!id.isReal || floor < 0) return;
    final byFloor = runs.putIfAbsent(id, () => {});
    byFloor[floor] = (byFloor[floor] ?? 0) + 1;
  }

  bool keyPaid(DungeonId id) => keysPaid.contains(id);

  void markKeyPaid(DungeonId id) {
    if (!id.isReal) return;
    keysPaid.add(id);
  }

  Map<String, dynamic> toJson() {
    return {
      'runs': {
        for (final entry in runs.entries)
          if (entry.key.isReal && entry.value.isNotEmpty)
            entry.key.name: {
              for (final floor in entry.value.entries)
                floor.key.toString(): floor.value,
            },
      },
      'keysPaid': [
        for (final id in keysPaid)
          if (id.isReal) id.name,
      ],
    };
  }

  /// Tolerant by design, the way the rest of the save's optional blocks are:
  /// a dungeon or floor that no longer parses is dropped rather than failing
  /// the load. The cost of a bad entry is a re-locked floor, not a lost game.
  factory DungeonProgressData.fromJson(Map<String, dynamic> json) {
    final byName = DungeonId.values.asNameMap();

    final runs = <DungeonId, Map<int, int>>{};
    final rawRuns = json['runs'];
    if (rawRuns is Map) {
      for (final entry in rawRuns.entries) {
        final id = byName[entry.key];
        final rawFloors = entry.value;
        if (id == null || !id.isReal || rawFloors is! Map) continue;
        final byFloor = <int, int>{};
        for (final floor in rawFloors.entries) {
          final index = int.tryParse('${floor.key}');
          final count = floor.value;
          if (index == null || index < 0 || count is! int || count <= 0) {
            continue;
          }
          byFloor[index] = count;
        }
        if (byFloor.isNotEmpty) runs[id] = byFloor;
      }
    }

    final keysPaid = <DungeonId>{};
    final rawKeys = json['keysPaid'];
    if (rawKeys is List) {
      for (final raw in rawKeys) {
        final id = byName['$raw'];
        if (id != null && id.isReal) keysPaid.add(id);
      }
    }

    return DungeonProgressData(runs: runs, keysPaid: keysPaid);
  }
}
