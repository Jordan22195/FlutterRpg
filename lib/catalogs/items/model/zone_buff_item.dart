import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/model/buff_item.dart';
import 'package:rpg/catalogs/items/model/item.dart';

class ZoneBuffItem extends BuffItem {
  ZoneId zoneId;

  /// The zone entity this buff belongs to — for a fire, the firepit it is
  /// burning in. Assigned when the buff is created, not by the definition,
  /// because one definition can be applied at any number of entities.
  EntityId ownerEntityId;

  ZoneBuffItem({
    required super.id,
    super.fuelUnits,
    this.zoneId = ZoneId.NULL,
    this.ownerEntityId = EntityId.NULL,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['zoneId'] = zoneId.name;
    json['ownerEntityId'] = ownerEntityId.name;
    return json;
  }

  /// Restores where the buff is applied. Both are tolerated as absent:
  /// [BuffData.fromJson] re-homes an unrecognised owner on the firepit and
  /// stamps the zone from the key it was filed under.
  void readZoneStateFromJson(Map<String, dynamic> json) {
    final rawZoneId = json['zoneId'];
    if (rawZoneId is String) {
      zoneId = parseZoneId(rawZoneId);
    }
    ownerEntityId = ownerEntityIdFromJson(json);
  }

  factory ZoneBuffItem.fromJson(Map<String, dynamic> json) {
    final item = Item.fromJson(json);
    if (item is! ZoneBuffItem) {
      throw FormatException('ItemId "${item.id.name}" is not a zone buff.');
    }
    return item;
  }
}
