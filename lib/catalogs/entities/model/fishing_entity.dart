import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/model/encounter_entity.dart';

// A fishing spot. Unlike trees/ore it never depletes and it doesn't
// fight back: the fishing action rolls against its difficulty (defence)
// for a catch and the spot stays put. That makes it a permanent feature
// of the zone rather than a resource node, so the explore screen lists
// it with the structures.
class FishingEntity extends EncounterEntity {
  FishingEntity({
    required super.id,
    required super.name,
    super.entityType = SkillId.FISHING,
    required super.count,
    required super.defence,
    required super.hitpoints,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'FishingEntity';
    return json;
  }

  factory FishingEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = EncounterEntity.fromJson({
      ...json,
      'runtimeType': 'EncounterEntity',
    });

    final entity = FishingEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      count: baseEntity.count,
      entityType: baseEntity.entityType,
      defence: baseEntity.defence,
      hitpoints: baseEntity.hitpoints,
    );
    entity.maxHitPoints = baseEntity.maxHitPoints;
    return entity;
  }
}
