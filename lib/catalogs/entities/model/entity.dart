import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/model/crafting_entity.dart';
import 'package:rpg/catalogs/entities/model/fire_pit_entity.dart';
import 'package:rpg/catalogs/entities/model/encounter_entity.dart';
import 'package:rpg/catalogs/entities/model/combat_entity.dart';
import 'package:rpg/catalogs/entities/model/fishing_entity.dart';
import 'package:rpg/catalogs/entities/model/shop_entity.dart';
import 'package:rpg/catalogs/entities/model/dungeon_entity.dart';

// Base Entity Class
class Entity {
  final EntityId id;
  final String name;
  final String instanceId;

  Entity({required this.id, required this.name})
    : instanceId = UniqueKey().toString();

  Map<String, dynamic> toJson() {
    return {
      'runtimeType': 'Entity',
      'id': id.name,
      'name': name,
      // instanceId is intentionally not serialized because it is a runtime-only value
    };
  }

  factory Entity.fromJson(Map<String, dynamic> json) {
    final runtimeType = json['runtimeType'];

    if (runtimeType is! String) {
      throw FormatException(
        'Missing or invalid "runtimeType". Expected String.',
      );
    }

    switch (runtimeType) {
      case 'Entity':
        final rawId = json['id'];
        final rawName = json['name'];

        if (rawId is! String) {
          throw FormatException('Missing or invalid "id". Expected String.');
        }

        if (rawName is! String) {
          throw FormatException('Missing or invalid "name". Expected String.');
        }

        final entityId = EntityId.values.firstWhere(
          (e) => e.name == rawId,
          orElse: () => throw FormatException('Invalid EntityId "$rawId".'),
        );

        return Entity(id: entityId, name: rawName);
      case 'CraftingEntity':
        return CraftingEntity.fromJson(json);
      case 'FirepitEntity':
        return FirePitEntity.fromJson(json);
      case 'EncounterEntity':
        return EncounterEntity.fromJson(json);
      case 'CombatEntity':
        return CombatEntity.fromJson(json);
      case 'FishingEntity':
        return FishingEntity.fromJson(json);
      case 'ShopEntity':
        return ShopEntity.fromJson(json);
      case 'DungeonEntity':
        return DungeonEntity.fromJson(json);
      default:
        throw FormatException('Unsupported runtimeType "$runtimeType".');
    }
  }
}
