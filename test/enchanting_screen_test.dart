import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/enchantments/enchantments.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/enchanting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/enchanting_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/equipment_card.dart';
import 'package:rpg/widgets/primary_button.dart';

/// The enchanting bench screen, rendered through the real provider tree.
///
/// The bench is the one station with two pickers to fill before it can do
/// anything, so what is pinned here is that pairing: what each empty slot
/// says, that picking only picks, and that the Action button stays dead
/// until both halves are in and affordable.
void main() {
  // BuffController ticks a periodic timer that never settles, so these use
  // fixed pumps rather than pumpAndSettle. Long enough to see a dialog all
  // the way on and all the way off again.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The cheapest recipe, and material enough to run it [times] over.
  EnchantRecipe stock(GameSession session, {int times = 1}) {
    final recipe = EnchantmentCatalog().recipes.first;
    final inventory = session.saveGameData.inventoryData;
    for (final input in recipe.inputs.entries) {
      inventory.itemMap[input.key] =
          (inventory.itemMap[input.key] ?? 0) + input.value * times;
    }
    final skill = session.saveGameData.playerData.skillData[SkillId.ENCHANTING]!;
    skill.xp = skill.xpTable[recipe.levelRequirement];
    return recipe;
  }

  EquipmentItem addHelmet(GameSession session, {int count = 1}) {
    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    helmet.count = count;
    session.saveGameData.inventoryData.equipment.add(helmet);
    return helmet;
  }

  Future<GameSession> pumpBench(WidgetTester tester) async {
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

    // tall enough that the whole ListView is built: the results card sits
    // below the fold at the default 800x600 surface
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GameSession>.value(value: session),
          ChangeNotifierProvider<EnchantingController>.value(
            value: session.enchantingController,
          ),
          ChangeNotifierProvider<WorldController>.value(
            value: session.worldController,
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
        child: const MaterialApp(home: Scaffold(body: EnchantingScreen())),
      ),
    );
    await settle(tester);
    return session;
  }

  testWidgets('an empty bench names both slots it needs filled', (
    tester,
  ) async {
    final session = await pumpBench(tester);

    expect(find.text('Enchanting Bench'), findsOneWidget);
    expect(find.text('Select a recipe'), findsOneWidget);
    expect(find.text('Select an item'), findsOneWidget);

    // the material header shows every tier, whether or not any is held
    expect(
      find.byType(EquipmentCard),
      findsNothing,
      reason: 'nothing is selected, so no target card should be drawn',
    );

    // and with nothing picked, the bench cannot be started
    final button = tester.widget<ActionOrTravelButton>(
      find.byType(ActionOrTravelButton),
    );
    expect(button.enabled, isFalse);

    session.dispose();
  });

  testWidgets('the recipe picker lists disenchant first, then the tiers', (
    tester,
  ) async {
    final session = await pumpBench(tester);

    await tester.tap(find.text('Select a recipe'));
    await settle(tester);

    expect(find.text('Select Recipe'), findsOneWidget);
    expect(find.text('Disenchant'), findsWidgets);
    for (final recipe in EnchantmentCatalog().recipes) {
      expect(
        find.text(recipe.name),
        findsWidgets,
        reason: '${recipe.name} is missing from the picker',
      );
    }

    // closing without choosing leaves the slot empty
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.text('Select Recipe'), findsNothing);
    expect(find.text('Select a recipe'), findsOneWidget);

    session.dispose();
  });

  testWidgets('picking a recipe fills its slot but starts nothing', (
    tester,
  ) async {
    final session = await pumpBench(tester);
    final recipe = stock(session);

    await tester.tap(find.text('Select a recipe'));
    await settle(tester);
    await tester.tap(find.text(recipe.name).last);
    await settle(tester);

    // the picker closed and the empty slot became the recipe's own card
    expect(find.text('Select Recipe'), findsNothing);
    expect(find.text('Select a recipe'), findsNothing);
    expect(find.text(recipe.name), findsOneWidget);
    expect(session.enchantingController.selectedRecipeId, recipe.id);

    // but there is still nothing to apply it to, so the bench is dead
    expect(find.text('Select an item'), findsOneWidget);
    expect(
      tester
          .widget<ActionOrTravelButton>(find.byType(ActionOrTravelButton))
          .enabled,
      isFalse,
    );
    expect(session.actionTimingController.isRunning, isFalse);

    session.dispose();
  });

  testWidgets('the target picker says which rows are worn', (tester) async {
    final session = await pumpBench(tester);
    final worn = addHelmet(session);
    session.equipmentController.equipItem(worn);
    addHelmet(session);
    await tester.pump();

    await tester.tap(find.text('Select an item'));
    await settle(tester);

    expect(find.text('Select Item'), findsOneWidget);
    expect(find.byType(EquipmentCard), findsNWidgets(2));
    final cards = tester
        .widgetList<EquipmentCard>(find.byType(EquipmentCard))
        .toList();
    expect(
      cards.first.equipped,
      isTrue,
      reason: 'worn gear leads the list and should be marked',
    );
    expect(cards.last.equipped, isFalse);

    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.text('Select an item'), findsOneWidget);

    session.dispose();
  });

  testWidgets('an empty bag says so rather than opening an empty list', (
    tester,
  ) async {
    final session = await pumpBench(tester);

    await tester.tap(find.text('Select an item'));
    await settle(tester);
    expect(find.text('No equipment in inventory.'), findsOneWidget);
    expect(find.byType(EquipmentCard), findsNothing);

    session.dispose();
  });

  testWidgets('both slots filled and affordable arms the button', (
    tester,
  ) async {
    final session = await pumpBench(tester);
    final recipe = stock(session);
    final helmet = addHelmet(session);

    await tester.tap(find.text('Select a recipe'));
    await settle(tester);
    await tester.tap(find.text(recipe.name).last);
    await settle(tester);

    await tester.tap(find.text('Select an item'));
    await settle(tester);
    await tester.tap(find.byType(EquipmentCard).last);
    await settle(tester);

    expect(find.text('Select an item'), findsNothing);
    expect(session.enchantingController.selectedTarget?.instanceId,
        helmet.instanceId);
    expect(
      tester
          .widget<ActionOrTravelButton>(find.byType(ActionOrTravelButton))
          .enabled,
      isTrue,
    );

    session.dispose();
  });

  testWidgets('a full selection with nothing to spend stays dead', (
    tester,
  ) async {
    final session = await pumpBench(tester);
    final recipe = EnchantmentCatalog().recipes.first;
    // the level, but none of the materials
    final skill = session.saveGameData.playerData.skillData[SkillId.ENCHANTING]!;
    skill.xp = skill.xpTable[recipe.levelRequirement];
    addHelmet(session);

    await tester.tap(find.text('Select a recipe'));
    await settle(tester);
    await tester.tap(find.text(recipe.name).last);
    await settle(tester);
    await tester.tap(find.text('Select an item'));
    await settle(tester);
    await tester.tap(find.byType(EquipmentCard).last);
    await settle(tester);

    expect(
      tester
          .widget<ActionOrTravelButton>(find.byType(ActionOrTravelButton))
          .enabled,
      isFalse,
      reason: 'the bench offered a run it cannot pay for',
    );

    session.dispose();
  });

  testWidgets('disenchant shows what the selected item is worth', (
    tester,
  ) async {
    final session = await pumpBench(tester);
    final helmet = addHelmet(session);

    await tester.tap(find.text('Select a recipe'));
    await settle(tester);
    await tester.tap(find.text('Disenchant').last);
    await settle(tester);
    await tester.tap(find.text('Select an item'));
    await settle(tester);
    await tester.tap(find.byType(EquipmentCard).last);
    await settle(tester);

    // the yield line only appears once there is something to price
    expect(find.text('Yields per action:  '), findsOneWidget);
    final preview = session.enchantingController.previewDisenchant(helmet);
    expect(preview, isNotNull);
    expect(preview!.count, greaterThan(0));

    // disenchanting costs nothing but the item, so it is always runnable
    expect(
      tester
          .widget<ActionOrTravelButton>(find.byType(ActionOrTravelButton))
          .enabled,
      isTrue,
    );

    session.dispose();
  });

  testWidgets('the session panel fills in as the bench works', (tester) async {
    final session = await pumpBench(tester);
    final controller = session.enchantingController;
    final helmet = addHelmet(session);

    controller.selectRecipe(EnchantingController.disenchantRecipeId);
    controller.selectTarget(helmet);
    await settle(tester);

    controller.startEnchantingAction();
    controller.doEnchantingAction(1);
    await settle(tester);

    expect(controller.sessionResults(), isNotEmpty);
    // the empty-state note is gone once the session has produced something
    expect(find.text('Nothing enchanted this session'), findsNothing);

    session.actionTimingController.stop();
    session.dispose();
  });
}
