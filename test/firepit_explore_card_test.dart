import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/explore_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/countdown_timer.dart';

// The explore list is the only place that tells you a fire can be cooked at,
// so the firepit card has to change with what is burning in it.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<GameSession> pumpExplore(
    WidgetTester tester, {
    String? lightRecipeId,
  }) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final firemaking = save.playerData.skillData[SkillId.FIREMAKING]!;
    firemaking.xp = firemaking.xpTable[40];
    save.inventoryData.itemMap[ItemId.LOGS] = 200;

    if (lightRecipeId != null) {
      save.craftingState.craftingEntityId = EntityId.FIREPIT;
      save.craftingState.activeRecipeId = lightRecipeId;
      session.craftingSystem.craftActiveRecipe(
        save.craftingState,
        save.playerData,
        save.inventoryData,
        save.playerData.buffData,
        save.worldData,
      );
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GameSession>.value(value: session),
          ChangeNotifierProvider<WorldController>.value(
            value: session.worldController,
          ),
          ChangeNotifierProvider<BuffController>.value(
            value: session.buffController,
          ),
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
          ChangeNotifierProvider<ActionTimingController>.value(
            value: session.actionTimingController,
          ),
          ChangeNotifierProvider<ActionQueueController>.value(
            value: session.actionQueueController,
          ),
          ChangeNotifierProvider<PlayerDataController>.value(
            value: session.playerDataController,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ExploreScreen())),
      ),
    );
    await settle(tester);

    // the zone list is tabbed and opens on resources; a firepit is a
    // structure, so every case here starts by opening that tab
    await tester.tap(find.textContaining('Structures'));
    await settle(tester);

    return session;
  }

  testWidgets('a cold firepit advertises firemaking only', (tester) async {
    final session = await pumpExplore(tester);

    expect(find.text('Firepit'), findsOneWidget);
    expect(find.text('Firemaking'), findsOneWidget);
    expect(find.byType(CountdownTimer), findsNothing);

    session.dispose();
  });

  testWidgets('a lit cookfire advertises cooking too', (tester) async {
    final session = await pumpExplore(tester, lightRecipeId: 'cookfire');

    // the card becomes the fire, and says both skills it now trains
    expect(find.text('Cookfire'), findsOneWidget);
    expect(find.text('Firepit'), findsNothing);
    expect(find.text('Firemaking · Cooking'), findsOneWidget);
    expect(find.byType(CountdownTimer), findsOneWidget);

    session.dispose();
  });

  testWidgets('a campfire burns without advertising cooking', (tester) async {
    final session = await pumpExplore(tester, lightRecipeId: 'basic_campfire');

    expect(find.text('Campfire'), findsOneWidget);
    expect(find.text('Firemaking'), findsOneWidget);
    expect(find.text('Firemaking · Cooking'), findsNothing);
    expect(find.byType(CountdownTimer), findsOneWidget);

    session.dispose();
  });
}
