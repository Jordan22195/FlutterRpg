import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/game_session.dart';

// Fishing and herbalism settle a whole stretch of time away in one fire, the
// way combat and crafting do. These cover what a batch owes the loop it
// stands in for: the same expected haul, the same xp, and an honest count of
// the actions it actually performed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  // puts [count] of [id] in the player's zone and opens an encounter on it
  EncounterEntity encounterWith(GameSession session, EntityId id, int count) {
    final save = session.saveGameData;
    session.explorationService.addEntityToCurrentZone(
      id,
      count,
      save.playerData,
      save.worldData,
    );
    final entity =
        session.explorationService.getEntity(
              id,
              save.playerData.currentZoneId,
              save.worldData,
            )
            as EncounterEntity;
    session.encounterService.setEncounterEntity(save.encounterData, entity);
    return entity;
  }

  // how many actions a gap of [seconds] is worth at the interval the loop
  // will run at: the bench default divided by the fast stance's speed
  // curve, rounded to the millisecond the way getCurrentActionDuration does
  int actionsIn(GameSession session, double seconds) {
    final scratch = ActionTimingData()
      ..maxInterval = session.actionTimingSystem.intervalFor(
        null,
        session.saveGameData.playerData,
      );
    final interval = ActionTimingService().getCurrentActionDuration(scratch);
    return (seconds * 1e6 ~/ interval.inMicroseconds);
  }

  int itemsIn(EncounterActionResult result) =>
      result.items.fold<int>(0, (sum, stack) => sum + stack.count);

  double xpFor(GameSession session, SkillId skill) =>
      session.saveGameData.playerData.skillData[skill]!.xp;

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  group('herbalism', () {
    EncounterActionResult pick(
      GameSession session, {
      int actionCount = 1,
      bool offline = true,
    }) {
      final save = session.saveGameData;
      return session.encounterSystem.executeHerbalismAction(
        playerState: save.playerData,
        encounter: save.encounterData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
        actionCount: actionCount,
        offline: offline,
      );
    }

    test('a batch picks the whole patch and says how many that was', () {
      final session = buildSession();
      final save = session.saveGameData;
      final herb = encounterWith(session, EntityId.GUAM, 40);

      final result = pick(session, actionCount: 40);

      expect(result.actionsPerformed, 40);
      expect(herb.count, 0);
      // one guaranteed herb a pick, plus up to four bonus ones
      expect(itemsIn(result), inInclusiveRange(40, 40 * 5));
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.GUAM_LEAF,
        ),
        itemsIn(result),
      );
      session.dispose();
    });

    test('the patch caps the batch, not the count it was handed', () {
      final session = buildSession();
      final herb = encounterWith(session, EntityId.GUAM, 3);

      final result = pick(session, actionCount: 500);

      // three herbs is three picks, and the loop would have stopped there
      expect(result.actionsPerformed, 3);
      expect(herb.count, 0);
      expect(itemsIn(result), inInclusiveRange(3, 15));
      session.dispose();
    });

    test('a stripped patch gathers nothing', () {
      final session = buildSession();
      encounterWith(session, EntityId.GUAM, 1);
      pick(session, actionCount: 1);

      final result = pick(session, actionCount: 100);

      expect(result.actionsPerformed, 0);
      expect(result.items, isEmpty);
      expect(result.xp, isEmpty);
      session.dispose();
    });

    test('xp is what the herbs it reported are worth', () {
      final session = buildSession();
      encounterWith(session, EntityId.GUAM, 20);
      final xpBefore = xpFor(session, SkillId.HERBALISM);

      final result = pick(session, actionCount: 20);

      final expected = itemsIn(result) * ItemId.GUAM_LEAF.definition.xpValue;
      expect(result.xp[SkillId.HERBALISM], closeTo(expected, 1e-6));
      expect(
        xpFor(session, SkillId.HERBALISM),
        closeTo(xpBefore + expected, 1e-6),
      );
      session.dispose();
    });

    test('a batch hauls what the same number of picks would', () {
      const picks = 300;

      final looped = buildSession();
      setLevel(looped, SkillId.HERBALISM, 20);
      encounterWith(looped, EntityId.GUAM, picks);
      var loopedHaul = 0;
      for (var i = 0; i < picks; i++) {
        loopedHaul += itemsIn(pick(looped, offline: false));
      }

      final batched = buildSession();
      setLevel(batched, SkillId.HERBALISM, 20);
      encounterWith(batched, EntityId.GUAM, picks);
      final batchedHaul = itemsIn(pick(batched, actionCount: picks));

      // the batch pays each pick the mean of its yield range, so it lands
      // where a few hundred rolls of it average out
      expect(batchedHaul, closeTo(loopedHaul, loopedHaul * 0.1));
      looped.dispose();
      batched.dispose();
    });
  });

  group('fishing', () {
    EncounterActionResult cast(
      GameSession session, {
      int actionCount = 1,
      bool offline = true,
    }) {
      final save = session.saveGameData;
      return session.encounterSystem.executeFishingAction(
        playerState: save.playerData,
        encounter: save.encounterData,
        world: save.worldData,
        playerInventory: save.inventoryData,
        actionCount: actionCount,
        offline: offline,
      );
    }

    test('every cast counts, and the ones that caught pay out', () {
      final session = buildSession();
      final save = session.saveGameData;
      final pond = encounterWith(session, EntityId.TRANQUIL_POND, 1);

      final result = cast(session, actionCount: 100);

      // a cast is an action whether or not it caught anything
      expect(result.actionsPerformed, 100);
      expect(itemsIn(result), greaterThan(0));
      expect(itemsIn(result), lessThanOrEqualTo(100));
      // a spot replenishes rather than depleting: it is still there to fish
      expect(pond.count, 1);
      expect(
        result.items
            .map((stack) => stack.id)
            .every((id) => [ItemId.MINNOW, ItemId.CARP].contains(id)),
        isTrue,
      );
      expect(
        session.inventoryService.getItemCount(
              save.inventoryData,
              ItemId.MINNOW,
            ) +
            session.inventoryService.getItemCount(
              save.inventoryData,
              ItemId.CARP,
            ),
        itemsIn(result),
      );
      session.dispose();
    });

    test('xp is what the catch it reported is worth', () {
      final session = buildSession();
      encounterWith(session, EntityId.TRANQUIL_POND, 1);
      final xpBefore = xpFor(session, SkillId.FISHING);

      final result = cast(session, actionCount: 100);

      var expected = 0.0;
      for (final stack in result.items) {
        expected += stack.id.definition.xpValue * stack.count;
      }
      expect(result.xp[SkillId.FISHING], closeTo(expected, 1e-6));
      expect(
        xpFor(session, SkillId.FISHING),
        closeTo(xpBefore + expected, 1e-6),
      );
      session.dispose();
    });

    test('a batch catches what the same number of casts would', () {
      const casts = 400;

      final looped = buildSession();
      setLevel(looped, SkillId.FISHING, 20);
      encounterWith(looped, EntityId.TRANQUIL_POND, 1);
      var loopedCatch = 0;
      for (var i = 0; i < casts; i++) {
        loopedCatch += itemsIn(cast(looped, offline: false));
      }

      final batched = buildSession();
      setLevel(batched, SkillId.FISHING, 20);
      encounterWith(batched, EntityId.TRANQUIL_POND, 1);
      final batchedCatch = itemsIn(cast(batched, actionCount: casts));

      expect(loopedCatch, greaterThan(0));
      // the batch takes the exact share of casts that catch, where the loop
      // rolls each one, so a few hundred casts land close either way
      expect(batchedCatch, closeTo(loopedCatch, loopedCatch * 0.2));
      looped.dispose();
      batched.dispose();
    });
  });

  group('settling time away', () {
    test('a gap strips the patch and stops the loop', () {
      final session = buildSession();
      final save = session.saveGameData;
      final herb = encounterWith(session, EntityId.GUAM, 5);

      expect(session.encounterController.startEncounterActionFor(herb), isTrue);

      // 60s away at the 3s bare-handed interval is 20 picks, but the patch
      // holds five
      final now = DateTime.now();
      save.playerData.lastActionTime = now.subtract(
        const Duration(seconds: 60),
      );
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      expect(herb.count, 0);

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      expect(report!.actionCount, 5);
      expect(report.items.itemMap[ItemId.GUAM_LEAF], greaterThanOrEqualTo(5));
      expect(report.xp[SkillId.HERBALISM], greaterThan(0));
      // the patch running dry is what stopped it
      expect(session.actionTimingController.isRunning, isFalse);

      session.dispose();
    });

    test('a gap at a fishing spot fishes the whole gap', () {
      final session = buildSession();
      final save = session.saveGameData;
      final pond = encounterWith(session, EntityId.TRANQUIL_POND, 1);

      expect(session.encounterController.startEncounterActionFor(pond), isTrue);

      final now = DateTime.now();
      save.playerData.lastActionTime = now.subtract(
        const Duration(seconds: 60),
      );
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      // a spot never runs dry, so every cast the gap was worth happens
      expect(report!.actionCount, actionsIn(session, 60));
      expect(
        report.items.itemMap.values.fold<int>(0, (a, b) => a + b),
        greaterThan(0),
      );
      expect(session.actionTimingController.isRunning, isTrue);

      session.actionTimingController.stop();
      session.dispose();
    });
  });
}
