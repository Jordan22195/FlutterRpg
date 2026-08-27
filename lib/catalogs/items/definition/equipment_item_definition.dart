import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/items/item_quality.dart';
import 'package:rpg/catalogs/items/model/equipment_item.dart';
import 'package:rpg/catalogs/items/definition/item_definition.dart';

class EquipmentItemDefinition extends ItemDefinition {
  final ArmorSlots armorSlot;
  final Map<SkillId, int> skillBonus;

  const EquipmentItemDefinition({
    required super.name,
    required super.value,
    required this.armorSlot,
    required this.skillBonus,
    super.description,
    super.iconAsset,
    super.quality,
  });

  @override
  EquipmentItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    ItemQuality? quality,
    ArmorSlots? armorSlot,
    Map<SkillId, int>? skillBonus,
  }) {
    return EquipmentItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      armorSlot: armorSlot ?? this.armorSlot,
      skillBonus: skillBonus ?? this.skillBonus,
    );
  }

  @override
  EquipmentItem toItem(ItemId id) => EquipmentItem(
    id: id,
    name: name,
    value: value,
    armorSlot: armorSlot,
    skillBonus: Map.of(skillBonus),
    // whatever the definition declares; crafting overwrites it with its own
    // roll on the instance it just made
    quality: quality,
  );
}
