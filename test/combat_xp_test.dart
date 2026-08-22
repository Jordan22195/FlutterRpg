import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/systems/encounter_system.dart';

// A fight pays the stance that fought it. Defence used to train only from
// blocked hits, which meant it barely trained at all; now every point of
// damage pays the stance's own skill, and the fast stance splits it.
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

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  // an enemy standing in the player's zone, opened as the active encounter
  EncounterEntity fightWith(
    GameSession session,
    EntityId id, {
    int count = 500,
  }) {
    final save = session.saveGameData;
    final entity = id.build() as EncounterEntity;
    entity.count = count;
    session.encounterService.setEncounterEntity(save.encounterData, entity);
    return entity;
  }

  // one offline batch over a stretch of time
  EncounterActionResult batch(GameSession session, {int count = 200}) {
    final save = session.saveGameData;
    return session.encounterSystem.executePlayerAction(
      playerState: save.playerData,
      encounter: save.encounterData,
      worldState: save.worldData,
      playerInventory: save.inventoryData,
      actionCount: count,
      offline: true,
      at: save.playerData.lastActionTime,
      span: Duration(seconds: count * 3),
    );
  }

  // one live action, retried until a swing actually lands: a miss pays
  // nothing and has no xp to route
  EncounterActionResult liveHit(GameSession session) {
    final save = session.saveGameData;
    for (var i = 0; i < 200; i++) {
      final result = session.encounterSystem.executePlayerAction(
        playerState: save.playerData,
        encounter: save.encounterData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
      );
      if (result.damageDone > 0) return result;
    }
    fail('no swing landed in 200 tries');
  }

  double xpFor(GameSession session, SkillId skill) =>
      session.saveGameData.playerData.skillData[skill]!.xp;

  group('a combat batch pays the stance that fought it', () {
    test('offensive trains the weapon skill and nothing else', () {
      final session = buildSession();
      setLevel(session, SkillId.ATTACK, 10);
      session.playerDataService.setStance(
        Stance.offensive,
        session.saveGameData.playerData,
      );
      fightWith(session, EntityId.CHICKEN);

      final result = batch(session);

      expect(result.damageDone, greaterThan(0));
      expect(
        result.xp[SkillId.ATTACK],
        EncounterSystem.xpPerDamage * result.damageDone,
      );
      expect(result.xp[SkillId.DEFENCE], isNull);

      session.dispose();
    });

    test('defensive trains defence and nothing else', () {
      final session = buildSession();
      setLevel(session, SkillId.ATTACK, 10);
      session.playerDataService.setStance(
        Stance.defensive,
        session.saveGameData.playerData,
      );
      fightWith(session, EntityId.CHICKEN);

      final result = batch(session);

      expect(result.damageDone, greaterThan(0));
      expect(
        result.xp[SkillId.DEFENCE],
        EncounterSystem.xpPerDamage * result.damageDone,
      );
      expect(result.xp[SkillId.ATTACK], isNull);

      session.dispose();
    });

    test('fast splits it evenly, and the halves add back up', () {
      final session = buildSession();
      setLevel(session, SkillId.ATTACK, 10);
      session.playerDataService.setStance(
        Stance.fast,
        session.saveGameData.playerData,
      );
      fightWith(session, EntityId.CHICKEN);

      final result = batch(session);

      final total = EncounterSystem.xpPerDamage * result.damageDone;
      expect(result.xp[SkillId.ATTACK], total / 2);
      expect(result.xp[SkillId.DEFENCE], total / 2);
      // a stance moves the xp, it does not create or destroy any
      expect(
        result.xp[SkillId.ATTACK]! + result.xp[SkillId.DEFENCE]!,
        closeTo(total, 1e-9),
      );

      session.dispose();
    });

    test('hitpoints takes a third of the damage xp in every stance', () {
      for (final stance in [Stance.offensive, Stance.defensive, Stance.fast]) {
        final session = buildSession();
        setLevel(session, SkillId.ATTACK, 10);
        session.playerDataService.setStance(
          stance,
          session.saveGameData.playerData,
        );
        fightWith(session, EntityId.CHICKEN);

        final result = batch(session);

        expect(
          result.xp[SkillId.HITPOINTS],
          closeTo(EncounterSystem.xpPerDamage * result.damageDone / 3.0, 1e-9),
          reason: '$stance',
        );

        session.dispose();
      }
    });

    test('a tree pays woodcutting whatever the stance', () {
      for (final stance in [Stance.offensive, Stance.defensive, Stance.fast]) {
        final session = buildSession();
        setLevel(session, SkillId.WOODCUTTING, 10);
        session.playerDataService.setStance(
          stance,
          session.saveGameData.playerData,
        );
        fightWith(session, EntityId.TREE);

        final result = batch(session);

        expect(
          result.xp[SkillId.WOODCUTTING],
          greaterThan(0),
          reason: '$stance',
        );
        expect(result.xp[SkillId.ATTACK], isNull, reason: '$stance');
        expect(result.xp[SkillId.DEFENCE], isNull, reason: '$stance');
        // a node cannot fight back, so it trains no hitpoints either
        expect(result.xp[SkillId.HITPOINTS], isNull, reason: '$stance');

        session.dispose();
      }
    });
  });

  group('a live swing pays the same way', () {
    test('offensive puts it on attack, defensive on defence', () {
      final offensive = buildSession();
      setLevel(offensive, SkillId.ATTACK, 20);
      offensive.playerDataService.setStance(
        Stance.offensive,
        offensive.saveGameData.playerData,
      );
      fightWith(offensive, EntityId.CHICKEN);
      final hit = liveHit(offensive);

      expect(
        hit.xp[SkillId.ATTACK],
        EncounterSystem.xpPerDamage * hit.damageDone,
      );
      expect(hit.xp[SkillId.DEFENCE], isNull);
      offensive.dispose();

      final defensive = buildSession();
      setLevel(defensive, SkillId.ATTACK, 20);
      defensive.playerDataService.setStance(
        Stance.defensive,
        defensive.saveGameData.playerData,
      );
      fightWith(defensive, EntityId.CHICKEN);
      final blocked = liveHit(defensive);

      expect(
        blocked.xp[SkillId.DEFENCE],
        EncounterSystem.xpPerDamage * blocked.damageDone,
      );
      expect(blocked.xp[SkillId.ATTACK], isNull);
      defensive.dispose();
    });

    test('fast splits a live swing too', () {
      final session = buildSession();
      setLevel(session, SkillId.ATTACK, 20);
      session.playerDataService.setStance(
        Stance.fast,
        session.saveGameData.playerData,
      );
      fightWith(session, EntityId.CHICKEN);

      final hit = liveHit(session);
      final total = EncounterSystem.xpPerDamage * hit.damageDone;

      expect(hit.xp[SkillId.ATTACK], total / 2);
      expect(hit.xp[SkillId.DEFENCE], total / 2);

      session.dispose();
    });
  });

  test('being missed pays nothing at all', () {
    final session = buildSession();
    final save = session.saveGameData;
    // a defence the enemy can barely touch, so most swings miss
    setLevel(session, SkillId.DEFENCE, 60);
    setLevel(session, SkillId.HITPOINTS, 60);
    save.playerData.hitpoints = 600;
    fightWith(session, EntityId.CHICKEN);

    final before = xpFor(session, SkillId.DEFENCE);
    for (var i = 0; i < 200; i++) {
      session.encounterSystem.executeEntityAttack(
        playerState: save.playerData,
        encounter: save.encounterData,
      );
    }

    // blocks used to be the only way defence trained; now they are worth
    // nothing and the stance is what pays
    expect(xpFor(session, SkillId.DEFENCE), before);

    session.dispose();
  });
}
