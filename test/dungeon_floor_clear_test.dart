import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/dungeon_progress_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'support/gathering_tools.dart';

// Played live, a cleared floor pauses on its summary before the loop runs
// on: the lap's loot, its time and damage against the floor's bests, and a
// countdown the player can cut short or cancel. Laps settled with the app
// closed run straight on, and set no bests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const den = DungeonId.WOLF_DEN;

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = withGatheringTools(factory.newGame(catalogs));
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void makePlayerStrong(GameSession session) {
    final skills = session.saveGameData.playerData.skillData;
    for (final id in [SkillId.ATTACK, SkillId.DEFENCE, SkillId.HITPOINTS]) {
      final s = skills[id]!;
      s.xp = s.xpTable[99];
    }
    session.saveGameData.playerData.hitpoints = session.playerDataService
        .getStatTotals(session.saveGameData.playerData)[SkillId.HITPOINTS]!;
    session.saveGameData.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 200000;
    session.saveGameData.playerData.equipmentData.equipedFood =
        ItemId.COOKED_CHICKEN;
  }

  /// Fights the running floor until the loop pauses on its clear.
  void fightToPause(GameSession session, {int limit = 40000}) {
    final encounter = session.encounterController;
    var ticks = 0;
    while (encounter.intermission == null && ticks < limit) {
      encounter.doEncounterAction(1);
      ticks++;
    }
    expect(
      encounter.intermission,
      isNotNull,
      reason: 'the floor never cleared',
    );
  }

  test('a live clear pauses on the floor, then runs on', () {
    final session = buildSession();
    makePlayerStrong(session);
    final encounter = session.encounterController;
    final timing = session.actionTimingController;
    final run = session.saveGameData.dungeonRun;

    expect(session.dungeonController.startSlot(den, 0), isTrue);
    fightToPause(session);

    final summary = encounter.intermission!;
    expect(summary.dungeonId, den);
    expect(summary.floorIndex, 0);
    expect(summary.floorName, den.definition.entries[0].name);
    expect(summary.lastMemberId, EntityId.CAVE_BEAR);
    expect(
      summary.defeated,
      den.definition.entries[0].entities.fold<int>(0, (s, r) => s + r.count),
    );
    expect(summary.clears, 1);
    expect(summary.sessionClears, 1);
    expect(summary.loot, isNotEmpty);
    // the bear is the floor's boss, so what it dropped is told apart
    expect(summary.boss, isTrue);
    expect(summary.bossLoot, isNotEmpty);

    // held, not stopped: the loop is bound to the floor and keeps its boost,
    // but nothing moves, and the spent floor waits as it is
    expect(timing.isRunning, isTrue);
    expect(timing.isHeld, isTrue);
    expect(run.runningSlot, 0);
    expect(run.slots[0].cleared, isTrue);

    encounter.finishIntermission();

    expect(encounter.intermission, isNull);
    expect(timing.isHeld, isFalse);
    expect(timing.isRunning, isTrue);
    // Loop floor: the same floor, refilled, on a fresh lap
    expect(run.runningSlot, 0);
    expect(run.slots[0].cleared, isFalse);
    expect(run.slots[0].current!.count, greaterThan(0));
    expect(run.lapLoot, isEmpty);
    expect(run.lapBossLoot, isEmpty);

    session.dispose();
  });

  test('the loop mode chosen during the pause decides the next floor', () {
    final session = buildSession();
    makePlayerStrong(session);
    final dungeons = session.dungeonController;

    dungeons.startSlot(den, 0);
    fightToPause(session);
    // the summary's Next: Loop dungeon, set while the floor waits
    expect(dungeons.nextFloorAfter(den, 0), 0);
    dungeons.setLoopDungeon(den, true);
    expect(dungeons.nextFloorAfter(den, 0), 1);

    session.encounterController.finishIntermission();

    expect(session.saveGameData.dungeonRun.runningSlot, 1);
    expect(session.actionTimingController.isRunning, isTrue);
    session.dispose();
  });

  test('cancel stops the loop on the floor it would have run on to', () {
    final session = buildSession();
    makePlayerStrong(session);
    final dungeons = session.dungeonController;
    final run = session.saveGameData.dungeonRun;

    dungeons.setLoopDungeon(den, true);
    dungeons.startSlot(den, 0);
    fightToPause(session);

    session.encounterController.cancelIntermission();

    expect(session.encounterController.intermission, isNull);
    expect(session.actionTimingController.isRunning, isFalse);
    expect(run.runningSlot, 1);
    expect(run.slots[1].current!.count, greaterThan(0));

    // play carries on with that floor rather than starting another
    expect(dungeons.playFloor(den, 1), isTrue);
    expect(run.runningSlot, 1);
    expect(session.actionTimingController.isRunning, isTrue);
    session.dispose();
  });

  test('an action fired into the pause runs on first, booking one clear', () {
    final session = buildSession();
    makePlayerStrong(session);
    final progress = session.saveGameData.dungeonProgress;

    session.dungeonController.startSlot(den, 0);
    fightToPause(session);
    expect(progress.runsFor(den, 0), 1);

    session.encounterController.doEncounterAction(1);

    expect(session.encounterController.intermission, isNull);
    expect(progress.runsFor(den, 0), 1);
    expect(session.saveGameData.dungeonRun.slots[0].cleared, isFalse);
    session.dispose();
  });

  test('a watched lap sets the floor\'s bests, and a beaten one is new', () {
    final session = buildSession();
    makePlayerStrong(session);
    final encounter = session.encounterController;
    final run = session.saveGameData.dungeonRun;
    final progress = session.saveGameData.dungeonProgress;

    session.dungeonController.startSlot(den, 0);
    run.lapTime = const Duration(seconds: 90);
    run.lapDamageTaken = 50;
    fightToPause(session);

    var summary = encounter.intermission!;
    expect(summary.time, const Duration(seconds: 90));
    expect(summary.damageTaken, 50);
    // a first timed lap sets the record, but beats nothing
    expect(summary.bestTimeBefore, isNull);
    expect(summary.newBestTime, isFalse);
    expect(progress.bestTime(den, 0), const Duration(seconds: 90));
    expect(progress.leastDamageTaken(den, 0), 50);

    encounter.finishIntermission();
    run.lapTime = const Duration(seconds: 60);
    run.lapDamageTaken = 80;
    fightToPause(session);

    summary = encounter.intermission!;
    expect(summary.bestTimeBefore, const Duration(seconds: 90));
    expect(summary.newBestTime, isTrue);
    expect(summary.leastDamageBefore, 50);
    expect(summary.newLeastDamage, isFalse);
    expect(summary.sessionClears, 2);
    expect(progress.bestTime(den, 0), const Duration(seconds: 60));
    expect(progress.leastDamageTaken(den, 0), 50);
    session.dispose();
  });

  test('a lap any of which settled offline sets no best', () {
    final session = buildSession();
    makePlayerStrong(session);
    final progress = session.saveGameData.dungeonProgress;

    session.dungeonController.startSlot(den, 0);
    session.encounterController.doEncounterAction(1, offline: true);
    fightToPause(session);

    final summary = session.encounterController.intermission!;
    expect(summary.time, isNull);
    expect(summary.damageTaken, isNull);
    expect(progress.bestTime(den, 0), isNull);
    session.dispose();
  });

  test('with no pause, a clear runs straight on', () {
    final session = buildSession();
    makePlayerStrong(session);
    final encounter = session.encounterController
      ..floorIntermission = Duration.zero;
    final progress = session.saveGameData.dungeonProgress;

    session.dungeonController.startSlot(den, 0);
    var ticks = 0;
    while (progress.runsFor(den, 0) == 0 && ticks < 40000) {
      encounter.doEncounterAction(1);
      ticks++;
    }

    expect(progress.runsFor(den, 0), 1);
    expect(encounter.intermission, isNull);
    expect(session.actionTimingController.isHeld, isFalse);
    expect(session.saveGameData.dungeonRun.slots[0].cleared, isFalse);
    session.dispose();
  });

  test('floor bests survive a save round trip', () {
    final progress = DungeonProgressData()
      ..recordLap(den, 1, const Duration(milliseconds: 251000), 920);
    // a slower, bloodier lap keeps the record
    progress.recordLap(den, 1, const Duration(minutes: 5), 1200);

    final loaded = DungeonProgressData.fromJson(progress.toJson());

    expect(loaded.bestTime(den, 1), const Duration(milliseconds: 251000));
    expect(loaded.leastDamageTaken(den, 1), 920);
    expect(loaded.bestTime(den, 0), isNull);
  });
}
