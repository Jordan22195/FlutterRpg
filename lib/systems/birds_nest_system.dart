import '../catalogs/drop_tables.dart';
import '../catalogs/items/items.dart';
import '../data/ObjectStack.dart';
import '../data/chest_loot.dart';
import '../data/inventory_data.dart';
import '../services/inventory_service.dart';
import '../services/weighted_drop_table_service.dart';

/// Bird's nests: woodcutting's treasure chests. A tree sheds one now and
/// then, and opening it from the bag rolls [openableRolls] - a lining of
/// fire reagents, a long shot at the Woodcutter's set of the nest's tier,
/// and a longer one at a gem. It pays out the way a dungeon chest does, so
/// it opens in the same dialog. Mining's geodes open the same way, so this
/// system opens those too (see geodeRolls).
class BirdsNestSystem {
  final InventoryService _inventoryService;
  final WeightedDropTableService _dropTableService;

  BirdsNestSystem({
    required InventoryService inventoryService,
    required WeightedDropTableService dropTableService,
  }) : _inventoryService = inventoryService,
       _dropTableService = dropTableService;

  static bool isNest(ItemId id) => openableRolls.containsKey(id);

  /// Opens up to [max] of the [nest]s held (all of them when null) and
  /// returns what came out, totalled by item and quality. Equipment arrives
  /// at the quality its line names.
  List<ChestLoot> open(ItemId nest, InventoryData inventoryState, {int? max}) {
    final rolls = openableRolls[nest];
    if (rolls == null) return const [];
    final held = _inventoryService.getItemCount(inventoryState, nest);
    final count = max == null || max > held ? held : max;
    if (count <= 0) return const [];
    _inventoryService.removeItems(inventoryState, nest, count);

    final totals = <(ItemId, Rarity), int>{};
    for (final drop in _dropTableService.rollBonusMulitpleTimes(count, rolls)) {
      final item = drop.id.id;
      if (drop.count <= 0 || item == ItemId.NULL) continue;
      final built = item.build();
      final Rarity rarity;
      if (built is EquipmentItem) {
        rarity = drop.id.rarity;
        built.quality = rarity;
        built.count = drop.count;
        _inventoryService.addEquipment(inventoryState, built);
      } else {
        rarity = item.definition.quality;
        _inventoryService.addItems(inventoryState, [
          ObjectStack<ItemId>(id: item, count: drop.count),
        ]);
      }
      totals[(item, rarity)] = (totals[(item, rarity)] ?? 0) + drop.count;
    }
    return [
      for (final entry in totals.entries)
        ChestLoot(id: entry.key.$1, rarity: entry.key.$2, count: entry.value),
    ];
  }
}
