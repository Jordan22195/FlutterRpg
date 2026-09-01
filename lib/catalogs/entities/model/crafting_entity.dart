import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/definition/crafting_entity_definition.dart';
import 'package:rpg/catalogs/entities/model/entity.dart';

class CraftingEntity extends Entity {
  CraftingEntity({required super.id});

  @override
  CraftingEntityDefinition get definition =>
      id.definition as CraftingEntityDefinition;

  SkillId get craftingSkill => definition.craftingSkill;
}
