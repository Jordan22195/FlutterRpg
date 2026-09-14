import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/dungeon_progress_data.dart';
import 'package:rpg/data/dungeon_run.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  // crank combat skills so the player reliably kills and survives, making
  // a full clear deterministic enough to loop to completion
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
    // and keep them fed: a floor loops for as long as its conditions hold,
    // so an unfed player stops the loop partway through a long lap
    session.saveGameData.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 200000;
    session.saveGameData.playerData.equipmentData.equipedFood =
        ItemId.COOKED_CHICKEN;
  }

  /// Runs the encounter tick until the loop stops. A floor never stops on
  /// its own now, so this is only for the paths that do stop it.
  int fightUntilStopped(GameSession session, {int limit = 20000}) {
    var ticks = 0;
    while (session.actionTimingController.isRunning && ticks < limit) {
      session.encounterController.doEncounterAction(1);
      ticks++;
    }
    return ticks;
  }

  /// Ticks while [waiting] is still true, up to [limit].
  int fightPast(
    GameSession session,
    bool Function() waiting, {
    int limit = 20000,
  }) {
    var ticks = 0;
    while (waiting() && ticks < limit) {
      session.encounterController.doEncounterAction(1);
      ticks++;
    }
    return ticks;
  }

  /// Ticks a fixed number of times, whatever the floor is doing.
  void fightFor(GameSession session, int ticks) {
    for (int i = 0; i < ticks; i++) {
      session.encounterController.doEncounterAction(1);
    }
  }

  DungeonProgressData progressOf(GameSession session) =>
      session.saveGameData.dungeonProgress;

  /// Starts floor [index] and fights until it books one more clear. The
  /// floor is still looping when this returns — that is what floors do.
  void clearFloorOnce(GameSession session, DungeonId id, int index) {
    final progress = progressOf(session);
    final before = progress.runsFor(id, index);
    session.dungeonController.startSlot(id, index);
    fightPast(session, () => progress.runsFor(id, index) == before);
  }

  /// Clears every floor above [index] so it is unlocked.
  void unlockUpTo(GameSession session, DungeonId id, int index) {
    for (int i = 0; i < index; i++) {
      clearFloorOnce(session, id, i);
    }
  }

  void giveKey(GameSession session) {
    session.inventoryService.setItemCount(
      session.saveGameData.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );
  }

  group('gating', () {
    test('the key gates only the first floor, and only until it is paid', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      const id = DungeonId.GOBLIN_QUEEN_LAIR;

      expect(dungeons.lockReason(id, 0), 'Requires Goblin Queen Key');
      giveKey(session);
      expect(dungeons.lockReason(id, 0), isNull);

      // paying it once opens the dungeon for good
      makePlayerStrong(session);
      expect(dungeons.startSlot(id, 0), isTrue);
      expect(dungeons.keyPaid(id), isTrue);
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.GOBLIN_QUEEN_KEY,
        ),
        0,
      );
      expect(dungeons.lockReason(id, 0), isNull);

      session.dispose();
    });

    test('a floor waits on the one above it unless it opts out', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      expect(dungeons.lockReason(id, 0), isNull);
      // the ore floor sets requiresPrevious: false
      expect(dungeons.lockReason(id, 1), isNull);
      expect(
        dungeons.lockReason(id, 2),
        'Complete Test Skippable Ore to unlock',
      );

      session.dispose();
    });

    test('clearing a floor unlocks the next one, permanently', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      expect(dungeons.lockReason(id, 2), isNotNull);

      clearFloorOnce(session, id, 1);

      expect(progressOf(session).hasCleared(id, 1), isTrue);
      expect(dungeons.lockReason(id, 2), isNull);

      // and it survives the floor being reset out from under it
      dungeons.resetRunningFloor();
      expect(dungeons.lockReason(id, 2), isNull);
      expect(dungeons.isCleared(id, 1), isTrue);

      session.dispose();
    });

    test('a floor unlocked once is still unlocked after a reload', () {
      final session = buildSession();
      final save = session.saveGameData;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      clearFloorOnce(session, id, 1);
      final lifetime = progressOf(session).runsFor(id, 1);
      expect(lifetime, greaterThan(0));

      final restored = SaveGameData.fromJson(save.toJson()).dungeonProgress;
      expect(restored.hasCleared(id, 1), isTrue);
      expect(restored.runsFor(id, 1), lifetime);

      session.dispose();
    });
  });

  group('the queue', () {
    test('a spent member hands off to the next without stopping the loop', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      // three goblins, then a giant spider
      dungeons.startSlot(id, 0);

      final slot = save.dungeonRun.slots[0];
      expect(slot.members.length, 2);
      expect(slot.index, 0);
      expect(session.encounterController.queueRemaining().length, 1);

      // fight until the first member is spent and the second is live
      fightPast(session, () => slot.index == 0);

      expect(slot.index, 1);
      expect(slot.current?.id, EntityId.GIANT_SPIDER);
      // the loop kept running across the boundary
      expect(session.actionTimingController.isRunning, isTrue);
      // and the rail is empty now that the boss is the one on screen
      expect(session.encounterController.queueRemaining(), isEmpty);

      session.dispose();
    });

    test('clearing the last member books the floor and pays out', () {
      final session = buildSession();
      final save = session.saveGameData;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      // the boss floor, reachable only once the one above it is done
      unlockUpTo(session, id, 3);

      // everything in the bag but the food the player is eating through
      int haul() =>
          save.inventoryData.itemMap.entries
              .where((e) => e.key != ItemId.COOKED_CHICKEN)
              .fold<int>(0, (sum, e) => sum + e.value) +
          save.inventoryData.equipment.fold<int>(0, (sum, e) => sum + e.count);
      final before = haul();

      clearFloorOnce(session, id, 3);

      expect(progressOf(session).runsFor(id, 3), 1);
      // the clear went straight into another lap rather than stopping
      expect(session.actionTimingController.isRunning, isTrue);
      expect(save.dungeonRun.runningSlot, 3);

      // the boss paid out one roll of its table. which line it rolled is a
      // coin flip - a nested spider table, a coin stack, or a silk necklace
      // that lands in equipment rather than the item map - so the assertion
      // is that the bag grew, not what it grew by
      expect(
        haul(),
        greaterThan(before),
        reason: 'the boss should have paid out one roll of its table',
      );

      session.dispose();
    });

    test('a non-combat floor clears the same way', () {
      final session = buildSession();
      final save = session.saveGameData;
      makePlayerStrong(session);

      clearFloorOnce(session, DungeonId.DEV_TRANSIENT_DUNGEON, 1); // 10 iron

      expect(
        progressOf(session).runsFor(DungeonId.DEV_TRANSIENT_DUNGEON, 1),
        1,
      );
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.IRON_ORE,
        ),
        greaterThanOrEqualTo(1),
      );

      session.dispose();
    });

    test('duplicate entity ids across floors stay separate', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      // the dev dungeon repeats GOBLIN in floors 0 and 2
      dungeons.startSlot(id, 0);
      final first = save.dungeonRun.slots[0].members.first;
      final duplicate = save.dungeonRun.slots[2].members.first;
      expect(first.id, duplicate.id);
      expect(identical(first, duplicate), isFalse);

      session.encounterController.doEncounterAction(1);

      // the screen resolves through the running floor, not the shared id
      expect(
        identical(session.encounterController.getActiveEntity(), first),
        isTrue,
      );
      expect(duplicate.count, 3);
      expect(duplicate.hitpoints, duplicate.maxHitPoints);

      session.dispose();
    });
  });

  group('the action button', () {
    // the primary button re-calls its start function on every press (and
    // again on the drag-to-lock), so this path runs constantly mid-floor
    test('re-pressing it keeps the floor running rather than dropping it', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.startSlot(DungeonId.SPIDER_DEN, 0);
      final railBefore = session.encounterController.queueRemaining().length;
      expect(railBefore, greaterThan(0));

      // what MomentumPrimaryButton calls on press
      session.encounterController.startEncounterAction();

      expect(save.dungeonRun.runningSlot, 0);
      expect(session.encounterController.queueRemaining().length, railBefore);
      expect(session.actionTimingController.isRunning, isTrue);

      // and the queue still hands off to the next member
      final slot = save.dungeonRun.slots[0];
      fightPast(session, () => slot.index == 0);
      expect(slot.index, 1);

      session.dispose();
    });
  });

  group('walking away resets the floor', () {
    test('starting a zone entity resets it', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.startSlot(DungeonId.DEV_TRANSIENT_DUNGEON, 0);
      final slot = save.dungeonRun.slots[0];
      final fullCount = slot.members.first.count;
      fightFor(session, 5);
      expect(
        slot.members.first.count < fullCount ||
            slot.members.first.hitpoints < slot.members.first.maxHitPoints,
        isTrue,
      );

      // the action queue starts world entities through the same entry point
      final zoneEntity = EntityId.TREE.build();
      session.encounterController.startEncounterActionFor(
        zoneEntity as EncounterEntity,
      );

      expect(save.dungeonRun.runningSlot, -1);
      expect(session.encounterController.queueRemaining(), isEmpty);
      // back to the top, full again
      final reset = save.dungeonRun.slots[0];
      expect(reset.index, 0);
      expect(reset.members.first.count, fullCount);
      expect(reset.members.first.hitpoints, reset.members.first.maxHitPoints);

      session.dispose();
    });

    test('exploring resets it — the bound-action hook, not the encounter '
        'path', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.startSlot(DungeonId.DEV_TRANSIENT_DUNGEON, 0);
      final fullCount = save.dungeonRun.slots[0].members.first.count;
      fightFor(session, 5);

      session.worldController.startExplore();

      expect(save.dungeonRun.runningSlot, -1);
      expect(save.dungeonRun.slots[0].index, 0);
      expect(save.dungeonRun.slots[0].members.first.count, fullCount);

      session.dispose();
    });

    test('the laps done on a floor reset with it', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      clearFloorOnce(session, id, 1);
      expect(dungeons.sessionRuns(id, 1), 1);
      expect(dungeons.lifetimeRuns(id, 1), 1);

      dungeons.resetRunningFloor();

      // the lap count is "since this floor last started", so it goes
      expect(dungeons.sessionRuns(id, 1), 0);
      expect(save.dungeonRun.runningSlot, -1);
      // the lifetime tally never does
      expect(dungeons.lifetimeRuns(id, 1), 1);

      session.dispose();
    });

    test('starting another floor resets the one that was running', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      dungeons.startSlot(id, 0);
      final fullCount = save.dungeonRun.slots[0].members.first.count;
      fightFor(session, 5);

      dungeons.startSlot(id, 1);

      expect(save.dungeonRun.runningSlot, 1);
      expect(save.dungeonRun.slots[0].index, 0);
      expect(save.dungeonRun.slots[0].members.first.count, fullCount);

      session.dispose();
    });

    test('looking at another dungeon leaves the running floor alone', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.startSlot(DungeonId.DEV_TRANSIENT_DUNGEON, 0);
      fightFor(session, 5);
      final running = save.dungeonRun.slots[0];

      // what the other dungeon's screen reads to paint its floors
      final other = dungeons.slotsFor(DungeonId.GRAINERY);
      expect(other, isNotEmpty);
      expect(other.first.members, isNotEmpty);

      expect(save.dungeonRun.dungeonId, DungeonId.DEV_TRANSIENT_DUNGEON);
      expect(save.dungeonRun.runningSlot, 0);
      expect(identical(save.dungeonRun.slots[0], running), isTrue);
      expect(session.actionTimingController.isRunning, isTrue);

      session.dispose();
    });
  });

  group('startability', () {
    test('every unlocked floor is re-runnable, keyed ones included', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      giveKey(session);
      const id = DungeonId.GOBLIN_QUEEN_LAIR;

      expect(dungeons.startable(id, 0), isTrue);
      clearFloorOnce(session, id, 0);

      expect(dungeons.startable(id, 0), isTrue);
      expect(dungeons.startable(id, 1), isTrue);

      session.dispose();
    });
  });

  group('looping the floor you are in', () {
    test('a cleared floor refills and carries straight on', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      dungeons.startSlot(id, 1); // the ore floor
      final progress = progressOf(session);
      final ticks = fightPast(session, () => progress.runsFor(id, 1) == 0);

      // the floor cleared, and the loop carried straight into another lap
      expect(progress.runsFor(id, 1), 1);
      expect(dungeons.sessionRuns(id, 1), 1);
      expect(session.actionTimingController.isRunning, isTrue);
      expect(save.dungeonRun.runningSlot, 1);
      // refilled: the queue is back at its first member with a full count
      expect(save.dungeonRun.slots[1].cleared, isFalse);
      expect(save.dungeonRun.slots[1].index, 0);
      expect(save.dungeonRun.slots[1].members.first.count, 10);
      expect(ticks, lessThan(20000));

      // and it keeps going, lap after lap
      fightPast(session, () => progress.runsFor(id, 1) < 2);
      expect(progress.runsFor(id, 1), greaterThanOrEqualTo(2));
      expect(dungeons.sessionRuns(id, 1), progress.runsFor(id, 1));
      expect(session.actionTimingController.isRunning, isTrue);

      session.dispose();
    });

    test('a one-shot dungeon laps too — every floor repeats now', () {
      final session = buildSession();
      final save = session.saveGameData;
      makePlayerStrong(session);
      giveKey(session);
      const id = DungeonId.GOBLIN_QUEEN_LAIR;

      final progress = progressOf(session);
      clearFloorOnce(session, id, 0);
      fightPast(session, () => progress.runsFor(id, 0) < 2);

      expect(progress.runsFor(id, 0), greaterThanOrEqualTo(2));
      expect(session.actionTimingController.isRunning, isTrue);
      expect(save.dungeonRun.runningSlot, 0);

      session.dispose();
    });

    test('a lap keeps the drop log and the momentum it built', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      // ObjectStacks are rebuilt per read and don't compare, so the log is
      // measured by what it holds
      int logged() => session.encounterController.itemDrops().fold<int>(
        0,
        (sum, stack) => sum + stack.count,
      );

      final progress = progressOf(session);
      dungeons.startSlot(id, 1); // 10 iron
      fightPast(session, () => progress.runsFor(id, 1) == 0);
      final atClear = logged();
      expect(atClear, greaterThan(0));

      // a lap binds in place - it never stops the loop - so the boost the
      // player built up crossing the floor boundary survives it
      save.actionTimingData.percentOfMaxBoost = 0.5;
      fightFor(session, 200);
      expect(logged(), greaterThan(atClear));
      expect(save.actionTimingData.percentOfMaxBoost, greaterThan(0.0));

      // tapping a different floor is a different haul
      dungeons.startSlot(id, 0);
      expect(logged(), 0);

      session.dispose();
    });

    test('a floor with nothing fightable in it does not open', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.startSlot(DungeonId.DEV_TRANSIENT_DUNGEON, 1);

      // an emptied floor would clear again the instant it started, looping
      // at no cost - the system refuses to open it instead
      save.dungeonRun.slots[1].members.first.count = 0;
      save.dungeonRun.slots[1].index = 0;
      expect(session.dungeonSystem.openSlot(save.dungeonRun, 1), isNull);

      session.dispose();
    });
  });

  group('the entry key', () {
    test('is charged once ever, and only on the first floor', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      giveKey(session);
      const id = DungeonId.GOBLIN_QUEEN_LAIR;

      expect(dungeons.showsKeyNote(id, 0), isTrue);
      expect(dungeons.showsKeyNote(id, 1), isFalse);
      expect(dungeons.willSpendKey(id, 0), isTrue);

      dungeons.startSlot(id, 0);
      expect(dungeons.keyPaid(id), isTrue);
      expect(dungeons.willSpendKey(id, 0), isFalse);

      // a second key in the bag is not taken by re-running the floor, nor
      // by walking away and coming back
      giveKey(session);
      dungeons.resetRunningFloor();
      dungeons.startSlot(id, 0);
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.GOBLIN_QUEEN_KEY,
        ),
        1,
      );

      // and the dungeon is still open after a reload
      final restored = SaveGameData.fromJson(save.toJson()).dungeonProgress;
      expect(restored.keyPaid(id), isTrue);

      session.dispose();
    });

    test('with no key in the bag there is nothing to spend', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      const id = DungeonId.GOBLIN_QUEEN_LAIR;

      expect(dungeons.showsKeyNote(id, 0), isTrue);
      expect(dungeons.willSpendKey(id, 0), isFalse);
      expect(dungeons.startable(id, 0), isFalse);

      session.dispose();
    });
  });

  group('what used to cost you the dungeon', () {
    test('running a transient dungeon does not consume its entrance', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      save.playerData.currentZoneId = ZoneId.DEV_DUNGEON_TESTING;
      session.explorationService.addEntityToCurrentZone(
        EntityId.DEV_DUNGEON_ENTRANCE,
        1,
        save.playerData,
        save.worldData,
      );
      final zone = save.worldData.zones[ZoneId.DEV_DUNGEON_TESTING]!;
      bool entranceStands() => zone.discoveredEntities.any(
        (e) => e.id == EntityId.DEV_DUNGEON_ENTRANCE,
      );
      expect(entranceStands(), isTrue);

      dungeons.startSlot(DungeonId.DEV_TRANSIENT_DUNGEON, 0);
      fightFor(session, 20);
      dungeons.resetRunningFloor();

      expect(entranceStands(), isTrue);

      session.dispose();
    });

    test('dying resets the floor but keeps what was unlocked', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      const id = DungeonId.DEV_TRANSIENT_DUNGEON;

      clearFloorOnce(session, id, 1);
      final fullCount = save.dungeonRun.slots[1].members.first.count;
      fightFor(session, 5);

      // what the shell does on death
      save.playerData.hitpoints = 0;
      dungeons.resetRunningFloor();

      expect(save.dungeonRun.runningSlot, -1);
      expect(save.dungeonRun.slots[1].index, 0);
      expect(save.dungeonRun.slots[1].members.first.count, fullCount);
      // the unlock and the lifetime tally stand
      expect(dungeons.isCleared(id, 1), isTrue);
      expect(dungeons.lifetimeRuns(id, 1), greaterThan(0));
      expect(dungeons.lockReason(id, 2), isNull);

      session.dispose();
    });
  });

  group('persistence', () {
    test('a running floor survives a save round-trip', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      giveKey(session);

      dungeons.startSlot(DungeonId.GOBLIN_QUEEN_LAIR, 0);
      // one hit so the live enemy has partial hp to preserve
      session.encounterController.doEncounterAction(1);
      save.dungeonRun.sessionRuns[0] = 4;

      final live = save.dungeonRun.slots[0].members.first;
      final restored = SaveGameData.fromJson(save.toJson());
      final run = restored.dungeonRun;

      expect(run.active, isTrue);
      expect(run.dungeonId, DungeonId.GOBLIN_QUEEN_LAIR);
      expect(run.runningSlot, 0);
      expect(run.sessionRuns[0], 4);
      expect(run.slots.length, save.dungeonRun.slots.length);
      expect(run.slots[0].name, 'Warren Entrance');
      expect(run.slots[0].index, save.dungeonRun.slots[0].index);
      // a half-killed enemy comes back half-killed
      expect(run.slots[0].current?.hitpoints, live.hitpoints);
      expect(run.slots[0].current?.count, live.count);

      session.dispose();
    });

    test('progress round-trips, and drops what no longer parses', () {
      final progress = DungeonProgressData();
      progress.recordRun(DungeonId.SPIDER_DEN, 0);
      progress.recordRun(DungeonId.SPIDER_DEN, 0);
      progress.recordRun(DungeonId.SPIDER_DEN, 2);
      progress.markKeyPaid(DungeonId.GOBLIN_QUEEN_LAIR);

      final json = progress.toJson();
      (json['runs'] as Map)['NOT_A_DUNGEON'] = {'0': 3};
      (json['keysPaid'] as List).add('NOT_A_DUNGEON');

      final restored = DungeonProgressData.fromJson(json);
      expect(restored.runsFor(DungeonId.SPIDER_DEN, 0), 2);
      expect(restored.runsFor(DungeonId.SPIDER_DEN, 2), 1);
      expect(restored.hasCleared(DungeonId.SPIDER_DEN, 1), isFalse);
      expect(restored.keyPaid(DungeonId.GOBLIN_QUEEN_LAIR), isTrue);
      expect(restored.runs.length, 1);
      expect(restored.keysPaid.length, 1);
    });

    test('the dungeon ui state round-trips', () {
      final session = buildSession();
      final save = session.saveGameData;

      save.uiState.dungeonId = DungeonId.SPIDER_DEN;
      save.uiState.dungeonSlot = 2;

      final ui = SaveGameData.fromJson(save.toJson()).uiState;
      expect(ui.dungeonId, DungeonId.SPIDER_DEN);
      expect(ui.dungeonSlot, 2);

      session.dispose();
    });

    test('a save from before floor lists loads as an inactive run', () {
      final legacy = {
        'active': true,
        'dungeonId': 'GOBLIN_QUEEN_LAIR',
        'floorIndex': 1,
        'packIndex': 0,
        'maxClearedFloor': 0,
        'awaitingFloorChoice': false,
      };
      final run = DungeonRun.fromJson(legacy);
      expect(run.active, isFalse);
      expect(run.slots, isEmpty);
    });

    test('a save from before permanent floors loads with none unlocked', () {
      final session = buildSession();
      final save = session.saveGameData;
      makePlayerStrong(session);
      session.dungeonController.startSlot(DungeonId.DEV_TRANSIENT_DUNGEON, 0);

      // the shape the old save wrote: run-scoped progress, no progress block
      final json = save.toJson();
      json.remove('dungeonProgress');
      (json['dungeonRun'] as Map<String, dynamic>)
        ..['cleared'] = [0, 1]
        ..['keySpent'] = true
        ..['loot'] = {'itemMap': {}};

      final restored = SaveGameData.fromJson(json);
      expect(restored.dungeonRun.active, isTrue);
      expect(restored.dungeonRun.dungeonId, DungeonId.DEV_TRANSIENT_DUNGEON);
      expect(restored.dungeonProgress.runs, isEmpty);
      expect(restored.dungeonProgress.keysPaid, isEmpty);

      session.dispose();
    });
  });
}
