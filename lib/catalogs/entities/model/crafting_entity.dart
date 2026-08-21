import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/model/entity.dart';

class CraftingEntity extends Entity {
  final SkillId craftingSkill;
  CraftingEntity({
    required super.id,
    required super.name,
    required this.craftingSkill,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'CraftingEntity';
    json['craftingSkill'] = craftingSkill.name;
    return json;
  }

  factory CraftingEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = Entity.fromJson({...json, 'runtimeType': 'Entity'});
    final rawCraftingSkill = json['craftingSkill'];

    if (rawCraftingSkill is! String) {
      throw FormatException(
        'Missing or invalid "craftingSkill". Expected String.',
      );
    }

    final craftingSkill = SkillId.values.firstWhere(
      (s) => s.name == rawCraftingSkill,
      orElse: () =>
          throw FormatException('Invalid SkillId "$rawCraftingSkill".'),
    );

    return CraftingEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      craftingSkill: craftingSkill,
    );
  }
}
