import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/model/buff_item.dart';
import 'package:rpg/catalogs/items/model/zone_buff_item.dart';

/// A fire burning in a firepit. [canCook] is what opens the cooking half of
/// the firepit screen; the COOKING entry in [skillBonus] is what makes a
/// better fire burn less food, via the buffed stat totals.
class FireItem extends ZoneBuffItem {
  final bool canCook;

  FireItem({
    required super.id,
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    super.zoneId,
    super.ownerEntityId,
    this.canCook = false,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'FireItem';
    json['canCook'] = canCook;
    return json;
  }

  factory FireItem.fromJson(Map<String, dynamic> json) {
    final baseItem = BuffItem.fromJson(json);

    final rawZoneId = json['zoneId'];
    if (rawZoneId is! String) {
      throw FormatException('Missing or invalid "zoneId". Expected String.');
    }

    final item = FireItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      skillBonus: Map<SkillId, int>.from(baseItem.skillBonus),
      duration: baseItem.duration,
      zoneId: parseZoneId(rawZoneId),
      ownerEntityId: ownerEntityIdFromJson(json),
      canCook: json['canCook'] == true,
    );

    item.count = baseItem.count;
    item.expirationTime = baseItem.expirationTime;
    return item;
  }
}
