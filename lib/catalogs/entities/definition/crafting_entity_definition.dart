import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/entities/model/crafting_entity.dart';
import 'package:rpg/catalogs/entities/definition/entity_definition.dart';

class CraftingEntityDefinition extends EntityDefinition {
  final SkillId craftingSkill;

  const CraftingEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    required this.craftingSkill,
  });

  @override
  CraftingEntity toEntity(EntityId id) =>
      CraftingEntity(id: id, name: name, craftingSkill: craftingSkill);

  @override
  CraftingEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? craftingSkill,
  }) {
    return CraftingEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      craftingSkill: craftingSkill ?? this.craftingSkill,
    );
  }
}
