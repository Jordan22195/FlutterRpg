import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/model/item.dart';

class BuffItem extends Item {
  final Map<SkillId, int> skillBonus;
  Duration duration;
  DateTime expirationTime;

  BuffItem({
    required super.id,
    required super.name,
    required super.value,
    required this.skillBonus,
    required this.duration,
  }) : expirationTime = DateTime.now().add(duration);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'BuffItem';
    json['skillBonus'] = skillBonusToJson(skillBonus);
    json['durationMs'] = duration.inMilliseconds;
    json['expirationTime'] = expirationTime.toIso8601String();
    return json;
  }

  factory BuffItem.fromJson(Map<String, dynamic> json) {
    final baseItem = Item.fromJson(json);

    final item = BuffItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      skillBonus: skillBonusFromJson(json, 'skillBonus'),
      duration: durationFromMilliseconds(json, 'durationMs'),
    );

    item.count = baseItem.count;
    item.expirationTime = dateTimeFromJson(json, 'expirationTime');
    return item;
  }
}
