import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/firepit_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/countdown_timer.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/skill_ring_row.dart';

// Renders the real FirepitScreen through the provider tree, so what the
// sections show comes from the live fire buff rather than a fixture.
void main() {
  // BuffController ticks a periodic timer that never settles, so these use
  // fixed pumps rather than pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<GameSession> pumpFirepit(
    WidgetTester tester, {
    String? lightRecipeId,
    // the firepit's own per-skill recipe selections, as the player would
    // have left them
    Map<SkillId, String>? selections,
    int logs = 200,
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

    // tall enough that the whole ListView is built: the COOK section sits
    // below the fold at the default 800x600 surface
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final firemaking = save.playerData.skillData[SkillId.FIREMAKING]!;
    firemaking.xp = firemaking.xpTable[40];
    save.inventoryData.itemMap[ItemId.LOGS] = logs;
    save.inventoryData.itemMap[ItemId.MINNOW] = 20;

    // the player is standing at the firepit
    save.playerData.currentEntityViewId = EntityId.FIREPIT;
    if (selections != null) {
      save.craftingState.selectedRecipeByEntity[EntityId.FIREPIT] = selections;
    }

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
          ChangeNotifierProvider<BuffController>.value(
            value: session.buffController,
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
        child: const MaterialApp(home: Scaffold(body: FirepitScreen())),
      ),
    );
    await settle(tester);
    return session;
  }

  testWidgets('a cold firepit offers fire only', (tester) async {
    final session = await pumpFirepit(tester);

    expect(find.text('Firepit'), findsOneWidget);
    // nothing to stack, so the pit shows the fire recipe alone and unnamed
    expect(find.byType(RecipeCard), findsOneWidget);
    expect(find.text('Firemaking'), findsNothing);
    expect(find.text('Cooking'), findsNothing);

    // nothing is burning, so there is no timer and nothing to put out
    expect(find.byType(CountdownTimer), findsNothing);
    expect(find.byIcon(Icons.water_drop_outlined), findsNothing);
    expect(find.text('Light Fire'), findsOneWidget);

    session.dispose();
  });

  testWidgets('a lit cookfire stacks cooking under firemaking', (tester) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'cookfire');

    // the header and hero become the fire
    expect(find.text('Cookfire'), findsOneWidget);
    // a pit doing two jobs shows both recipes at once, each one named
    expect(find.byType(RecipeCard), findsNWidgets(2));
    expect(find.text('Firemaking'), findsOneWidget);
    expect(find.text('Cooking'), findsOneWidget);

    // cooking is the section the button runs, so its card carries the mark
    final cards = tester.widgetList<RecipeCard>(find.byType(RecipeCard));
    expect(cards.map((c) => c.selected), [false, true]);

    // and the cooking card sits below the firemaking one
    expect(
      tester.getTopLeft(find.byType(RecipeCard).at(1)).dy,
      greaterThan(tester.getTopLeft(find.byType(RecipeCard).first).dy),
    );

    // burn time in the hero's corner, and the fire can be put out
    expect(find.byType(CountdownTimer), findsWidgets);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

    session.dispose();
  });

  testWidgets('picking a cookfire opens cooking before it is lit', (
    tester,
  ) async {
    final session = await pumpFirepit(tester);

    // nothing picked yet, so the cold pit is still fire-only
    expect(find.byType(RecipeCard), findsOneWidget);

    // pick the cookfire out of the fire card's picker (catalog order:
    // 0 = cookfire, 1 = campfire)
    await tester.tap(find.byType(RecipeCard).first);
    await settle(tester);
    await tester.tap(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(RecipeCard),
          )
          .first,
    );
    // the picker dismisses on a transition, so give it longer than the
    // shared two-pump settle to leave the tree
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    // the cooking recipe is on screen even though nothing is burning, with
    // what the cook will burn to light the pit
    expect(find.byType(RecipeCard), findsNWidgets(2));
    expect(find.text('Cooking'), findsOneWidget);
    expect(find.text('Burns 2 × Logs per fire'), findsOneWidget);
    expect(find.byType(CountdownTimer), findsNothing);

    // a cookfire is only ever lit by cooking on it, so even though the fire
    // card was the one tapped, the button cooks
    final cards = tester.widgetList<RecipeCard>(find.byType(RecipeCard));
    expect(cards.map((c) => c.selected), [false, true]);
    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Light Fire'), findsNothing);

    session.dispose();
  });

  testWidgets('a cold pit with a cookfire picked defaults to Cook', (
    tester,
  ) async {
    final session = await pumpFirepit(
      tester,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );

    // nothing is burning, but the cook lights the pit itself, so cooking
    // is what the button runs
    expect(find.byType(CountdownTimer), findsNothing);
    final cards = tester.widgetList<RecipeCard>(find.byType(RecipeCard));
    expect(cards.map((c) => c.selected), [false, true]);
    expect(find.text('Cook'), findsOneWidget);
    expect(
      tester
          .widget<MomentumPrimaryButton>(find.byType(MomentumPrimaryButton))
          .enabled,
      isTrue,
    );
    expect(find.text('Burns 2 × Logs per fire'), findsOneWidget);

    session.dispose();
  });

  testWidgets('without logs the Cook button waits', (tester) async {
    final session = await pumpFirepit(
      tester,
      logs: 0,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );

    // still the cook's card, still says what it needs - but nothing to
    // light the pit with, so the button stays down
    final cards = tester.widgetList<RecipeCard>(find.byType(RecipeCard));
    expect(cards.map((c) => c.selected), [false, true]);
    expect(find.text('Burns 2 × Logs per fire'), findsOneWidget);
    expect(
      tester
          .widget<MomentumPrimaryButton>(find.byType(MomentumPrimaryButton))
          .enabled,
      isFalse,
    );

    session.dispose();
  });

  testWidgets('a lit cookfire keeps the log-cost hint', (tester) async {
    final session = await pumpFirepit(
      tester,
      lightRecipeId: 'cookfire',
      selections: {SkillId.FIREMAKING: 'cookfire'},
    );

    expect(find.byType(RecipeCard), findsNWidgets(2));
    expect(find.text('Burns 2 × Logs per fire'), findsOneWidget);
    expect(find.text('Pick a cookfire to cook'), findsNothing);
    expect(find.text('Cook'), findsOneWidget);

    session.dispose();
  });

  testWidgets('a lit cookfire with a campfire picked says to pick a cookfire', (
    tester,
  ) async {
    final session = await pumpFirepit(
      tester,
      lightRecipeId: 'cookfire',
      selections: {
        SkillId.FIREMAKING: 'basic_campfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );

    // the fire is cooking now, so the button runs; but once it dies the
    // cook has nothing it is allowed to relight with, and the card says so
    expect(find.text('Pick a cookfire to cook'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
    expect(
      tester
          .widget<MomentumPrimaryButton>(find.byType(MomentumPrimaryButton))
          .enabled,
      isTrue,
    );

    session.dispose();
  });

  testWidgets('pressing Cook on a cold pit lights the fire and stays on '
      'cooking', (tester) async {
    final session = await pumpFirepit(
      tester,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );
    expect(find.text('Firepit'), findsOneWidget);

    // the button's start path, and its first tick
    expect(
      session.craftingController.startCraftingActionFor(
        'cook_minnow',
        EntityId.FIREPIT,
      ),
      isTrue,
    );
    session.craftingController.doCraftingAction(1);
    session.buffController.refresh();
    await settle(tester);

    // the pit is lit, and the running cook keeps the highlight
    expect(find.text('Cookfire'), findsOneWidget);
    expect(find.byType(CountdownTimer), findsWidgets);
    final cards = tester.widgetList<RecipeCard>(find.byType(RecipeCard));
    expect(cards.map((c) => c.selected), [false, true]);
    expect(find.text('Cook'), findsOneWidget);

    session.actionTimingController.stop();
    session.dispose();
  });

  testWidgets('a campfire burns without opening cooking', (tester) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'basic_campfire');

    expect(find.text('Campfire'), findsOneWidget);
    // a campfire cannot cook, so there is nothing to stack
    expect(find.byType(RecipeCard), findsOneWidget);
    expect(find.text('Cooking'), findsNothing);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

    session.dispose();
  });

  testWidgets('putting the fire out closes cooking again', (tester) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'cookfire');
    expect(find.byType(RecipeCard), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.water_drop_outlined));
    await settle(tester);
    // confirm in the dialog
    await tester.tap(find.text('Put out'));
    await settle(tester);

    expect(find.byType(RecipeCard), findsOneWidget);
    expect(find.text('Cooking'), findsNothing);
    expect(find.text('Firepit'), findsOneWidget);
    expect(find.byType(CountdownTimer), findsNothing);

    session.dispose();
  });

  testWidgets('lighting a fire does not move the rest of the screen', (
    tester,
  ) async {
    // the hero and the skill rings are what sit above the recipe cards, and
    // neither may shift when a fire catches: the ring row used to re-centre
    // as it grew from one ring to two. (the cooking card does appear below
    // them, which is what grows the stack.)
    final session = await pumpFirepit(tester);

    Offset ringsAt() => tester.getTopLeft(find.byType(SkillRingRow));
    Size ringsSize() => tester.getSize(find.byType(SkillRingRow));

    final coldRings = ringsAt();
    final coldRingsSize = ringsSize();

    // light a cookfire underneath the running screen
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = EntityId.FIREPIT;
    save.craftingState.activeRecipeId = 'cookfire';
    session.craftingSystem.craftActiveRecipe(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
    );
    session.buffController.refresh();
    await settle(tester);

    expect(find.byType(RecipeCard), findsNWidgets(2));
    expect(ringsAt(), coldRings);
    expect(ringsSize(), coldRingsSize);

    session.dispose();
  });

  testWidgets('the button reads Add Logs only for the burning fire', (
    tester,
  ) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'basic_campfire');

    // a campfire cannot cook, so the pit is fire-only and the button lights
    expect(find.text('Light Fire'), findsOneWidget);

    // picks the nth firemaking recipe out of the fire card's picker.
    // recipe cards carry no name, so they are addressed by catalog order:
    // 0 = cookfire, 1 = campfire.
    Future<void> pickFire(int index) async {
      await tester.tap(find.byType(RecipeCard).first);
      await settle(tester);
      final inPicker = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(RecipeCard),
      );
      await tester.tap(inPicker.at(index));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
    }

    // choosing the fire that is already burning tops it up
    await pickFire(1);
    expect(find.text('Add Logs'), findsOneWidget);
    expect(find.text('Replaces the current fire'), findsNothing);

    // a cookfire would take the firepit over, and the card says so - but
    // a cookfire is lit by cooking on it, so the button cooks rather than
    // lighting it by hand
    await pickFire(0);
    expect(find.text('Replaces the current fire'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Light Fire'), findsNothing);

    session.dispose();
  });
}
