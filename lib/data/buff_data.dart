import '../catalogs/item_catalog.dart';
import '../catalogs/zone_catalog.dart';

class BuffData {
  final Map<ZoneId, Map<ItemId, ZoneBuffItem>> zoneBuffs = {};

  final Map<ItemId, BuffItem> globalBuffs = {};
}
