import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:rpg/widgets/food_card.dart';

// The food dialog lists food most healing first — the order auto-eat moves
// down as stacks run out — says how auto-eat works, and sets the hp share
// it eats at.
void main() {
  late GameSession session;

  setUp(() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    session = factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    for (final entry in {
      ItemId.COOKED_MINNOW: 3,
      ItemId.COOKED_SHARK: 1,
      ItemId.COOKED_TROUT: 2,
      ItemId.COOKED_CHICKEN: 4,
    }.entries) {
      session.inventoryService.setItemCount(
        session.saveGameData.inventoryData,
        entry.key,
        entry.value,
      );
    }
  });

  tearDown(() => session.dispose());

  ItemId? picked;

  Future<void> openPicker(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    picked = null;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
          ChangeNotifierProvider<PlayerDataController>.value(
            value: session.playerDataController,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => FoodPicker.build(context, (id) => picked = id),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('food is listed most healing first', (tester) async {
    await openPicker(tester);

    final shown = tester
        .widgetList<FoodCard>(find.byType(FoodCard))
        .map((c) => c.id)
        .toList();
    // shark 35, trout 5, chicken 4, minnow 1
    expect(shown, [
      ItemId.COOKED_SHARK,
      ItemId.COOKED_TROUT,
      ItemId.COOKED_CHICKEN,
      ItemId.COOKED_MINNOW,
    ]);

    // and a pick equips it
    await tester.tap(find.byType(FoodCard).at(1));
    await tester.pumpAndSettle();
    expect(picked, ItemId.COOKED_TROUT);
  });

  testWidgets('it says how auto-eat works', (tester) async {
    await openPicker(tester);

    final help = tester.widget<Text>(
      find.byKey(const ValueKey('auto-eat-help')),
    );
    expect(help.data, contains('Auto-eat'));
    expect(help.data, contains('threshold'));
    expect(help.data, contains('next'));
  });

  testWidgets('the slider sets the hp share auto-eat eats at', (tester) async {
    await openPicker(tester);

    // the standard rule to start
    expect(find.text('Eat at 75%'), findsOneWidget);
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('auto-eat-slider')))
          .value,
      0.75,
    );

    // drag it down: the player's rule follows, and so does the label
    await tester.drag(
      find.byKey(const ValueKey('auto-eat-slider')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    final threshold = session.playerDataController.getAutoEatThreshold();
    expect(threshold, lessThan(0.75));
    expect(threshold, greaterThanOrEqualTo(FoodPicker.minThreshold));
    expect(session.saveGameData.playerData.autoEatRule.threshold, threshold);
    // in 5% steps
    final percent = (threshold * 100).round();
    expect(percent % 5, 0);
    expect(find.text('Eat at $percent%'), findsOneWidget);
  });
}
