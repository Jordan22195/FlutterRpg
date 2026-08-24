import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/rarity.dart';
import 'package:rpg/catalogs/entities/model/fire_pit_entity.dart';
import 'package:rpg/catalogs/entities/definition/crafting_entity_definition.dart';

class FirePitEntityDefinition extends CraftingEntityDefinition {
  const FirePitEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    super.craftingSkill = SkillId.FIREMAKING,
  });

  @override
  FirePitEntity toEntity(EntityId id) =>
      FirePitEntity(id: id, name: name, craftingSkill: craftingSkill);

  @override
  FirePitEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? craftingSkill,
  }) {
    return FirePitEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      craftingSkill: craftingSkill ?? this.craftingSkill,
    );
  }
}
