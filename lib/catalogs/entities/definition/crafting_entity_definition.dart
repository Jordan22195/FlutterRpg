import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/model/crafting_entity.dart';
import 'package:rpg/catalogs/entities/definition/entity_definition.dart';

class CraftingEntityDefinition extends EntityDefinition {
  final SkillId craftingSkill;

  const CraftingEntityDefinition({
    required super.name,
    required super.iconAsset,
    required this.craftingSkill,
  });

  @override
  CraftingEntity toEntity(EntityId id) =>
      CraftingEntity(id: id, name: name, craftingSkill: craftingSkill);

  @override
  CraftingEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    SkillId? craftingSkill,
  }) {
    return CraftingEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      craftingSkill: craftingSkill ?? this.craftingSkill,
    );
  }
}
