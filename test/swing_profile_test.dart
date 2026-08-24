import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/data/swing_profile.dart';

// A batched fight cannot roll a swing at a time, so it asks SwingProfile how
// many landing swings a hitpoint pool costs. That number is not the pool
// divided by the average swing: a swing rolls uniformly in 1..maxHit and
// overkill is discarded, so the last swing of a kill is usually worth less
// than an average one, and the pool takes more swings than the mean suggests.
//
// The cheap answer - ceil(pool / averageDamage) - under-counts by a third in
// the range where a kill takes about one swing, and a settle that under-counts
// the cost of a kill hands out more kills than the fight earned. So the table
// is checked against the thing it stands in for: swings actually rolled.
void main() {
  // rolls uniformly in 1..maxHit until the pool is gone, [trials] times, and
  // reports the mean number of rolls it took
  double simulate(
    int hitpoints,
    int maxHit, {
    int trials = 40000,
    int seed = 9,
  }) {
    final rng = Random(seed);
    var total = 0;
    for (var t = 0; t < trials; t++) {
      var left = hitpoints;
      while (left > 0) {
        left -= 1 + rng.nextInt(maxHit);
        total++;
      }
    }
    return total / trials;
  }

  group('hitsToRemove', () {
    // the shapes that matter: a pool that takes many swings, one that takes a
    // few, and one a single swing usually finishes - the last is where
    // dividing the mean goes furthest wrong
    for (final c in [
      (hitpoints: 200, maxHit: 4),
      (hitpoints: 40, maxHit: 16),
      (hitpoints: 10, maxHit: 3),
      (hitpoints: 5, maxHit: 9),
      (hitpoints: 5, maxHit: 19),
      (hitpoints: 2, maxHit: 25),
    ]) {
      test('${c.hitpoints}hp against a 1..${c.maxHit} roll', () {
        final profile = SwingProfile(hitChance: 1.0, maxHit: c.maxHit);
        final expected = profile.hitsToRemove(c.hitpoints);
        final rolled = simulate(c.hitpoints, c.maxHit);

        expect(expected, closeTo(rolled, rolled * 0.03));
      });
    }

    test('a swing rolling exactly one is the pool itself', () {
      final profile = SwingProfile(hitChance: 1.0, maxHit: 1);
      expect(profile.hitsToRemove(5), 5.0);
      expect(profile.hitsToRemove(1), 1.0);
    });

    test('never below one swing, and nothing for an empty pool', () {
      final profile = SwingProfile(hitChance: 1.0, maxHit: 100);
      expect(profile.hitsToRemove(1), greaterThanOrEqualTo(1.0));
      expect(profile.hitsToRemove(0), 0);
      expect(profile.hitsToRemove(-5), 0);
    });

    test('rises with the pool, and the table is stable when reread', () {
      final profile = SwingProfile(hitChance: 0.6, maxHit: 7);
      var previous = 0.0;
      for (var hp = 1; hp <= 300; hp++) {
        final hits = profile.hitsToRemove(hp);
        expect(hits, greaterThanOrEqualTo(previous));
        previous = hits;
      }
      // grown on demand, so a reread has to give the same answer
      expect(profile.hitsToRemove(150), profile.hitsToRemove(150));
      expect(profile.hitsToRemove(1), 1.0);
    });

    test('a pool past the table limit extrapolates on the same slope', () {
      final profile = SwingProfile(hitChance: 1.0, maxHit: 8);
      // the curve is a straight line long before here, so a step of n pool
      // costs n / damagePerHit swings whichever side of the limit it lands
      final near = profile.hitsToRemove(4000);
      final far = profile.hitsToRemove(9000);
      expect(far - near, closeTo(5000 / profile.damagePerHit, 1.0));
    });
  });

  group('actions and hits', () {
    test('a hit costs more than an action, because swings miss', () {
      final profile = SwingProfile(hitChance: 0.5, maxHit: 4);
      expect(profile.actionsForHits(3), 6.0);
      expect(profile.hitsForActions(10), 5.0);
    });

    // the invariant the whole class exists to protect: a kill needs at least
    // one landing swing, a swing lands at most 95% of the time, so a kill
    // always costs more than one action and a batch can never pay out more
    // kills than it fired actions
    test('a kill always costs more than one action', () {
      for (final hitChance in [0.05, 0.5, 0.95]) {
        for (final maxHit in [1, 10, 1000]) {
          final profile = SwingProfile(hitChance: hitChance, maxHit: maxHit);
          expect(
            profile.actionsForHits(profile.hitsToRemove(1)),
            greaterThan(1.0),
          );
        }
      }
    });
  });
}
