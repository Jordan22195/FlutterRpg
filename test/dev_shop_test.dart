import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';

/// The dev shop sells the whole catalog. Its point is that nobody has to
/// keep it in sync: the shelf is [ItemId] itself, walked at read time, so
/// an item is buyable the moment its id exists.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryService = InventoryService();
  final shopService = ShopService(inventoryService: inventoryService);

  final def = EntityId.DEV_SHOP.definition as ShopEntityDefinition;

  /// Every id the dev shop is expected to carry: the catalog less the two
  /// sentinels, which are not items anyone can hold, and coins, which are
  /// what is being spent.
  final sellable = ItemId.values
      .where(
        (id) =>
            id != ItemId.NULL && id != ItemId.NULL_BUFF && id != ItemId.COINS,
      )
      .toList();

  test('the pool is the item catalog, not a hand-written list', () {
    expect(def, isA<DevShopEntityDefinition>());
    expect(def.shopStockPool.map((e) => e.itemId).toList(), sellable);
  });

  test('a restock puts the whole catalog on the shelf, in catalog order', () {
    final shop = def.toEntity(EntityId.DEV_SHOP) as ShopEntity;
    final now = DateTime(2026, 1, 1);

    shopService.restockIfDue(shop, def, now: now, rng: Random(7));

    expect(shop.stock.map((s) => s.itemId).toList(), sellable);
    expect(shop.nextRestockAt, now.add(def.restockInterval));
  });

  test('equipment stocks pieces, everything else stocks a deep stack', () {
    for (final entry in def.shopStockPool) {
      final expected = entry.itemId.definition is EquipmentItemDefinition
          ? 10
          : 1000;
      expect(entry.count, expected, reason: '${entry.itemId.name} stock depth');
    }
  });

  test('it sells at cost, so a dev pays value and nothing over', () {
    expect(def.priceMarkup, 1.0);
    for (final entry in def.shopStockPool) {
      expect(
        shopService.buyPrice(entry.itemId, def),
        shopService.sellPrice(entry.itemId),
      );
    }
  });

  test('buying takes coins and hands over the item', () {
    final shop = def.toEntity(EntityId.DEV_SHOP) as ShopEntity;
    shopService.restockIfDue(shop, def, now: DateTime(2026, 1, 1));

    final inventory = InventoryData(itemMap: {ItemId.COINS: 1000000});

    // a stackable lands as a count
    final logs = shop.stock.firstWhere((s) => s.itemId == ItemId.LOGS);
    expect(shopService.buyItem(shop, logs, def, inventory), isTrue);
    expect(inventoryService.getItemCount(inventory, ItemId.LOGS), 1);

    // equipment lands as a unique instance, not a count
    final helmet = shop.stock.firstWhere((s) => s.itemId == ItemId.IRON_HELMET);
    expect(shopService.buyItem(shop, helmet, def, inventory), isTrue);
    expect(inventoryService.getItemCount(inventory, ItemId.IRON_HELMET), 0);
    expect(inventory.equipment.map((e) => e.id), contains(ItemId.IRON_HELMET));
  });
}
