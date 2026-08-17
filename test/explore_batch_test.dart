import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/exploration_service.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

// batching exists so hours of offline progress can be settled in one call
// instead of looping the explore action thousands of times. the contract it
// has to keep is that a batch pays what the loop would have paid.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ExplorationService();
  final dropTable = WeightedDropTableService();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void setExplorationLevel(GameSession session, int level) {
    final skill =
        session.saveGameData.playerData.skillData[SkillId.EXPLORATION]!;
    skill.xp = skill.xpTable[level];
  }

  double explorationXp(GameSession session) =>
      session.saveGameData.playerData.skillData[SkillId.EXPLORATION]!.xp;

  int totalCount<T>(List<dynamic> stacks) =>
      stacks.fold<int>(0, (sum, s) => sum + (s.count as int));

  // everything the dev forest holds after a run, counted by head rather
  // than by stack: a single find can turn up several of a thing
  int discoveredIn(GameSession session) {
    final total = session
        .saveGameData
        .worldData
        .zones[ZoneId.DEV_FOREST]!
        .discoveredEntities
        .whereType<EncounterEntity>()
        .fold<int>(0, (sum, e) => sum + e.count);
    session.dispose();
    return total;
  }

  GameSession loopExplores(int explores, {int level = 1}) {
    final session = buildSession();
    session.saveGameData.playerData.currentZoneId = ZoneId.DEV_FOREST;
    setExplorationLevel(session, level);
    for (var i = 0; i < explores; i++) {
      session.worldController.doExplore(1);
    }
    return session;
  }

  GameSession batchExplores(int explores, {int level = 1}) {
    final session = buildSession();
    session.saveGameData.playerData.currentZoneId = ZoneId.DEV_FOREST;
    setExplorationLevel(session, level);
    session.worldController.doExplore(explores);
    return session;
  }

  group('rollMulitpleTimes', () {
    test('returns exactly one roll\'s worth of results per roll asked', () {
      final table = [
        for (final id in [ItemId.LOGS, ItemId.COAL, ItemId.COINS, ItemId.RUBY])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1),
      ];

      final out = dropTable.rollMulitpleTimes(100, table, rng: Random(7));

      // every entry has a fixed count of 1, so 100 rolls is 100 items
      expect(totalCount(out), 100);
      expect(out.map((s) => s.id), containsAll(table.map((e) => e.id)));

      // a uniform table splits evenly. 100/4 = 25 guaranteed to each, and
      // the allocation is exact here, so there is no remainder to scatter
      for (final stack in out) {
        expect(stack.count, 25);
      }
    });

    test('honours weight, not just membership', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 3),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 1),
      ];

      final out = dropTable.rollMulitpleTimes(1000, table, rng: Random(11));
      final byId = {for (final s in out) s.id: s.count};

      expect(totalCount(out), 1000);
      expect(byId[ItemId.LOGS], closeTo(750, 25));
      expect(byId[ItemId.COAL], closeTo(250, 25));
    });

    test('draws a stack size per roll for a variable-count entry', () {
      // count 2..6 — each of the 50 rolls draws its own size, so the total
      // has to land inside 50*2 .. 50*6 and above a flat 50*count
      final table = [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.LOGS,
          weight: 1,
          count: 2,
          highCount: 6,
        ),
      ];

      final out = dropTable.rollMulitpleTimes(50, table, rng: Random(3));

      expect(out, hasLength(1));
      expect(out.single.count, greaterThan(50 * 2));
      expect(out.single.count, lessThanOrEqualTo(50 * 6));
    });

    test('is deterministic for a given seed', () {
      final table = [
        for (final id in [ItemId.LOGS, ItemId.COAL, ItemId.COINS])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1, highCount: 4),
      ];

      Map<ItemId, int> run(int seed) => {
        for (final s in dropTable.rollMulitpleTimes(
          37,
          table,
          rng: Random(seed),
        ))
          s.id: s.count,
      };

      expect(run(5), run(5));
    });

    test('handles degenerate inputs without throwing', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
      ];

      expect(dropTable.rollMulitpleTimes(0, table), isEmpty);
      expect(dropTable.rollMulitpleTimes(-5, table), isEmpty);
      expect(
        dropTable.rollMulitpleTimes<ItemId>(
          10,
          <WeightedDropTableEntry<ItemId>>[],
        ),
        isEmpty,
      );
    });

    test('rejects a non-positive weight, as a single roll does', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 0),
      ];

      expect(
        () => dropTable.rollMulitpleTimes(10, table),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('addItemsToCurrentZone', () {
    // the system filters NULL out before it gets here, so this is the only
    // place the service's own contract is actually exercised
    test('skips the blanks and keeps the finds behind them', () {
      final session = buildSession();
      final save = session.saveGameData;

      final added = session.explorationService.addItemsToCurrentZone(
        [
          ObjectStack<ItemId>(id: ItemId.NULL, count: 5),
          ObjectStack<ItemId>(id: ItemId.COINS, count: 7),
          ObjectStack<ItemId>(id: ItemId.LOGS, count: 0),
          ObjectStack<ItemId>(id: ItemId.SAPPHIRE, count: 2),
        ],
        save.playerData,
        save.worldData,
      );

      // read the zone tally straight off the service: the controller's
      // getter is gated on an explore session being open
      final finds = {
        for (final s in session.explorationService.getCurrentZoneItems(
          save.playerData,
          save.worldData,
        ))
          s.id: s.count,
      };

      expect(added, isTrue);
      // a leading NULL must not swallow the two real stacks behind it
      expect(finds[ItemId.COINS], 7);
      expect(finds[ItemId.SAPPHIRE], 2);
      expect(finds.containsKey(ItemId.NULL), isFalse);
      expect(finds.containsKey(ItemId.LOGS), isFalse);
      session.dispose();
    });

    test('reports nothing added when every stack is a blank', () {
      final session = buildSession();
      final save = session.saveGameData;

      final added = session.explorationService.addItemsToCurrentZone(
        [ObjectStack<ItemId>(id: ItemId.NULL, count: 3)],
        save.playerData,
        save.worldData,
      );

      expect(added, isFalse);
      expect(
        session.explorationService.getCurrentZoneItems(
          save.playerData,
          save.worldData,
        ),
        isEmpty,
      );
      session.dispose();
    });
  });

  group('batched explore', () {
    test('pays the same xp as the same number of single explores', () {
      // the whole point of the batch path: xp/hr must not depend on whether
      // the player was watching. the dev forest's table is uniform, so a
      // single explore pays exactly xpPerExplore with no variance to average
      const explores = 100;
      const zoneXpPerExplore = 10.0;

      final looped = buildSession();
      looped.saveGameData.playerData.currentZoneId = ZoneId.DEV_FOREST;
      for (var i = 0; i < explores; i++) {
        looped.worldController.doExplore(1);
      }
      final loopedXp = explorationXp(looped);
      looped.dispose();

      final batched = buildSession();
      batched.saveGameData.playerData.currentZoneId = ZoneId.DEV_FOREST;
      batched.worldController.doExplore(explores);
      final batchedXp = explorationXp(batched);
      batched.dispose();

      expect(loopedXp, closeTo(explores * zoneXpPerExplore, 1e-6));
      expect(batchedXp, closeTo(loopedXp, 1e-6));
    });

    test('takes the find count from the level, not the explore count', () {
      // at exploration 50 in a level-1 zone the player earns ~5.9 finds an
      // explore. batching must roll the find count, or an outlevelled zone
      // silently pays a fraction of what looping would
      final session = buildSession();
      final save = session.saveGameData;
      save.playerData.currentZoneId = ZoneId.DEV_FOREST;
      setExplorationLevel(session, 50);

      const explores = 20;
      final zone = session.catalogBundle.zoneCatalog.getDefinitionFor(
        ZoneId.DEV_FOREST,
      );
      final expectedFinds =
          (service.findsPerExplore(
                    session.explorationSystem.explorationLevel(save.playerData),
                    zone.explorationLevel,
                  ) *
                  explores)
              .floor();

      final result = session.explorationSystem.explore(
        playerState: save.playerData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
        numTimesToExplore: explores,
      );

      expect(expectedFinds, greaterThan(explores));
      expect(result.findCount, expectedFinds);
      // entities arrive aggregated into one stack per id, and a single roll
      // can yield a stack of several, so the haul is at least one per find
      expect(totalCount(result.entities), greaterThanOrEqualTo(expectedFinds));
      session.dispose();
    });

    test('resolves the whole batch at the level it started from', () {
      // a documented consequence of settling in one pass: 200 explores as a
      // loop earn enough xp to climb from exploration 1 to 13, and the finds
      // per explore climb with them. a batch prices all 200 at level 1, so
      // it pays strictly less - and never levels into its own unlocks
      const explores = 200;

      final looped = loopExplores(explores);
      final loopedLevel = looped.explorationSystem.explorationLevel(
        looped.saveGameData.playerData,
      );
      final loopedFinds = discoveredIn(looped);

      final batched = batchExplores(explores);
      final batchedFinds = discoveredIn(batched);

      expect(
        loopedLevel,
        greaterThan(1),
        reason: 'the loop levels up as it runs',
      );
      expect(loopedFinds, greaterThan(batchedFinds));

      // but the batch still paid a full find per explore at its own level
      expect(batchedFinds, greaterThanOrEqualTo(explores));
    });

    test('discovers as many entities as looping does, outlevelled', () {
      // the regression this pins: rolling numTimesToExplore instead of the
      // find count would make the batch yield ~1/6th of the loop here
      const explores = 200;
      const level = 50;
      final looped = discoveredIn(loopExplores(explores, level: level));
      final batched = discoveredIn(batchExplores(explores, level: level));

      expect(looped, greaterThan(explores * 3));
      expect(batched, closeTo(looped, looped * 0.15));
    });

    test('credits item finds to both the player and the zone tally', () {
      final session = buildSession();
      final save = session.saveGameData;
      final world = session.worldController;

      expect(save.playerData.currentZoneId, ZoneId.TUTORIAL_FARM);
      // coins are gated behind exploration 3. a batch resolves the whole
      // run at the level held when it started, so unlike a 300-explore loop
      // it never levels into its own unlocks part way through
      setExplorationLevel(session, 5);

      world.startExplore();
      world.doExplore(300);

      final finds = world.getCurrentZoneItems();
      expect(
        finds,
        isNotEmpty,
        reason: 'coins should drop within 300 explores',
      );

      // the item table carries a NULL "found nothing" entry. it is the most
      // common outcome by weight, so a batch roll always turns some up — and
      // none of it may reach either inventory
      expect(finds.map((s) => s.id), isNot(contains(ItemId.NULL)));
      expect(save.inventoryData.itemMap.keys, isNot(contains(ItemId.NULL)));

      for (final stack in finds) {
        expect(
          save.inventoryData.itemMap[stack.id],
          stack.count,
          reason: 'player inventory mirrors the explore find list',
        );
      }
      session.dispose();
    });

    test('a zone with nothing to find yields nothing and does not throw', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.playerData.currentZoneId = ZoneId.SOUTH_HAVEN;

      final result = session.explorationSystem.explore(
        playerState: save.playerData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
        numTimesToExplore: 50,
      );

      expect(result.entities, isEmpty);
      expect(result.items, isEmpty);
      expect(result.xp, 0);
      expect(explorationXp(session), 0);
      session.dispose();
    });
  });
}
