import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

// rollMulitpleTimes is the batching shortcut behind offline progress: it has
// to pay what numberOfRolls individual rolls would have paid, without doing
// numberOfRolls worth of work. these tests pin the parts of that bargain that
// are cheap to get wrong - the shares summing back to the batch, the tail of
// the table not being starved by the head, and the caller's table surviving
// the call unmodified.
void main() {
  final service = WeightedDropTableService();

  // the number of ITEMS handed out, which is only the number of rolls when
  // every entry in the table is a plain count-1 drop. an entry carrying a
  // stack size decouples the two entirely - see the 'items are not rolls'
  // group below.
  int totalCount<T>(List<dynamic> stacks) =>
      stacks.fold<int>(0, (sum, s) => sum + (s.count as int));

  Map<T, int> byId<T>(List<dynamic> stacks) => {
    for (final s in stacks) s.id as T: s.count as int,
  };

  group('rollMulitpleTimes allocation', () {
    test('a uniform table splits the batch evenly', () {
      final table = [
        for (final id in [ItemId.LOGS, ItemId.COAL, ItemId.COINS, ItemId.RUBY])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1),
      ];

      final out = service.rollMulitpleTimes(100, table, rng: Random(7));

      // 100/4 = 25.0 each: whole shares, so the coin flips never fire and
      // every entry gets its 25 rolls outright. these entries are all
      // count-1, which is the only reason 100 rolls reads as 100 items.
      expect(totalCount(out), 100);
      for (final stack in out) {
        expect(stack.count, 25);
      }
    });

    test('the low-weight head does not starve the high-weight tail', () {
      // the regression this method was rewritten around. shares are measured
      // against the full table weight and the full batch, so processing the
      // 1-weight entry first must not eat into what the 100-weight entry is
      // owed. c is worth half the table: 50 rolls, not 25.
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 99),
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 100),
      ];

      final out = byId<ItemId>(
        service.rollMulitpleTimes(100, table, rng: Random(1)),
      );

      expect(out[ItemId.LOGS], 50);
      expect(out[ItemId.COAL], anyOf(49, 50));
      expect(out[ItemId.RUBY], anyOf(isNull, 1));
    });

    test('honours weight, not just membership', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 3),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 1),
      ];

      final out = byId<ItemId>(
        service.rollMulitpleTimes(1000, table, rng: Random(11)),
      );

      expect(out[ItemId.LOGS], 750);
      expect(out[ItemId.COAL], 250);
    });

    test('ragged shares still hand out exactly numberOfRolls', () {
      // 7 entries over 100 rolls is 14.2857 each - not one whole share in
      // the table, which is the case a per-entry rounding scheme leaks
      // rolls on. the count-1 entries let the item total stand in for the
      // roll count here.
      final table = [
        for (final id in [
          ItemId.LOGS,
          ItemId.COAL,
          ItemId.COINS,
          ItemId.RUBY,
          ItemId.SAPPHIRE,
          ItemId.COPPER_BAR,
          ItemId.IRON_BAR,
        ])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1),
      ];

      for (var seed = 0; seed < 200; seed++) {
        final out = service.rollMulitpleTimes(100, table, rng: Random(seed));
        expect(totalCount(out), 100, reason: 'seed $seed');
      }
    });

    test(
      'a sub-one-percent entry lands at its rate instead of flooring away',
      () {
        // 1-in-1000 over 100 rolls is a share of 0.1: it can never win a whole
        // roll, and a floor-only allocation would drop it entirely. across 400
        // seeds it should show up about a tenth of the time.
        final table = [
          WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 1),
          WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 999),
        ];

        var appearances = 0;
        for (var seed = 0; seed < 400; seed++) {
          final out = byId<ItemId>(
            service.rollMulitpleTimes(100, table, rng: Random(seed)),
          );
          if (out.containsKey(ItemId.RUBY)) appearances++;
        }

        expect(appearances, closeTo(40, 25));
      },
    );

    test('a whole-number share needs no luck at all', () {
      // every seed must agree: 25.0 is guaranteed, not flipped for
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 3),
      ];

      for (var seed = 0; seed < 20; seed++) {
        final out = byId<ItemId>(
          service.rollMulitpleTimes(100, table, rng: Random(seed)),
        );
        expect(out[ItemId.LOGS], 25);
        expect(out[ItemId.COAL], 75);
      }
    });
  });

  group('rollMulitpleTimes stack sizes', () {
    test('a variable-count entry pays the mean of its range per roll', () {
      // 2..6 averages 4, so 50 rolls is 200 - and it is the mean, so no seed
      // moves it
      final table = [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.LOGS,
          weight: 1,
          count: 2,
          highCount: 6,
        ),
      ];

      for (var seed = 0; seed < 10; seed++) {
        final out = service.rollMulitpleTimes(50, table, rng: Random(seed));
        expect(out.single.count, 200);
      }
    });

    test('a fixed count multiplies through', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1, count: 3),
      ];

      expect(
        service.rollMulitpleTimes(20, table, rng: Random(4)).single.count,
        60,
      );
    });

    test('a highCount at or below count is not a range', () {
      // catalogs leave highCount at 0 for fixed drops, and highCount == count
      // is the same statement said twice
      final table = [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.LOGS,
          weight: 1,
          count: 5,
          highCount: 5,
        ),
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COAL,
          weight: 1,
          count: 5,
          highCount: 0,
        ),
      ];

      final out = byId<ItemId>(
        service.rollMulitpleTimes(20, table, rng: Random(4)),
      );
      expect(out[ItemId.LOGS], 50);
      expect(out[ItemId.COAL], 50);
    });

    test('an odd-width range rounds rather than truncating', () {
      // 1..60 averages 30.5; 3 rolls is 91.5, which must not floor to 91
      final table = [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COINS,
          weight: 1,
          count: 1,
          highCount: 60,
        ),
      ];

      expect(
        service.rollMulitpleTimes(3, table, rng: Random(4)).single.count,
        92,
      );
    });
  });

  group('rollMulitpleTimes items are not rolls', () {
    // two independent reasons the item total is not the roll count, worth
    // pinning separately so neither gets "fixed" into the other:
    //   1. a roll of a stacking entry pays a whole stack, not one item
    //   2. fractional shares are settled by coin flip, so the rolls handed
    //      out land near numberOfRolls rather than on it
    test('a stacking entry pays a stack per roll, not an item per roll', () {
      // 1..60 averages 30.5, so 100 rolls of a coin drop is 3050 coins.
      // reading that back as "100 items" would undercount the batch 30x.
      final table = [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COINS,
          weight: 1,
          count: 1,
          highCount: 60,
        ),
      ];

      final out = service.rollMulitpleTimes(100, table, rng: Random(21));

      expect(out.single.count, 3050);
      expect(totalCount(out), isNot(100));
    });

    test('a mixed table pays each entry in its own stack size', () {
      // an even split of 100 rolls, but the two entries cash their 50 rolls
      // at wildly different rates. the roll allocation is recoverable from
      // the item counts only because the stack size is the fixed mean.
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COINS,
          weight: 1,
          count: 1,
          highCount: 60,
        ),
      ];

      final out = byId<ItemId>(
        service.rollMulitpleTimes(100, table, rng: Random(22)),
      );

      expect(out[ItemId.LOGS], 50);
      expect(out[ItemId.COINS], 1525);
      expect(out[ItemId.LOGS]! + out[ItemId.COINS]!, 1575);
    });

    test('the split moves with the seed but the total never does', () {
      // 3 entries over 10 rolls is 3.333 each: 9 whole rolls plus a leftover
      // that has to go somewhere. which entry collects it is the seed's
      // business - the total is not.
      final table = [
        for (final id in [ItemId.LOGS, ItemId.COAL, ItemId.COINS])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1),
      ];

      final splits = <String>{};
      for (var seed = 0; seed < 60; seed++) {
        final out = service.rollMulitpleTimes(10, table, rng: Random(seed));
        expect(totalCount(out), 10, reason: 'seed $seed');
        splits.add(byId<ItemId>(out).toString());
      }

      // the leftover really is being scattered, not parked on one entry
      expect(splits.length, greaterThan(1));
    });
  });

  group('rollMulitpleTimes roll conservation', () {
    // the property the whole batching shortcut rests on: a batch of N pays
    // what N single rolls would have paid. if the rolls handed out drift
    // from N, offline progress silently over- or under-pays.
    test('random tables of every shape hand out exactly numberOfRolls', () {
      final ids = [
        ItemId.LOGS,
        ItemId.COAL,
        ItemId.COINS,
        ItemId.RUBY,
        ItemId.SAPPHIRE,
        ItemId.COPPER_BAR,
        ItemId.IRON_BAR,
        ItemId.COW_HIDE,
      ];
      final shapeRng = Random(99);

      for (var trial = 0; trial < 300; trial++) {
        final entryCount = 1 + shapeRng.nextInt(ids.length);
        final rolls = 1 + shapeRng.nextInt(5000);
        final table = [
          for (var i = 0; i < entryCount; i++)
            WeightedDropTableEntry<ItemId>(
              id: ids[i],
              // spans four orders of magnitude, so most trials carry at
              // least one share well under a single roll
              weight: shapeRng.nextDouble() * 1000 + 0.001,
            ),
        ];

        // every entry is count-1, so the item total is the roll count
        final out = service.rollMulitpleTimes(rolls, table, rng: Random(trial));

        expect(
          totalCount(out),
          rolls,
          reason: 'trial $trial: $entryCount entries, $rolls rolls',
        );
      }
    });

    test('a table that is nearly all one entry still pays out in full', () {
      // the degenerate shape: seven entries that round to nothing and one
      // that takes the lot. the seven must not each quietly claim a roll.
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1000000),
        for (final id in [
          ItemId.COAL,
          ItemId.COINS,
          ItemId.RUBY,
          ItemId.SAPPHIRE,
          ItemId.COPPER_BAR,
          ItemId.IRON_BAR,
          ItemId.COW_HIDE,
        ])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1),
      ];

      for (var seed = 0; seed < 100; seed++) {
        final out = service.rollMulitpleTimes(50, table, rng: Random(seed));
        expect(totalCount(out), 50, reason: 'seed $seed');
      }
    });

    test('a single roll goes to exactly one entry', () {
      // numberOfRolls of 1 is the sharpest case: the batch cannot be split,
      // so somebody gets it and nobody else gets anything
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 3),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 1),
      ];

      final winners = <ItemId>{};
      for (var seed = 0; seed < 100; seed++) {
        final out = service.rollMulitpleTimes(1, table, rng: Random(seed));
        expect(out, hasLength(1), reason: 'seed $seed');
        expect(out.single.count, 1, reason: 'seed $seed');
        winners.add(out.single.id);
      }

      // and over 100 seeds both entries should have had a turn
      expect(winners, containsAll([ItemId.LOGS, ItemId.COAL]));
    });
  });

  group('rollMulitpleTimes contracts', () {
    test('does not reorder the caller\'s table', () {
      // encounter_system hands over the entity catalog's own itemDrops list.
      // sorting that in place would permanently reshuffle catalog data.
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 100),
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 50),
      ];
      final before = [for (final e in table) e.id];

      service.rollMulitpleTimes(100, table, rng: Random(2));

      expect([for (final e in table) e.id], before);
    });

    test('the result does not depend on the order the table is written in', () {
      List<WeightedDropTableEntry<ItemId>> build() => [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 60),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 30),
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 10),
      ];

      final forwards = byId<ItemId>(
        service.rollMulitpleTimes(250, build(), rng: Random(9)),
      );
      final backwards = byId<ItemId>(
        service.rollMulitpleTimes(
          250,
          build().reversed.toList(),
          rng: Random(9),
        ),
      );

      expect(forwards, backwards);
    });

    test('the same id twice in a table accumulates instead of clobbering', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 3),
      ];

      final out = service.rollMulitpleTimes(100, table, rng: Random(6));

      expect(out, hasLength(1));
      expect(out.single.count, 100);
    });

    test('is deterministic for a given seed', () {
      final table = [
        for (final id in [ItemId.LOGS, ItemId.COAL, ItemId.COINS])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1, highCount: 4),
      ];

      Map<ItemId, int> run(int seed) =>
          byId<ItemId>(service.rollMulitpleTimes(37, table, rng: Random(seed)));

      expect(run(5), run(5));
    });

    test('an entry that wins no rolls is left out entirely', () {
      // a zero stack in the output would show up as a phantom "you found 0
      // rubies" line in the offline report
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 100000),
      ];

      final out = service.rollMulitpleTimes(2, table, rng: Random(0));

      expect(out.map((s) => s.id), isNot(contains(ItemId.RUBY)));
      expect(out.every((s) => s.count > 0), isTrue);
    });

    test('an entry declaring count 0 yields no stack', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.NULL, weight: 1, count: 0),
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
      ];

      final out = service.rollMulitpleTimes(100, table, rng: Random(8));

      expect(out.map((s) => s.id), isNot(contains(ItemId.NULL)));
    });

    test('handles degenerate inputs without throwing', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
      ];

      expect(service.rollMulitpleTimes(0, table), isEmpty);
      expect(service.rollMulitpleTimes(-5, table), isEmpty);
      expect(
        service.rollMulitpleTimes<ItemId>(
          10,
          <WeightedDropTableEntry<ItemId>>[],
        ),
        isEmpty,
      );
    });

    test('a single-entry table takes the whole batch', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 0.5),
      ];

      expect(
        service.rollMulitpleTimes(1000, table, rng: Random(12)).single.count,
        1000,
      );
    });

    test('rejects a non-positive weight, as a single roll does', () {
      for (final bad in [0.0, -1.0]) {
        final table = [
          WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
          WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: bad),
        ];
        expect(
          () => service.rollMulitpleTimes(10, table),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

    test('a huge batch stays close to the weights it was given', () {
      // the offline-progress case: tens of thousands of rolls settled at once
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 70),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 25),
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 5),
      ];

      final out = byId<ItemId>(
        service.rollMulitpleTimes(50000, table, rng: Random(13)),
      );

      expect(out[ItemId.LOGS], 35000);
      expect(out[ItemId.COAL], 12500);
      expect(out[ItemId.RUBY], 2500);
    });
  });
}
