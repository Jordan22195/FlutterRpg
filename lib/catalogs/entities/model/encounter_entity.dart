import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/model/entity.dart';

// Encounter Entity Class
class EncounterEntity extends Entity {
  final SkillId entityType;
  final int defence;
  int count;
  int hitpoints;
  int maxHitPoints;

  EncounterEntity({
    required super.id,
    required super.name,
    required this.count,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
  }) : maxHitPoints = hitpoints;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'EncounterEntity';
    json['entityType'] = entityType.name;
    json['defence'] = defence;
    json['count'] = count;
    json['hitpoints'] = hitpoints;
    json['maxHitPoints'] = maxHitPoints;
    return json;
  }

  factory EncounterEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = Entity.fromJson({...json, 'runtimeType': 'Entity'});
    final rawEntityType = json['entityType'];
    final rawDefence = json['defence'];
    final rawCount = json['count'];
    final rawHitpoints = json['hitpoints'];
    final rawMaxHitPoints = json['maxHitPoints'];

    if (rawEntityType is! String) {
      throw FormatException(
        'Missing or invalid "entityType". Expected String.',
      );
    }

    if (rawDefence is! int) {
      throw FormatException('Missing or invalid "defence". Expected int.');
    }

    if (rawCount is! int) {
      throw FormatException('Missing or invalid "count". Expected int.');
    }

    if (rawHitpoints is! int) {
      throw FormatException('Missing or invalid "hitpoints". Expected int.');
    }

    if (rawMaxHitPoints is! int) {
      throw FormatException('Missing or invalid "maxHitPoints". Expected int.');
    }

    final entityType = SkillId.values.firstWhere(
      (s) => s.name == rawEntityType,
      orElse: () => throw FormatException('Invalid SkillId "$rawEntityType".'),
    );

    // the constructor derives maxHitPoints from hitpoints, so build at full
    // health and then restore both — a half-killed entity has to come back
    // half-killed, or closing the app mid-fight heals it
    final entity = EncounterEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      count: rawCount,
      entityType: entityType,
      defence: rawDefence,
      hitpoints: rawMaxHitPoints,
    );

    entity.maxHitPoints = rawMaxHitPoints;
    entity.hitpoints = rawHitpoints;
    return entity;
  }
}
