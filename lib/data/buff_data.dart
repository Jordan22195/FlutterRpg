import '../catalogs/item_catalog.dart';
import '../catalogs/zone_catalog.dart';

class BuffData {
  final Map<ZoneId, Map<ItemId, BuffItem>> zoneBuffs = {};

  final Map<ItemId, BuffItem> globalBuffs = {};
  BuffItem campfireBuff = BuffItem(
    id: ItemId.NULL,
    skillBonus: {},
    value: 0,
    name: "Campfire Warmth",
    duration: Duration.zero,
  );
}
