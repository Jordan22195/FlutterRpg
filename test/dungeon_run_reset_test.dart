import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/dungeon_progress_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'support/gathering_tools.dart';

// A dungeon's run is the floors cleared since it was last reset. Reset
// sends it back to floor 1; Loop dungeon walks the floors and comes back
// round on its own; clearing every main floor once a run earns a chest,
// and earned chests wait, stacked, for one claim.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  // strong and fed, so floors clear and keep looping deterministically
  void makePlayerStrong(GameSession session) {
    final skills = session.saveGameData.playerData.skillData;
    for (final id in [
      SkillId.ATTACK,
      SkillId.DEFENCE,
      SkillId.HITPOINTS,
      SkillId.MINING,
    ]) {
      final s = skills[id]!;
      s.xp = s.xpTable[99];
    }
    session.saveGameData.playerData.hitpoints = session.playerDataService
        .getStatTotals(session.saveGameData.playerData)[SkillId.HITPOINTS]!;
    session.saveGameData.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 200000;
    session.saveGameData.playerData.equipmentData.equipedFood =
        ItemId.COOKED_CHICKEN;
  }

  int fightPast(
    GameSession session,
    bool Function() waiting, {
    int limit = 40000,
  }) {
    var ticks = 0;
    while (waiting() && ticks < limit) {
      session.encounterController.doEncounterAction(1);
      ticks++;
    }
    return ticks;
  }

  DungeonProgressData progressOf(GameSession session) =>
      session.saveGameData.dungeonProgress;

  /// Starts floor [index] and fights until it books one more clear.
  void clearFloorOnce(GameSession session, DungeonId id, int index) {
    final progress = progressOf(session);
    final before = progress.runsFor(id, index);
    expect(session.dungeonController.startSlot(id, index), isTrue);
    fightPast(session, () => progress.runsFor(id, index) == before);
    expect(progress.runsFor(id, index), before + 1);
  }

  const den = DungeonId.SPIDER_DEN;

  group('reset', () {
    test('sends the dungeon back to floor 1 and stops its floor', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      clearFloorOnce(session, den, 0);
      expect(dungeons.lockReason(den, 1), isNull);
      expect(session.actionTimingController.isRunning, isTrue);

      dungeons.resetDungeon(den);

      expect(session.actionTimingController.isRunning, isFalse);
      expect(session.saveGameData.dungeonRun.runningSlot, -1);
      expect(dungeons.isCleared(den, 0), isFalse);
      expect(dungeons.lockReason(den, 0), isNull);
      expect(dungeons.lockReason(den, 1), "Complete Webbed Thicket to unlock");
      expect(dungeons.currentFloor(den), 0);
      // the lifetime tally is a stat, and survives
      expect(dungeons.lifetimeRuns(den, 0), 1);
      // every floor is rebuilt fresh
      final slot = session.saveGameData.dungeonRun.slots[0];
      expect(slot.index, 0);
      expect(
        slot.members.first.count,
        den.definition.entries[0].entities[0].count,
      );

      session.dispose();
    });

    test('leaves a floor running in another dungeon alone', () {
      final session = buildSession();
      makePlayerStrong(session);
      session.dungeonController.startSlot(den, 0);

      session.dungeonController.resetDungeon(DungeonId.WOLF_DEN);

      expect(session.actionTimingController.isRunning, isTrue);
      expect(session.saveGameData.dungeonRun.runningSlot, 0);
      session.dispose();
    });

    test('keeps a landmark\'s key paid', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const lair = DungeonId.GOBLIN_QUEEN_LAIR;
      session.inventoryService.setItemCount(
        session.saveGameData.inventoryData,
        ItemId.GOBLIN_QUEEN_KEY,
        1,
      );

      clearFloorOnce(session, lair, 0);
      expect(dungeons.keyPaid(lair), isTrue);
      expect(dungeons.keyCount(lair), 0);

      dungeons.resetDungeon(lair);

      // no key in the bag, and the first floor is still open
      expect(dungeons.keyPaid(lair), isTrue);
      expect(dungeons.lockReason(lair, 0), isNull);
      expect(dungeons.lockReason(lair, 1), isNotNull);
      session.dispose();
    });
  });

  group('the full-clear chest', () {
    test('is earned once a run, and again after a reset', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      clearFloorOnce(session, den, 0);
      expect(dungeons.chestsWaiting(den), 0);
      expect(dungeons.mainFloorsCleared(den), 1);

      clearFloorOnce(session, den, 1);
      expect(dungeons.chestsWaiting(den), 1);
      expect(dungeons.chestEarned(den), isTrue);

      // Loop floor laps the boss floor; a second clear earns nothing more
      final progress = progressOf(session);
      final laps = progress.runsFor(den, 1);
      fightPast(session, () => progress.runsFor(den, 1) == laps);
      expect(progress.runsFor(den, 1), laps + 1);
      expect(dungeons.chestsWaiting(den), 1);

      // a reset lets it be earned again, and the one waiting stays
      dungeons.resetDungeon(den);
      expect(dungeons.chestEarned(den), isFalse);
      expect(dungeons.chestsWaiting(den), 1);

      clearFloorOnce(session, den, 0);
      clearFloorOnce(session, den, 1);
      expect(dungeons.chestsWaiting(den), 2);
      session.dispose();
    });

    test('needs only the main floors', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const dev = DungeonId.DEV_TRANSIENT_DUNGEON;
      // the ore floor beside the path is never cleared
      expect(dungeons.mainFloorCount(dev), 3);

      clearFloorOnce(session, dev, 0);
      clearFloorOnce(session, dev, 2);
      clearFloorOnce(session, dev, 3);

      expect(dungeons.isCleared(dev, 1), isFalse);
      expect(dungeons.chestsWaiting(dev), 1);
      session.dispose();
    });

    test('stacked chests all open on one claim, into the bag', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      final progress = progressOf(session);
      // two runs' chests, waiting
      progress.earnChest(den);
      progress.resetRun(den);
      progress.earnChest(den);
      expect(dungeons.chestsWaiting(den), 2);

      final inventory = session.saveGameData.inventoryData;
      final coinsBefore = session.inventoryService.getItemCount(
        inventory,
        ItemId.COINS,
      );

      final loot = dungeons.claimChests(den);

      expect(dungeons.chestsWaiting(den), 0);
      // the stand-in table pays a guaranteed purse per chest
      final floors = den.definition.mainFloors.length;
      final coins = loot.firstWhere((s) => s.id == ItemId.COINS).count;
      expect(coins, greaterThanOrEqualTo(2 * 50 * floors));
      expect(
        session.inventoryService.getItemCount(inventory, ItemId.COINS),
        coinsBefore + coins,
      );
      // nothing left to claim
      expect(dungeons.claimChests(den), isEmpty);
      session.dispose();
    });
  });

  group('loop dungeon', () {
    test('runs on into the next floor and comes back round', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      final run = session.saveGameData.dungeonRun;
      makePlayerStrong(session);
      dungeons.setLoopDungeon(den, true);

      dungeons.startSlot(den, 0);
      fightPast(session, () => run.runningSlot == 0);

      // floor 1 cleared, and the loop walked straight on without stopping
      expect(run.runningSlot, 1);
      expect(session.actionTimingController.isRunning, isTrue);
      expect(dungeons.isCleared(den, 0), isTrue);
      expect(dungeons.currentFloor(den), 1);
      // the floor left behind is back at the top
      expect(run.slots[0].index, 0);

      fightPast(session, () => dungeons.chestsWaiting(den) == 0);

      // off the last floor: the chest, then back to the top, relocked
      expect(dungeons.chestsWaiting(den), 1);
      expect(run.runningSlot, 0);
      expect(session.actionTimingController.isRunning, isTrue);
      expect(dungeons.isCleared(den, 0), isFalse);
      expect(dungeons.lockReason(den, 1), isNotNull);
      expect(dungeons.chestEarned(den), isFalse);

      // and the next lap earns the next chest
      fightPast(session, () => dungeons.chestsWaiting(den) == 1);
      expect(dungeons.chestsWaiting(den), 2);
      session.dispose();
    });

    test('walks past a side floor', () {
      final session = buildSession();
      final run = session.saveGameData.dungeonRun;
      makePlayerStrong(session);
      const dev = DungeonId.DEV_TRANSIENT_DUNGEON;
      session.dungeonController.setLoopDungeon(dev, true);

      session.dungeonController.startSlot(dev, 0);
      fightPast(session, () => run.runningSlot == 0);

      expect(run.runningSlot, 2);
      session.dispose();
    });

    test('a side floor still loops itself', () {
      final session = buildSession();
      final run = session.saveGameData.dungeonRun;
      makePlayerStrong(session);
      const dev = DungeonId.DEV_TRANSIENT_DUNGEON;
      session.dungeonController.setLoopDungeon(dev, true);

      clearFloorOnce(session, dev, 1);

      expect(run.runningSlot, 1);
      expect(session.actionTimingController.isRunning, isTrue);
      session.dispose();
    });

    test('carries a player watching the floor on to the next', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      final encounters = session.encounterController;
      final run = session.saveGameData.dungeonRun;
      makePlayerStrong(session);
      dungeons.setLoopDungeon(den, true);

      // on floor 1's encounter screen, fighting it
      final token = dungeons.enterSlot(den, 0);
      expect(token, isNotNull);
      expect(dungeons.startViewedFloor(), isTrue);
      fightPast(session, () => run.runningSlot == 0);
      expect(run.runningSlot, 1);

      // the screen is on the floor the loop moved to, not offering to
      // start the one it left
      expect(encounters.floorToStart, isNull);
      expect(encounters.isViewingActiveEncounter(), isTrue);

      dungeons.leaveSlot(token!);
      session.dispose();
    });
  });

  group('persistence', () {
    test('run clears, chests and loop mode round-trip', () {
      final progress = DungeonProgressData();
      progress.recordRun(den, 0);
      progress.recordRun(den, 1);
      progress.earnChest(den);
      progress.setLoopDungeon(den, true);
      progress.markKeyPaid(DungeonId.GOBLIN_QUEEN_LAIR);

      final json = progress.toJson();
      (json['cleared'] as Map)['NOT_A_DUNGEON'] = [0];
      (json['chests'] as Map)['NOT_A_DUNGEON'] = 3;
      (json['loopDungeon'] as List).add('NOT_A_DUNGEON');

      final restored = DungeonProgressData.fromJson(json);
      expect(restored.hasCleared(den, 0), isTrue);
      expect(restored.hasCleared(den, 1), isTrue);
      expect(restored.chestsWaiting(den), 1);
      expect(restored.chestEarnedThisRun(den), isTrue);
      expect(restored.loopsDungeon(den), isTrue);
      expect(restored.keyPaid(DungeonId.GOBLIN_QUEEN_LAIR), isTrue);
      expect(restored.cleared.length, 1);
      expect(restored.chests.length, 1);
      expect(restored.loopDungeon.length, 1);
    });

    test('a save from before resets starts every dungeon at floor 1', () {
      // the old shape: lifetime runs were the unlocks
      final restored = DungeonProgressData.fromJson({
        'runs': {
          'SPIDER_DEN': {'0': 4, '1': 2},
        },
        'keysPaid': ['GOBLIN_QUEEN_LAIR'],
      });

      expect(restored.hasCleared(den, 0), isFalse);
      expect(restored.hasCleared(den, 1), isFalse);
      expect(restored.runsFor(den, 0), 4);
      expect(restored.runsFor(den, 1), 2);
      expect(restored.keyPaid(DungeonId.GOBLIN_QUEEN_LAIR), isTrue);
      expect(restored.loopsDungeon(den), isFalse);
      expect(restored.chestsWaiting(den), 0);
    });
  });
}
