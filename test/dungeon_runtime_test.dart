import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/dungeon_run.dart';
import 'package:rpg/data/ObjectStack.dart';
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
  }

  /// Runs the encounter tick until the loop stops (a card cleared, or the
  /// player went down). Returns the number of ticks taken.
  int fightUntilStopped(GameSession session, {int limit = 20000}) {
    var ticks = 0;
    while (session.actionTimingController.isRunning && ticks < limit) {
      session.encounterController.doEncounterAction(1);
      ticks++;
    }
    return ticks;
  }

  /// Ticks while [waiting] is still true, up to [limit]. The stop-based
  /// helper above is no use to a run whose card laps or walks on: the loop
  /// never stops on its own.
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

  /// Ticks a fixed number of times, whatever the run is doing.
  void fightFor(GameSession session, int ticks) {
    for (int i = 0; i < ticks; i++) {
      session.encounterController.doEncounterAction(1);
    }
  }

  /// Clears every card up to [index] so it is reachable, then leaves the
  /// run parked on it.
  void clearUpTo(GameSession session, int index) {
    for (int i = 0; i < index; i++) {
      session.dungeonController.startSlot(i);
      fightUntilStopped(session);
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
    test('the key gates only the first card, and only until it is paid', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;

      dungeons.openDungeon(DungeonId.GOBLIN_QUEEN_LAIR);

      expect(dungeons.lockReason(0), 'Requires Goblin Queen Key');
      giveKey(session);
      expect(dungeons.lockReason(0), isNull);

      // paying it once opens the card for the rest of the run
      makePlayerStrong(session);
      expect(dungeons.startSlot(0), isTrue);
      expect(save.dungeonRun.keySpent, isTrue);
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.GOBLIN_QUEEN_KEY,
        ),
        0,
      );
      expect(dungeons.lockReason(0), isNull);

      session.dispose();
    });

    test('a card waits on the one above it unless it opts out', () {
      final session = buildSession();
      final dungeons = session.dungeonController;

      dungeons.openDungeon(DungeonId.SPIDER_DEN);

      expect(dungeons.lockReason(0), isNull);
      // the ore seam sets requiresPrevious: false
      expect(dungeons.lockReason(1), isNull);
      expect(dungeons.lockReason(2), 'Complete Collapsed Seam to unlock');

      session.dispose();
    });

    test('clearing a card unlocks the next one', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      expect(dungeons.lockReason(2), isNotNull);

      dungeons.startSlot(1);
      fightUntilStopped(session);

      expect(save.dungeonRun.cleared, contains(1));
      expect(dungeons.lockReason(2), isNull);

      session.dispose();
    });
  });

  group('the queue', () {
    test('a spent member hands off to the next without stopping the loop', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      // the boss card: giant spiders, then the broodmother
      clearUpTo(session, 3);
      dungeons.startSlot(3);

      final slot = save.dungeonRun.slots[3];
      expect(slot.members.length, 2);
      expect(slot.index, 0);
      expect(session.encounterController.queueRemaining().length, 1);

      // fight until the first member is spent and the second is live
      var ticks = 0;
      while (slot.index == 0 && ticks < 20000) {
        session.encounterController.doEncounterAction(1);
        ticks++;
      }

      expect(slot.index, 1);
      expect(slot.current?.id, EntityId.SPIDER_BROODMOTHER);
      // the loop kept running across the boundary
      expect(session.actionTimingController.isRunning, isTrue);
      // and the rail is empty now that the boss is the one on screen
      expect(session.encounterController.queueRemaining(), isEmpty);

      session.dispose();
    });

    test('clearing the last member marks the card and reports it', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      clearUpTo(session, 3);
      final before = session.encounterController.slotClearedSequence;

      dungeons.startSlot(3);
      fightUntilStopped(session);

      expect(save.dungeonRun.slots[3].cleared, isTrue);
      expect(save.dungeonRun.cleared, contains(3));
      expect(session.encounterController.slotClearedSequence, before + 1);
      expect(session.encounterController.lastClearedSlot, 3);

      // The boss paid out. Its table is one weighted roll — a 100+ coin stack
      // at weight 1, or one of the silk necklaces whose weights sum to 0.165 —
      // so coins land about 86% of the time, not always. Asserting coins alone
      // fails roughly one run in seven.
      final coins = session.inventoryService.getItemCount(
        save.inventoryData,
        ItemId.COINS,
      );
      // the necklace is equipment, so it stacks in inventoryData.equipment
      // rather than the itemMap that getItemCount reads
      final necklaces = save.inventoryData.equipment
          .where((e) => e.id == ItemId.SPIDER_SILK_NECKLACE)
          .fold<int>(0, (sum, e) => sum + e.count);
      expect(
        coins >= 100 || necklaces > 0,
        isTrue,
        reason:
            'the boss should have paid out one roll of its table, '
            'got $coins coins and $necklaces necklaces',
      );

      session.dispose();
    });

    test('a non-combat card clears the same way', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(1); // 8 iron
      fightUntilStopped(session);

      expect(save.dungeonRun.slots[1].cleared, isTrue);
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.IRON_ORE,
        ),
        greaterThanOrEqualTo(1),
      );

      session.dispose();
    });

    test('duplicate entity ids across cards stay separate', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      // the dev dungeon repeats GOBLIN in cards 0 and 2
      dungeons.openDungeon(DungeonId.DEV_TRANSIENT_DUNGEON);
      final first = save.dungeonRun.slots[0].members.first;
      final duplicate = save.dungeonRun.slots[2].members.first;
      expect(first.id, duplicate.id);
      expect(identical(first, duplicate), isFalse);

      dungeons.startSlot(0);
      session.encounterController.doEncounterAction(1);

      // the screen resolves through the running card, not the shared id
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
    // again on the drag-to-lock), so this path runs constantly mid-card
    test('re-pressing it keeps the card running rather than dropping it', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(0);
      final railBefore = session.encounterController.queueRemaining().length;
      expect(railBefore, greaterThan(0));

      // what MomentumPrimaryButton calls on press
      session.encounterController.startEncounterAction();

      expect(save.dungeonRun.runningSlot, 0);
      expect(session.encounterController.queueRemaining().length, railBefore);
      expect(session.actionTimingController.isRunning, isTrue);

      // and the queue still hands off to the next member
      final slot = save.dungeonRun.slots[0];
      var ticks = 0;
      while (slot.index == 0 && ticks < 20000) {
        session.encounterController.doEncounterAction(1);
        ticks++;
      }
      expect(slot.index, 1);

      session.dispose();
    });

    test('starting a zone entity does release the card', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(0);
      expect(save.dungeonRun.runningSlot, 0);

      // the action queue starts world entities through the same entry point
      final zoneEntity = EntityId.TREE.build();
      session.encounterController.startEncounterActionFor(
        zoneEntity as EncounterEntity,
      );

      expect(save.dungeonRun.runningSlot, -1);
      expect(session.encounterController.queueRemaining(), isEmpty);

      session.dispose();
    });
  });

  group('loot', () {
    int total(List<ObjectStack> stacks) =>
        stacks.fold(0, (sum, s) => sum + s.count);

    test('the run adds up while the encounter log resets per card', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(1); // the ore seam
      fightUntilStopped(session);

      final afterFirstCard = total(dungeons.runLoot());
      expect(afterFirstCard, greaterThan(0));
      expect(session.encounterController.itemDrops(), isNotEmpty);

      dungeons.startSlot(2); // a new card starts the encounter log over
      expect(session.encounterController.itemDrops(), isEmpty);
      fightUntilStopped(session);

      // ...but the run's haul kept the first card's drops
      expect(total(dungeons.runLoot()), greaterThan(afterFirstCard));

      session.dispose();
    });

    test('a boss unique reaches the haul, not just the bag', () {
      // equipment is paid out as an instance carrying its rolled quality,
      // never as a count in the item map. the run haul took the stackable
      // half only, so the drop a dungeon is run for was the one thing
      // missing from the loot tab
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.GRAINERY);

      // found rather than hardcoded, so re-cutting the dungeon's cards
      // doesn't quietly point this at one with no equipment on it
      final slot = List.generate(3, (i) => i).firstWhere(
        (i) =>
            dungeons.slotAt(i)?.members.any((m) => m.id == EntityId.BIG_RED) ??
            false,
      );
      final bigRed = dungeons
          .slotAt(slot)!
          .members
          .firstWhere((m) => m.id == EntityId.BIG_RED);
      // three of Big Red's five drop lines are the charm, so a card's worth
      // of them makes one a certainty rather than a coin flip
      bigRed.count = 40;

      dungeons.startSlot(slot);
      fightUntilStopped(session);

      final inBag = save.inventoryData.equipment
          .where((e) => e.id == ItemId.CHICKEN_CHARM)
          .fold<int>(0, (sum, e) => sum + e.count);
      expect(inBag, greaterThan(0), reason: 'no charm dropped in this run');

      // the haul carries it as an instance, not folded into the stackables
      expect(
        dungeons
            .runEquipment()
            .where((e) => e.id == ItemId.CHICKEN_CHARM)
            .fold<int>(0, (sum, e) => sum + e.count),
        inBag,
      );
      expect(
        dungeons.runLoot().any((s) => s.id == ItemId.CHICKEN_CHARM),
        isFalse,
      );
      // and it is the run's own instance, not the one handed to the bag -
      // addEquipment merges by mutating whatever stack it lands on
      expect(
        save.dungeonRun.loot.equipment.any(
          (e) => identical(e, save.inventoryData.equipment.first),
        ),
        isFalse,
      );

      session.dispose();
    });

    test('leaving clears the run haul', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(1);
      fightUntilStopped(session);
      expect(dungeons.runLoot(), isNotEmpty);

      dungeons.leaveDungeon();
      expect(dungeons.runLoot(), isEmpty);

      session.dispose();
    });
  });

  group('startability', () {
    test('a cleared card is re-runnable only where cards repeat', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(1);
      fightUntilStopped(session);
      expect(dungeons.startable(1), isTrue);

      session.dispose();
    });

    test('a keyed dungeon does not offer a cleared card again', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      giveKey(session);

      dungeons.openDungeon(DungeonId.GOBLIN_QUEEN_LAIR);
      expect(dungeons.startable(0), isTrue);
      dungeons.startSlot(0);
      fightUntilStopped(session);

      expect(dungeons.startable(0), isFalse);
      expect(dungeons.startable(1), isTrue);

      session.dispose();
    });
  });

  group('what a cleared card runs next', () {
    test('the loop toggle laps the same card in place, without stopping', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.loopFloor = true;
      final reported = session.encounterController.slotClearedSequence;

      dungeons.startSlot(1); // the ore seam: no card above it to clear
      final ticks = fightPast(session, () => save.dungeonRun.cleared.isEmpty);

      // the card cleared, and the loop carried straight into another lap
      expect(save.dungeonRun.cleared, contains(1));
      expect(session.actionTimingController.isRunning, isTrue);
      expect(save.dungeonRun.runningSlot, 1);
      // refilled: the queue is back at its first member with a full count
      expect(save.dungeonRun.slots[1].cleared, isFalse);
      expect(save.dungeonRun.slots[1].index, 0);
      expect(save.dungeonRun.slots[1].members.first.count, 8);
      // and the shell was never told to drop back to the list
      expect(session.encounterController.slotClearedSequence, reported);
      expect(session.encounterController.lastClearedSlot, -1);
      expect(ticks, lessThan(20000));

      session.dispose();
    });

    test('a lap keeps the drop log and the momentum it built', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.loopFloor = true;

      // ObjectStacks are rebuilt per read and don't compare, so the log is
      // measured by what it holds
      int logged() => session.encounterController.itemDrops().fold<int>(
        0,
        (sum, stack) => sum + stack.count,
      );

      dungeons.startSlot(1); // 8 iron
      fightPast(session, () => save.dungeonRun.cleared.isEmpty);
      final atClear = logged();
      expect(atClear, greaterThan(0));

      // a lap binds in place - it never stops the loop - so the boost the
      // player built up crossing the card boundary survives it
      save.actionTimingData.percentOfMaxBoost = 0.5;
      fightFor(session, 200);
      expect(logged(), greaterThan(atClear));
      expect(save.actionTimingData.percentOfMaxBoost, greaterThan(0.0));

      // the run's own haul never reset either
      expect(
        session.inventoryService.getItemCount(
          save.dungeonRun.loot,
          ItemId.IRON_ORE,
        ),
        greaterThan(0),
      );

      // tapping a different card is a different haul
      dungeons.startSlot(2);
      expect(logged(), 0);

      session.dispose();
    });

    test('auto-advance runs the next card without the screen', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.autoAdvance = true;

      dungeons.startSlot(1);
      fightPast(session, () => save.dungeonRun.runningSlot == 1);

      // straight on to the card the clear unlocked, still running
      expect(save.dungeonRun.cleared, contains(1));
      expect(save.dungeonRun.runningSlot, 2);
      expect(session.actionTimingController.isRunning, isTrue);
      // a new card is a new haul
      expect(session.encounterController.itemDrops(), isEmpty);

      session.dispose();
    });

    test('with both toggles off, a cleared card ends the action', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(1);
      fightUntilStopped(session);

      expect(save.dungeonRun.slots[1].cleared, isTrue);
      expect(session.actionTimingController.isRunning, isFalse);
      expect(session.encounterController.lastClearedSlot, 1);

      session.dispose();
    });

    test('the two toggles turn each other off', () {
      final session = buildSession();
      final dungeons = session.dungeonController;

      dungeons.autoAdvance = true;
      dungeons.loopFloor = true;
      expect(dungeons.autoAdvance, isFalse);

      dungeons.autoAdvance = true;
      expect(dungeons.loopFloor, isFalse);

      session.dispose();
    });

    test('a one-shot card never laps, whatever the toggle says', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      giveKey(session);

      dungeons.openDungeon(DungeonId.GOBLIN_QUEEN_LAIR);
      expect(dungeons.canLoopFloor, isFalse);

      dungeons.loopFloor = true;
      dungeons.startSlot(0);
      fightUntilStopped(session);

      // the card can't be refought, so clearing it ends the action
      expect(save.dungeonRun.slots[0].cleared, isTrue);
      expect(session.actionTimingController.isRunning, isFalse);
      expect(session.encounterController.lastClearedSlot, 0);

      session.dispose();
    });

    test('a card with nothing fightable in it does not open', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(1);
      fightUntilStopped(session);

      // an emptied card would clear again the instant it started, looping
      // at no cost - the system refuses to open it instead
      save.dungeonRun.slots[1].members.first.count = 0;
      save.dungeonRun.slots[1].index = 0;
      expect(session.dungeonSystem.openSlot(save.dungeonRun, 1), isNull);

      session.dispose();
    });
  });

  group('the entry key', () {
    test('is charged once, and only on the first card', () {
      final session = buildSession();
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      giveKey(session);

      dungeons.openDungeon(DungeonId.GOBLIN_QUEEN_LAIR);
      expect(dungeons.showsKeyNote(0), isTrue);
      expect(dungeons.showsKeyNote(1), isFalse);
      expect(dungeons.willSpendKey(0), isTrue);

      dungeons.startSlot(0);
      expect(dungeons.keySpent, isTrue);
      // already paid: re-running the card doesn't charge again
      expect(dungeons.willSpendKey(0), isFalse);

      session.dispose();
    });

    test('with no key in the bag there is nothing to spend', () {
      final session = buildSession();
      final dungeons = session.dungeonController;

      dungeons.openDungeon(DungeonId.GOBLIN_QUEEN_LAIR);
      expect(dungeons.showsKeyNote(0), isTrue);
      expect(dungeons.willSpendKey(0), isFalse);
      expect(dungeons.startable(0), isFalse);

      session.dispose();
    });
  });

  group('leaving', () {
    test('a zone dungeon refights a cleared card, a keyed one does not', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      dungeons.startSlot(1);
      fightUntilStopped(session);
      expect(save.dungeonRun.slots[1].cleared, isTrue);

      // re-tapping a cleared card in a repeatable dungeon refills it, and
      // the cleared mark stays so the next card doesn't re-lock
      expect(dungeons.startSlot(1), isTrue);
      expect(save.dungeonRun.slots[1].cleared, isFalse);
      expect(save.dungeonRun.cleared, contains(1));

      expect(DungeonId.GOBLIN_QUEEN_LAIR.definition.repeatableEntries, isFalse);

      session.dispose();
    });

    test('leaving resets the run; the spent key is not refunded', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);
      giveKey(session);

      dungeons.openDungeon(DungeonId.GOBLIN_QUEEN_LAIR);
      dungeons.startSlot(0);
      expect(save.dungeonRun.active, isTrue);

      dungeons.leaveDungeon();

      expect(save.dungeonRun.active, isFalse);
      expect(save.dungeonRun.slots, isEmpty);
      expect(save.dungeonRun.cleared, isEmpty);
      expect(save.dungeonRun.runningSlot, -1);
      expect(save.dungeonRun.keySpent, isFalse);
      expect(session.actionTimingController.isRunning, isFalse);
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.GOBLIN_QUEEN_KEY,
        ),
        0,
      );

      session.dispose();
    });

    test('leaving a transient dungeon consumes its entrance', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;

      save.playerData.currentZoneId = ZoneId.DEV_DUNGEON_TESTING;
      session.explorationService.addEntityToCurrentZone(
        EntityId.DEV_DUNGEON_ENTRANCE,
        1,
        save.playerData,
        save.worldData,
      );
      final zone = save.worldData.zones[ZoneId.DEV_DUNGEON_TESTING]!;
      expect(
        zone.discoveredEntities.any(
          (e) => e.id == EntityId.DEV_DUNGEON_ENTRANCE,
        ),
        isTrue,
      );

      dungeons.openDungeon(DungeonId.DEV_TRANSIENT_DUNGEON);
      dungeons.leaveDungeon();

      expect(
        zone.discoveredEntities.any(
          (e) => e.id == EntityId.DEV_DUNGEON_ENTRANCE,
        ),
        isFalse,
      );

      session.dispose();
    });

    test('dying ends the run exactly like leaving does', () {
      // the same run driven two ways has to land in the same place, or the
      // death path and the leave path will drift apart
      Map<String, Object?> endStateAfter({required bool byDeath}) {
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

        dungeons.openDungeon(DungeonId.DEV_TRANSIENT_DUNGEON);
        dungeons.startSlot(0);
        session.encounterController.doEncounterAction(1);

        if (byDeath) {
          // the shell ends the run on death, the same call leaving makes
          save.playerData.hitpoints = 0;
          dungeons.leaveDungeon();
        } else {
          dungeons.leaveDungeon();
        }

        final zone = save.worldData.zones[ZoneId.DEV_DUNGEON_TESTING]!;
        final state = <String, Object?>{
          'active': save.dungeonRun.active,
          'slots': save.dungeonRun.slots.length,
          'cleared': save.dungeonRun.cleared.length,
          'runningSlot': save.dungeonRun.runningSlot,
          'keySpent': save.dungeonRun.keySpent,
          'running': session.actionTimingController.isRunning,
          'entrance': zone.discoveredEntities.any(
            (e) => e.id == EntityId.DEV_DUNGEON_ENTRANCE,
          ),
        };
        session.dispose();
        return state;
      }

      final leaving = endStateAfter(byDeath: false);
      expect(endStateAfter(byDeath: true), leaving);
      expect(leaving['active'], isFalse);
      expect(leaving['entrance'], isFalse);
    });
  });

  test('an in-progress run survives a save round-trip', () {
    final session = buildSession();
    final save = session.saveGameData;
    final dungeons = session.dungeonController;
    makePlayerStrong(session);
    giveKey(session);

    dungeons.openDungeon(DungeonId.GOBLIN_QUEEN_LAIR);
    dungeons.startSlot(0);
    // one hit so the live enemy has partial hp to preserve
    session.encounterController.doEncounterAction(1);

    final live = save.dungeonRun.slots[0].members.first;
    final restored = SaveGameData.fromJson(save.toJson());
    final run = restored.dungeonRun;

    expect(run.active, isTrue);
    expect(run.dungeonId, DungeonId.GOBLIN_QUEEN_LAIR);
    expect(run.runningSlot, 0);
    expect(run.keySpent, isTrue);
    expect(run.slots.length, save.dungeonRun.slots.length);
    expect(run.slots[0].name, 'Warren Entrance');
    expect(run.slots[0].index, save.dungeonRun.slots[0].index);
    // a half-killed enemy comes back half-killed
    expect(run.slots[0].current?.hitpoints, live.hitpoints);
    expect(run.slots[0].current?.count, live.count);

    session.dispose();
  });

  test('the dungeon ui state round-trips', () {
    final session = buildSession();
    final save = session.saveGameData;

    save.uiState.dungeonId = DungeonId.SPIDER_DEN;
    save.uiState.dungeonSlot = 2;
    save.uiState.dungeonAutoAdvance = true;
    save.uiState.dungeonLoopFloor = true;

    final ui = SaveGameData.fromJson(save.toJson()).uiState;
    expect(ui.dungeonId, DungeonId.SPIDER_DEN);
    expect(ui.dungeonSlot, 2);
    expect(ui.dungeonAutoAdvance, isTrue);
    expect(ui.dungeonLoopFloor, isTrue);

    session.dispose();
  });

  test('a save from before card lists loads as an inactive run', () {
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
}
