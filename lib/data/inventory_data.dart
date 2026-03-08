import '../catalogs/item_catalog.dart';

class InventoryData {
  Map<ItemId, int> itemMap = {};

  InventoryData({required this.itemMap});

  Map<String, dynamic> toJson() {
    return {
      'items': itemMap.map(
        (key, count) => MapEntry(
          key.name, // enum → string
          count,
        ),
      ),
    };
  }

  factory InventoryData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as Map<String, dynamic>? ?? {};

    return InventoryData(
      itemMap: rawItems.map(
        (key, value) => MapEntry(
          ItemId.values.firstWhere((e) => e.name == key),
          value as int,
        ),
      ),
    );
  }
}
