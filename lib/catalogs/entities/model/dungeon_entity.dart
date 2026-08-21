import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/model/entity.dart';

// A dungeon entrance that lives inside a zone (a zone dungeon). Carries
// the [DungeonId] it opens; tapping it routes to the dungeon screen.
// Purely an entrance — no fight/count state of its own.
class DungeonEntity extends Entity {
  final DungeonId dungeonId;

  DungeonEntity({
    required super.id,
    required super.name,
    required this.dungeonId,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'DungeonEntity';
    json['dungeonId'] = dungeonId.name;
    return json;
  }

  factory DungeonEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = Entity.fromJson({...json, 'runtimeType': 'Entity'});
    final rawDungeonId = json['dungeonId'];

    if (rawDungeonId is! String) {
      throw FormatException('Missing or invalid "dungeonId". Expected String.');
    }

    final dungeonId = DungeonId.values.firstWhere(
      (d) => d.name == rawDungeonId,
      orElse: () => throw FormatException('Invalid DungeonId "$rawDungeonId".'),
    );

    return DungeonEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      dungeonId: dungeonId,
    );
  }
}
