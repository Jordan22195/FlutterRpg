import '../catalogs/items/items.dart';

class InventoryData {
  /// Stackable items (materials, food, ...), stored as counts.
  Map<ItemId, int> itemMap = {};

  /// Unique equipment instances (armor/weapons). Each carries its own
  /// quality and enchantment, so they never stack.
  List<EquipmentItem> equipment = [];

  InventoryData({required this.itemMap, List<EquipmentItem>? equipment})
    : equipment = equipment ?? [];

  Map<String, dynamic> toJson() {
    return {
      'items': itemMap.map(
        (key, count) => MapEntry(
          key.name, // enum → string
          count,
        ),
      ),
      'equipment': equipment.map((e) => e.toJson()).toList(),
    };
  }

  /// An item id the catalog has since retired is skipped rather than
  /// thrown on, the way `Zone.fromJson` already skips retired entities.
  /// Without this, removing an id takes down every save that holds one —
  /// and a bare `firstWhere` throws `StateError`, which the bootstrap's
  /// `FormatException` fallback in main.dart would not even catch.
  factory InventoryData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as Map<String, dynamic>? ?? {};

    final itemMap = <ItemId, int>{};
    for (final entry in rawItems.entries) {
      final id = ItemId.values.asNameMap()[entry.key];
      final count = entry.value;
      if (id == null || count is! int) continue;
      itemMap[id] = count;
    }

    // tolerated when missing: older saves stored equipment as counts
    // in the item map (migrated in GameSessionFactory.create)
    final rawEquipment = json['equipment'];
    final equipment = <EquipmentItem>[];
    if (rawEquipment is List) {
      for (final entry in rawEquipment) {
        if (entry is! Map<String, dynamic>) continue;
        try {
          equipment.add(WeaponItem.equipmentFromJson(entry));
        } on FormatException {
          continue;
        }
      }
    }

    return InventoryData(itemMap: itemMap, equipment: equipment);
  }
}
