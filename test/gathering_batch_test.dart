import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/encounter_service.dart';
import 'support/gathering_tools.dart';

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
      save: withGatheringTools(factory.newGame(catalogs)),
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
  // will run at: the [skill]'s tool interval (the bench default without
  // one) divided by the fast stance's speed curve, rounded to the
  // millisecond the way getCurrentActionDuration does
  int actionsIn(GameSession session, double seconds, {SkillId? skill}) {
    final scratch = ActionTimingData()
      ..maxInterval = session.actionTimingSystem.intervalFor(
        skill,
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

    test('a spot\'s pool grows with the spot, 5 up to the ocean\'s 25', () {
      const pools = {
        EntityId.TRANQUIL_POND: 5,
        EntityId.CREEK: 5,
        EntityId.RIVER: 10,
        EntityId.DEEP_POND: 15,
        EntityId.LAKE: 20,
        EntityId.OCEAN: 25,
      };
      for (final pool in pools.entries) {
        final def = pool.key.definition as EncounterEntityDefinition;
        expect(def.hitpoints, pool.value, reason: pool.key.name);
      }
    });

    test('a pool\'s worth of damage is a catch, and overkill rolls again', () {
      final service = EncounterService();
      expect(service.catchesFor(0, 10), 0);
      expect(service.catchesFor(1, 10), 1);
      expect(service.catchesFor(10, 10), 1);
      expect(service.catchesFor(11, 10), 2);
      expect(service.catchesFor(25, 10), 3);
      // a landed cast at max hit 11 against a 10-hp pool: ten single
      // catches and one double, over eleven equally likely rolls
      expect(service.meanCatchesPerHit(11, 10), closeTo(12 / 11, 1e-9));
      expect(service.meanCatchesPerHit(10, 10), 1);
    });

    test('a live cast catches once per pool\'s worth and pays every fish', () {
      final session = buildSession();
      // well past the pond, so a cast can run a pool over
      setLevel(session, SkillId.FISHING, 60);
      final pond = encounterWith(session, EntityId.TRANQUIL_POND, 1);
      // the rod's swing: its damage, times what Fishing multiplies it by
      final maxHit = session.encounterSystem.playerSwingMaxHit(
        session.saveGameData.playerData,
        pond,
      )!;
      expect(maxHit, greaterThan(pond.maxHitPoints));

      var sawOverkill = false;
      var sawMaxHit = false;
      for (var i = 0; i < 300; i++) {
        final xpBefore = xpFor(session, SkillId.FISHING);
        final r = cast(session, offline: false);
        expect(r.actionsPerformed, 1);
        expect(
          r.catches,
          session.encounterService.catchesFor(r.damageDone, pond.maxHitPoints),
        );
        // every pond fish comes up one to a roll
        expect(itemsIn(r), r.catches);
        // every roll that lands the most fish a cast can is a max catch,
        // not only the top damage roll
        expect(
          r.maxHit,
          r.catches > 1 &&
              r.catches ==
                  session.encounterService.catchesFor(
                    maxHit,
                    pond.maxHitPoints,
                  ),
        );
        // the pool stands full for the next cast
        expect(pond.hitpoints, pond.maxHitPoints);

        var fishXp = 0.0;
        for (final stack in r.items) {
          fishXp += stack.id.definition.xpValue * stack.count;
        }
        expect(
          xpFor(session, SkillId.FISHING) - xpBefore,
          closeTo(fishXp, 1e-6),
        );

        if (r.catches > 1) sawOverkill = true;
        if (r.maxHit) sawMaxHit = true;
      }
      expect(sawOverkill, isTrue);
      expect(sawMaxHit, isTrue);
      session.dispose();
    });

    test('every cast that lands the max catch is a max catch', () {
      final session = buildSession();
      final pond = encounterWith(session, EntityId.TRANQUIL_POND, 1);
      final pool = pond.maxHitPoints;

      // a level whose top catch is reached by more than one damage roll -
      // three catches off 21 to 24 damage, say - which is the case that
      // used to light up only on the top roll
      late int maxHit;
      for (var level = 30; level <= 99; level++) {
        setLevel(session, SkillId.FISHING, level);
        maxHit = session.encounterSystem.playerSwingMaxHit(
          session.saveGameData.playerData,
          pond,
        )!;
        if (maxHit > pool && (maxHit - 1) % pool >= 1) break;
      }
      final maxCatch = session.encounterService.catchesFor(maxHit, pool);

      var sawLowRollMaxCatch = false;
      for (var i = 0; i < 2000 && !sawLowRollMaxCatch; i++) {
        final r = cast(session, offline: false);
        if (r.catches == maxCatch) {
          expect(r.maxHit, isTrue, reason: 'damage ${r.damageDone}');
          if (r.damageDone < maxHit) sawLowRollMaxCatch = true;
        } else {
          expect(r.maxHit, isFalse, reason: 'damage ${r.damageDone}');
        }
      }
      expect(sawLowRollMaxCatch, isTrue);
      session.dispose();
    });

    test('a spot a cast cannot run over never lights a max catch', () {
      final session = buildSession();
      // a fresh angler at the pond: the rod's best swing is a pool's worth,
      // so every catch is the most a cast can land - and none is a max catch
      setLevel(session, SkillId.FISHING, 1);
      final pond = encounterWith(session, EntityId.TRANQUIL_POND, 1);
      final maxHit = session.encounterSystem.playerSwingMaxHit(
        session.saveGameData.playerData,
        pond,
      )!;
      expect(session.encounterService.catchesFor(maxHit, pond.maxHitPoints), 1);

      var caught = 0;
      for (var i = 0; i < 200; i++) {
        final r = cast(session, offline: false);
        caught += r.catches;
        expect(r.maxHit, isFalse);
      }
      expect(caught, greaterThan(0));
      session.dispose();
    });

    test('a batch at overkill levels still matches the casts', () {
      const casts = 400;

      final looped = buildSession();
      setLevel(looped, SkillId.FISHING, 60);
      encounterWith(looped, EntityId.TRANQUIL_POND, 1);
      var loopedCatch = 0;
      for (var i = 0; i < casts; i++) {
        loopedCatch += itemsIn(cast(looped, offline: false));
      }

      final batched = buildSession();
      setLevel(batched, SkillId.FISHING, 60);
      encounterWith(batched, EntityId.TRANQUIL_POND, 1);
      final batchedCatch = itemsIn(cast(batched, actionCount: casts));

      // overkill lifts both above one fish a cast
      expect(loopedCatch, greaterThan(casts));
      expect(batchedCatch, greaterThan(casts));
      expect(batchedCatch, closeTo(loopedCatch, loopedCatch * 0.15));
      looped.dispose();
      batched.dispose();
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
      expect(
        report!.actionCount,
        actionsIn(session, 60, skill: SkillId.FISHING),
      );
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
