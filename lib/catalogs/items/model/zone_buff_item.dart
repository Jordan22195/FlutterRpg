import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/model/buff_item.dart';
import 'package:rpg/catalogs/items/model/fire_item.dart';

class ZoneBuffItem extends BuffItem {
  ZoneId zoneId;

  /// The zone entity this buff belongs to — for a fire, the firepit it is
  /// burning in. Assigned when the buff is created, not by the definition,
  /// because one definition can be applied at any number of entities.
  EntityId ownerEntityId;

  ZoneBuffItem({
    required super.id,
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    this.zoneId = ZoneId.NULL,
    this.ownerEntityId = EntityId.NULL,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'ZoneBuffItem';
    json['zoneId'] = zoneId.name;
    json['ownerEntityId'] = ownerEntityId.name;
    return json;
  }

  factory ZoneBuffItem.fromJson(Map<String, dynamic> json) {
    if (json['runtimeType'] == 'FireItem') return FireItem.fromJson(json);

    final baseItem = BuffItem.fromJson(json);

    final rawZoneId = json['zoneId'];
    if (rawZoneId is! String) {
      throw FormatException('Missing or invalid "zoneId". Expected String.');
    }

    final item = ZoneBuffItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      skillBonus: Map<SkillId, int>.from(baseItem.skillBonus),
      duration: baseItem.duration,
      zoneId: parseZoneId(rawZoneId),
      ownerEntityId: ownerEntityIdFromJson(json),
    );

    item.count = baseItem.count;
    item.expirationTime = baseItem.expirationTime;
    return item;
  }
}
