import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
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

/// The jewelcrafting bench, opened the way a player opens it: the screen
/// and then its recipe picker, which lists every gem x cut x setting.
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

    save.playerData.currentEntityViewId = EntityId.JEWELCRAFTING_BENCH;
    if (savedSelection != null) {
      save.craftingState.selectedRecipeByEntity[EntityId.JEWELCRAFTING_BENCH] =
          {SkillId.JEWELCRAFTING: savedSelection};
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

  testWidgets('the bench opens', (tester) async {
    final session = await pumpBench(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(RecipeCard), findsWidgets);
    session.dispose();
  });

  testWidgets('its recipe picker opens', (tester) async {
    final session = await pumpBench(tester);
    await tester.tap(find.byType(RecipeCard).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.byType(RecipePickerSheet), findsOneWidget);
    session.dispose();
  });

  // a save from before the gold bases moved to blacksmithing still holds
  // the jewelcrafting recipe it last had selected
  for (final retired in ['jc_gold_ring', 'forge_gold_ring', 'no_such_recipe']) {
    testWidgets('a saved selection of $retired reads as nothing chosen', (
      tester,
    ) async {
      final session = await pumpBench(tester, savedSelection: retired);
      expect(tester.takeException(), isNull);
      expect(session.craftingController.selectedRecipeId, isEmpty);
      if (retired != 'forge_gold_ring') {
        expect(session.craftingController.activeRecipeId, isEmpty);
      }
      session.dispose();
    });
  }

  // the info tab's quality odds come from the jewelcrafting total set
  // against each recipe's own level, so a low recipe and a high one read
  // differently once the player is past the low one
  testWidgets('the info tab shows each recipe its own quality odds', (
    tester,
  ) async {
    final session = await pumpBench(tester);
    final skill =
        session.saveGameData.playerData.skillData[SkillId.JEWELCRAFTING]!;
    skill.xp = skill.xpTable[60];

    List<String> odds() => [
      for (final rarity in ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'])
        (tester
                .widget<Text>(
                  find
                      .descendant(
                        of: find
                            .ancestor(
                              of: find.text(rarity),
                              matching: find.byType(Row),
                            )
                            .first,
                        matching: find.textContaining('%'),
                      )
                      .first,
                )
                .data ??
            ''),
    ];

    session.craftingController.selectRecipe('jc_topaz_ring');
    await tester.pump();
    await tester.tap(find.textContaining('Info').first);
    await tester.pump();
    final topaz = odds();

    session.craftingController.selectRecipe('jc_onyx_radiant_ring');
    await tester.pump();
    final onyx = odds();

    expect(topaz.first, isNot(onyx.first), reason: 'topaz $topaz onyx $onyx');
    expect(onyx.first, '98.9%');
    session.dispose();
  });
}
