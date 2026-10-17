import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/art_header.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/status_row.dart';
import 'package:rpg/widgets/zone_header.dart';

// The explore view leads with the zone's art, 360pt from the top of the
// screen, which collapses into a strip carrying the status row and title as
// the list scrolls. The tabs pin beneath it and the explore timer stays down
// by the button, so neither scrolls out of reach.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<GameSession> pumpExplore(WidgetTester tester) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    // the art is real io, so it loads outside the fake clock — and before
    // the screen mounts, so the header finds it ready rather than starting
    // its own load under the fake clock
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/zones/farm.png'),
        tester.element(find.byType(SizedBox)),
      ),
    );

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    // phone sized, so the list is long enough to scroll
    tester.view.physicalSize = const Size(414, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
    await settle(tester);

    return session;
  }

  // the header's own box: the stack the title sits in fills it
  Size headerSize(WidgetTester tester) => tester.getSize(
    find
        .ancestor(
          of: find.text('Southglen Meadow'),
          matching: find.byType(Stack),
        )
        .first,
  );

  Future<void> scrollToBottom(WidgetTester tester) async {
    // the info tab's discovery tables make the list long enough to collapse
    // the header all the way
    await tester.tap(find.text('Info'));
    await settle(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await settle(tester);
  }

  testWidgets('southglen meadow opens on its square farm art', (tester) async {
    final session = await pumpExplore(tester);

    expect(session.worldController.viewedZoneId, ZoneId.TUTORIAL_FARM);
    final image = tester.widget<Image>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Image),
          )
          .first,
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/zones/farm.png',
    );
    expect(headerSize(tester), const Size(414, ArtHeader.expandedHeight));
    // the status row rides over the top of the art
    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(StatusRow),
      ),
      findsOneWidget,
    );

    session.dispose();
  });

  testWidgets('scrolling collapses the art into a strip', (tester) async {
    final session = await pumpExplore(tester);

    await scrollToBottom(tester);

    // the test view has no safe area, so the strip is just its two rows
    expect(headerSize(tester).height, ArtHeader.collapsedHeight(0));
    // the name, the way back and the status row stay on the strip
    expect(find.text('Southglen Meadow').hitTestable(), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back).hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(find.byType(StatusRow)).dy, 0);
    // and the title steps down from 30 to 24
    expect(
      tester.widget<Text>(find.text('Southglen Meadow')).style!.fontSize,
      24,
    );

    session.dispose();
  });

  testWidgets('the tabs stay pinned under the header', (tester) async {
    final session = await pumpExplore(tester);

    await scrollToBottom(tester);

    expect(find.textContaining('Loot').hitTestable(), findsOneWidget);
    // sitting right under the collapsed strip, not scrolled away above it
    final collapsed = ArtHeader.collapsedHeight(0);
    final top = tester.getTopLeft(find.textContaining('Loot')).dy;
    expect(top, greaterThan(collapsed));
    expect(top, lessThan(collapsed + 64));

    // and they still switch from down here
    await tester.tap(find.textContaining('Loot'));
    await settle(tester);
    expect(find.text('Nothing found here yet'), findsOneWidget);

    session.dispose();
  });

  testWidgets('the explore timer stays by the button', (tester) async {
    final session = await pumpExplore(tester);

    final timer = find.byType(ActionTimerRow);
    expect(
      find.descendant(of: find.byType(CustomScrollView), matching: timer),
      findsNothing,
    );
    final before = tester.getTopLeft(timer);

    await scrollToBottom(tester);

    expect(timer.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(timer), before);
    // between the list and the Explore button
    expect(
      before.dy,
      lessThan(tester.getTopLeft(find.byType(ActionButtonRow)).dy),
    );

    session.dispose();
  });

  testWidgets('a zone without art opens on the collapsed strip', (
    tester,
  ) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final session = factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    Future<double> barHeight(String iconAsset) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorldController>.value(
              value: session.worldController,
            ),
            ChangeNotifierProvider<ActionTimingController>.value(
              value: session.actionTimingController,
            ),
            ChangeNotifierProvider<PlayerDataController>.value(
              value: session.playerDataController,
            ),
            ChangeNotifierProvider<EncounterController>.value(
              value: session.encounterController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  ZoneHeader(
                    key: ValueKey(iconAsset),
                    name: 'Somewhere',
                    iconAsset: iconAsset,
                    zoneLevel: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Somewhere'),
                  matching: find.byType(Stack),
                )
                .first,
          )
          .height;
    }

    // no path at all, and a path whose art hasn't been drawn yet
    expect(await barHeight(''), ArtHeader.collapsedHeight(0));
    expect(
      await barHeight('assets/images/zones/not_drawn_yet.png'),
      ArtHeader.collapsedHeight(0),
    );

    session.dispose();
  });
}
