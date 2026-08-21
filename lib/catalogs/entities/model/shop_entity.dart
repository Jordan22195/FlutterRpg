import 'package:rpg/catalogs/entities/model/entity.dart';
import 'package:rpg/catalogs/entities/model/shop_stock_slot.dart';

// Shop Entity Class
// a permanent entity that trades items for coins. its stock and next
// restock time are runtime state, so they serialize with the zone;
// pricing and restock cadence live on the definition
class ShopEntity extends Entity {
  final List<ShopStockSlot> stock = [];
  DateTime? nextRestockAt;

  ShopEntity({required super.id, required super.name});

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'ShopEntity';
    json['stock'] = stock.map((s) => s.toJson()).toList();
    if (nextRestockAt != null) {
      json['nextRestockAt'] = nextRestockAt!.toIso8601String();
    }
    return json;
  }

  factory ShopEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = Entity.fromJson({...json, 'runtimeType': 'Entity'});

    final shop = ShopEntity(id: baseEntity.id, name: baseEntity.name);

    final rawStock = json['stock'];
    if (rawStock is List) {
      for (final rawEntry in rawStock) {
        if (rawEntry is Map<String, dynamic>) {
          shop.stock.add(ShopStockSlot.fromJson(rawEntry));
        }
      }
    }

    // optional: a shop that never restocked has no timestamp yet
    final rawRestock = json['nextRestockAt'];
    if (rawRestock is String) {
      shop.nextRestockAt = DateTime.tryParse(rawRestock);
    }

    return shop;
  }
}
