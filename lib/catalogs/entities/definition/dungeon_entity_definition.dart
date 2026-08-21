import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/model/dungeon_entity.dart';
import 'package:rpg/catalogs/entities/definition/entity_definition.dart';

class DungeonEntityDefinition extends EntityDefinition {
  final DungeonId dungeonId;

  const DungeonEntityDefinition({
    required super.name,
    required super.iconAsset,
    required this.dungeonId,
  });

  @override
  DungeonEntity toEntity(EntityId id) =>
      DungeonEntity(id: id, name: name, dungeonId: dungeonId);
}

// Catalog
