import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryService = InventoryService();
  final shopService = ShopService(inventoryService: inventoryService);

  ShopEntityDefinition shopDef(EntityId id) =>
      id.definition as ShopEntityDefinition;

  test(
    'the two dev-forest shops are shop definitions with expected config',
    () {
      final post = shopDef(EntityId.TRADING_POST);
      expect(post.restockInterval, const Duration(hours: 6));
      expect(post.stockSlots, 10);
      expect(post.priceMarkup, greaterThan(1.0));

      final merchant = shopDef(EntityId.WANDERING_MERCHANT);
      expect(merchant.restockInterval, const Duration(hours: 1));
      expect(merchant.priceMarkup, 1.5);
    },
  );

  test(
    'South Haven mining shop shelves the whole mining pool every restock',
    () {
      expect(
        ZoneId.SOUTH_HAVEN.definition.permanentEntities,
        contains(EntityId.MINING_SHOP),
      );

      final def = shopDef(EntityId.MINING_SHOP);
      final shop = def.toEntity(EntityId.MINING_SHOP);
      shopService.restockIfDue(
        shop,
        def,
        now: DateTime(2026, 1, 1),
        rng: Random(1),
      );

      final counts = {for (final s in shop.stock) s.itemId: s.count};
      expect(counts.length, 19);
      for (final ore in [ItemId.COPPER_ORE, ItemId.IRON_ORE, ItemId.COAL]) {
        expect(counts[ore], 200);
      }
      expect(
        counts.keys,
        containsAll([
          ItemId.BASIC_MINERS_HAT,
          ItemId.NOVICE_MINERS_CLOAK,
          ItemId.COPPER_PICKAXE,
          ItemId.IRON_PICKAXE,
          ItemId.STEEL_PICKAXE,
          ItemId.MITHRIL_PICKAXE,
        ]),
      );
    },
  );

  test('restock fills 10 distinct items and buy price beats sell price', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);

    final now = DateTime(2026, 1, 1);
    shopService.restockIfDue(shop, def, now: now, rng: Random(42));

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

    shopService.restockIfDue(shop, def, now: now, rng: Random(1));
    final firstStock = shop.stock.map((s) => s.itemId).toList();

    // one hour later: still within the 6h window, no reroll
    shopService.restockIfDue(
      shop,
      def,
      now: now.add(const Duration(hours: 1)),
      rng: Random(2),
    );
    expect(shop.stock.map((s) => s.itemId).toList(), firstStock);

    // seven hours later: due, rerolls
    shopService.restockIfDue(
      shop,
      def,
      now: now.add(const Duration(hours: 7)),
      rng: Random(2),
    );
    expect(shop.nextRestockAt, now.add(const Duration(hours: 13)));
  });

  test('buying deducts coins, grants the item, and depletes stock', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);
    // well over any one price, so a purchase never spends the coins to zero
    final inventory = InventoryData(itemMap: {ItemId.COINS: 100000});

    shopService.restockIfDue(
      shop,
      def,
      now: DateTime(2026, 1, 1),
      rng: Random(7),
    );

    final entry = shop.stock.first;
    final price = shopService.buyPrice(entry.itemId, def);
    final startCount = entry.count;

    expect(shopService.buyItem(shop, entry, def, inventory), isTrue);
    expect(inventory.itemMap[ItemId.COINS], 100000 - price);
    // the bought item landed in inventory (stackable) or equipment
    final gotStackable = (inventory.itemMap[entry.itemId] ?? 0) >= 1;
    final gotEquipment = inventory.equipment.any((e) => e.id == entry.itemId);
    expect(gotStackable || gotEquipment, isTrue);
    // stock decremented, the slot still on the shelf
    expect(shop.stock, contains(same(entry)));
    expect(entry.count, startCount - 1);
  });

  test('a price override replaces value plus markup, and 0 is free', () {
    final def = shopDef(EntityId.FARMER);
    final shop = def.toEntity(EntityId.FARMER);
    // no coins at all: a free item must still sell
    final inventory = InventoryData(itemMap: {});

    // the farmer's pool fits his shelf, so a restock shelves all of it
    shopService.restockIfDue(shop, def, now: DateTime(2026, 1, 1));
    final chicken = shop.stock.singleWhere(
      (s) => s.itemId == ItemId.COOKED_CHICKEN,
    );
    expect(chicken.count, 5);
    expect(shopService.buyPrice(ItemId.COOKED_CHICKEN, def), 0);

    expect(shopService.buyItem(shop, chicken, def, inventory), isTrue);
    expect(inventory.itemMap[ItemId.COOKED_CHICKEN], 1);
    expect(chicken.count, 4);

    // an entry without an override still pays value plus markup
    expect(
      shopService.buyPrice(ItemId.LOGS, def),
      (ItemId.LOGS.build().value * def.priceMarkup).ceil(),
    );
  });

  test('a bought-out slot stays on the shelf at zero, and sells no more', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);
    final inventory = InventoryData(itemMap: {ItemId.COINS: 1000000});

    shopService.restockIfDue(
      shop,
      def,
      now: DateTime(2026, 1, 1),
      rng: Random(7),
    );
    final entry = shop.stock.first;
    final slots = shop.stock.length;

    // buy it out
    while (entry.count > 0) {
      expect(shopService.buyItem(shop, entry, def, inventory), isTrue);
    }

    // it is still there, at zero, in its place
    expect(shop.stock.length, slots);
    expect(shop.stock.first, same(entry));
    expect(entry.count, 0);

    // and buying from it again takes nothing
    final coins = inventory.itemMap[ItemId.COINS];
    expect(shopService.buyItem(shop, entry, def, inventory), isFalse);
    expect(inventory.itemMap[ItemId.COINS], coins);
  });

  test('cannot buy without enough coins', () {
    final shop = shopDef(
      EntityId.WANDERING_MERCHANT,
    ).toEntity(EntityId.WANDERING_MERCHANT);
    final def = shopDef(EntityId.WANDERING_MERCHANT);
    final inventory = InventoryData(itemMap: {ItemId.COINS: 0});

    shopService.restockIfDue(
      shop,
      def,
      now: DateTime(2026, 1, 1),
      rng: Random(3),
    );

    final entry = shop.stock.first;
    expect(shopService.buyItem(shop, entry, def, inventory), isFalse);
    expect(inventory.itemMap[ItemId.COINS] ?? 0, 0);
  });

  test('selling a stackable item pays the item value in coins', () {
    final inventory = InventoryData(
      itemMap: {ItemId.COPPER_ORE: 3, ItemId.COINS: 0},
    );
    final value = ItemId.COPPER_ORE.build().value;

    expect(shopService.sellItem(ItemId.COPPER_ORE, inventory), isTrue);
    expect(inventory.itemMap[ItemId.COPPER_ORE], 2);
    expect(inventory.itemMap[ItemId.COINS], value);

    // cannot sell coins themselves
    expect(shopService.sellItem(ItemId.COINS, inventory), isFalse);
  });

  test('buying a whole slot stops at the slot or the purse', () {
    final def = shopDef(EntityId.MINING_SHOP);
    final shop = def.toEntity(EntityId.MINING_SHOP);
    shopService.restockIfDue(
      shop,
      def,
      now: DateTime(2026, 1, 1),
      rng: Random(1),
    );
    final entry = shop.stock.firstWhere((s) => s.itemId == ItemId.COPPER_ORE);
    final price = shopService.buyPrice(entry.itemId, def);
    expect(price, greaterThan(0));
    final slot = entry.count;

    // a purse short of the whole slot buys what it covers, and no more
    final poor = InventoryData(itemMap: {ItemId.COINS: price * 3 + 1});
    expect(shopService.affordableCount(entry, def, poor), 3);
    expect(shopService.buyItems(shop, entry, def, poor, entry.count), 3);
    expect(poor.itemMap[ItemId.COPPER_ORE], 3);
    expect(poor.itemMap[ItemId.COINS], 1);
    expect(entry.count, slot - 3);

    // a deep purse takes the rest of the slot
    final rich = InventoryData(itemMap: {ItemId.COINS: price * slot * 2});
    expect(shopService.affordableCount(entry, def, rich), slot - 3);
    expect(
      shopService.buyItems(shop, entry, def, rich, entry.count),
      slot - 3,
    );
    expect(entry.count, 0);
    expect(shopService.affordableCount(entry, def, rich), 0);
  });

  test('selling a whole stack pays for every unit, and no more', () {
    final inventory = InventoryData(
      itemMap: {ItemId.COPPER_ORE: 7, ItemId.COINS: 0},
    );
    final value = ItemId.COPPER_ORE.build().value;

    // asking for more than is held sells what there is
    expect(shopService.sellItems(ItemId.COPPER_ORE, 100, inventory), 7);
    expect(inventory.itemMap[ItemId.COPPER_ORE] ?? 0, 0);
    expect(inventory.itemMap[ItemId.COINS], value * 7);

    // nothing left: nothing sold, nothing paid
    expect(shopService.sellItems(ItemId.COPPER_ORE, 1, inventory), 0);
    expect(inventory.itemMap[ItemId.COINS], value * 7);

    // and coins are never for sale
    expect(shopService.sellItems(ItemId.COINS, 5, inventory), 0);
  });

  test('selling an equipment stack sells every piece in it', () {
    final inventory = InventoryData(itemMap: {ItemId.COINS: 0});
    final helmet = ItemId.IRON_HELMET.build() as EquipmentItem;
    helmet.count = 3;
    inventoryService.addEquipment(inventory, helmet);

    expect(shopService.sellEquipmentStack(helmet.instanceId, inventory), 3);
    expect(inventory.equipment, isEmpty);
    expect(inventory.itemMap[ItemId.COINS], helmet.value * 3);
  });

  test('shop stock survives a save/load round trip', () {
    final shop = shopDef(EntityId.TRADING_POST).toEntity(EntityId.TRADING_POST);
    final def = shopDef(EntityId.TRADING_POST);
    shopService.restockIfDue(
      shop,
      def,
      now: DateTime(2026, 1, 1),
      rng: Random(9),
    );

    final restored = Entity.fromJson(shop.toJson()) as ShopEntity;
    expect(restored.stock.length, shop.stock.length);
    expect(restored.stock.first.itemId, shop.stock.first.itemId);
    expect(restored.stock.first.count, shop.stock.first.count);
    expect(restored.nextRestockAt, shop.nextRestockAt);
  });

  test('dev forest builds its shops as permanent entities', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    // select by id: several zones now carry a shop, so "the first zone
    // with any shop" would land on the farm or South Haven instead.
    final devForest = save.worldData.zones[ZoneId.DEV_FOREST]!;
    final shops = devForest.permanentEntities.whereType<ShopEntity>().toList();
    expect(shops.map((s) => s.id).toSet(), {
      EntityId.TRADING_POST,
      EntityId.WANDERING_MERCHANT,
      EntityId.DEV_SHOP,
    });

    session.dispose();
  });
}
