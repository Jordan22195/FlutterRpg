import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/picker_list.dart';
import 'package:rpg/widgets/recipe_card.dart';

/// Where a picker opens. A list of forty recipes that always opens on the
/// first four of them makes the player hunt for their own selection, so the
/// row already in play is what the dialog opens centred on.
void main() {
  // ------------------------------------------------------------ the list

  group('a picker list opens on the row already in play', () {
    /// [PickerList] in a viewport exactly [rows] rows tall, so the maths the
    /// test does is the maths the widget does.
    Future<ScrollableState> pumpList(
      WidgetTester tester, {
      required int itemCount,
      required int selectedIndex,
      double rows = 5,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: PickerList.defaultRowExtent * rows,
                child: PickerList(
                  itemCount: itemCount,
                  selectedIndex: selectedIndex,
                  itemBuilder: (_, i) =>
                      SizedBox(key: ValueKey(i), child: Text('row $i')),
                ),
              ),
            ),
          ),
        ),
      );
      // the centring lands on the frame after the first layout
      await tester.pump();
      return tester.state<ScrollableState>(find.byType(Scrollable));
    }

    /// Where the selected row would have to sit for the viewport to be
    /// centred on it.
    double centredOffset(ScrollableState scrollable, int selectedIndex) {
      const extent = PickerList.defaultRowExtent;
      return selectedIndex * extent +
          extent / 2 -
          scrollable.position.viewportDimension / 2;
    }

    testWidgets('a selection in the middle is centred', (tester) async {
      final scrollable = await pumpList(
        tester,
        itemCount: 40,
        selectedIndex: 25,
      );

      expect(
        scrollable.position.pixels,
        closeTo(centredOffset(scrollable, 25), 0.5),
      );
      // and the row itself is on screen, in the middle of the viewport
      final viewport = tester.getRect(find.byType(PickerList));
      final row = tester.getRect(find.byKey(const ValueKey(25)));
      expect(row.center.dy, closeTo(viewport.center.dy, 0.5));
    });

    testWidgets('a selection near the top opens at the top', (tester) async {
      final scrollable = await pumpList(
        tester,
        itemCount: 40,
        selectedIndex: 1,
      );

      // centring it would scroll above the first row, so the list simply
      // opens as far that way as it goes
      expect(scrollable.position.pixels, 0);
      expect(find.byKey(const ValueKey(1)), findsOneWidget);
    });

    testWidgets('a selection near the bottom opens at the bottom', (
      tester,
    ) async {
      final scrollable = await pumpList(
        tester,
        itemCount: 40,
        selectedIndex: 39,
      );

      expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
      expect(find.byKey(const ValueKey(39)), findsOneWidget);
    });

    testWidgets('a list short enough to fit does not scroll', (tester) async {
      final scrollable = await pumpList(
        tester,
        itemCount: 3,
        selectedIndex: 2,
        rows: 10,
      );

      expect(scrollable.position.pixels, 0);
      expect(scrollable.position.maxScrollExtent, 0);
    });

    testWidgets('nothing selected opens at the top', (tester) async {
      final scrollable = await pumpList(
        tester,
        itemCount: 40,
        selectedIndex: -1,
      );

      expect(scrollable.position.pixels, 0);
      expect(find.byKey(const ValueKey(0)), findsOneWidget);
    });
  });

  // ---------------------------------------------------------- the picker

  group('the crafting recipe picker', () {
    Future<GameSession> pumpCraftingScreen(WidgetTester tester) async {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final save = factory.newGame(catalogs);
      final session = factory.create(
        save: save,
        catalogs: catalogs,
        vsync: const TestVSync(),
      );

      registerCatalogIconResolvers();
      EnumImageProviderLookup.register<SkillId>(
        SkillController.imageProviderFor,
      );

      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // the player is standing at the anvil, which crafts blacksmithing
      save.playerData.currentEntityViewId = EntityId.ANVIL;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GameSession>.value(value: session),
            ChangeNotifierProvider<CraftingController>.value(
              value: session.craftingController,
            ),
            ChangeNotifierProvider<InventoryController>.value(
              value: session.inventoryController,
            ),
            ChangeNotifierProvider<ActionTimingController>.value(
              value: session.actionTimingController,
            ),
            ChangeNotifierProvider<BuffController>.value(
              value: session.buffController,
            ),
            ChangeNotifierProvider<PlayerDataController>.value(
              value: session.playerDataController,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CraftingScreen())),
        ),
      );
      await tester.pump();
      return session;
    }

    testWidgets('opens on the recipe already selected', (tester) async {
      final session = await pumpCraftingScreen(tester);
      final controller = session.craftingController;
      final recipes = controller.availableRecipes();

      // a recipe far enough down the anvil's list that a picker opening at
      // the top would not have built it at all
      expect(recipes.length, greaterThan(10));
      final target = recipes.last;
      controller.selectRecipe(target.id);
      await tester.pump();

      // the card on the screen shows the current selection; tapping it opens
      // the picker
      await tester.tap(find.byType(RecipeCard).first);
      await tester.pump();
      await tester.pump();

      expect(find.text('Select Recipe'), findsOneWidget);

      // the selected row is the one on screen, and it is the marked one
      final selected = find.byWidgetPredicate(
        (widget) =>
            widget is RecipeCard &&
            widget.recipeId == target.id &&
            widget.selected,
      );
      expect(selected, findsOneWidget);

      // and it sits in the middle of the list rather than off the end of it
      final viewport = tester.getRect(find.byType(PickerList));
      final row = tester.getRect(selected);
      expect(viewport.contains(row.center), isTrue);
      // the centring is arithmetic off a fixed row height, so a card that
      // stopped matching it would quietly aim at the wrong row
      expect(row.height, PickerList.defaultRowExtent);

      session.dispose();
    });

    testWidgets('with nothing selected it opens at the top', (tester) async {
      final session = await pumpCraftingScreen(tester);
      final recipes = session.craftingController.availableRecipes();

      await tester.tap(find.byType(RecipeCard).first);
      await tester.pump();
      await tester.pump();

      // the recipe rows scroll their inputs horizontally, so the picker's
      // own list is the first scrollable under it
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(PickerList),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, 0);
      expect(recipes.first.id, isNotEmpty);

      session.dispose();
    });
  });
}
