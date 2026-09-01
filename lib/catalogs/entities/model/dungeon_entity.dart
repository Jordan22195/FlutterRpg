import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/definition/dungeon_entity_definition.dart';
import 'package:rpg/catalogs/entities/model/entity.dart';

// A dungeon entrance that lives inside a zone (a zone dungeon). Carries
// the [DungeonId] it opens; tapping it routes to the dungeon screen.
// Purely an entrance — no fight/count state of its own.
class DungeonEntity extends Entity {
  DungeonEntity({required super.id});

  @override
  DungeonEntityDefinition get definition =>
      id.definition as DungeonEntityDefinition;

  DungeonId get dungeonId => definition.dungeonId;
}
