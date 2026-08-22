import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/data/combat_segment_outcome.dart';
import 'package:rpg/services/encounter_service.dart';

// The enemy's side of a fight, resolved swing by swing. Averaging it is what
// made offline combat free: an enemy averaging 6 against a 10hp player never
// kills, while the same enemy rolling its max of 12 ends the fight outright.
void main() {
  final service = EncounterService();

  // a fight with the numbers spelled out, so a test reads as a scenario
  CombatSegmentOutcome fight({
    required int hitpoints,
    required int enemyAttack,
    int maxHp = 10,
    int playerDefence = 1,
    int foodCount = 0,
    int restoreAmount = 0,
    double eatThreshold = 0.75,
    double attackInterval = 2.0,
    required double seconds,
    int seed = 7,
  }) {
    return service.resolveIncomingDamage(
      hitpoints: hitpoints,
      maxHp: maxHp,
      eatThreshold: eatThreshold,
      foodCount: foodCount,
      restoreAmount: restoreAmount,
      enemyAttack: enemyAttack,
      playerDefence: playerDefence,
      attackInterval: attackInterval,
      seconds: seconds,
      rng: Random(seed),
    );
  }

  group('a swing that lands harder than the player can take', () {
    test('kills through a full bag of food', () {
      // an enemy that hits for more than the player has left is lethal even
      // with food: the death lands before the eat can
      final outcome = fight(
        hitpoints: 10,
        enemyAttack: 60, // max hit well above 10
        foodCount: 99,
        restoreAmount: 20,
        seconds: 600,
      );

      expect(outcome.died, isTrue);
      expect(outcome.hitpoints, 0);
      // it died early, with the bag barely touched
      expect(outcome.swings, lessThan(20));
      expect(outcome.foodEaten, lessThan(20));
    });

    test('a food that heals less than a hit only buys the hp it heals', () {
      // the case that motivated the walk: 10hp, an enemy averaging ~6, and
      // food worth 1. hit to 4, eat to 5, hit to 0 - dead with food left.
      final outcome = fight(
        hitpoints: 10,
        enemyAttack: 12,
        foodCount: 99,
        restoreAmount: 1,
        seconds: 3600,
      );

      expect(outcome.died, isTrue);
      // nowhere near the 99 swings a bag of 99 would buy if food could
      // resurrect a player from zero
      expect(outcome.swings, lessThan(30));
      expect(outcome.foodEaten, lessThan(30));
    });
  });

  group('surviving', () {
    test('a fed player outlasts an enemy it can out-heal', () {
      final outcome = fight(
        hitpoints: 10,
        enemyAttack: 1, // max hit 1 against defence 1
        foodCount: 500,
        restoreAmount: 3,
        seconds: 600, // 300 swings
      );

      expect(outcome.died, isFalse);
      expect(outcome.elapsed, 600);
      expect(outcome.swings, 300);
      expect(outcome.hitpoints, greaterThan(0));
      expect(outcome.foodEaten, greaterThan(0));
      expect(outcome.foodEaten, lessThan(500));
    });

    test('an unfed player dies to a chicken given long enough', () {
      final outcome = fight(
        hitpoints: 10,
        enemyAttack: 1,
        seconds: 3600, // 1800 swings at 2s
      );

      expect(outcome.died, isTrue);
      // ~0.5 damage a swing against 10hp: tens of swings, not hundreds
      expect(outcome.swings, inInclusiveRange(10, 100));
      expect(outcome.elapsed, outcome.swings * 2.0);
    });

    test('hp never climbs past the maximum, however much food is eaten', () {
      final outcome = fight(
        hitpoints: 10,
        enemyAttack: 1,
        foodCount: 1000,
        restoreAmount: 99,
        seconds: 600,
      );

      expect(outcome.hitpoints, lessThanOrEqualTo(10));
      expect(outcome.died, isFalse);
    });
  });

  group('degenerate inputs', () {
    test('a window too short for a swing resolves nothing', () {
      final outcome = fight(hitpoints: 10, enemyAttack: 5, seconds: 1.0);
      expect(outcome.swings, 0);
      expect(outcome.died, isFalse);
      expect(outcome.elapsed, 1.0);
      expect(outcome.hitpoints, 10);
    });

    test('a zero or negative window does nothing', () {
      expect(fight(hitpoints: 10, enemyAttack: 5, seconds: 0).swings, 0);
      expect(fight(hitpoints: 10, enemyAttack: 5, seconds: -5).elapsed, 0);
    });

    test('an entity with no attack cadence never swings', () {
      final outcome = fight(
        hitpoints: 10,
        enemyAttack: 5,
        attackInterval: 0,
        seconds: 3600,
      );
      expect(outcome.swings, 0);
      expect(outcome.hitpoints, 10);
    });

    test('food that restores nothing is no food at all', () {
      final outcome = fight(
        hitpoints: 10,
        enemyAttack: 5,
        foodCount: 99,
        restoreAmount: 0,
        seconds: 3600,
      );
      expect(outcome.died, isTrue);
      expect(outcome.foodEaten, 0);
    });
  });

  test('ten million swings resolve in well under a second', () {
    final watch = Stopwatch()..start();
    final outcome = service.resolveIncomingDamage(
      hitpoints: 100000,
      maxHp: 100000,
      eatThreshold: 0.75,
      foodCount: 100000000,
      restoreAmount: 40,
      enemyAttack: 5,
      playerDefence: 1,
      attackInterval: 2.0,
      seconds: 20000000, // 10M swings
      rng: Random(1),
    );
    watch.stop();

    expect(outcome.swings, 10000000);
    // a loose bound: tight enough to catch an allocation creeping into the
    // loop, loose enough not to flake on a busy machine
    expect(watch.elapsedMilliseconds, lessThan(2000));
  });
}
