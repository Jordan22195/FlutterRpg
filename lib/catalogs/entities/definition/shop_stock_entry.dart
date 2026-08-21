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

  const ShopStockEntry({required this.itemId, required this.count});

  ShopStockEntry copyWith({ItemId? itemId, int? count}) =>
      ShopStockEntry(itemId: itemId ?? this.itemId, count: count ?? this.count);

  /// A fresh mutable shelf slot for this pool entry.
  ShopStockSlot toSlot() => ShopStockSlot(itemId: itemId, count: count);
}
