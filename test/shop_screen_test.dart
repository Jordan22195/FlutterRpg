import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/shop_controller.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/shop_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/data/skill_data.dart';

// Boots a real session, drops the player in the dev forest viewing the
// trading post, and renders the actual ShopScreen through the provider
// tree to verify buy/sell wiring end to end.
void main() {
  testWidgets('shop screen lists stock and trades with the player', (
    tester,
  ) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    // icon resolvers so ItemStackTile/IconRenderer don't throw
    ItemCatalog.init();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    EnumImageProviderLookup.register<EntityId>(
      session.catalogBundle.entityCatalog.imageProviderFor,
    );

    // give the player coins + a sellable stack and move them to the dev
    // forest, viewing the trading post
    save.inventoryData.itemMap[ItemId.COINS] = 10000;
    save.inventoryData.itemMap[ItemId.COPPER_ORE] = 5;
    save.playerData.currentZoneId = ZoneId.DEV_FOREST;
    save.playerData.currentEntityViewId = EntityId.TRADING_POST;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShopController>.value(
            value: session.shopController,
          ),
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ShopScreen())),
      ),
    );
    await tester.pump();

    // header + for-sale section render
    expect(find.text('Trading Post'), findsOneWidget);
    expect(find.text('For Sale'), findsOneWidget);

    // restock filled the shelf with 10 items (the lazy ListView only
    // builds the visible subset, so assert stock via the controller)
    expect(session.shopController.stock().length, 10);
    final buyButtons = find.textContaining('Buy ');
    expect(buyButtons, findsWidgets);

    final coinsBeforeBuy = session.shopController.playerCoins();

    // buy the first item; coins drop (player has plenty of coins so this should always work)
    await tester.ensureVisible(buyButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(buyButtons.first);
    await tester.pump();
    expect(session.shopController.playerCoins(), lessThan(coinsBeforeBuy));

    // the sell section sits below the fold; drag the list up to reveal it
    final listView = find.byType(Scrollable).first;
    for (int i = 0; i < 6 && find.textContaining('Sell ').evaluate().isEmpty; i++) {
      await tester.drag(listView, const Offset(0, -300));
      await tester.pump();
    }
    final sellButton = find.textContaining('Sell ');
    expect(sellButton, findsWidgets);

    final coinsBeforeSell = session.shopController.playerCoins();
    final oreBefore = save.inventoryData.itemMap[ItemId.COPPER_ORE] ?? 0;

    // Target the copper ore sell row explicitly instead of `.first`
    // to avoid flakiness when other inventory items have 0-value sell prices
    final copperOreText = find.text('Copper Ore');
    await tester.ensureVisible(copperOreText);
    await tester.pumpAndSettle();

    // Find the Card parent of copper ore by searching upward in the widget tree
    final copperOreCard = find.ancestor(
      of: copperOreText,
      matching: find.byType(Card),
    );

    expect(copperOreCard, findsOneWidget,
        reason: 'Copper ore should be in a Card widget');

    // Find the sell button within that Card
    final copperOreSellButton = find.descendant(
      of: copperOreCard.first,
      matching: find.textContaining('Sell '),
    );

    expect(copperOreSellButton, findsWidgets,
        reason: 'Copper ore Card should have a Sell button');

    await tester.tap(copperOreSellButton.first);
    await tester.pump();
    expect(session.shopController.playerCoins(), greaterThan(coinsBeforeSell));
    expect(save.inventoryData.itemMap[ItemId.COPPER_ORE] ?? 0, oreBefore - 1);

    session.dispose();
  });
}
