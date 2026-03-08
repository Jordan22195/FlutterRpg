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
  SkillData skillData;
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
}
