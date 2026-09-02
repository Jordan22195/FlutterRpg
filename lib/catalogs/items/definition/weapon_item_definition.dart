import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/weapon_item.dart';
import 'package:rpg/catalogs/items/definition/equipment_item_definition.dart';

class WeaponItemDefinition extends EquipmentItemDefinition {
  final Duration actionInterval;

  const WeaponItemDefinition({
    required super.name,
    required super.value,
    required super.armorSlot,
    required super.fibLevel,
    required super.statWeights,
    required this.actionInterval,
    super.description,
    super.iconAsset,
    super.quality,
  });

  @override
  WeaponItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    ArmorSlots? armorSlot,
    int? fibLevel,
    Map<SkillId, int>? statWeights,
    Duration? actionInterval,
  }) {
    return WeaponItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      armorSlot: armorSlot ?? this.armorSlot,
      fibLevel: fibLevel ?? this.fibLevel,
      statWeights: statWeights ?? this.statWeights,
      actionInterval: actionInterval ?? this.actionInterval,
    );
  }

  @override
  WeaponItem toItem(ItemId id) => WeaponItem(id: id);
}
