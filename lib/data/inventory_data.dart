import '../catalogs/items/items.dart';

class InventoryData {
  /// Stackable items (materials, food, ...), stored as counts.
  Map<ItemId, int> itemMap = {};

  /// Unique equipment instances (armor/weapons). Each carries its own
  /// quality and enchantment, so they never stack.
  List<EquipmentItem> equipment = [];

  /// Every item the player has ever had come into the bag, kept after the
  /// item itself is sold, eaten or salvaged, with each rarity a piece of
  /// gear has come in at. Stackables carry no rarity, so theirs is empty.
  /// It is what a dungeon's unique loot reads as collected. Saves from
  /// before it was kept are seeded on load from what they hold
  /// (GameSessionFactory.create).
  Map<ItemId, Set<Rarity>> obtained;

  InventoryData({
    required this.itemMap,
    List<EquipmentItem>? equipment,
    Map<ItemId, Set<Rarity>>? obtained,
  }) : equipment = equipment ?? [],
       obtained = obtained ?? {};

  /// Logs [id] as obtained, at [rarity] when it is gear.
  void recordObtained(ItemId id, [Rarity? rarity]) {
    if (id == ItemId.NULL) return;
    final rarities = obtained[id] ??= {};
    if (rarity != null) rarities.add(rarity);
  }

  Map<String, dynamic> toJson() {
    return {
      'items': itemMap.map(
        (key, count) => MapEntry(
          key.name, // enum → string
          count,
        ),
      ),
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'obtained': {
        for (final MapEntry(key: id, value: rarities) in obtained.entries)
          id.name: [for (final r in rarities) r.name],
      },
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
      final id = ItemId.byName(entry.key);
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

    // tolerated when missing: older saves never kept it. a bare list of
    // names is the first form it took, before rarities were kept: those
    // items stay obtained, at no rarity known
    final obtained = <ItemId, Set<Rarity>>{};
    final rawObtained = json['obtained'];
    if (rawObtained is List) {
      for (final name in rawObtained) {
        final id = name is String ? ItemId.byName(name) : null;
        if (id != null) obtained[id] = {};
      }
    } else if (rawObtained is Map<String, dynamic>) {
      for (final MapEntry(key: name, value: raw) in rawObtained.entries) {
        final id = ItemId.byName(name);
        if (id == null) continue;
        obtained[id] = {
          if (raw is List)
            for (final r in raw)
              if (r is String) ?Rarity.values.asNameMap()[r],
        };
      }
    }

    return InventoryData(
      itemMap: itemMap,
      equipment: equipment,
      obtained: obtained,
    );
  }
}
