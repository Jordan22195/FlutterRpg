import 'dart:math';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/services/inventory_service.dart';

// ignore_for_file: constant_identifier_names

/// How a shop screen's rows are ordered. Purely how the counter is read —
/// it changes nothing about what is on it or what it costs.
enum ShopSortMode {
  /// The order the list was built in: catalog order for a shelf, and the
  /// order things were picked up in for the player's own bag.
  CATALOG('Default'),
  NAME('Name'),

  /// Dearest first, which is the end of a long shelf worth looking at.
  VALUE('Value');

  const ShopSortMode(this.label);

  /// What the sort button calls this ordering.
  final String label;
}

class ShopService {
  final InventoryService _inventoryService;

  ShopService({required InventoryService inventoryService})
    : _inventoryService = inventoryService;

  /// Buy price for one unit: the item's value plus the shop's markup.
  int buyPrice(ItemId itemId, ShopEntityDefinition def) {
    final value = itemId.build().value;
    return (value * def.priceMarkup).ceil();
  }

  /// Sell price for one unit: the item's value.
  int sellPrice(ItemId itemId) {
    return itemId.build().value;
  }

  /// Rerolls the shop's stock when its restock time has passed (or it
  /// has never stocked). Stock is [ShopEntityDefinition.stockSlots]
  /// distinct random items; equipment stocks a single piece, stackables
  /// stock 1-10 units.
  void restockIfDue(
    ShopEntity shop,
    ShopEntityDefinition def, {
    DateTime? now,
    Random? rng,
  }) {
    final time = now ?? DateTime.now();
    if (shop.nextRestockAt != null && time.isBefore(shop.nextRestockAt!)) {
      return;
    }

    final random = rng ?? Random();

    // draw without replacement from a *copy* of the pool — the pool belongs
    // to the catalog definition and is shared by every shop of this kind, so
    // draining it here would leave later restocks with nothing to stock.
    final candidates = [...def.shopStockPool];

    shop.stock.clear();
    final slots = min(def.stockSlots, candidates.length);

    // a shop with at least a slot per pool entry sells its whole pool, so
    // there is nothing to draw for: shelve it in catalog order instead, which
    // is the order the pool was written in and reads far better than a
    // shuffle on a shelf that holds everything anyway
    if (slots == candidates.length) {
      for (final entry in candidates) {
        shop.stock.add(entry.toSlot());
      }
    } else {
      for (int i = 0; i < slots; i++) {
        final pick = candidates.removeAt(random.nextInt(candidates.length));
        shop.stock.add(pick.toSlot());
      }
    }

    shop.nextRestockAt = time.add(def.restockInterval);
  }

  /// Reorders a list of shop rows for display. [itemIdOf] says which item
  /// a row is about, which is all any of the orderings need — so the shelf,
  /// the player's stackables and their equipment all sort through this one
  /// method.
  ///
  /// The rows themselves are handed back untouched, never copies: buying
  /// works off the identity of the [ShopStockSlot] the row was drawn from,
  /// so a sort that rebuilt its rows would sell the wrong thing.
  ///
  /// Sorting is stable, so rows that tie — two qualities of one piece, say —
  /// keep the order they came in.
  List<T> sortedForDisplay<T>(
    List<T> rows,
    ShopSortMode mode,
    ItemId Function(T row) itemIdOf,
  ) {
    if (mode == ShopSortMode.CATALOG) return List.unmodifiable(rows);

    // read straight off the definition rather than through build(): these
    // comparators run O(n log n) times over a shelf that can hold the whole
    // item catalog, and an item per comparison is an item too many
    final sorted = [...rows];
    switch (mode) {
      case ShopSortMode.NAME:
        sorted.sort(
          (a, b) => itemIdOf(a).definition.name.toLowerCase().compareTo(
            itemIdOf(b).definition.name.toLowerCase(),
          ),
        );
      case ShopSortMode.VALUE:
        sorted.sort(
          (a, b) => itemIdOf(
            b,
          ).definition.value.compareTo(itemIdOf(a).definition.value),
        );
      case ShopSortMode.CATALOG:
        break;
    }
    return List.unmodifiable(sorted);
  }

  /// Buys one unit of [entry] from [shop]. Returns false when the shop
  /// is out of stock or the player can't afford it.
  bool buyItem(
    ShopEntity shop,
    ShopStockSlot entry,
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
    final item = entry.itemId.build();
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
