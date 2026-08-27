import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
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
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

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
    for (
      int i = 0;
      i < 6 && find.textContaining('Sell ').evaluate().isEmpty;
      i++
    ) {
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

    expect(
      copperOreCard,
      findsOneWidget,
      reason: 'Copper ore should be in a Card widget',
    );

    // Find the sell button within that Card
    final copperOreSellButton = find.descendant(
      of: copperOreCard.first,
      matching: find.textContaining('Sell '),
    );

    expect(
      copperOreSellButton,
      findsWidgets,
      reason: 'Copper ore Card should have a Sell button',
    );

    await tester.tap(copperOreSellButton.first);
    await tester.pump();
    expect(session.shopController.playerCoins(), greaterThan(coinsBeforeSell));
    expect(save.inventoryData.itemMap[ItemId.COPPER_ORE] ?? 0, oreBefore - 1);

    session.dispose();
  });

  testWidgets('holding a buy button buys repeatedly until released', (
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

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    save.inventoryData.itemMap[ItemId.COINS] = 10000;
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

    final buyButtons = find.textContaining('Buy ');
    await tester.ensureVisible(buyButtons.first);
    await tester.pumpAndSettle();

    final coinsBeforeHold = session.shopController.playerCoins();

    // hold past the long-press threshold, then keep pumping the repeat
    // interval while still down: each tick should buy again
    final gesture = await tester.startGesture(
      tester.getCenter(buyButtons.first),
    );
    await tester.pump(kLongPressTimeout + kPressTimeout);
    final coinsAfterFirstHit = session.shopController.playerCoins();
    expect(coinsAfterFirstHit, lessThan(coinsBeforeHold));

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
    final coinsAfterRepeats = session.shopController.playerCoins();
    expect(coinsAfterRepeats, lessThan(coinsAfterFirstHit));

    // releasing stops the repeat: coins stay put across further ticks
    await gesture.up();
    await tester.pump();
    final coinsAfterRelease = session.shopController.playerCoins();
    await tester.pump(const Duration(milliseconds: 500));
    expect(session.shopController.playerCoins(), coinsAfterRelease);

    session.dispose();
  });

  testWidgets('holding a buy button past one second speeds up the repeat', (
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

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    save.inventoryData.itemMap[ItemId.COINS] = 1000000;
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

    // top up the held slot so the fast phase isn't cut short by running
    // out of stock (a fresh restock only guarantees 1-10 units)
    final entry = session.shopController.stock().first;
    entry.count = 500;
    final price = session.shopController.buyPrice(entry.itemId);

    final buyButtons = find.textContaining('Buy ');
    await tester.ensureVisible(buyButtons.first);
    await tester.pumpAndSettle();

    int coins() => session.shopController.playerCoins();

    final gesture = await tester.startGesture(
      tester.getCenter(buyButtons.first),
    );

    // trips the long-press threshold: fires the first buy and starts the
    // normal 120ms-interval repeat
    await tester.pump(kLongPressTimeout + kPressTimeout);
    final coinsAfterFirstHit = coins();

    // stay well inside the first second, still on the normal interval
    await tester.pump(const Duration(milliseconds: 240));
    final boughtNormalPhase = (coinsAfterFirstHit - coins()) ~/ price;

    // cross the one-second mark, then measure a fresh window once the
    // fast interval has taken over
    await tester.pump(const Duration(milliseconds: 900));
    final coinsAtAccel = coins();
    await tester.pump(const Duration(milliseconds: 150));
    final boughtFastPhase = (coinsAtAccel - coins()) ~/ price;

    // the fast interval is 8x quicker (120ms -> 15ms), so even a shorter
    // window should buy several times as much
    expect(boughtFastPhase, greaterThan(boughtNormalPhase * 3));

    await gesture.up();
    session.dispose();
  });
}
