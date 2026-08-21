import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/model/equipment_item.dart';

class WeaponItem extends EquipmentItem {
  final Duration actionInterval;

  WeaponItem({
    required super.id,
    required super.name,
    required super.value,
    required super.armorSlot,
    required super.skillBonus,
    required this.actionInterval,
    super.quality,
    super.enchantName,
    super.enchantBonus,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'WeaponItem';
    json['actionIntervalMs'] = actionInterval.inMilliseconds;
    return json;
  }

  factory WeaponItem.fromJson(Map<String, dynamic> json) {
    final baseItem = EquipmentItem.fromJson(json);

    final item = WeaponItem(
      id: baseItem.id,
      name: baseItem.name,
      value: baseItem.value,
      armorSlot: baseItem.armorSlot,
      skillBonus: Map<SkillId, int>.from(baseItem.skillBonus),
      actionInterval: durationFromMilliseconds(json, 'actionIntervalMs'),
    );

    item.count = baseItem.count;
    item.readInstanceFieldsFromJson(json);
    return item;
  }

  /// Parses an equipment instance, dispatching on the serialized type.
  static EquipmentItem equipmentFromJson(Map<String, dynamic> json) {
    return json['runtimeType'] == 'WeaponItem'
        ? WeaponItem.fromJson(json)
        : EquipmentItem.fromJson(json);
  }

  @override
  WeaponItem copy() {
    return WeaponItem(
      id: id,
      name: name,
      value: value,
      armorSlot: armorSlot,
      skillBonus: Map.of(skillBonus),
      actionInterval: actionInterval,
      quality: quality,
      enchantName: enchantName,
      enchantBonus: Map.of(enchantBonus),
    );
  }
}
