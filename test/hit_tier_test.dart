import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/encounter_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/encounter_screen.dart';
import 'package:rpg/services/encounter_service.dart';

// The number for a hit the player deals is coloured by how it rolled:
// a miss, below the average hit, at or above it, or the top of the range.
// Hits roll evenly from 1 to the swing's max, so the average sits halfway.
void main() {
  group('tiers', () {
    test('a miss is a miss', () {
      expect(HitTier.of(0, maxRoll: 10), HitTier.miss);
    });

    test('the average splits low from high, and counts as high', () {
      // 1..10 averages 5.5: 5 is below it, 6 above
      expect(HitTier.of(1, maxRoll: 10), HitTier.low);
      expect(HitTier.of(5, maxRoll: 10), HitTier.low);
      expect(HitTier.of(6, maxRoll: 10), HitTier.high);
      expect(HitTier.of(9, maxRoll: 10), HitTier.high);
      // 1..9 averages exactly 5, which is high
      expect(HitTier.of(4, maxRoll: 9), HitTier.low);
      expect(HitTier.of(5, maxRoll: 9), HitTier.high);
    });

    test('the top of the range is a max hit', () {
      expect(HitTier.of(10, maxRoll: 10), HitTier.max);
      // a range of one: every hit is the max
      expect(HitTier.of(1, maxRoll: 1), HitTier.max);
      // the roll's own word for it, when a kill capped what it dealt
      expect(HitTier.of(3, maxRoll: 10, maxHit: true), HitTier.max);
    });

    test('with no range to read, any hit is high', () {
      expect(HitTier.of(4, maxRoll: 0), HitTier.high);
    });
  });

  test('a swing reports its range, and a max hit only at its top', () {
    final factory = GameSessionFactory();
    final player = factory.newGame(factory.catalog1()).playerData;
    final service = EncounterService();
    final rng = Random(7);
    final stats = {SkillId.ATTACK: 60};

    var sawMax = false;
    var sawBelow = false;
    for (var i = 0; i < 400; i++) {
      // hp to spare, so no kill caps what the swing deals
      final bear = EntityId.CAVE_BEAR.build() as CombatEntity;
      bear.hitpoints = bear.maxHitPoints;
      final encounter = EncounterData()
        ..isActive = true
        ..entity = bear;

      final r = service.resolvePlayerDamage(
        stats,
        player,
        encounter,
        damage: 4,
        rng: rng,
      );

      expect(r.maxRoll, greaterThan(1));
      expect(r.damageDone, lessThanOrEqualTo(r.maxRoll));
      expect(r.maxHit, r.damageDone == r.maxRoll);
      if (r.maxHit) sawMax = true;
      if (r.damageDone > 0 && !r.maxHit) sawBelow = true;
    }
    expect(sawMax, isTrue);
    expect(sawBelow, isTrue);
  });
}
