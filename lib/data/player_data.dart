import 'package:rpg/catalogs/entity_catalog.dart';
import 'skill_data.dart';
import 'equipment_data.dart';
import '../catalogs/zone_catalog.dart';
import '../data/buff_data.dart';

class PlayerData {
  // location info
  ZoneId currentZoneId;
  EntityId currentEntityViewId;

  // skill stats
  BuffData buffData;
  Map<SkillId, SkillData> skillData;
  EquipmentData equipmentData;

  // mutable stats
  int hitpoints = 10;
  double stamina = 0;

  PlayerData({
    required this.currentZoneId,
    required this.currentEntityViewId,
    required this.buffData,
    required this.skillData,
    required this.equipmentData,
    required this.hitpoints,
    required this.stamina,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentZoneId': currentZoneId.name,
      'currentEntityViewId': currentEntityViewId.name,
      'buffData': buffData.toJson(),
      'skillData': skillData.map(
        (key, value) => MapEntry(key.name, value.toJson()),
      ),
      'equipmentData': equipmentData.toJson(),
      'hitpoints': hitpoints,
      'stamina': stamina,
    };
  }

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    final rawZoneId = json['currentZoneId'];
    final rawEntityId = json['currentEntityViewId'];
    final rawBuffData = json['buffData'];
    final rawSkillData = json['skillData'];
    final rawEquipmentData = json['equipmentData'];
    final rawHitpoints = json['hitpoints'];
    final rawStamina = json['stamina'];

    if (rawZoneId is! String) {
      throw FormatException('Missing or invalid "currentZoneId".');
    }

    if (rawEntityId is! String) {
      throw FormatException('Missing or invalid "currentEntityViewId".');
    }

    if (rawBuffData is! Map) {
      throw FormatException('Missing or invalid "buffData".');
    }

    if (rawSkillData is! Map) {
      throw FormatException('Missing or invalid "skillData".');
    }

    if (rawEquipmentData is! Map) {
      throw FormatException('Missing or invalid "equipmentData".');
    }

    if (rawHitpoints is! int) {
      throw FormatException('Missing or invalid "hitpoints".');
    }

    if (rawStamina is! num) {
      throw FormatException('Missing or invalid "stamina".');
    }

    final skillData = <SkillId, SkillData>{};

    for (final entry in rawSkillData.entries) {
      final rawSkillId = entry.key;
      final rawSkill = entry.value;

      if (rawSkillId is! String) {
        throw FormatException('Invalid skill id key.');
      }

      if (rawSkill is! Map<String, dynamic>) {
        throw FormatException('Invalid skill data for "\$rawSkillId".');
      }

      final skillId = SkillId.values.firstWhere(
        (s) => s.name == rawSkillId,
        orElse: () => throw FormatException('Invalid SkillId "\$rawSkillId".'),
      );

      skillData[skillId] = SkillData.fromJson(rawSkill);
    }

    return PlayerData(
      currentZoneId: ZoneId.values.firstWhere(
        (z) => z.name == rawZoneId,
        orElse: () => throw FormatException('Invalid ZoneId "\$rawZoneId".'),
      ),
      currentEntityViewId: EntityId.values.firstWhere(
        (e) => e.name == rawEntityId,
        orElse: () =>
            throw FormatException('Invalid EntityId "\$rawEntityId".'),
      ),
      buffData: BuffData.fromJson(Map<String, dynamic>.from(rawBuffData)),
      skillData: skillData,
      equipmentData: EquipmentData.fromJson(
        Map<String, dynamic>.from(rawEquipmentData),
      ),
      hitpoints: rawHitpoints,
      stamina: rawStamina.toDouble(),
    );
  }
}
