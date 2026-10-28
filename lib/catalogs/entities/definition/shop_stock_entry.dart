import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/entities/model/shop_stock_slot.dart';

// one item stack a shop currently offers
/// One line of a shop's stock *pool* — what the shop is able to sell, and
/// how many of it a restock puts on the shelf. Part of the definition, so
/// it is const and never changes: buying from a shop consumes a
/// [ShopStockSlot], not this.
class ShopStockEntry {
  final ItemId itemId;
  final int count;

  /// What one unit costs, in coins, in place of the item's value plus the
  /// shop's markup. Null for the usual pricing; 0 gives it away. Read off the
  /// pool by item rather than carried on the [ShopStockSlot], so a shelf saved
  /// before an override was set still sells at the new price.
  final int? priceOverride;

  const ShopStockEntry({
    required this.itemId,
    required this.count,
    this.priceOverride,
  });

  ShopStockEntry copyWith({ItemId? itemId, int? count, int? priceOverride}) =>
      ShopStockEntry(
        itemId: itemId ?? this.itemId,
        count: count ?? this.count,
        priceOverride: priceOverride ?? this.priceOverride,
      );

  /// A fresh mutable shelf slot for this pool entry.
  ShopStockSlot toSlot() => ShopStockSlot(itemId: itemId, count: count);
}
