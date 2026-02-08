import 'package:rpg/controllers/weighted_drop_table.dart';
import 'package:rpg/data/zone_location.dart';
import 'entity.dart';

enum Zones { TUTORIAL_FARM, STARTING_FOREST, CHALLENGING_MOUNTAIN, NULL }

class Zone {
  final Zones id;
  final String name;
  final List<ZoneLocationType> permanentLocations;
  final List<WeightedDropTableEntry<Entities>> discoverableEntities;
  final WeightedDropTable entityTable;

  Zone({
    required this.id,
    required this.name,
    required this.discoverableEntities,
    required this.permanentLocations,
  }) : entityTable = WeightedDropTable<Entities>(items: discoverableEntities);
}
