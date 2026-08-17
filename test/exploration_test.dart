import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/exploration_service.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ExplorationService();

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

  group('xp pool split', () {
    test('expected xp of one explore is exactly the zone pool', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 0.5),
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 0.1),
      ];
      const pool = 20.0;

      final expected = table.fold<double>(
        0,
        (sum, e) =>
            sum +
            service.findChance(e, table) * service.xpForFind(e, table, pool),
      );

      expect(expected, closeTo(pool, 1e-9));
    });

    test('a rarer find is worth proportionally more xp', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COAL, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.ONYX, weight: 0.1),
      ];
      const pool = 10.0;

      final common = service.xpForFind(table.first, table, pool);
      final rare = service.xpForFind(table.last, table, pool);

      // W = 4.1, n = 5: common = 10*4.1/(5*1) = 8.2, rare = 10x that
      expect(common, closeTo(8.2, 1e-9));
      expect(rare, closeTo(82.0, 1e-9));
      expect(rare / common, closeTo(10.0, 1e-9));
    });

    test('a uniform table pays every find the same', () {
      final table = [
        for (final id in [ItemId.LOGS, ItemId.COAL, ItemId.COINS])
          WeightedDropTableEntry<ItemId>(id: id, weight: 1),
      ];
      for (final entry in table) {
        expect(service.xpForFind(entry, table, 12), closeTo(12.0, 1e-9));
      }
    });

    test('an empty table pays nothing', () {
      final orphan = WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1);
      expect(service.xpForFind(orphan, [], 10), 0);
      expect(service.findChance(orphan, []), 0);
    });
  });

  group('findsPerExplore', () {
    test('is 1.00 at parity and climbs linearly without a ceiling', () {
      expect(service.findsPerExplore(5, 5), closeTo(1.00, 1e-9));
      expect(service.findsPerExplore(6, 5), closeTo(1.10, 1e-9));
      expect(service.findsPerExplore(15, 5), closeTo(2.00, 1e-9));
      expect(service.findsPerExplore(60, 5), closeTo(6.50, 1e-9));
      // no cap: a maxed explorer in the starter zone really does get ~11
      expect(service.findsPerExplore(99, 1), closeTo(10.80, 1e-9));
    });

    test('never drops below 1.00 under parity', () {
      expect(service.findsPerExplore(1, 15), closeTo(1.00, 1e-9));
      expect(service.findsPerExplore(0, 99), closeTo(1.00, 1e-9));
    });
  });

  group('rollFindCount', () {
    test('is exactly one at parity, whatever the seed', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(service.rollFindCount(5, 5, rng: Random(seed)), 1);
      }
    });

    test('is exactly two at a whole extra find, whatever the seed', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(service.rollFindCount(15, 5, rng: Random(seed)), 2);
      }
    });

    test('splits either side of a fractional count, averaging to it', () {
      final rng = Random(7);
      var total = 0;
      const rolls = 20000;
      for (var i = 0; i < rolls; i++) {
        final count = service.rollFindCount(10, 5, rng: rng);
        expect(count, anyOf(1, 2));
        total += count;
      }
      // 1 + 5/10 = 1.50 expected
      expect(total / rolls, closeTo(1.5, 0.02));
    });
  });

  group('availableAt', () {
    test('admits an entry at exactly its unlock level', () {
      final table = [
        WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1),
        WeightedDropTableEntry<ItemId>(
          id: ItemId.RUBY,
          weight: 1,
          unlockLevel: 8,
        ),
      ];

      expect(WeightedDropTableService.availableAt(table, 7), hasLength(1));
      expect(WeightedDropTableService.availableAt(table, 8), hasLength(2));
      expect(WeightedDropTableService.availableAt(table, 99), hasLength(2));
      // an ungated table passes straight through
      expect(
        WeightedDropTableService.availableAt([table.first], 0),
        hasLength(1),
      );
    });
  });

  group('explore action', () {
    test('a town with nothing to find yields nothing and does not throw', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.playerData.currentZoneId = ZoneId.SOUTH_HAVEN;

      final result = session.explorationSystem.explore(
        playerState: save.playerData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
      );

      expect(result.entities, isEmpty);
      expect(result.xp, 0);
      expect(explorationXp(session), 0);
      expect(
        save.worldData.zones[ZoneId.SOUTH_HAVEN]!.discoveredEntities,
        isEmpty,
      );
      session.dispose();
    });

    test('exploring awards exploration xp', () {
      final session = buildSession();
      final save = session.saveGameData;

      expect(explorationXp(session), 0);
      session.worldController.doExplore(1);

      // the meadow's baseline table is uniform, so every find pays the
      // zone's whole pool
      expect(explorationXp(session), closeTo(8.0, 1e-9));
      session.dispose();
    });

    test('extra finds pay loot but not xp, so xp/hr stays flat', () {
      // the dev forest's discoverable table is uniformly weighted, which
      // makes every find worth exactly its xpPerExplore — no variance to
      // average out, so the two runs can be compared exactly
      const explores = 100;
      const zoneXpPerExplore = 10.0;

      int discoveredCount(GameSession session) => session
          .saveGameData
          .worldData
          .zones[ZoneId.DEV_FOREST]!
          .discoveredEntities
          .whereType<EncounterEntity>()
          .fold<int>(0, (sum, e) => sum + e.count);

      double run(int level, void Function(GameSession) onDone) {
        final session = buildSession();
        final save = session.saveGameData;
        save.playerData.currentZoneId = ZoneId.DEV_FOREST;
        setExplorationLevel(session, level);
        final before = explorationXp(session);

        for (var i = 0; i < explores; i++) {
          session.worldController.doExplore(1);
        }

        final gained = explorationXp(session) - before;
        onDone(session);
        session.dispose();
        return gained;
      }

      var atParityFinds = 0;
      final atParity = run(1, (s) => atParityFinds = discoveredCount(s));

      var masteredFinds = 0;
      final mastered = run(50, (s) => masteredFinds = discoveredCount(s));

      // identical xp at both levels: only the first find of an explore pays
      expect(atParity, closeTo(explores * zoneXpPerExplore, 1e-6));
      expect(mastered, closeTo(explores * zoneXpPerExplore, 1e-6));

      // but the mastered run turned up far more stuff
      expect(masteredFinds, greaterThan(atParityFinds * 3));
    });

    test('a locked discovery stays out of the table until its level', () {
      final session = buildSession();
      final save = session.saveGameData;
      final catalogs = session.catalogBundle;

      // Big Red is gated behind Exploration 4 in the meadow
      setExplorationLevel(session, 1);
      var unlocked = session.explorationService
          .getZoneEntityDropTableEntries(
            save.playerData,
            catalogs.zoneCatalog,
            session.explorationSystem.explorationLevel(save.playerData),
          )
          .map((e) => e.id);
      expect(unlocked, isNot(contains(EntityId.BIG_RED)));

      setExplorationLevel(session, 4);
      unlocked = session.explorationService
          .getZoneEntityDropTableEntries(
            save.playerData,
            catalogs.zoneCatalog,
            session.explorationSystem.explorationLevel(save.playerData),
          )
          .map((e) => e.id);
      expect(unlocked, contains(EntityId.BIG_RED));

      session.dispose();
    });
  });

  group('zone details', () {
    test('lists locked and unlocked discoveries with live odds', () {
      final session = buildSession();
      final save = session.saveGameData;
      setExplorationLevel(session, 1);

      final details = session.explorationSystem.buildZoneDetails(
        save.playerData,
        ZoneId.TUTORIAL_FARM,
      );

      expect(details.zoneLevel, 1);
      expect(details.explorationLevel, 1);
      expect(details.findsPerExplore, closeTo(1.0, 1e-9));

      final bigRed = details.entities.firstWhere((d) => d.name == 'Big Red');
      expect(bigRed.locked, isTrue);
      expect(bigRed.unlockLevel, 4);
      expect(bigRed.chance, 0);

      // the four baseline nodes are unlocked and split the table evenly
      final unlocked = details.entities.where((d) => !d.locked).toList();
      expect(unlocked, hasLength(4));
      for (final d in unlocked) {
        expect(d.chance, closeTo(0.25, 1e-9));
        expect(d.xp, closeTo(8.0, 1e-9));
      }

      // the odds of everything available always add up
      expect(
        unlocked.fold<double>(0, (sum, d) => sum + d.chance),
        closeTo(1.0, 1e-9),
      );

      expect(details.lockedCount, greaterThan(0));
      session.dispose();
    });

    test('outlevelling a zone unlocks its rares and raises find count', () {
      final session = buildSession();
      final save = session.saveGameData;
      setExplorationLevel(session, 21);

      final details = session.explorationSystem.buildZoneDetails(
        save.playerData,
        ZoneId.TUTORIAL_FARM,
      );

      expect(details.levelsAboveZone, 20);
      expect(details.findsPerExplore, closeTo(3.0, 1e-9));
      expect(details.lockedCount, 0);
      expect(details.entities.every((d) => !d.locked), isTrue);
      session.dispose();
    });
  });
}
