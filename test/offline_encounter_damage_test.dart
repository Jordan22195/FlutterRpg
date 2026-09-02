import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// A batched fight resolves both sides: the player's kills come off average
// damage, but the enemy's swings are walked one at a time, because what ends
// a fight is a roll the average never sees.
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

  // a catalog enemy, standing in the player's zone and opened as the
  // active encounter. the shape of the fight is chosen by picking the
  // entity whose stats are that shape, not by dialling stats onto an
  // instance - stats live on the definition.
  CombatEntity fightWith(GameSession session, EntityId id, {int count = 1000}) {
    final entity = id.build() as CombatEntity;
    entity.count = count;
    session.encounterService.setEncounterEntity(
      session.saveGameData.encounterData,
      entity,
    );
    return entity;
  }

  // a plain node - no attack, so nothing swings back and the whole stretch
  // belongs to the player. trees and rocks settle through the same batch a
  // fight does.
  EncounterEntity nodeWith(
    GameSession session,
    EntityId id, {
    int count = 5000,
  }) {
    final node = id.build() as EncounterEntity;
    node.count = count;
    session.encounterService.setEncounterEntity(
      session.saveGameData.encounterData,
      node,
    );
    return node;
  }

  void equipFood(GameSession session, {int count = 500}) {
    final save = session.saveGameData;
    session.inventoryService.setItemCount(
      save.inventoryData,
      ItemId.COOKED_CHICKEN, // heals 3 against a max hp of 10
      count,
    );
    save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
  }

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  int foodLeft(GameSession session) => session.inventoryService.getItemCount(
    session.saveGameData.inventoryData,
    ItemId.COOKED_CHICKEN,
  );

  // one offline batch of [count] actions covering [span].
  //
  // Seeded: the enemy's swings are rolled one at a time, so how far into an
  // hour an unfed player gets - and therefore how many kills they bought
  // before dying - varies run to run. An unseeded roll made that test flaky
  // about one run in three.
  EncounterActionResult settleFight(
    GameSession session, {
    required int count,
    required Duration span,
    int seed = 20260901,
  }) {
    final save = session.saveGameData;
    return session.encounterSystem.executePlayerAction(
      playerState: save.playerData,
      encounter: save.encounterData,
      worldState: save.worldData,
      playerInventory: save.inventoryData,
      actionCount: count,
      offline: true,
      at: save.playerData.lastActionTime,
      span: span,
      rng: Random(seed),
    );
  }

  test('an unfed player dies partway through a long fight', () {
    final session = buildSession();
    final save = session.saveGameData;
    setLevel(session, SkillId.ATTACK, 10);
    // the catalog's gentlest attacker: it takes a while to chew through 10
    // unfed hitpoints, so the player gets a run of kills in first. a chicken
    // hits for 5 and ends the fight in two swings, before any kill lands.
    fightWith(session, EntityId.FIELD_RAT);

    // an hour of fighting at 3s an action, with nothing to eat
    final result = settleFight(
      session,
      count: 1200,
      span: const Duration(hours: 1),
    );

    expect(result.playerDied, isTrue);
    expect(save.playerData.hitpoints, 0);
    // only the actions the player was alive for were paid
    expect(result.actionsPerformed, greaterThan(0));
    expect(result.actionsPerformed, lessThan(1200));
    // and the kills are what those actions bought, not an hour's worth
    expect(result.entitiesDefeated.single.count, greaterThan(0));
    expect(result.entitiesDefeated.single.count, lessThan(100));

    session.dispose();
  });

  test('a fed player lives on their food and keeps fighting', () {
    final session = buildSession();
    final save = session.saveGameData;
    equipFood(session);
    // the combat curve reads attack against defence as a ratio, so a low
    // defence against a scarecrow's attack is a near-certain hit - more
    // damage in an hour than 500 food can heal. Defence 12 drops that to a
    // rate the player can eat through.
    setLevel(session, SkillId.DEFENCE, 12);
    // the catalog's softest puncher that still swings often enough to cost
    // food: a lot of hitpoints behind an attack of 4
    fightWith(session, EntityId.ROTWOOD_SCARECROW);

    final result = settleFight(
      session,
      count: 1200,
      span: const Duration(hours: 1),
    );

    expect(result.playerDied, isFalse);
    expect(save.playerData.hitpoints, greaterThan(0));
    // the whole hour was fought, and it cost food
    expect(result.actionsPerformed, 1200);
    expect(foodLeft(session), lessThan(500));

    session.dispose();
  });

  test('blocks pay the defence xp live pays for them', () {
    final session = buildSession();
    equipFood(session);
    fightWith(session, EntityId.ROTWOOD_SCARECROW);

    final result = settleFight(
      session,
      count: 1200,
      span: const Duration(hours: 1),
    );

    expect(result.xp[SkillId.DEFENCE], greaterThan(0));
    session.dispose();
  });

  test('a fight that runs out of enemies stops taking damage', () {
    final session = buildSession();
    final save = session.saveGameData;
    setLevel(session, SkillId.ATTACK, 10);
    // one weak enemy, dead in a swing or two: the rest of the hour is not
    // spent standing there being hit
    fightWith(session, EntityId.FIELD_RAT, count: 1);
    final startingHitpoints = save.playerData.hitpoints;

    final result = settleFight(
      session,
      count: 1200,
      span: const Duration(hours: 1),
    );

    expect(result.playerDied, isFalse);
    expect(result.entitiesDefeated.single.count, 1);
    expect(result.actionsPerformed, lessThan(10));
    // an hour of the rat's swings would have worn the player down; the few
    // seconds the fight actually lasted barely scratches them. it swings on
    // its own clock for as long as the actions took, and each swing is
    // worth at most its attack - so bound the damage by that rather than by
    // a number that a retune would invalidate.
    final rat = EntityId.FIELD_RAT.definition as CombatEntityDefinition;
    final worstCase =
        (result.actionsPerformed * 3 / rat.attackInterval).ceil() * rat.attack;
    expect(
      save.playerData.hitpoints,
      greaterThanOrEqualTo(startingHitpoints - worstCase),
    );

    session.dispose();
  });

  test('a node that cannot fight back never swings', () {
    final session = buildSession();
    final save = session.saveGameData;
    final tree = EntityId.TREE.build() as EncounterEntity;
    tree.count = 500;
    session.encounterService.setEncounterEntity(save.encounterData, tree);

    final result = settleFight(
      session,
      count: 1200,
      span: const Duration(hours: 1),
    );

    expect(result.playerDied, isFalse);
    expect(save.playerData.hitpoints, 10);
    expect(result.actionsPerformed, 1200);

    session.dispose();
  });

  test('hitpoints xp is paid for the damage the batch dealt', () {
    final session = buildSession();
    equipFood(session);
    fightWith(session, EntityId.CHICKEN);

    final result = settleFight(
      session,
      count: 600,
      span: const Duration(minutes: 30),
    );

    // damageDone is what the kills were worth, and hitpoints xp follows it
    expect(result.damageDone, greaterThan(0));
    expect(result.xp[SkillId.HITPOINTS], greaterThan(0));

    session.dispose();
  });

  // a batch settles kills off average damage, but a swing that overkills is
  // worth no more than the pool it emptied - so however hard the player
  // hits, one action is one kill at most.
  group('a kill costs a whole action', () {
    test('a node the player one-shots pays at most a kill an action', () {
      final session = buildSession();
      setLevel(session, SkillId.WOODCUTTING, 20); // fells it in a swing
      nodeWith(session, EntityId.TREE);

      final result = settleFight(
        session,
        count: 1200,
        span: const Duration(hours: 1),
      );

      expect(result.actionsPerformed, 1200);
      // one hit is enough, so the only thing between an action and a kill
      // is the swings that miss. what that leaves is pinned against a live
      // loop in test/offline_parity_test.dart; here it is the ceiling that
      // matters - it used to come back at several times the action count.
      expect(result.entitiesDefeated.single.count, lessThan(1200));
      expect(result.entitiesDefeated.single.count, greaterThan(600));

      session.dispose();
    });

    test('an over-levelled fight never kills more than it swung', () {
      final session = buildSession();
      equipFood(session, count: 5000);
      setLevel(session, SkillId.ATTACK, 20);
      // the catalog's weakest enemy against a max hit many times its whole
      // pool: the old batch paid several kills for every action
      fightWith(session, EntityId.FIELD_RAT, count: 5000);

      final result = settleFight(
        session,
        count: 1200,
        span: const Duration(hours: 1),
      );

      expect(
        result.entitiesDefeated.single.count,
        lessThanOrEqualTo(result.actionsPerformed),
      );

      session.dispose();
    });

    test('a slow kill still lands on a whole action', () {
      final session = buildSession();
      equipFood(session, count: 5000);
      // a wall of hitpoints against a level 1 attack: many actions a kill,
      // and the kills are the actions divided down, never rounded up
      fightWith(session, EntityId.SLIME, count: 5000);

      final result = settleFight(
        session,
        count: 1200,
        span: const Duration(hours: 1),
      );

      expect(result.entitiesDefeated.single.count, greaterThan(0));
      expect(
        result.entitiesDefeated.single.count,
        lessThanOrEqualTo(result.actionsPerformed),
      );

      session.dispose();
    });

    test('an entity with no hitpoints settles to nothing', () {
      final session = buildSession();
      // nothing to take down, so nothing is: the swings still cost the
      // stretch they took, the way a run of pure misses would
      nodeWith(session, EntityId.NULL_ENCOUNTER);

      final result = settleFight(
        session,
        count: 1200,
        span: const Duration(hours: 1),
      );

      expect(result.entitiesDefeated, isEmpty);
      expect(result.actionsPerformed, 1200);

      session.dispose();
    });
  });

  // a settle cuts the window at every buff expiry and level-up, so a fight
  // is handed to the batch in pieces. what one piece started, the next has
  // to be able to finish.
  group('a fight carries across the batches that settle it', () {
    test('a batch that cannot finish one leaves its damage on it', () {
      final session = buildSession();
      final node = nodeWith(session, EntityId.IRON);

      // a minute against an iron vein at level 1: nowhere near a kill
      final first = settleFight(
        session,
        count: 20,
        span: const Duration(seconds: 60),
      );

      expect(first.entitiesDefeated, isEmpty);
      expect(node.hitpoints, lessThan(node.maxHitPoints));
      expect(first.damageDone, greaterThan(0));

      // and the next stretch picks the same one up where it was left
      final carried = node.hitpoints;
      settleFight(session, count: 20, span: const Duration(seconds: 60));
      expect(node.hitpoints, lessThan(carried));

      session.dispose();
    });

    test('enough batches in a row add up to the kill', () {
      final session = buildSession();
      final node = nodeWith(session, EntityId.IRON);
      final startingCount = node.count;

      var kills = 0;
      for (var i = 0; i < 40; i++) {
        final result = settleFight(
          session,
          count: 20,
          span: const Duration(seconds: 60),
        );
        kills += result.entitiesDefeated.fold<int>(
          0,
          (sum, stack) => sum + stack.count,
        );
      }

      // 800 actions of half-landing 1-damage swings is 400 damage, so four
      // 100 hitpoint nodes - which only adds up if nothing was healed at a
      // batch boundary
      expect(kills, greaterThan(2));
      expect(node.count, startingCount - kills);

      session.dispose();
    });

    test('a single action pays the xp its damage was worth', () {
      final session = buildSession();
      nodeWith(session, EntityId.IRON);

      // the probe the settle loop opens every window with. half a landing
      // swing is too little to move a whole hitpoint, but it is not too
      // little to be worth xp - and the loop reads that xp back as the rate
      // it predicts level-ups from, so a zero here stops it predicting any.
      final result = settleFight(
        session,
        count: 1,
        span: const Duration(seconds: 3),
      );

      expect(result.damageDone, 0);
      expect(result.xp[SkillId.MINING], greaterThan(0));

      session.dispose();
    });
  });

  group('settling time away', () {
    test('a fight that kills the player ends the settle and says so', () {
      final session = buildSession();
      final save = session.saveGameData;

      // a flock of chickens: enough to keep swinging for the whole gap
      final chicken = EntityId.CHICKEN.build() as EncounterEntity;
      chicken.count = 1000;
      save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities
          .add(chicken);
      expect(
        session.encounterController.startEncounterActionFor(chicken),
        isTrue,
      );

      // an hour away, unfed. even a chicken gets there eventually.
      final now = DateTime.now();
      save.playerData.lastActionTime = now.subtract(const Duration(hours: 1));
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      expect(report!.died, isTrue);
      expect(report.killedBy, EntityId.CHICKEN);
      // it happened early in the gap, not at the end of it
      expect(report.diedAfter, isNotNull);
      expect(report.diedAfter!.inMinutes, lessThan(5));
      // the fight is over: the loop is stopped and the player is back on 1hp
      expect(session.actionTimingController.isRunning, isFalse);
      expect(save.playerData.hitpoints, 1);
      // and the rest of the hour was not fought
      expect(report.actionCount, lessThan(100));

      session.dispose();
    });

    test('a fed player fights the whole gap and comes back alive', () {
      final session = buildSession();
      final save = session.saveGameData;
      equipFood(session, count: 5000);

      final chicken = EntityId.CHICKEN.build() as EncounterEntity;
      chicken.count = 100000;
      save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities
          .add(chicken);
      expect(
        session.encounterController.startEncounterActionFor(chicken),
        isTrue,
      );

      final now = DateTime.now();
      save.playerData.lastActionTime = now.subtract(const Duration(hours: 1));
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      expect(report!.died, isFalse);
      expect(save.playerData.hitpoints, greaterThan(0));
      // an hour of chickens, paid for in food
      expect(report.actionCount, greaterThan(100));
      expect(foodLeft(session), lessThan(5000));
      expect(session.actionTimingController.isRunning, isTrue);

      session.actionTimingController.stop();
      session.dispose();
    });
  });
}
