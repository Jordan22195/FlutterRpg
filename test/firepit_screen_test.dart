import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/firepit_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/countdown_timer.dart';
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

    // tall enough that the whole ListView is built: the COOK section sits
    // below the fold at the default 800x600 surface
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final firemaking = save.playerData.skillData[SkillId.FIREMAKING]!;
    firemaking.xp = firemaking.xpTable[40];
    save.inventoryData.itemMap[ItemId.LOGS] = 200;
    save.inventoryData.itemMap[ItemId.MINNOW] = 20;

    // the player is standing at the firepit
    save.playerData.currentEntityViewId = EntityId.FIREPIT;

    if (lightRecipeId != null) {
      save.craftingState.craftingEntityId = EntityId.FIREPIT;
      save.craftingState.activeRecipeId = lightRecipeId;
      session.craftingSystem.craftActiveRecipeOnce(
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
    expect(find.text('FIRE'), findsOneWidget);
    expect(find.text('COOK'), findsNothing);

    // nothing is burning, so there is no timer and nothing to put out
    expect(find.byType(CountdownTimer), findsNothing);
    expect(find.byIcon(Icons.water_drop_outlined), findsNothing);
    expect(find.text('Light Fire'), findsOneWidget);

    session.dispose();
  });

  testWidgets('a lit cookfire opens the cook section', (tester) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'cookfire');

    // the header and hero become the fire
    expect(find.text('Cookfire'), findsOneWidget);
    expect(find.text('FIRE'), findsOneWidget);
    expect(find.text('COOK'), findsOneWidget);

    // burn time in the hero's corner, and the fire can be put out
    expect(find.byType(CountdownTimer), findsWidgets);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

    session.dispose();
  });

  testWidgets('a campfire burns without opening cooking', (tester) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'basic_campfire');

    expect(find.text('Campfire'), findsOneWidget);
    expect(find.text('COOK'), findsNothing);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

    session.dispose();
  });

  testWidgets('putting the fire out closes cooking again', (tester) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'cookfire');
    expect(find.text('COOK'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.water_drop_outlined));
    await settle(tester);
    // confirm in the dialog
    await tester.tap(find.text('Put out'));
    await settle(tester);

    expect(find.text('COOK'), findsNothing);
    expect(find.text('Firepit'), findsOneWidget);
    expect(find.byType(CountdownTimer), findsNothing);

    session.dispose();
  });

  testWidgets('lighting a fire does not move the rest of the screen', (
    tester,
  ) async {
    // the buff row slot and the skill rings are the two things that used to
    // shift when a fire caught: the row appeared out of nothing, and the
    // ring row re-centred as it grew from one ring to two
    final session = await pumpFirepit(tester);

    Offset ringsAt() => tester.getTopLeft(find.byType(SkillRingRow));
    Offset fireLabelAt() => tester.getTopLeft(find.text('FIRE'));

    final coldRings = ringsAt();
    final coldFireLabel = fireLabelAt();

    // light a cookfire underneath the running screen
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = EntityId.FIREPIT;
    save.craftingState.activeRecipeId = 'cookfire';
    session.craftingSystem.craftActiveRecipeOnce(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
    );
    session.buffController.refresh();
    await settle(tester);

    expect(find.text('COOK'), findsOneWidget);
    expect(ringsAt(), coldRings);
    expect(fireLabelAt(), coldFireLabel);

    session.dispose();
  });

  testWidgets('the button reads Add Logs only for the burning fire', (
    tester,
  ) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'cookfire');

    // a lit cookfire lands on the cook section, which is what you walked
    // over to a burning fire to do
    expect(find.text('Cook'), findsOneWidget);

    // picks the nth firemaking recipe out of the fire section's picker.
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
    }

    // choosing the fire that is already burning tops it up
    await pickFire(0);
    expect(find.text('Add Logs'), findsOneWidget);
    expect(find.text('Replaces the current fire'), findsNothing);

    // a different fire takes the firepit over, and the card says so
    await pickFire(1);
    expect(find.text('Light Fire'), findsOneWidget);
    expect(find.text('Replaces the current fire'), findsOneWidget);

    session.dispose();
  });
}
