import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';

/// A combat entity's stats are a level (the size of the budget) split by a
/// [CombatType] (the shape of the split). The claim under test is that the
/// split is lossless: the three derived stats always name the level they
/// came from, for any weights, at any level.
void main() {
  int levelOfType(CombatType t, int level) => CombatType.levelOf(
    attack: t.attackAt(level),
    defence: t.defenceAt(level),
    hitpoints: t.hitpointsAt(level),
  );

  group('CombatType', () {
    test('level round-trips through the derived stats, 1..99', () {
      for (final t in CombatType.values) {
        for (var level = 1; level <= 99; level++) {
          expect(
            levelOfType(t, level),
            level,
            reason: '${t.name} at level $level',
          );
        }
      }
    });

    test('round-trip does not depend on the weights summing to 10', () {
      // the weights are a ratio over their own total, so an arbitrary
      // scale must work exactly as well as the catalog's tens. the one
      // exception is the min-1 floor: a stat whose true share is below 1
      // gets rounded up, which buys the entity a little budget it did not
      // earn, so the level can read back one higher
      const oddTriples = [
        [1, 1, 1],
        [2, 3, 7],
        [5, 5, 9],
        [3, 1, 20],
        [7, 7, 7],
      ];
      for (final w in oddTriples) {
        final total = w[0] + w[1] + w[2];
        for (var level = 1; level <= 99; level++) {
          final attack = combatAttackAt(level, w[0], total);
          final defence = combatDefenceAt(level, w[1], total);
          final hitpoints = combatHitpointsAt(level, w[2], total);
          final read = CombatType.levelOf(
            attack: attack,
            defence: defence,
            hitpoints: hitpoints,
          );
          final floored =
              level * 3 * w[0] / total < 0.5 ||
              level * 3 * w[1] / total < 0.5 ||
              level * 3 * 5 * w[2] / total < 0.5;
          if (floored) {
            expect(
              read,
              inInclusiveRange(level, level + 1),
              reason: 'weights $w at level $level (a stat floored to 1)',
            );
          } else {
            expect(read, level, reason: 'weights $w at level $level');
          }
        }
      }
    });

    test('stats match the documented formula', () {
      expect(
        [
          CombatType.BALANCE.attackAt(10),
          CombatType.BALANCE.defenceAt(10),
          CombatType.BALANCE.hitpointsAt(10),
        ],
        [9, 9, 60],
      );
      expect(
        [
          CombatType.ROCK_CRAB.attackAt(10),
          CombatType.ROCK_CRAB.defenceAt(10),
          CombatType.ROCK_CRAB.hitpointsAt(10),
        ],
        [3, 3, 120],
      );
      expect(
        [
          CombatType.GLASS_CANNON.attackAt(10),
          CombatType.GLASS_CANNON.defenceAt(10),
          CombatType.GLASS_CANNON.hitpointsAt(10),
        ],
        [24, 3, 15],
      );
    });

    test('no stat ever lands on zero', () {
      for (final t in CombatType.values) {
        for (var level = 1; level <= 99; level++) {
          expect(t.attackAt(level), greaterThanOrEqualTo(1));
          expect(t.defenceAt(level), greaterThanOrEqualTo(1));
          expect(t.hitpointsAt(level), greaterThanOrEqualTo(1));
        }
      }
      expect(CombatType.SHELL.attackAt(1), 1);
    });
  });

  group('CombatEntityDefinition', () {
    test('derives its stats from level and type', () {
      final def = EntityId.GOBLIN_QUEEN.definition as CombatEntityDefinition;
      expect(def.level, 28);
      expect(def.combatType, CombatType.LEATHER_TANK);
      expect(def.attack, 17);
      expect(def.defence, 34);
      expect(def.hitpoints, 168);
    });

    test('the runtime entity carries the derived stats', () {
      final entity = EntityId.GOBLIN.build() as CombatEntity;
      expect(entity.attack, 5);
      expect(entity.defence, 2);
      expect(entity.hitpoints, 9);
      expect(entity.maxHitPoints, 9);
    });
  });
}
