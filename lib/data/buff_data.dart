import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../catalogs/zones/zones.dart';
import '../utilities/json_utils.dart';

class BuffData {
  /// Zone buffs are keyed by the entity that owns them, not by item: two
  /// firepits in one zone can burn the same kind of fire independently, and
  /// lighting a new fire in a firepit replaces whatever it was burning.
  final Map<ZoneId, Map<EntityId, ZoneBuffItem>> zoneBuffs;
  final Map<ItemId, BuffItem> globalBuffs;

  BuffData({
    Map<ZoneId, Map<EntityId, ZoneBuffItem>>? zoneBuffs,
    Map<ItemId, BuffItem>? globalBuffs,
  }) : zoneBuffs = zoneBuffs ?? {},
       globalBuffs = globalBuffs ?? {};

  Map<String, dynamic> toJson() {
    return {
      'zoneBuffs': zoneBuffs.map(
        (zoneId, entityMap) => MapEntry(
          zoneId.name,
          entityMap.map(
            (entityId, buff) => MapEntry(entityId.name, buff.toJson()),
          ),
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

    final Map<ZoneId, Map<EntityId, ZoneBuffItem>> parsedZoneBuffs = {};

    for (final entry in zoneBuffsJson.entries) {
      if (entry.value is! Map) {
        throw FormatException(
          'Invalid value in zoneBuffs for key "${entry.key}". Expected object.',
        );
      }

      final zoneId = JsonUtils.parseZoneId(entry.key);
      final zoneMap = <EntityId, ZoneBuffItem>{};

      for (final buffEntry in Map<String, dynamic>.from(entry.value).entries) {
        final raw = buffEntry.value;
        if (raw is! Map) {
          throw FormatException(
            'Invalid value in "zoneBuffs.${entry.key}" for key '
            '"${buffEntry.key}". Expected object.',
          );
        }

        final buff = ZoneBuffItem.fromJson(Map<String, dynamic>.from(raw));

        // migration: these were keyed by ItemId and owned by a campfire
        // entity that no longer exists. the only zone buff that ever shipped
        // was a campfire, so anything unrecognised is re-homed on the firepit
        final ownerId =
            EntityId.values.asNameMap()[buffEntry.key] ?? EntityId.FIREPIT;
        buff.ownerEntityId = ownerId;
        buff.zoneId = zoneId;
        zoneMap[ownerId] = buff;
      }

      parsedZoneBuffs[zoneId] = zoneMap;
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
