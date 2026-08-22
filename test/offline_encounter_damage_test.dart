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

  // an enemy of the given shape, standing in the player's zone and opened
  // as the active encounter
  CombatEntity fightWith(
    GameSession session, {
    int attack = 5,
    int hitpoints = 10,
    int count = 1000,
    double attackInterval = 2.0,
  }) {
    final entity = CombatEntity(
      id: EntityId.CHICKEN,
      name: 'Test Enemy',
      count: count,
      defence: 1,
      hitpoints: hitpoints,
      attack: attack,
      attackInterval: attackInterval,
    );
    session.encounterService.setEncounterEntity(
      session.saveGameData.encounterData,
      entity,
    );
    return entity;
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

  // one offline batch of [count] actions covering [span]
  EncounterActionResult settleFight(
    GameSession session, {
    required int count,
    required Duration span,
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
    );
  }

  test('an unfed player dies partway through a long fight', () {
    final session = buildSession();
    final save = session.saveGameData;
    setLevel(session, SkillId.ATTACK, 10); // kills a chicken in one swing
    fightWith(session, attack: 5, hitpoints: 2);

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
    fightWith(session, attack: 2); // max hit 1 against defence 1

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
    fightWith(session, attack: 2);

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
    fightWith(session, attack: 1, hitpoints: 2, count: 1);

    final result = settleFight(
      session,
      count: 1200,
      span: const Duration(hours: 1),
    );

    expect(result.playerDied, isFalse);
    expect(result.entitiesDefeated.single.count, 1);
    expect(result.actionsPerformed, lessThan(10));
    // an hour of a 1-attack enemy would have worn the player down; a few
    // seconds of it barely scratches them
    expect(save.playerData.hitpoints, greaterThanOrEqualTo(9));

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
    fightWith(session, attack: 2, hitpoints: 5);

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
