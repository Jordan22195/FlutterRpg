import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/zone_info_body.dart';

// Boots a real session and renders the actual ZoneInfoBody through the
// provider tree, so the numbers on screen come from the live exploration
// math rather than a fixture.
void main() {
  Future<GameSession> pumpZoneDetail(
    WidgetTester tester, {
    required int explorationLevel,
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
              children: const [ZoneInfoBody(zoneId: ZoneId.TUTORIAL_FARM)],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return session;
  }

  testWidgets('zone detail shows finds per explore, odds and locked rows', (
    tester,
  ) async {
    final session = await pumpZoneDetail(tester, explorationLevel: 1);

    // at the zone's own level an explore turns up exactly one thing
    expect(find.text('1.00'), findsOneWidget);
    expect(find.text('finds per explore'), findsOneWidget);

    expect(find.text('Zone difficulty'), findsOneWidget);
    expect(find.text('Exploration 1'), findsOneWidget);
    // the xp pool is a tuning number, so read it off the catalog — the claim
    // is that the row shows the zone's pool, not that the pool is any value.
    // Whole numbers render without their ".0", same as the widget does.
    final raw = ZoneId.TUTORIAL_FARM.definition.xpPerExplore.toStringAsFixed(1);
    final pool = raw.endsWith('.0')
        ? raw.substring(0, raw.length - 2)
        : raw;
    expect(find.text('$pool per explore'), findsOneWidget);

    // the four baseline nodes are live and split the table evenly
    expect(find.text('Tree'), findsOneWidget);
    expect(find.text('Cow'), findsOneWidget);
    expect(find.text('25.0%'), findsNWidgets(4));
    expect(find.text('$pool xp'), findsNWidgets(4));

    // the rares are visible but locked, with the level that opens them.
    // The scarecrow ships as two variants sharing one display name, so count
    // the rows the catalog actually puts in this zone rather than assuming one.
    expect(find.text('Big Red'), findsOneWidget);
    expect(find.text('Exploration 4'), findsOneWidget);
    final details = session.explorationSystem.buildZoneDetails(
      session.saveGameData.playerData,
      ZoneId.TUTORIAL_FARM,
    );
    final scarecrows = details.entities
        .where((d) => d.name == 'Rotwood Scarecrow')
        .toList();
    expect(scarecrows, isNotEmpty);
    expect(
      find.text('Rotwood Scarecrow'),
      findsNWidgets(scarecrows.length),
    );
    for (final s in scarecrows) {
      expect(find.text('Exploration ${s.unlockLevel}'), findsWidgets);
    }

    // how many things the zone still hides depends on its tables, so ask the
    // system for the count the widget is rendering
    final locked = details.lockedCount;
    expect(locked, greaterThan(0));
    expect(
      find.text('$locked ${locked == 1 ? 'discovery' : 'discoveries'}'),
      findsOneWidget,
    );

    // the item table's gated finds are listed the same way, further down
    await tester.scrollUntilVisible(find.text('Sapphire'), 120);
    expect(find.text('Coins  1-10'), findsOneWidget);
    expect(find.text('Exploration 3'), findsOneWidget);
    expect(find.text('Exploration 6'), findsOneWidget);

    session.dispose();
  });

  testWidgets('outlevelling the zone raises finds and clears the locks', (
    tester,
  ) async {
    final session = await pumpZoneDetail(tester, explorationLevel: 21);

    // 1 + (21 - 1) / 10 = 3.00
    expect(find.text('3.00'), findsOneWidget);
    expect(find.text('21  (+20)'), findsOneWidget);

    // nothing is hidden any more, so no lock rows and no "still hidden"
    expect(find.text('Still hidden'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);

    // Big Red is now rolling at its real odds rather than greyed out. The
    // odds follow the zone's discovery table, so derive them the way the
    // widget does rather than pinning a percentage that any table edit moves.
    expect(find.text('Big Red'), findsOneWidget);
    final details = session.explorationSystem.buildZoneDetails(
      session.saveGameData.playerData,
      ZoneId.TUTORIAL_FARM,
    );
    final bigRed = details.entities.firstWhere((d) => d.name == 'Big Red');
    expect(bigRed.locked, isFalse);
    expect(bigRed.chance, greaterThan(0));
    final odds =
        '${(bigRed.chance * 100).toStringAsFixed(bigRed.chance < 0.01 ? 2 : 1)}%';
    expect(find.text(odds), findsOneWidget);

    session.dispose();
  });
}
