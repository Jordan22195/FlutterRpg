import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
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
    Rarity? quality,
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
  // todo: make item intance objet and Id and some modifiers rather than
  // keeping all the core item info in the item instance. The game will lookup data
  // from the catalog based on the id, and calculate stat totals from the modifier
  // rather keeping the stat totals in the item instance. This makes sure there
  // is a single source of truth for item data. That way when there are turning updates,
  // all the existing item instances take the changes, rather than needing a wipe
  // or some tooling to adjust the existing instantiated items.
  // quality is left unrolled, so the piece reads back whatever the
  // definition declares until crafting, a drop or a shop rolls one onto it
  EquipmentItem toItem(ItemId id) => EquipmentItem(id: id);
}
