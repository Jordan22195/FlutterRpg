import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/zone_detail_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';

// Boots a real session and renders the actual ZoneDetailScreen through the
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
    ItemCatalog.init();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    EnumImageProviderLookup.register<EntityId>(
      session.catalogBundle.entityCatalog.imageProviderFor,
    );

    final skill = save.playerData.skillData[SkillId.EXPLORATION]!;
    skill.xp = skill.xpTable[explorationLevel];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorldController>.value(
            value: session.worldController,
          ),
        ],
        child: const MaterialApp(
          home: ZoneDetailScreen(zoneId: ZoneId.TUTORIAL_FARM),
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

    expect(find.text('Southglen Meadow'), findsOneWidget);

    // at the zone's own level an explore turns up exactly one thing
    expect(find.text('1.00'), findsOneWidget);
    expect(find.text('finds per explore'), findsOneWidget);

    expect(find.text('Zone difficulty'), findsOneWidget);
    expect(find.text('Exploration 1'), findsOneWidget);
    expect(find.text('8 per explore'), findsOneWidget);

    // the four baseline nodes are live and split the table evenly
    expect(find.text('Tree'), findsOneWidget);
    expect(find.text('Cow'), findsOneWidget);
    expect(find.text('25.0%'), findsNWidgets(4));
    expect(find.text('8 xp'), findsNWidgets(4));

    // the rares are visible but locked, with the level that opens them
    expect(find.text('Big Red'), findsOneWidget);
    expect(find.text('Exploration 4'), findsOneWidget);
    expect(find.text('Rotwood Scarecrow'), findsOneWidget);
    expect(find.text('Exploration 8'), findsOneWidget);

    expect(find.text('4 discoveries'), findsOneWidget);

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

    // Big Red is now rolling at its real odds rather than greyed out
    expect(find.text('Big Red'), findsOneWidget);
    expect(find.text('2.4%'), findsOneWidget);

    session.dispose();
  });
}
