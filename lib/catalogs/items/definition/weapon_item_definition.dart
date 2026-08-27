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
    required super.skillBonus,
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
    Map<SkillId, int>? skillBonus,
    Duration? actionInterval,
  }) {
    return WeaponItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      armorSlot: armorSlot ?? this.armorSlot,
      skillBonus: skillBonus ?? this.skillBonus,
      actionInterval: actionInterval ?? this.actionInterval,
    );
  }

  @override
  WeaponItem toItem(ItemId id) => WeaponItem(
    id: id,
    name: name,
    value: value,
    armorSlot: armorSlot,
    skillBonus: Map.of(skillBonus),
    actionInterval: actionInterval,
    quality: quality,
  );
}
