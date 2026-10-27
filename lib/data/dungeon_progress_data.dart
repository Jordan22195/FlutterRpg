import '../catalogs/dungeons/dungeons.dart';

/// What the player has done in dungeons: the floors cleared this run, the
/// full-clear chests earned and waiting, how many times each floor has ever
/// been cleared, which entry keys have been paid, and how each dungeon
/// loops.
///
/// Deliberately separate from [DungeonRun], which is only ever "which floor
/// is live right now" and is reset by starting something else.
///
/// A run's clears are what open the floors below them, and Reset (or a
/// dungeon loop coming back round) wipes them back to the first floor. The
/// lifetime tallies, the paid keys and the waiting chests survive a reset.
class DungeonProgressData {
  /// Lifetime clears, per dungeon, per floor index. Stats only: nothing is
  /// unlocked by them.
  final Map<DungeonId, Map<int, int>> runs;

  /// Floors cleared since the dungeon was last reset — the unlocks.
  final Map<DungeonId, Set<int>> cleared;

  /// Dungeons whose entry key has been paid.
  final Set<DungeonId> keysPaid;

  /// Full-clear chests earned and not yet claimed. They stack, so laps run
  /// while the player is away are never lost.
  final Map<DungeonId, int> chests;

  /// Dungeons whose chest this run has already been earned; cleared by a
  /// reset, which is what makes the chest once per run.
  final Set<DungeonId> chestEarned;

  /// Dungeons set to Loop dungeon: a cleared floor runs on into the next,
  /// and the last comes back round to the first. The rest loop one floor.
  final Set<DungeonId> loopDungeon;

  DungeonProgressData({
    Map<DungeonId, Map<int, int>>? runs,
    Map<DungeonId, Set<int>>? cleared,
    Set<DungeonId>? keysPaid,
    Map<DungeonId, int>? chests,
    Set<DungeonId>? chestEarned,
    Set<DungeonId>? loopDungeon,
  }) : runs = runs ?? {},
       cleared = cleared ?? {},
       keysPaid = keysPaid ?? {},
       chests = chests ?? {},
       chestEarned = chestEarned ?? {},
       loopDungeon = loopDungeon ?? {};

  /// How many times [floor] of [id] has ever been cleared.
  int runsFor(DungeonId id, int floor) => runs[id]?[floor] ?? 0;

  /// Whether [floor] of [id] has been cleared this run — the unlock.
  bool hasCleared(DungeonId id, int floor) =>
      cleared[id]?.contains(floor) ?? false;

  /// Records one clear of [floor]: this run's unlock and the lifetime tally.
  void recordRun(DungeonId id, int floor) {
    if (!id.isReal || floor < 0) return;
    final byFloor = runs.putIfAbsent(id, () => {});
    byFloor[floor] = (byFloor[floor] ?? 0) + 1;
    cleared.putIfAbsent(id, () => {}).add(floor);
  }

  /// Back to the first floor: this run's clears and its chest go. Lifetime
  /// tallies, the paid key and any chest still waiting are kept.
  void resetRun(DungeonId id) {
    cleared.remove(id);
    chestEarned.remove(id);
  }

  bool keyPaid(DungeonId id) => keysPaid.contains(id);

  void markKeyPaid(DungeonId id) {
    if (!id.isReal) return;
    keysPaid.add(id);
  }

  int chestsWaiting(DungeonId id) => chests[id] ?? 0;

  bool chestEarnedThisRun(DungeonId id) => chestEarned.contains(id);

  /// Books this run's chest, once: a second call before a reset does
  /// nothing. Returns whether a chest was added.
  bool earnChest(DungeonId id) {
    if (!id.isReal || !chestEarned.add(id)) return false;
    chests[id] = chestsWaiting(id) + 1;
    return true;
  }

  /// Takes every waiting chest of [id] and returns how many there were.
  /// Takes up to [max] of [id]'s waiting chests (all of them when null).
  int takeChests(DungeonId id, {int? max}) {
    final waiting = chests[id] ?? 0;
    final taken = max == null ? waiting : max.clamp(0, waiting);
    if (taken >= waiting) {
      chests.remove(id);
    } else {
      chests[id] = waiting - taken;
    }
    return taken;
  }

  bool loopsDungeon(DungeonId id) => loopDungeon.contains(id);

  void setLoopDungeon(DungeonId id, bool on) {
    if (!id.isReal) return;
    on ? loopDungeon.add(id) : loopDungeon.remove(id);
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
      'cleared': {
        for (final entry in cleared.entries)
          if (entry.key.isReal && entry.value.isNotEmpty)
            entry.key.name: (entry.value.toList()..sort()),
      },
      'keysPaid': _names(keysPaid),
      'chests': {
        for (final entry in chests.entries)
          if (entry.key.isReal && entry.value > 0) entry.key.name: entry.value,
      },
      'chestEarned': _names(chestEarned),
      'loopDungeon': _names(loopDungeon),
    };
  }

  static List<String> _names(Set<DungeonId> ids) => [
    for (final id in ids)
      if (id.isReal) id.name,
  ];

  static Set<DungeonId> _idSet(Object? raw, Map<String, DungeonId> byName) {
    final out = <DungeonId>{};
    if (raw is! List) return out;
    for (final entry in raw) {
      final id = byName['$entry'];
      if (id != null && id.isReal) out.add(id);
    }
    return out;
  }

  /// Tolerant by design, the way the rest of the save's optional blocks are:
  /// a dungeon or floor that no longer parses is dropped rather than failing
  /// the load. The cost of a bad entry is a re-locked floor, not a lost game.
  ///
  /// A save from before runs could be reset has no 'cleared' block, so every
  /// dungeon loads back at its first floor — the old forever-unlocks are
  /// deliberately not carried over. Its lifetime tallies are.
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

    final cleared = <DungeonId, Set<int>>{};
    final rawCleared = json['cleared'];
    if (rawCleared is Map) {
      for (final entry in rawCleared.entries) {
        final id = byName[entry.key];
        final rawFloors = entry.value;
        if (id == null || !id.isReal || rawFloors is! List) continue;
        final floors = <int>{
          for (final floor in rawFloors)
            if (floor is int && floor >= 0) floor,
        };
        if (floors.isNotEmpty) cleared[id] = floors;
      }
    }

    final chests = <DungeonId, int>{};
    final rawChests = json['chests'];
    if (rawChests is Map) {
      for (final entry in rawChests.entries) {
        final id = byName[entry.key];
        final count = entry.value;
        if (id == null || !id.isReal || count is! int || count <= 0) continue;
        chests[id] = count;
      }
    }

    return DungeonProgressData(
      runs: runs,
      cleared: cleared,
      keysPaid: _idSet(json['keysPaid'], byName),
      chests: chests,
      chestEarned: _idSet(json['chestEarned'], byName),
      loopDungeon: _idSet(json['loopDungeon'], byName),
    );
  }
}
