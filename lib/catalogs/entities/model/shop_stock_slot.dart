import 'package:rpg/catalogs/items/items.dart';

/// One line of what a shop currently has on the shelf. Runtime state: the
/// count drops as the player buys, and it serializes with the zone.
class ShopStockSlot {
  final ItemId itemId;
  int count;

  ShopStockSlot({required this.itemId, required this.count});

  Map<String, dynamic> toJson() {
    return {'itemId': itemId.name, 'count': count};
  }

  factory ShopStockSlot.fromJson(Map<String, dynamic> json) {
    final rawItemId = json['itemId'];
    final rawCount = json['count'];

    if (rawItemId is! String) {
      throw FormatException('Missing or invalid "itemId". Expected String.');
    }
    if (rawCount is! int) {
      throw FormatException('Missing or invalid "count". Expected int.');
    }

    final itemId = ItemId.values.firstWhere(
      (i) => i.name == rawItemId,
      orElse: () => throw FormatException('Invalid ItemId "$rawItemId".'),
    );

    return ShopStockSlot(itemId: itemId, count: rawCount);
  }
}
