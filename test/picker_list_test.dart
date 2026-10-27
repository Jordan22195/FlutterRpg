import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/picker_list.dart';
import 'package:rpg/widgets/recipe_picker_sheet.dart';
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
            ChangeNotifierProvider<WorldController>.value(
              value: session.worldController,
            ),
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
            // the status row on the art strip reads the encounter for its
            // damage numbers
            ChangeNotifierProvider<EncounterController>.value(
              value: session.encounterController,
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

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.byType(RecipeCard).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('lists one card per recipe, lowest level first', (
      tester,
    ) async {
      final session = await pumpCraftingScreen(tester);
      await openSheet(tester);

      expect(find.byType(RecipePickerSheet), findsOneWidget);
      expect(find.text('Anvil'), findsWidgets);
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      final levels = session.craftingController
          .availableRecipes()
          .map((r) => r.levelRequirement)
          .toList();
      final sorted = [...levels]..sort();
      expect(sorted.first, levels.reduce((a, b) => a < b ? a : b));

      // every card clears the touch-target minimum
      final cards = find.bySemanticsLabel(RegExp(r', (level \d+, |locked, )'));
      expect(cards, findsWidgets);
      expect(tester.getSize(cards.first).height, greaterThanOrEqualTo(84));

      session.dispose();
    });

    testWidgets('ingredient chips abbreviate large counts', (tester) async {
      final session = await pumpCraftingScreen(tester);
      session.inventoryController.devSetItemCount(ItemId.COPPER_ORE, 1234);
      await openSheet(tester);

      expect(find.text('1.23k'), findsWidgets);

      session.dispose();
    });

    testWidgets('the screen shows the selected recipe as a picker card', (
      tester,
    ) async {
      final session = await pumpCraftingScreen(tester);
      final controller = session.craftingController;
      controller.selectRecipe(controller.availableRecipes().first.id);
      await tester.pump();

      expect(find.byType(RecipePickerCard), findsOneWidget);
      expect(find.byType(RecipeCard), findsNothing);

      // tapping it opens the picker
      await tester.tap(find.byType(RecipePickerCard));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RecipePickerSheet), findsOneWidget);

      session.dispose();
    });

    testWidgets('metal tabs filter the list', (tester) async {
      final session = await pumpCraftingScreen(tester);
      await openSheet(tester);

      expect(find.bySemanticsLabel('Copper tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Iron tab'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Iron tab'));
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp(r'^Copper .*, (level|locked)')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Iron .*, (level|locked)')),
        findsWidgets,
      );

      session.dispose();
    });

    testWidgets(
      'a locked recipe cannot be picked, and the close button dismisses',
      (tester) async {
        final session = await pumpCraftingScreen(tester);
        final before = session.craftingController.selectedRecipeId;
        await openSheet(tester);

        final locked = find.bySemanticsLabel(
          RegExp(r', locked, requires level'),
        );
        if (locked.evaluate().isNotEmpty) {
          await tester.ensureVisible(locked.first);
          await tester.tap(locked.first);
          await tester.pump();
          expect(session.craftingController.selectedRecipeId, before);
          expect(find.byType(RecipePickerSheet), findsOneWidget);
        }

        await tester.tap(find.byIcon(Icons.close).hitTestable());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(RecipePickerSheet), findsNothing);

        session.dispose();
      },
    );
  });
}
