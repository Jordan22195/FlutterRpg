import 'dart:math';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/services/inventory_service.dart';

class ShopService {
  final InventoryService _inventoryService;

  ShopService({required InventoryService inventoryService})
    : _inventoryService = inventoryService;

  /// Buy price for one unit: the item's value plus the shop's markup.
  int buyPrice(ItemId itemId, ShopEntityDefinition def) {
    final value = ItemCatalog.buildItem(itemId).value;
    return (value * def.priceMarkup).ceil();
  }

  /// Sell price for one unit: the item's value.
  int sellPrice(ItemId itemId) {
    return ItemCatalog.buildItem(itemId).value;
  }

  /// Rerolls the shop's stock when its restock time has passed (or it
  /// has never stocked). Stock is [ShopEntityDefinition.stockSlots]
  /// distinct random items; equipment stocks a single piece, stackables
  /// stock 1-10 units.
  void restockIfDue(
    ShopEntity shop,
    ShopEntityDefinition def,
    ItemCatalog itemCatalog, {
    DateTime? now,
    Random? rng,
  }) {
    final time = now ?? DateTime.now();
    if (shop.nextRestockAt != null && time.isBefore(shop.nextRestockAt!)) {
      return;
    }

    final random = rng ?? Random();

    // sellable pool: every defined item except the currency itself
    final candidates = ItemId.values
        .where(
          (id) =>
              id != ItemId.NULL &&
              id != ItemId.COINS &&
              itemCatalog.definitionFor(id) != null,
        )
        .toList();

    shop.stock.clear();
    final slots = min(def.stockSlots, candidates.length);
    for (int i = 0; i < slots; i++) {
      final pick = candidates.removeAt(random.nextInt(candidates.length));
      final isEquipment = itemCatalog.definitionFor(pick) is EquipmentItemDefition;
      shop.stock.add(
        ShopStockEntry(
          itemId: pick,
          count: isEquipment ? 1 : 1 + random.nextInt(10),
        ),
      );
    }

    shop.nextRestockAt = time.add(def.restockInterval);
  }

  /// Buys one unit of [entry] from [shop]. Returns false when the shop
  /// is out of stock or the player can't afford it.
  bool buyItem(
    ShopEntity shop,
    ShopStockEntry entry,
    ShopEntityDefinition def,
    InventoryData inventoryState,
  ) {
    if (entry.count <= 0) return false;

    final price = buyPrice(entry.itemId, def);
    final coins = _inventoryService.getItemCount(inventoryState, ItemId.COINS);
    if (coins < price) return false;

    _inventoryService.removeItems(inventoryState, ItemId.COINS, price);

    entry.count -= 1;
    if (entry.count <= 0) {
      shop.stock.remove(entry);
    }

    // equipment is a unique instance; everything else is a stackable count
    final item = ItemCatalog.buildItem(entry.itemId);
    if (item is EquipmentItem) {
      _inventoryService.addEquipment(inventoryState, item);
    } else {
      _inventoryService.addItem(inventoryState, entry.itemId);
    }
    return true;
  }

  /// Sells one unit of the stackable [itemId] for its value in coins.
  /// Returns false when the player has none (or tries to sell coins).
  bool sellItem(ItemId itemId, InventoryData inventoryState) {
    if (itemId == ItemId.COINS) return false;
    if (_inventoryService.getItemCount(inventoryState, itemId) <= 0) {
      return false;
    }

    _inventoryService.removeItems(inventoryState, itemId, 1);
    _inventoryService.addItems(inventoryState, [
      ObjectStack(id: ItemId.COINS, count: sellPrice(itemId)),
    ]);
    return true;
  }

  /// Sells one piece off the equipment stack [instanceId] for its value.
  bool sellEquipment(String instanceId, InventoryData inventoryState) {
    final item = _inventoryService.takeOneEquipment(inventoryState, instanceId);
    if (item == null) return false;

    _inventoryService.addItems(inventoryState, [
      ObjectStack(id: ItemId.COINS, count: item.value),
    ]);
    return true;
  }
}
