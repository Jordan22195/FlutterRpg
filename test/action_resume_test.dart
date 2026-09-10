import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/bound_action.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// The action loop fires a closure, which no save can hold. These cover the
// way round that: the loop records what was bound, and a relaunch re-runs the
// controller's own start path to bind it again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final factory = GameSessionFactory();

  GameSession sessionFrom(SaveGameData save) {
    return factory.create(
      save: save,
      catalogs: factory.catalog1(),
      vsync: const TestVSync(),
    );
  }

  GameSession newSession() => sessionFrom(factory.newGame(factory.catalog1()));

  // what the app does across a restart: write the save out, read it back,
  // and build a session on the result
  GameSession relaunch(GameSession session) {
    final encoded = jsonEncode(session.saveGameData.toJson());
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    return sessionFrom(SaveGameData.fromJson(decoded));
  }

  // puts a TREE in the starting zone the way exploring would, so the zone
  // lookup a resume does can find it again
  EncounterEntity addTreeToZone(GameSession session) {
    final save = session.saveGameData;
    final tree = EntityId.TREE.build() as EncounterEntity;
    save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities.add(
      tree,
    );
    return tree;
  }

  void stockForFiremaking(GameSession session) {
    final save = session.saveGameData;
    final skill = save.playerData.skillData[SkillId.FIREMAKING]!;
    skill.xp = skill.xpTable[10];
    save.inventoryData.itemMap[ItemId.LOGS] = 200;
  }

  group('the bound action is recorded as it is bound', () {
    test('exploring records the zone', () {
      final session = newSession();
      session.worldController.startExplore();

      final bound = session.saveGameData.actionTimingData.boundAction;
      expect(bound?.kind, BoundActionKind.EXPLORE);
      expect(bound?.zoneId, session.saveGameData.playerData.currentZoneId);

      session.dispose();
    });

    test('an encounter records the entity and its zone', () {
      final session = newSession();
      final tree = addTreeToZone(session);
      expect(session.encounterController.startEncounterActionFor(tree), isTrue);

      final bound = session.saveGameData.actionTimingData.boundAction;
      expect(bound?.kind, BoundActionKind.ENCOUNTER);
      expect(bound?.entityId, EntityId.TREE);
      expect(bound?.zoneId, session.saveGameData.playerData.currentZoneId);

      session.dispose();
    });

    test('a dungeon card records its slot', () {
      final session = newSession();
      session.dungeonController.openDungeon(DungeonId.SPIDER_DEN);
      expect(session.dungeonController.startSlot(1), isTrue);

      final bound = session.saveGameData.actionTimingData.boundAction;
      expect(bound?.kind, BoundActionKind.DUNGEON_SLOT);
      expect(bound?.dungeonSlot, 1);

      session.dispose();
    });

    test('crafting records the station and the recipe', () {
      final session = newSession();
      stockForFiremaking(session);
      expect(
        session.craftingController.startCraftingActionFor(
          'cookfire',
          EntityId.FIREPIT,
        ),
        isTrue,
      );

      final bound = session.saveGameData.actionTimingData.boundAction;
      expect(bound?.kind, BoundActionKind.CRAFT);
      expect(bound?.entityId, EntityId.FIREPIT);
      expect(bound?.recipeId, 'cookfire');

      session.dispose();
    });

    test('stopping clears it, so nothing is left to resume', () {
      final session = newSession();
      session.worldController.startExplore();
      expect(session.saveGameData.actionTimingData.boundAction, isNotNull);

      session.actionTimingController.stop();

      expect(session.saveGameData.actionTimingData.boundAction, isNull);
      expect(session.saveGameData.actionTimingData.running, isFalse);

      session.dispose();
    });
  });

  group('resumeBoundAction', () {
    test('an explore comes back bound to the explore action', () {
      final before = newSession();
      before.worldController.startExplore();

      final after = relaunch(before);
      // nothing is bound yet: the closure did not survive the save
      expect(after.actionTimingController.isTicking, isFalse);

      after.resumeBoundAction();

      expect(after.actionTimingController.isTicking, isTrue);
      expect(
        after.actionTimingController.isRunningAction(
          after.worldController.doExplore,
        ),
        isTrue,
      );

      before.dispose();
      after.dispose();
    });

    test('an encounter comes back on the same entity', () {
      final before = newSession();
      final tree = addTreeToZone(before);
      before.encounterController.startEncounterActionFor(tree);

      final after = relaunch(before);
      after.resumeBoundAction();

      expect(after.actionTimingController.isTicking, isTrue);
      expect(
        after.actionTimingController.isRunningAction(
          after.encounterController.doEncounterAction,
        ),
        isTrue,
      );
      expect(after.saveGameData.encounterData.entity?.id, EntityId.TREE);

      before.dispose();
      after.dispose();
    });

    test('a craft comes back on the same recipe', () {
      final before = newSession();
      stockForFiremaking(before);
      before.craftingController.startCraftingActionFor(
        'cookfire',
        EntityId.FIREPIT,
      );

      final after = relaunch(before);
      after.resumeBoundAction();

      expect(after.actionTimingController.isTicking, isTrue);
      expect(
        after.actionTimingController.isRunningAction(
          after.craftingController.doCraftingAction,
        ),
        isTrue,
      );
      expect(after.saveGameData.craftingState.activeRecipeId, 'cookfire');

      before.dispose();
      after.dispose();
    });

    test('the momentum and progress built up before the close survive', () {
      final before = newSession();
      before.worldController.startExplore();
      final timing = before.saveGameData.actionTimingData;
      timing.percentOfMaxBoost = 0.8;
      timing.actionProgressPercentComplete = 0.4;
      timing.boostLocked = true;

      final after = relaunch(before);
      after.resumeBoundAction();

      // the start path stops the loop first, which zeroes both - the resume
      // is what puts them back
      final resumed = after.saveGameData.actionTimingData;
      expect(resumed.percentOfMaxBoost, closeTo(0.8, 1e-9));
      expect(resumed.actionProgressPercentComplete, closeTo(0.4, 1e-9));
      expect(resumed.boostLocked, isTrue);

      before.dispose();
      after.dispose();
    });

    test('the offline gap is left intact for the first frame to settle', () {
      final before = newSession();
      before.worldController.startExplore();

      final after = relaunch(before);
      // the app was closed for a while
      final closedAt = DateTime.now().subtract(const Duration(minutes: 5));
      after.saveGameData.playerData.lastActionTime = closedAt;

      after.resumeBoundAction();

      // starting the loop normally stamps this to now, which would throw the
      // gap away before any frame could pay it out
      expect(after.saveGameData.playerData.lastActionTime, closedAt);

      before.dispose();
      after.dispose();
    });

    test('a dungeon card resumes with the gap it was away for', () {
      final before = newSession();
      before.dungeonController.openDungeon(DungeonId.SPIDER_DEN);
      expect(before.dungeonController.startSlot(1), isTrue);

      final after = relaunch(before);
      final closedAt = DateTime.now().subtract(const Duration(minutes: 10));
      after.saveGameData.playerData.lastActionTime = closedAt;

      after.resumeBoundAction();

      // the card is running again, and the gap it was closed on is still
      // owed - the screen restore deliberately leaves the start to this
      expect(after.actionTimingController.isTicking, isTrue);
      expect(after.saveGameData.dungeonRun.runningSlot, 1);
      expect(after.saveGameData.playerData.lastActionTime, closedAt);

      before.dispose();
      after.dispose();
    });

    test('a dungeon card that was not running is left alone', () {
      final before = newSession();
      before.dungeonController.openDungeon(DungeonId.SPIDER_DEN);
      expect(before.dungeonController.startSlot(1), isTrue);
      // the player stopped the card before closing the app
      before.actionTimingController.stop();

      final after = relaunch(before);
      after.resumeBoundAction();

      expect(after.actionTimingController.isTicking, isFalse);

      before.dispose();
      after.dispose();
    });

    test('an idle save resumes nothing', () {
      final session = newSession();
      session.resumeBoundAction();

      expect(session.actionTimingController.isTicking, isFalse);

      session.dispose();
    });

    test('an entity that is gone from the zone comes back idle', () {
      final before = newSession();
      final tree = addTreeToZone(before);
      before.encounterController.startEncounterActionFor(tree);

      final after = relaunch(before);
      // the tree was chopped out of existence before the app reopened
      after
          .saveGameData
          .worldData
          .zones[after.saveGameData.playerData.currentZoneId]!
          .discoveredEntities
          .removeWhere((e) => e.id == EntityId.TREE);

      after.resumeBoundAction();

      expect(after.actionTimingController.isTicking, isFalse);

      before.dispose();
      after.dispose();
    });

    test('a craft whose materials ran out comes back idle', () {
      final before = newSession();
      stockForFiremaking(before);
      before.craftingController.startCraftingActionFor(
        'cookfire',
        EntityId.FIREPIT,
      );

      final after = relaunch(before);
      after.saveGameData.inventoryData.itemMap.remove(ItemId.LOGS);

      after.resumeBoundAction();

      expect(after.actionTimingController.isTicking, isFalse);

      before.dispose();
      after.dispose();
    });

    test('a cook whose fire died while the app was closed comes back and '
        'relights', () {
      final before = newSession();
      stockForFiremaking(before);
      // more fish than ten minutes can cook, so the fire is the only thing
      // that could stop the loop
      before.saveGameData.inventoryData.itemMap[ItemId.MINNOW] = 1000;
      before.saveGameData.craftingState.selectedRecipeByEntity[EntityId
          .FIREPIT] = {
        SkillId.FIREMAKING: 'cookfire',
      };
      before.firemakingSystem.lightOrExtend(
        ItemId.COOKFIRE,
        EntityId.FIREPIT,
        before.saveGameData.playerData.currentZoneId,
        before.saveGameData.playerData.buffData,
      );
      expect(
        before.craftingController.startCraftingActionFor(
          'cook_minnow',
          EntityId.FIREPIT,
        ),
        isTrue,
      );

      final after = relaunch(before);
      final save = after.saveGameData;
      // ten minutes away, and the fire had thirty seconds left when the
      // app closed
      final now = DateTime.now();
      final closedAt = now.subtract(const Duration(minutes: 10));
      save.playerData.lastActionTime = closedAt;
      after.buffService
          .getZoneBuff(
            save.playerData.buffData,
            save.playerData.currentZoneId,
            EntityId.FIREPIT,
          )!
          .expirationTime = closedAt.add(
        const Duration(seconds: 30),
      );

      after.resumeBoundAction();

      // a dead fire used to leave the cook idle and drop the gap. with
      // logs on hand the cook can relight it, so it resumes with the gap
      // intact for the first frame to settle
      expect(after.actionTimingController.isTicking, isTrue);
      expect(save.playerData.lastActionTime, closedAt);

      after.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );
      final report = after.actionTimingController.pendingOfflineReport!;
      expect(report.xp[SkillId.COOKING], greaterThan(0));
      expect(report.xp[SkillId.FIREMAKING], greaterThan(0));
      expect(after.actionTimingController.isRunning, isTrue);
      expect(
        after.firemakingSystem.activeFire(
          EntityId.FIREPIT,
          save.playerData.currentZoneId,
          save.playerData.buffData,
        ),
        isNotNull,
      );

      after.actionTimingController.stop();
      before.dispose();
      after.dispose();
    });

    test('a cook with no logs to relight comes back idle', () {
      final before = newSession();
      stockForFiremaking(before);
      before.saveGameData.inventoryData.itemMap[ItemId.MINNOW] = 200;
      before.saveGameData.craftingState.selectedRecipeByEntity[EntityId
          .FIREPIT] = {
        SkillId.FIREMAKING: 'cookfire',
      };
      before.firemakingSystem.lightOrExtend(
        ItemId.COOKFIRE,
        EntityId.FIREPIT,
        before.saveGameData.playerData.currentZoneId,
        before.saveGameData.playerData.buffData,
      );
      before.craftingController.startCraftingActionFor(
        'cook_minnow',
        EntityId.FIREPIT,
      );

      final after = relaunch(before);
      final save = after.saveGameData;
      save.inventoryData.itemMap.remove(ItemId.LOGS);
      after.buffService
          .getZoneBuff(
            save.playerData.buffData,
            save.playerData.currentZoneId,
            EntityId.FIREPIT,
          )!
          .expirationTime = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      after.resumeBoundAction();

      expect(after.actionTimingController.isTicking, isFalse);

      before.dispose();
      after.dispose();
    });

    test('an action already running is left alone', () {
      final before = newSession();
      before.worldController.startExplore();

      final after = relaunch(before);
      // the screen restore got there first and started something itself
      final tree = addTreeToZone(after);
      after.encounterController.startEncounterActionFor(tree);

      after.resumeBoundAction();

      // still the encounter, not the explore the save recorded
      expect(
        after.actionTimingController.isRunningAction(
          after.encounterController.doEncounterAction,
        ),
        isTrue,
      );

      before.dispose();
      after.dispose();
    });
  });
}
