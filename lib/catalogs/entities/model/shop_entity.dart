import 'package:rpg/catalogs/entities/model/entity.dart';
import 'package:rpg/catalogs/entities/model/shop_stock_slot.dart';

// Shop Entity Class
// a permanent entity that trades items for coins. its stock and next
// restock time are runtime state, so they serialize with the zone;
// pricing and restock cadence live on the definition
class ShopEntity extends Entity {
  final List<ShopStockSlot> stock = [];
  DateTime? nextRestockAt;

  ShopEntity({required super.id});

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['stock'] = stock.map((s) => s.toJson()).toList();
    if (nextRestockAt != null) {
      json['nextRestockAt'] = nextRestockAt!.toIso8601String();
    }
    return json;
  }

  /// Overlays the saved shelf onto a freshly built shop.
  void readShopStateFromJson(Map<String, dynamic> json) {
    final rawStock = json['stock'];
    if (rawStock is List) {
      stock.clear();
      for (final rawEntry in rawStock) {
        if (rawEntry is Map<String, dynamic>) {
          stock.add(ShopStockSlot.fromJson(rawEntry));
        }
      }
    }

    // optional: a shop that never restocked has no timestamp yet
    final rawRestock = json['nextRestockAt'];
    if (rawRestock is String) {
      nextRestockAt = DateTime.tryParse(rawRestock);
    }
  }
}
