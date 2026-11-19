import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/recipe_picker_sheet.dart';

/// The alchemy station's recipe picker and its skill filter chips.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameSession> pumpBench(
    WidgetTester tester, {
    String? savedSelection,
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
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    save.playerData.currentEntityViewId = EntityId.ALCHEMY_STATION;
    if (savedSelection != null) {
      save.craftingState.selectedRecipeByEntity[EntityId.ALCHEMY_STATION] =
          {SkillId.ALCHEMY: savedSelection};
      save.craftingState.activeRecipeId = savedSelection;
    }

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

  testWidgets('the picker offers a chip per buffed skill and filters by it', (
    tester,
  ) async {
    final session = await pumpBench(tester);
    await tester.tap(find.byType(RecipeCard).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Defence tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Woodcutting tab'), findsOneWidget);
    final all = find.byType(RecipePickerCard).evaluate().length;

    await tester.tap(find.bySemanticsLabel('Defence tab'));
    await tester.pump();
    final cards = find.byType(RecipePickerCard);
    expect(cards, findsWidgets);
    expect(cards.evaluate().length, lessThan(all));
    for (final e in cards.evaluate()) {
      final out = (e.widget as RecipePickerCard).recipe.output.first.id;
      expect((out.definition as PotionDefinition).skill, SkillId.DEFENCE);
    }
    session.dispose();
  });
}
