import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Content invariants for the shared drop tables.
///
/// The tables are `const` top-level lists so that a `const` catalog
/// definition can splice them. That is the load-bearing claim of the whole
/// design, and [splicedIntoAConstTable] below asserts it at compile time:
/// if const spreading ever stopped working here, this file would not build.
const List<WeightedDropTableEntry<ItemId>> splicedIntoAConstTable = [
  ...gemDropTable,
  WeightedDropTableEntry(id: ItemId.COPPER_ORE, weight: 1),
];

/// The gems, in the order the table is expected to list them.
const expectedGems = <ItemId>[
  ItemId.TOPAZ,
  ItemId.SAPPHIRE,
  ItemId.EMERALD,
  ItemId.RUBY,
  ItemId.DIAMOND,
  ItemId.DRAGONSTONE,
  ItemId.ONYX,
];

/// The herbs, in the order the table is expected to list them.
const expectedHerbs = <ItemId>[
  ItemId.GUAM_LEAF,
  ItemId.MARRENTILL,
  ItemId.TARROMIN,
  ItemId.HARRALANDER,
  ItemId.RANARR_WEED,
  ItemId.TOADFLAX,
  ItemId.IRIT_LEAF,
  ItemId.AVANTOE,
  ItemId.KWUARM,
  ItemId.SNAPDRAGON,
  ItemId.CADANTINE,
  ItemId.LANTADYME,
  ItemId.DWARF_WEED,
  ItemId.TORSTOL,
];

/// The tables under test, by the name a failure should name them by.
const tables = <String, List<WeightedDropTableEntry<ItemId>>>{
  'gemDropTable': gemDropTable,
  'herbDropTable': herbDropTable,
};

void main() {
  group('contents', () {
    // frozen on purpose: a gem or herb added to ItemId and forgotten here
    // would never drop from anything using the shared table
    test('the gem table is every gem, in value order', () {
      expect(gemDropTable.map((e) => e.id).toList(), expectedGems);
    });

    test('the herb table is every herb, in herbalism-level order', () {
      expect(herbDropTable.map((e) => e.id).toList(), expectedHerbs);
    });

    test('no table lists an item twice', () {
      for (final entry in tables.entries) {
        final ids = entry.value.map((e) => e.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: '${entry.key} lists an item twice',
        );
      }
    });

    test('weights descend, so the ladder cannot be scrambled', () {
      for (final entry in tables.entries) {
        final weights = entry.value.map((e) => e.weight).toList();
        for (var i = 1; i < weights.length; i++) {
          expect(
            weights[i],
            lessThan(weights[i - 1]),
            reason:
                '${entry.key}: ${entry.value[i].id} is not rarer than '
                '${entry.value[i - 1].id}',
          );
        }
      }
    });

    test('every entry yields exactly one item per roll', () {
      for (final entry in tables.entries) {
        for (final e in entry.value) {
          expect(e.count, 1, reason: '${entry.key}: ${e.id} drops ${e.count}');
          expect(e.highCount, 0, reason: '${entry.key}: ${e.id} has a range');
          // unlockLevel is unenforced in entity drop rolls, so a nonzero one
          // here would silently do nothing — see the library doc
          expect(
            e.unlockLevel,
            0,
            reason: '${entry.key}: ${e.id} is level-gated',
          );
        }
      }
    });
  });

  group('rolling', () {
    test('a roll only ever produces a member of its table', () {
      final service = WeightedDropTableService();
      for (final entry in tables.entries) {
        final members = entry.value.map((e) => e.id).toSet();
        final rng = Random(7);
        for (var i = 0; i < 500; i++) {
          final stack = service.roll(entry.value, rng: rng);
          expect(
            members,
            contains(stack.id),
            reason: '${entry.key} rolled ${stack.id}, which is not in it',
          );
          expect(stack.count, 1);
        }
      }
    });

    test('a batch hands out exactly the rolls it was asked for', () {
      final service = WeightedDropTableService();
      for (final entry in tables.entries) {
        final stacks = service.rollMulitpleTimes(
          1000,
          entry.value,
          rng: Random(7),
        );
        final total = stacks.fold<int>(0, (sum, s) => sum + s.count);
        expect(total, 1000, reason: '${entry.key} lost or invented rolls');
      }
    });

    test('the heaviest entry is the one that comes up most', () {
      final service = WeightedDropTableService();
      for (final entry in tables.entries) {
        final stacks = service.rollMulitpleTimes(
          1000,
          entry.value,
          rng: Random(7),
        );
        stacks.sort((a, b) => b.count.compareTo(a.count));
        expect(
          stacks.first.id,
          entry.value.first.id,
          reason: '${entry.key}: ${stacks.first.id} beat its heaviest entry',
        );
      }
    });
  });

  group('the const contract', () {
    test('a table splices into another const table', () {
      expect(splicedIntoAConstTable.length, gemDropTable.length + 1);
      expect(splicedIntoAConstTable.last.id, ItemId.COPPER_ORE);
      expect(splicedIntoAConstTable.first.id, gemDropTable.first.id);
    });

    test('a table drops straight into a const DropRoll', () {
      const roll = DropRoll(chance: 0.02, entries: herbDropTable);
      expect(roll.entries, same(herbDropTable));
      expect(roll.chance, 0.02);
    });
  });
}
