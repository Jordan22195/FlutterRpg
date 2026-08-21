import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/model/crafting_entity.dart';

/// A firepit. Carries no state of its own: what is burning in it, and for how
/// long, is the zone buff keyed to this entity id in [BuffData]. Keeping it
/// stateless is deliberate — firepits are permanent entities, and permanent
/// entities are rebuilt from the catalog on every load, so anything stored
/// here would be lost.
class FirePitEntity extends CraftingEntity {
  FirePitEntity({
    required super.id,
    required super.name,
    super.craftingSkill = SkillId.FIREMAKING,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    // 'Firepit', not 'FirePit': this string is the save format and predates
    // the class rename, so it stays spelled the way existing saves spell it.
    json['runtimeType'] = 'FirepitEntity';
    return json;
  }

  factory FirePitEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = CraftingEntity.fromJson({
      ...json,
      'runtimeType': 'CraftingEntity',
    });

    return FirePitEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      craftingSkill: baseEntity.craftingSkill,
    );
  }
}
