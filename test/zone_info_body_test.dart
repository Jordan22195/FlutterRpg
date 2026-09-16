import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/zone_details.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/zone_info_body.dart';

// Boots a real session and renders the actual ZoneInfoBody through the
// provider tree, so the numbers on screen come from the live exploration
// math rather than a fixture.
//
// Which monsters and items a zone holds is tuning, and it has moved before:
// every roster claim below is read off the catalog or off the details the
// widget itself renders from. What is pinned is the *rendering* — that a
// locked row shows its unlock level and no odds, that an unlocked one shows
// its share, that a find row carries its count range and no xp.
void main() {
  Future<GameSession> pumpZoneDetail(
    WidgetTester tester, {
    required int explorationLevel,
    ZoneId zoneId = ZoneId.TUTORIAL_FARM,
  }) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    // icon resolvers so IconRenderer doesn't throw
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    final skill = save.playerData.skillData[SkillId.EXPLORATION]!;
    skill.xp = skill.xpTable[explorationLevel];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorldController>.value(
            value: session.worldController,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [ZoneInfoBody(zoneId: zoneId)],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return session;
  }

  /// Whole numbers render without their ".0", the way the widget writes them.
  String trim(double value) {
    final rounded = value.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }

  String odds(ZoneDiscovery d) =>
      '${(d.chance * 100).toStringAsFixed(d.chance < 0.01 ? 2 : 1)}%';

  /// The row's title: a find that rolls a stack carries its range inline,
  /// as "Coins  5-50". Locked or not — the range is part of the name.
  String label(ZoneDiscovery d) =>
      d.hasCountRange ? '${d.name}  ${d.minCount}-${d.maxCount}' : d.name;

  ZoneDetails detailsOf(GameSession session, ZoneId zoneId) =>
      session.explorationSystem.buildZoneDetails(
        session.saveGameData.playerData,
        zoneId,
      );

  testWidgets('zone detail shows finds per explore, odds and locked rows', (
    tester,
  ) async {
    final session = await pumpZoneDetail(tester, explorationLevel: 1);
    final details = detailsOf(session, ZoneId.TUTORIAL_FARM);

    // at the zone's own level an explore turns up exactly one thing
    expect(find.text('1.00'), findsOneWidget);
    expect(find.text('finds per explore'), findsOneWidget);

    expect(find.text('Zone difficulty'), findsOneWidget);
    expect(find.text('Exploration 1'), findsOneWidget);
    // the xp pool is a tuning number, so read it off the catalog — the claim
    // is that the row shows the zone's pool, not that the pool is any value
    final pool = trim(ZoneId.TUTORIAL_FARM.definition.xpPerExplore.toDouble());
    expect(find.text('$pool per explore'), findsOneWidget);

    // the baseline nodes are live, each showing its share of the table and
    // the xp that share is worth. The meadow's baseline is evenly weighted,
    // so they all read the same number — assert that rather than the number
    final unlocked = details.entities.where((d) => !d.locked).toList();
    expect(unlocked, isNotEmpty);
    final shares = unlocked.map(odds).toSet();
    expect(shares, hasLength(1), reason: 'the meadow baseline is not uniform');
    expect(find.text(shares.single), findsNWidgets(unlocked.length));
    expect(find.text('$pool xp'), findsNWidgets(unlocked.length));
    for (final d in unlocked) {
      expect(find.text(d.name), findsWidgets, reason: '${d.name} is missing');
    }

    // the rares are visible but locked: named, tagged with the level that
    // opens them, and showing no odds at all
    final locked = details.entities.where((d) => d.locked).toList();
    expect(locked, isNotEmpty, reason: 'the meadow gates nothing');
    for (final d in locked) {
      expect(find.text(d.name), findsWidgets);
      expect(find.text('Exploration ${d.unlockLevel}'), findsWidgets);
      expect(d.chance, 0);
    }
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(locked.length));

    // and the summary counts them
    expect(
      find.text(
        '${details.lockedCount} '
        '${details.lockedCount == 1 ? 'discovery' : 'discoveries'}',
      ),
      findsOneWidget,
    );

    session.dispose();
  });

  testWidgets('outlevelling the zone raises finds and clears the locks', (
    tester,
  ) async {
    final session = await pumpZoneDetail(tester, explorationLevel: 21);
    final details = detailsOf(session, ZoneId.TUTORIAL_FARM);

    // 1 + (21 - 1) / 10 = 3.00
    expect(find.text('3.00'), findsOneWidget);
    expect(find.text('21  (+20)'), findsOneWidget);

    // nothing is hidden any more, so no lock rows and no "still hidden"
    expect(details.lockedCount, 0);
    expect(find.text('Still hidden'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);

    // what was gated is now rolling at its real odds rather than greyed out
    final wasGated = ZoneId.TUTORIAL_FARM.definition.discoverableEntities
        .where((e) => e.unlockLevel > 1)
        .map((e) => e.id.definition.name)
        .toSet();
    expect(wasGated, isNotEmpty);
    for (final name in wasGated) {
      final row = details.entities.firstWhere((d) => d.name == name);
      expect(row.locked, isFalse);
      expect(row.chance, greaterThan(0));
      expect(find.text(name), findsWidgets);
      expect(find.text(odds(row)), findsWidgets);
    }

    session.dispose();
  });

  // The item table is a second card with its own rules: a find pays loot but
  // no exploration xp, and it can carry a stack range the entity rows never
  // do. The meadow has no item table at all, so this is read off a zone the
  // catalog actually gives one to.
  group('the finds table', () {
    /// A zone whose item table holds something other than the NULL filler,
    /// and the lowest level that opens one of its finds.
    (ZoneId, WeightedDropTableEntry<ItemId>)? zoneWithItemFinds() {
      for (final zone in ZoneId.values) {
        final real = zone.definition.discoverableItems
            .where((e) => e.id != ItemId.NULL)
            .toList();
        if (real.isEmpty) continue;
        real.sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));
        return (zone, real.first);
      }
      return null;
    }

    testWidgets('a gated find is listed, locked, with the level that opens it', (
      tester,
    ) async {
      final found = zoneWithItemFinds();
      expect(found, isNotNull, reason: 'no zone has an item table any more');
      final (zone, entry) = found!;
      expect(
        entry.unlockLevel,
        greaterThan(1),
        reason: 'expected the first find to be gated',
      );

      final session = await pumpZoneDetail(
        tester,
        explorationLevel: 1,
        zoneId: zone,
      );
      final details = detailsOf(session, zone);
      expect(details.items, isNotEmpty);

      await tester.scrollUntilVisible(find.text('FINDS'), 120);
      for (final d in details.items) {
        expect(d.locked, isTrue);
        expect(find.text(label(d)), findsWidgets);
        expect(find.text('Exploration ${d.unlockLevel}'), findsWidgets);
        // a locked row shows no odds, only the level that opens it
        expect(d.chance, 0);
      }

      session.dispose();
    });

    testWidgets('an open find shows its stack range and odds, but no xp', (
      tester,
    ) async {
      final (zone, entry) = zoneWithItemFinds()!;
      final session = await pumpZoneDetail(
        tester,
        explorationLevel: entry.unlockLevel,
        zoneId: zone,
      );
      final details = detailsOf(session, zone);

      final open = details.items.where((d) => !d.locked).toList();
      expect(open, isNotEmpty, reason: 'the find did not open at its level');

      await tester.scrollUntilVisible(find.text('FINDS'), 120);
      for (final d in open) {
        await tester.scrollUntilVisible(find.text(label(d)), 120);
        expect(find.text(label(d)), findsOneWidget);
        expect(find.text(odds(d)), findsWidgets);
        // finds pay loot, not exploration xp, so the xp column is left out
        expect(d.xp, 0);
        expect(find.text('${trim(d.xp)} xp'), findsNothing);
      }

      session.dispose();
    });
  });
}
