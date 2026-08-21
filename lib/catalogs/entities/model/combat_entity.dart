import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/model/encounter_entity.dart';

// Combat Encounter Entity Class
class CombatEntity extends EncounterEntity {
  final int attack;
  final double attackInterval;
  CombatEntity({
    required super.id,
    required super.name,
    super.entityType = SkillId.ATTACK,
    required super.count,
    required super.defence,
    required super.hitpoints,
    required this.attack,
    required this.attackInterval,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'CombatEntity';
    json['attack'] = attack;
    json['attackInterval'] = attackInterval;
    return json;
  }

  factory CombatEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = EncounterEntity.fromJson({
      ...json,
      'runtimeType': 'EncounterEntity',
    });
    final rawAttack = json['attack'];
    final rawAttackInterval = json['attackInterval'];

    if (rawAttack is! int) {
      throw FormatException('Missing or invalid "attack". Expected int.');
    }

    if (rawAttackInterval is! num) {
      throw FormatException(
        'Missing or invalid "attackInterval". Expected number.',
      );
    }

    final entity = CombatEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      entityType: baseEntity.entityType,
      count: baseEntity.count,
      defence: baseEntity.defence,
      hitpoints: baseEntity.hitpoints,
      attack: rawAttack,
      attackInterval: rawAttackInterval.toDouble(),
    );

    entity.maxHitPoints = baseEntity.maxHitPoints;
    return entity;
  }
}
