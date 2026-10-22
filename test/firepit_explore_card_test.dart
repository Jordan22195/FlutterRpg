import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/explore_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/countdown_timer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/place_tile.dart';
import 'package:rpg/widgets/icon_renderer.dart';

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
          // the status row over the art reads the encounter for its
          // damage numbers
          ChangeNotifierProvider<EncounterController>.value(
            value: session.encounterController,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ExploreScreen())),
      ),
    );
    await settle(tester);

    return session;
  }

  /// The skill sprites on the firepit's tile, in order.
  /// The skill sprites on the line under the firepit's name — the skills it
  /// trains, not the stats its fire's chips show.
  List<SkillId?> skillSprites(WidgetTester tester) => tester
      .widgetList<IconRenderer<SkillId>>(
        find.descendant(
          of: find.descendant(
            of: find.byKey(const ValueKey(EntityId.FIREPIT)),
            matching: find.byType(PlaceLine),
          ),
          matching: find.byWidgetPredicate((w) => w is IconRenderer<SkillId>),
        ),
      )
      .map((w) => w.id)
      .toList();

  testWidgets('a cold firepit advertises firemaking only', (tester) async {
    final session = await pumpExplore(tester);

    expect(find.text('Firepit'), findsOneWidget);
    expect(skillSprites(tester), [SkillId.FIREMAKING]);
    expect(find.byType(CountdownTimer), findsNothing);

    session.dispose();
  });

  testWidgets('a lit cookfire advertises cooking too', (tester) async {
    final session = await pumpExplore(tester, lightRecipeId: 'cookfire');

    // the card becomes the fire, and shows both skills it now trains
    expect(find.text('Cookfire'), findsOneWidget);
    expect(find.text('Firepit'), findsNothing);
    expect(skillSprites(tester), [SkillId.FIREMAKING, SkillId.COOKING]);
    expect(find.byType(CountdownTimer), findsOneWidget);

    session.dispose();
  });

  testWidgets('a campfire burns without advertising cooking', (tester) async {
    final session = await pumpExplore(tester, lightRecipeId: 'basic_campfire');

    expect(find.text('Campfire'), findsOneWidget);
    expect(skillSprites(tester), [SkillId.FIREMAKING]);
    expect(find.byType(CountdownTimer), findsOneWidget);

    session.dispose();
  });

  group('a lit fire wears what it gives', () {
    final stats = find.byKey(const ValueKey('place-tile-fire-stats'));
    Finder chipFor(SkillId skill) => find.descendant(
      of: stats,
      matching: find.byWidgetPredicate(
        (w) => w is BuffBadge && w.skill == skill,
      ),
    );

    testWidgets('a cookfire: cooking and hitpoints, on the fire\'s tile', (
      tester,
    ) async {
      final session = await pumpExplore(tester, lightRecipeId: 'cookfire');

      expect(stats, findsOneWidget);
      expect(
        find.ancestor(
          of: stats,
          matching: find.byKey(const ValueKey(EntityId.FIREPIT)),
        ),
        findsOneWidget,
      );
      expect(chipFor(SkillId.COOKING), findsOneWidget);
      expect(chipFor(SkillId.HITPOINTS), findsOneWidget);
      // top-left of the tile, opposite the burn time
      final tile = tester.getRect(find.byKey(const ValueKey(EntityId.FIREPIT)));
      expect(tester.getCenter(stats).dx, lessThan(tile.center.dx));
      expect(
        tester.getCenter(stats).dx,
        lessThan(tester.getCenter(find.byType(CountdownTimer)).dx),
      );

      session.dispose();
    });

    testWidgets('a campfire: stamina and recovery', (tester) async {
      final session = await pumpExplore(
        tester,
        lightRecipeId: 'basic_campfire',
      );
      expect(chipFor(SkillId.STAMINA), findsOneWidget);
      expect(chipFor(SkillId.RECOVERY), findsOneWidget);
      session.dispose();
    });

    testWidgets('a cold firepit wears none', (tester) async {
      final session = await pumpExplore(tester);
      expect(stats, findsNothing);
      session.dispose();
    });
  });
}
