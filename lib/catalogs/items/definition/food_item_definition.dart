import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/item.dart';
import 'package:rpg/catalogs/items/definition/item_definition.dart';

class FoodItemDefinition extends ItemDefinition {
  final int restoreAmount;
  final SkillId restoreSkill;

  const FoodItemDefinition({
    required super.name,
    required super.value,
    required this.restoreAmount,
    this.restoreSkill = SkillId.HITPOINTS,
    super.description,
    super.iconAsset,
    super.quality,
    super.xpValue,
  });

  @override
  FoodItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    int? restoreAmount,
    SkillId? restoreSkill,
  }) {
    return FoodItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      xpValue: xpValue ?? this.xpValue,
      restoreAmount: restoreAmount ?? this.restoreAmount,
      restoreSkill: restoreSkill ?? this.restoreSkill,
    );
  }

  @override
  Item toItem(ItemId id) => Item(id: id, name: name, value: value);
}
