import '../catalogs/item_catalog.dart';

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

  factory InventoryData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as Map<String, dynamic>? ?? {};

    // tolerated when missing: older saves stored equipment as counts
    // in the item map (migrated in GameSessionFactory.create)
    final rawEquipment = json['equipment'];
    final equipment = <EquipmentItem>[];
    if (rawEquipment is List) {
      for (final entry in rawEquipment) {
        if (entry is Map<String, dynamic>) {
          equipment.add(WeaponItem.equipmentFromJson(entry));
        }
      }
    }

    return InventoryData(
      itemMap: rawItems.map(
        (key, value) => MapEntry(
          ItemId.values.firstWhere((e) => e.name == key),
          value as int,
        ),
      ),
      equipment: equipment,
    );
  }
}
