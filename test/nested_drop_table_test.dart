import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// A drop table line can be a reference to another table.
///
/// Landing on it yields exactly one pick from that table, and the reference
/// may stamp a quality on whatever comes out — which is what lets one shared
/// table serve all five rarity variants of a monster instead of each variant
/// hand-writing the same lines at its own rarity.
///
/// It is resolved by flattening, in `WeightedDrops.flattened`: a reference of
/// weight `W` over children summing to `C` becomes those children at
/// `W * c / C`. Those add back up to `W`, so the parent table's total never
/// moves and a leaf's odds come out at the product of the chain — the same
/// distribution as rolling twice, which is why nothing in the roller had to
/// learn about nesting.
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

  // The shape from the goblin: a heavy fish nest, two even gear nests and a
  // plain coin line, so flattening has one of every kind to do.
  const goblinShaped = <ItemDropType>[
    NestedDrop(cookedFishDropTable, weight: 2),
    NestedDrop(ironToolsDropTable, weight: 1),
    NestedDrop(ironMinorArmorDropTable, weight: 1),
    ItemDropType(id: ItemId.COINS, lowCount: 1, highCount: 5, weight: 1),
  ];

  // A nested table has to survive const evaluation, or it cannot go into a
  // catalog definition at all — that is the constraint the whole design was
  // built around. This one failing is a compile error, not a test failure.
  const inAConstDefinition = EncounterEntityDefinition(
    name: 'Test',
    iconAsset: 'assets/icons/items/coins.png',
    entityType: SkillId.ATTACK,
    defence: 1,
    hitpoints: 1,
    itemDrops: goblinShaped,
  );

  double totalWeight(List<ItemDropType> table) =>
      table.fold<double>(0, (sum, e) => sum + e.weight);

  double chanceOf(List<ItemDropType> flat, ItemId id) => flat
      .where((e) => e.id == id)
      .fold<double>(0, (sum, e) => sum + e.weight / totalWeight(flat));

  group('flattening', () {
    test('a table with no reference in it is handed straight back', () {
      expect(gemDropTable.flattened, same(gemDropTable));
    });

    test('a reference is replaced by the leaves it stands for', () {
      final flat = goblinShaped.flattened;

      expect(flat.whereType<NestedDrop>(), isEmpty);
      // read off the tables rather than pinned to them: what this is about
      // is that each reference expands, in place, into exactly its own
      // contents - not what the content happens to be this week
      expect(flat.map((e) => e.id), [
        ...cookedFishDropTable.map((e) => e.id),
        ...ironToolsDropTable.map((e) => e.id),
        ...ironMinorArmorDropTable.map((e) => e.id),
        ItemId.COINS,
      ]);
    });

    test(
      'the table total is untouched, so the plain lines keep their odds',
      () {
        expect(totalWeight(goblinShaped.flattened), closeTo(5, 1e-12));
        // the coin line still holds exactly the fifth it was written as
        expect(
          chanceOf(goblinShaped.flattened, ItemId.COINS),
          closeTo(0.2, 1e-12),
        );
      },
    );

    test('a leaf gets the product of the chain', () {
      final flat = goblinShaped.flattened;
      // the reference's share of its table, times the leaf's share of the
      // one it points at. Both halves are computed, so retuning a shared
      // table moves the expectation with it
      expect(
        chanceOf(flat, cookedFishDropTable.first.id),
        closeTo(2 / 5 * 1 / cookedFishDropTable.length, 1e-12),
      );
      expect(
        chanceOf(flat, ironToolsDropTable.first.id),
        closeTo(1 / 5 * 1 / ironToolsDropTable.length, 1e-12),
      );
      expect(
        chanceOf(flat, ironMinorArmorDropTable.first.id),
        closeTo(1 / 5 * 1 / ironMinorArmorDropTable.length, 1e-12),
      );
    });

    test('a stack range rides through untouched', () {
      final coins = goblinShaped.flattened.singleWhere(
        (e) => e.id == ItemId.COINS,
      );
      expect(coins.lowCount, 1);
      expect(coins.highCount, 5);
    });

    test('a nest inside a nest multiplies all the way down', () {
      const inner = <ItemDropType>[
        ItemDropType(id: ItemId.IRON_BOOTS, weight: 1),
        ItemDropType(id: ItemId.IRON_GLOVES, weight: 3),
      ];
      const outer = <ItemDropType>[NestedDrop(inner, weight: 1)];
      const table = <ItemDropType>[
        NestedDrop(outer, weight: 1),
        ItemDropType(id: ItemId.COINS, weight: 1),
      ];

      final flat = table.flattened;
      expect(totalWeight(flat), closeTo(2, 1e-12));
      // half to reach the outer nest, all of which reaches the inner, then
      // a quarter of that
      expect(chanceOf(flat, ItemId.IRON_BOOTS), closeTo(0.125, 1e-12));
      expect(chanceOf(flat, ItemId.IRON_GLOVES), closeTo(0.375, 1e-12));
    });

    test('an empty nested table is skipped, not divided by', () {
      const table = <ItemDropType>[
        NestedDrop([], weight: 3),
        ItemDropType(id: ItemId.COINS, weight: 1),
      ];

      final flat = table.flattened;
      expect(flat.map((e) => e.id), [ItemId.COINS]);
      // the alternative is a 0/0 that reaches the roller as a baffling
      // "weight <= 0"
      expect(flat.every((e) => !e.weight.isNaN), isTrue);
      expect(
        () => WeightedDropTableService().roll(table.weighted),
        returnsNormally,
      );
    });

    test('a table that contains itself is cut off, not followed forever', () {
      // const evaluation makes a cycle a compile error, so this can only be
      // built at runtime — but getScaledDropTable and copyWith both take
      // runtime lists, which is what the depth cap is for
      final cyclic = <ItemDropType>[];
      cyclic.add(NestedDrop(cyclic, weight: 1));

      expect(
        () => cyclic.flattened,
        throwsA(isA<AssertionError>()),
        reason: 'the depth cap should name the problem rather than hang',
      );
    });

    test('a reference survives a copyWith as a reference', () {
      // the inherited copyWith hard-builds an ItemDropType, so without an
      // override this would come back as an ItemId.NULL leaf with the
      // sub-table gone, and nothing would have said so
      const nest = NestedDrop(ironToolsDropTable, weight: 1);
      final copy = nest.copyWith(weight: 4);

      expect(copy, isA<NestedDrop>());
      expect(copy.table, same(ironToolsDropTable));
      expect(copy.weight, 4);
      expect(
        [copy].flattened.map((e) => e.id),
        ironToolsDropTable.map((e) => e.id),
      );

      // and a rarity passed to it becomes the override, outermost-wins
      expect(nest.copyWith(rarity: Rarity.EPIC).rarityOverride, Rarity.EPIC);
    });

    test('two references to different tables are not the same drop', () {
      const a = NestedDrop(ironToolsDropTable, weight: 1);
      const b = NestedDrop(cookedFishDropTable, weight: 1);
      // the inherited == compares id/rarity/count/highCount, all identical
      // here, so without an override of its own every reference would read
      // as every other one
      expect(a == b, isFalse);
      expect(a == const NestedDrop(ironToolsDropTable, weight: 1), isTrue);
    });
  });

  group('the count multiplier', () {
    // a bulk line and a fixed one side by side, so every test here sees
    // both halves of the rule
    const bulk = <ItemDropType>[
      ItemDropType(id: ItemId.COINS, lowCount: 3, highCount: 10, weight: 1),
      ItemDropType(id: ItemId.IRON_DAGGER, weight: 1),
    ];

    test('scales a leaf that declares a range', () {
      const table = <ItemDropType>[
        NestedDrop(bulk, weight: 1, countMultiplier: 10),
      ];

      final coins = table.flattened.singleWhere((e) => e.id == ItemId.COINS);
      expect(coins.lowCount, 30);
      expect(coins.highCount, 100);
    });

    test('passes over a leaf with a fixed count', () {
      const table = <ItemDropType>[
        NestedDrop(bulk, weight: 1, countMultiplier: 10),
      ];

      // one dagger is the drop; ten daggers would be a different drop, not
      // a bigger one
      final dagger = table.flattened.singleWhere(
        (e) => e.id == ItemId.IRON_DAGGER,
      );
      expect(dagger.lowCount, 1);
      expect(dagger.highCount, 0);
    });

    test('an unset multiplier leaves the counts as written', () {
      const table = <ItemDropType>[NestedDrop(bulk, weight: 1)];

      final coins = table.flattened.singleWhere((e) => e.id == ItemId.COINS);
      expect(coins.lowCount, 3);
      expect(coins.highCount, 10);
      // and the table it points at is left as it was
      expect(bulk.first.lowCount, 3);
      expect(bulk.first.highCount, 10);
    });

    test('it does not disturb the odds', () {
      const table = <ItemDropType>[
        NestedDrop(bulk, weight: 3, countMultiplier: 10),
        ItemDropType(id: ItemId.LOGS, weight: 1),
      ];

      expect(totalWeight(table.flattened), closeTo(4, 1e-12));
      expect(chanceOf(table.flattened, ItemId.COINS), closeTo(0.375, 1e-12));
    });

    test('nested multipliers compound, unlike the rarity override', () {
      const inner = <ItemDropType>[
        NestedDrop(bulk, weight: 1, countMultiplier: 3),
      ];
      const table = <ItemDropType>[
        NestedDrop(inner, weight: 1, countMultiplier: 2),
      ];

      // a scalar multiplies where a category would have to pick a winner
      final coins = table.flattened.singleWhere((e) => e.id == ItemId.COINS);
      expect(coins.lowCount, 18);
      expect(coins.highCount, 60);
    });

    test('it rides alongside a rarity override', () {
      const table = <ItemDropType>[
        NestedDrop(bulk, weight: 1, rarity: Rarity.EPIC, countMultiplier: 4),
      ];

      final flat = table.flattened;
      expect(flat.map((e) => e.rarity), everyElement(Rarity.EPIC));
      expect(flat.singleWhere((e) => e.id == ItemId.COINS).highCount, 40);
    });

    test('a multiplier of zero is refused rather than dropping nothing', () {
      expect(() => NestedDrop(bulk, countMultiplier: 0), throwsA(anything));
    });

    test('a copyWith carries it', () {
      const nest = NestedDrop(bulk, weight: 1, countMultiplier: 7);
      expect(nest.copyWith(weight: 2).countMultiplier, 7);
      expect(nest.copyWith(countMultiplier: 2).countMultiplier, 2);
      // and two references differing only by it are not the same drop
      expect(
        nest == const NestedDrop(bulk, weight: 1, countMultiplier: 3),
        isFalse,
      );
    });

    test('the roll pays the scaled stack', () {
      const table = <ItemDropType>[
        NestedDrop(bulk, weight: 1, countMultiplier: 10),
      ];
      final service = WeightedDropTableService();
      final rng = Random(4);

      var sawCoins = false;
      for (var i = 0; i < 400; i++) {
        final rolled = service.roll(table.weighted, rng: rng);
        if (rolled.id.id != ItemId.COINS) continue;
        sawCoins = true;
        expect(rolled.count, inInclusiveRange(30, 100));
      }
      expect(sawCoins, isTrue, reason: 'the coin line never landed');
    });
  });

  group('the rarity override', () {
    test('stamps every leaf the reference reaches', () {
      const table = <ItemDropType>[
        NestedDrop(ironToolsDropTable, weight: 1, rarity: Rarity.RARE),
      ];

      expect(
        table.flattened.map((e) => e.rarity),
        everyElement(Rarity.RARE),
        reason: 'the shared table itself is written at COMMON',
      );
      // and the table it points at is left as it was
      expect(
        ironToolsDropTable.map((e) => e.rarity),
        everyElement(Rarity.COMMON),
      );
    });

    test('an unstamped reference leaves the leaves alone', () {
      const table = <ItemDropType>[NestedDrop(ironToolsDropTable, weight: 1)];
      expect(table.flattened.map((e) => e.rarity), everyElement(Rarity.COMMON));
    });

    test('the outermost reference has the last word', () {
      const inner = <ItemDropType>[
        ItemDropType(id: ItemId.IRON_DAGGER, rarity: Rarity.UNCOMMON),
      ];
      const outer = <ItemDropType>[
        NestedDrop(inner, weight: 1, rarity: Rarity.EPIC),
      ];
      const table = <ItemDropType>[
        NestedDrop(outer, weight: 1, rarity: Rarity.LEGENDARY),
      ];

      expect(table.flattened.single.rarity, Rarity.LEGENDARY);
    });

    test('reaches the equipment instance a roll pays out', () {
      final session = buildSession();
      final save = session.saveGameData;
      for (final skill in [
        SkillId.ATTACK,
        SkillId.STRENGTH,
        SkillId.DEFENCE,
        SkillId.HITPOINTS,
      ]) {
        final data = save.playerData.skillData[skill]!;
        data.xp = data.xpTable[data.xpTable.length - 1];
      }

      final goblin = EntityId.GOBLIN_RARE.build() as CombatEntity;
      goblin.count = 100000;
      session.encounterService.setEncounterEntity(save.encounterData, goblin);

      final rng = Random(5);
      for (var i = 0; i < 2000; i++) {
        session.encounterSystem.executePlayerAction(
          playerState: save.playerData,
          encounter: save.encounterData,
          worldState: save.worldData,
          playerInventory: save.inventoryData,
          instantRespawn: true,
          rng: rng,
        );
      }

      final gear = save.inventoryData.equipment;
      expect(gear, isNotEmpty, reason: 'the gear nests never landed');
      expect(
        gear.map((piece) => piece.quality),
        everyElement(Rarity.RARE),
        reason: 'the override never reached the instance',
      );
      // and the fish, which take no stamp, arrived as ordinary stacks
      expect(
        save.inventoryData.itemMap[ItemId.COOKED_CARP],
        greaterThan(0),
        reason: 'the unstamped nest never landed',
      );

      session.dispose();
    });
  });

  group('the roller needed no changes', () {
    // the same table rolled the long way: pick a line, then pick inside it
    // when that line turned out to be a reference
    ItemId rollTwoStage(
      WeightedDropTableService service,
      List<ItemDropType> table,
      Random rng,
    ) {
      final line = service.roll([
        for (final e in table)
          WeightedDropTableEntry<ItemDropType>(id: e, weight: e.weight),
      ], rng: rng).id;
      return line is NestedDrop
          ? rollTwoStage(service, line.table, rng)
          : line.id;
    }

    test('flattening samples the same distribution as rolling twice', () {
      final service = WeightedDropTableService();
      const rolls = 40000;
      final flatCounts = <ItemId, int>{};
      final stageCounts = <ItemId, int>{};

      final flatRng = Random(17);
      final stageRng = Random(23);
      for (var i = 0; i < rolls; i++) {
        final flat = service.roll(goblinShaped.weighted, rng: flatRng).id.id;
        flatCounts.update(flat, (n) => n + 1, ifAbsent: () => 1);
        final staged = rollTwoStage(service, goblinShaped, stageRng);
        stageCounts.update(staged, (n) => n + 1, ifAbsent: () => 1);
      }

      // both land on the analytic odds, which is the actual claim — the two
      // runs draw independently, so they only agree to sampling error
      final expected = {
        cookedFishDropTable.first.id: 2 / 5 / cookedFishDropTable.length,
        ironToolsDropTable.first.id: 1 / 5 / ironToolsDropTable.length,
        ironMinorArmorDropTable.first.id:
            1 / 5 / ironMinorArmorDropTable.length,
        ItemId.COINS: 0.2,
      };
      for (final entry in expected.entries) {
        expect(
          (flatCounts[entry.key] ?? 0) / rolls,
          closeTo(entry.value, 0.01),
          reason: 'flattened: ${entry.key.name}',
        );
        expect(
          (stageCounts[entry.key] ?? 0) / rolls,
          closeTo(entry.value, 0.01),
          reason: 'two-stage: ${entry.key.name}',
        );
      }
    });

    test('the batch allocator still hands out exactly what it was asked', () {
      // no stack ranges anywhere, so one pick is one item and the picks can
      // simply be counted
      const nested = <ItemDropType>[
        NestedDrop([
          NestedDrop(ironToolsDropTable, weight: 3),
          NestedDrop(cookedFishDropTable, weight: 1),
        ], weight: 3),
        NestedDrop(gemDropTable, weight: 1),
        ItemDropType(id: ItemId.LOGS, weight: 1),
      ];

      final rolled = WeightedDropTableService().rollMulitpleTimes(
        1000,
        nested.weighted,
        rng: Random(9),
      );

      expect(rolled.fold<int>(0, (sum, s) => sum + s.count), 1000);
      expect(rolled.map((s) => s.id).whereType<NestedDrop>(), isEmpty);
    });

    test('a definition hands the roller leaves, never a reference', () {
      expect(
        inAConstDefinition.weightedDropTable.map((e) => e.id),
        isNot(contains(isA<NestedDrop>())),
      );
      expect(
        inAConstDefinition.weightedDropTable.fold<double>(
          0,
          (sum, e) => sum + e.weight,
        ),
        closeTo(5, 1e-12),
      );
    });
  });

  group('what the player is shown', () {
    test('the goblin reads as nine flat rows adding to one', () {
      final session = buildSession();
      final details = session.worldController.entityDetails(
        EntityId.GOBLIN.build() as EncounterEntity,
      );
      final main = details.drops.where((d) => !d.bonus).toList();

      // one row per reachable item and not one per table line: the nesting
      // is invisible to the player
      final reachable =
          cookedFishDropTable.length +
          ironToolsDropTable.length +
          ironMinorArmorDropTable.length +
          1;
      expect(
        main,
        hasLength(reachable),
        reason: 'a nested table leaked into the UI',
      );
      expect(
        main.fold<double>(0, (sum, d) => sum + d.chance),
        closeTo(1.0, 1e-9),
      );

      double chanceFor(ItemId id) =>
          main.singleWhere((d) => d.itemId == id).chance;
      expect(
        chanceFor(cookedFishDropTable.first.id),
        closeTo(2 / 5 / cookedFishDropTable.length, 1e-9),
      );
      expect(
        chanceFor(ironToolsDropTable.first.id),
        closeTo(1 / 5 / ironToolsDropTable.length, 1e-9),
      );
      expect(chanceFor(ItemId.COINS), closeTo(0.2, 1e-9));

      // the reference's placeholder id never reaches a row
      expect(details.drops.map((d) => d.itemId), isNot(contains(ItemId.NULL)));

      session.dispose();
    });

    test('a rarity variant labels the gear rows it stamped', () {
      final session = buildSession();
      final details = session.worldController.entityDetails(
        EntityId.GOBLIN_LEGENDARY.build() as EncounterEntity,
      );

      expect(
        details.drops
            .singleWhere((d) => d.itemId == ironToolsDropTable.first.id)
            .rarity,
        Rarity.LEGENDARY,
      );
      // fish are not equipment, so the nest holding them takes no stamp
      expect(
        details.drops
            .singleWhere((d) => d.itemId == cookedFishDropTable.first.id)
            .rarity,
        Rarity.COMMON,
      );

      session.dispose();
    });

    test('one item on two lines of a table reads as a single row', () {
      // the Lake lists whitefish twice, at weight 1 and weight .25 of a
      // 1.75 total. Two rows saying 57% and 14% is a worse answer than one
      // saying 71%, and flattening makes the same thing happen whenever two
      // nested tables can pay the same item
      final session = buildSession();
      final details = session.worldController.entityDetails(
        EntityId.LAKE.build() as EncounterEntity,
      );

      expect(details.drops, hasLength(2));
      final whitefish = details.drops.singleWhere(
        (d) => d.itemId == ItemId.WHITEFISH,
      );
      expect(whitefish.chance, closeTo(1.25 / 1.75, 1e-9));
      expect(
        details.drops.fold<double>(0, (sum, d) => sum + d.chance),
        closeTo(1.0, 1e-9),
      );

      session.dispose();
    });
  });
}
