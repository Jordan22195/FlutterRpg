import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final itemCatalog = ItemCatalog();
  final entityCatalog = EntityCatalog();
  final inventoryService = InventoryService();
  final shopService = ShopService(inventoryService: inventoryService);

  ShopEntityDefinition shopDef(EntityId id) =>
      entityCatalog.getDefinitionFor(id) as ShopEntityDefinition;

  test('the two dev-forest shops are shop definitions with expected config', () {
    final post = shopDef(EntityId.TRADING_POST);
    expect(post.restockInterval, const Duration(hours: 6));
    expect(post.stockSlots, 10);
    expect(post.priceMarkup, greaterThan(1.0));

    final merchant = shopDef(EntityId.WANDERING_MERCHANT);
    expect(merchant.restockInterval, const Duration(hours: 1));
    expect(merchant.priceMarkup, 1.5);
  });

  test('restock fills 10 distinct items and buy price beats sell price', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);

    final now = DateTime(2026, 1, 1);
    shopService.restockIfDue(
      shop,
      def,
      itemCatalog,
      now: now,
      rng: Random(42),
    );

    expect(shop.stock.length, 10);
    // distinct items
    final ids = shop.stock.map((s) => s.itemId).toSet();
    expect(ids.length, 10);
    // no coins on the shelf
    expect(ids.contains(ItemId.COINS), isFalse);
    // next restock is 6 hours out
    expect(shop.nextRestockAt, now.add(const Duration(hours: 6)));

    // markup: buy price is always >= sell price (the item's value)
    for (final entry in shop.stock) {
      final buy = shopService.buyPrice(entry.itemId, def);
      final sell = shopService.sellPrice(entry.itemId);
      expect(buy, greaterThanOrEqualTo(sell));
    }
  });

  test('restock does not reroll before the interval elapses', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);
    final now = DateTime(2026, 1, 1);

    shopService.restockIfDue(shop, def, itemCatalog, now: now, rng: Random(1));
    final firstStock = shop.stock.map((s) => s.itemId).toList();

    // one hour later: still within the 6h window, no reroll
    shopService.restockIfDue(
      shop,
      def,
      itemCatalog,
      now: now.add(const Duration(hours: 1)),
      rng: Random(2),
    );
    expect(shop.stock.map((s) => s.itemId).toList(), firstStock);

    // seven hours later: due, rerolls
    shopService.restockIfDue(
      shop,
      def,
      itemCatalog,
      now: now.add(const Duration(hours: 7)),
      rng: Random(2),
    );
    expect(shop.nextRestockAt, now.add(const Duration(hours: 13)));
  });

  test('buying deducts coins, grants the item, and depletes stock', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);
    final inventory = InventoryData(itemMap: {ItemId.COINS: 1000});

    shopService.restockIfDue(
      shop,
      def,
      itemCatalog,
      now: DateTime(2026, 1, 1),
      rng: Random(7),
    );

    final entry = shop.stock.first;
    final price = shopService.buyPrice(entry.itemId, def);
    final startCount = entry.count;

    expect(shopService.buyItem(shop, entry, def, inventory), isTrue);
    expect(inventory.itemMap[ItemId.COINS], 1000 - price);
    // the bought item landed in inventory (stackable) or equipment
    final gotStackable = (inventory.itemMap[entry.itemId] ?? 0) >= 1;
    final gotEquipment = inventory.equipment.any((e) => e.id == entry.itemId);
    expect(gotStackable || gotEquipment, isTrue);
    // stock decremented (entry removed if it hit zero)
    final remaining = shop.stock
        .where((s) => identical(s, entry))
        .fold<int>(0, (sum, s) => sum + s.count);
    expect(remaining == startCount - 1 || (startCount == 1 && remaining == 0),
        isTrue);
  });

  test('cannot buy without enough coins', () {
    final shop = shopDef(EntityId.WANDERING_MERCHANT)
        .toEntity(EntityId.WANDERING_MERCHANT);
    final def = shopDef(EntityId.WANDERING_MERCHANT);
    final inventory = InventoryData(itemMap: {ItemId.COINS: 0});

    shopService.restockIfDue(
      shop,
      def,
      itemCatalog,
      now: DateTime(2026, 1, 1),
      rng: Random(3),
    );

    final entry = shop.stock.first;
    expect(shopService.buyItem(shop, entry, def, inventory), isFalse);
    expect(inventory.itemMap[ItemId.COINS] ?? 0, 0);
  });

  test('selling a stackable item pays the item value in coins', () {
    final inventory =
        InventoryData(itemMap: {ItemId.COPPER_ORE: 3, ItemId.COINS: 0});
    final value = ItemCatalog.buildItem(ItemId.COPPER_ORE).value;

    expect(shopService.sellItem(ItemId.COPPER_ORE, inventory), isTrue);
    expect(inventory.itemMap[ItemId.COPPER_ORE], 2);
    expect(inventory.itemMap[ItemId.COINS], value);

    // cannot sell coins themselves
    expect(shopService.sellItem(ItemId.COINS, inventory), isFalse);
  });

  test('shop stock survives a save/load round trip', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);
    shopService.restockIfDue(
      shop,
      def,
      itemCatalog,
      now: DateTime(2026, 1, 1),
      rng: Random(9),
    );

    final restored =
        Entity.fromJson(shop.toJson()) as ShopEntity;
    expect(restored.stock.length, shop.stock.length);
    expect(restored.stock.first.itemId, shop.stock.first.itemId);
    expect(restored.stock.first.count, shop.stock.first.count);
    expect(restored.nextRestockAt, shop.nextRestockAt);
  });

  test('dev forest builds both shops as permanent entities', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    final devForest = save.worldData.zones.values.firstWhere(
      (z) => z.permanentEntities.any((e) => e is ShopEntity),
    );
    final shops =
        devForest.permanentEntities.whereType<ShopEntity>().toList();
    expect(shops.length, 2);

    session.dispose();
  });
}
