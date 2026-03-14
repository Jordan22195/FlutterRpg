import '../catalogs/item_catalog.dart';
import '../catalogs/zone_catalog.dart';
import '../utilities/json_utils.dart';

class BuffData {
  final Map<ZoneId, Map<ItemId, ZoneBuffItem>> zoneBuffs;
  final Map<ItemId, BuffItem> globalBuffs;

  BuffData({
    Map<ZoneId, Map<ItemId, ZoneBuffItem>>? zoneBuffs,
    Map<ItemId, BuffItem>? globalBuffs,
  }) : zoneBuffs = zoneBuffs ?? {},
       globalBuffs = globalBuffs ?? {};

  Map<String, dynamic> toJson() {
    return {
      'zoneBuffs': zoneBuffs.map(
        (zoneId, itemMap) => MapEntry(
          zoneId.name,
          itemMap.map((itemId, buff) => MapEntry(itemId.name, buff.toJson())),
        ),
      ),
      'globalBuffs': globalBuffs.map(
        (itemId, buff) => MapEntry(itemId.name, buff.toJson()),
      ),
    };
  }

  factory BuffData.fromJson(Map<String, dynamic> json) {
    final zoneBuffsJson = JsonUtils.requireMap(json, 'zoneBuffs');
    final globalBuffsJson = JsonUtils.requireMap(json, 'globalBuffs');

    final Map<ZoneId, Map<ItemId, ZoneBuffItem>> parsedZoneBuffs = {};

    for (final entry in zoneBuffsJson.entries) {
      if (entry.key is! String) {
        throw FormatException('Invalid key in zoneBuffs. Expected String.');
      }

      if (entry.value is! Map) {
        throw FormatException(
          'Invalid value in zoneBuffs for key "${entry.key}". Expected object.',
        );
      }

      final zoneId = JsonUtils.parseZoneId(entry.key);

      parsedZoneBuffs[zoneId] = JsonUtils.parseMap<ItemId, ZoneBuffItem>(
        Map<String, dynamic>.from(entry.value),
        fieldName: 'zoneBuffs.${entry.key}',
        parseKey: (key) => JsonUtils.parseItemId(key),
        parseValue: (value) => ZoneBuffItem.fromJson(value),
      );
    }

    final parsedGlobalBuffs = JsonUtils.parseMap<ItemId, BuffItem>(
      globalBuffsJson,
      fieldName: 'globalBuffs',
      parseKey: (key) => JsonUtils.parseItemId(key),
      parseValue: (value) => BuffItem.fromJson(value),
    );

    return BuffData(zoneBuffs: parsedZoneBuffs, globalBuffs: parsedGlobalBuffs);
  }
}
