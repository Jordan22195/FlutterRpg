import 'inventory_data.dart';
import '../catalogs/entity_catalog.dart';

class EncounterData {
  EncounterData();
  InventoryData itemDrops = InventoryData(itemMap: {});
  int lastPlayerDamage = 0;
  bool isActive = false;
  bool respawning = false;
  EncounterEntity? entity;

  Map<String, dynamic> toJson() {
    return {
      'itemDrops': itemDrops.toJson(),
      'lastPlayerDamage': lastPlayerDamage,
      'isActive': isActive,
      'respawning': respawning,
      'entity': entity?.toJson(),
    };
  }

  factory EncounterData.fromJson(Map<String, dynamic> json) {
    final rawDrops = json['itemDrops'];
    final rawDamage = json['lastPlayerDamage'];
    final rawActive = json['isActive'];
    final rawRespawning = json['respawning'];
    final rawEntity = json['entity'];

    if (rawDrops is! Map<String, dynamic>) {
      throw FormatException('Missing or invalid "itemDrops". Expected object.');
    }

    if (rawDamage is! int) {
      throw FormatException(
        'Missing or invalid "lastPlayerDamage". Expected int.',
      );
    }

    if (rawActive is! bool) {
      throw FormatException('Missing or invalid "isActive". Expected bool.');
    }

    if (rawRespawning is! bool) {
      throw FormatException('Missing or invalid "respawning". Expected bool.');
    }

    EncounterEntity? entity;
    if (rawEntity != null) {
      if (rawEntity is! Map<String, dynamic>) {
        throw FormatException('Invalid "entity". Expected object.');
      }
      final parsed = Entity.fromJson(rawEntity);
      if (parsed is! EncounterEntity) {
        throw FormatException('Entity is not an EncounterEntity.');
      }
      entity = parsed;
    }

    final data = EncounterData();
    data.itemDrops = InventoryData.fromJson(rawDrops);
    data.lastPlayerDamage = rawDamage;
    data.isActive = rawActive;
    data.respawning = rawRespawning;
    data.entity = entity;

    return data;
  }
}
