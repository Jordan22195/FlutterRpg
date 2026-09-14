import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/shop_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/shop_screen.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';
import 'package:rpg/utilities/image_resolver.dart';

/// The shop screen's sort button. One control orders every list on the
/// screen — the shelf and both halves of the sell side — because a shelf
/// that can hold the whole item catalog is not readable in catalog order.
void main() {
  final shopService = ShopService(inventoryService: InventoryService());

  group('ordering', () {
    List<ShopStockSlot> shelf(List<ItemId> ids) => [
      for (final id in ids) ShopStockSlot(itemId: id, count: 1),
    ];

    // deliberately neither alphabetical nor by value
    final ids = [
      ItemId.IRON_HELMET,
      ItemId.COOKED_MINNOW,
      ItemId.LOGS,
      ItemId.CHICKEN_MEAT,
    ];

    List<ItemId> order(ShopSortMode mode) => shopService
        .sortedForDisplay(shelf(ids), mode, (slot) => slot.itemId)
        .map((slot) => slot.itemId)
        .toList();

    test('the default ordering is the one the list came in', () {
      expect(order(ShopSortMode.CATALOG), ids);
    });

    test('by name is alphabetical on the name the row shows', () {
      final names = shopService
          .sortedForDisplay(shelf(ids), ShopSortMode.NAME, (s) => s.itemId)
          .map((slot) => slot.itemId.definition.name)
          .toList();
      expect(names, ['Chicken Meat', 'Cooked Minnow', 'Iron Helmet', 'Logs']);
    });

    test('by value is dearest first', () {
      final byValue = [...ids]
        ..sort((a, b) => b.definition.value.compareTo(a.definition.value));
      expect(order(ShopSortMode.VALUE), byValue);
      // the dearest of the four leads, so this is not merely self-consistent
      expect(order(ShopSortMode.VALUE).first, ItemId.IRON_HELMET);
    });

    test('rows come back as the same objects, so buying still works', () {
      final rows = shelf(ids);
      final sorted = shopService.sortedForDisplay(
        rows,
        ShopSortMode.NAME,
        (slot) => slot.itemId,
      );
      for (final row in rows) {
        expect(sorted.any((s) => identical(s, row)), isTrue);
      }
    });

    test('ties keep the order they came in', () {
      // two pieces of one item: same name, same value
      final first = ItemId.CHICKEN_CHARM.build() as EquipmentItem;
      final second = ItemId.CHICKEN_CHARM.build() as EquipmentItem;
      second.quality = Rarity.EPIC;

      for (final mode in [ShopSortMode.NAME, ShopSortMode.VALUE]) {
        final sorted = shopService.sortedForDisplay(
          [first, second],
          mode,
          (item) => item.id,
        );
        expect(sorted.first, same(first), reason: '$mode is not stable');
      }
    });
  });

  test('buying off a sorted shelf takes the row that was tapped', () {
    final def = EntityId.TRADING_POST.definition as ShopEntityDefinition;
    final shop = def.toEntity(EntityId.TRADING_POST) as ShopEntity;
    shopService.restockIfDue(shop, def, now: DateTime(2026, 1, 1));

    final inventory = InventoryData(itemMap: {ItemId.COINS: 1000000});
    final sorted = shopService.sortedForDisplay(
      shop.stock,
      ShopSortMode.NAME,
      (slot) => slot.itemId,
    );

    // the sorted shelf is a different order from the one the shop holds, so
    // a sort that handed back copies would sell something else entirely
    final row = sorted.first;
    expect(shopService.buyItem(shop, row, def, inventory), isTrue);
    expect(
      inventory.equipment.map((e) => e.id),
      contains(row.itemId),
      reason: 'the trading post sells equipment only',
    );
    expect(
      shop.stock.map((s) => s.itemId),
      isNot(contains(row.itemId)),
      reason: 'the single piece on that row came off the shelf',
    );
  });

  group('the screen', () {
    testWidgets('the sort button reorders the shelf and the sell list', (
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
      EnumImageProviderLookup.register<SkillId>(
        SkillController.imageProviderFor,
      );

      save.inventoryData.itemMap[ItemId.COINS] = 10000;
      save.inventoryData.itemMap[ItemId.LOGS] = 5;
      save.inventoryData.itemMap[ItemId.COOKED_MINNOW] = 5;
      save.inventoryData.itemMap[ItemId.CHICKEN_MEAT] = 5;
      save.playerData.currentZoneId = ZoneId.DEV_FOREST;
      save.playerData.currentEntityViewId = EntityId.TRADING_POST;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorldController>.value(
              value: session.worldController,
            ),
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

      final controller = session.shopController;
      expect(controller.sortMode(), ShopSortMode.CATALOG);
      // the button wears the ordering in force
      expect(find.text('Default'), findsOneWidget);

      // open the menu and pick Name
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      expect(controller.sortMode(), ShopSortMode.NAME);
      expect(find.text('Name'), findsOneWidget, reason: 'button label');

      List<String> shelfNames() =>
          controller.stock().map((s) => s.itemId.definition.name).toList();
      List<String> sellNames() =>
          controller.sellableItems().map((s) => s.id.definition.name).toList();

      expect(shelfNames(), _ascending(shelfNames()));
      expect(sellNames(), _ascending(sellNames()));

      // and by value, dearest first, on both lists
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Value').last);
      await tester.pumpAndSettle();

      expect(controller.sortMode(), ShopSortMode.VALUE);
      List<int> values(List<ObjectStack<ItemId>> rows) =>
          rows.map((s) => s.id.definition.value).toList();
      final sellValues = values(controller.sellableItems());
      expect(sellValues, [...sellValues]..sort((a, b) => b.compareTo(a)));

      final shelfValues = controller
          .stock()
          .map((s) => s.itemId.definition.value)
          .toList();
      expect(shelfValues, [...shelfValues]..sort((a, b) => b.compareTo(a)));

      session.dispose();
    });
  });
}

List<String> _ascending(List<String> names) =>
    [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
