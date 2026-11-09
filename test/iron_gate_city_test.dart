import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/zones/zones.dart';

/// Iron Gate City is the city at the end of the prairie road, east
/// of Stormgrass Prairie, and the home of the jewelcrafting bench.
void main() {
  final town = ZoneId.IRON_GATE_CITY.definition;

  group('Iron Gate City', () {
    test('is a settlement with the jewelcrafting bench', () {
      expect(town.name, 'Iron Gate City');
      expect(town.type, MapNodeType.SETTLEMENT);
      expect(town.permanentEntities, contains(EntityId.JEWELCRAFTING_BENCH));
      expect(town.discoverableEntities, isEmpty);
    });

    test('is reached through Stormgrass Prairie', () {
      expect(
        ZoneTravelGraph.travelHops(ZoneId.FOOTHILLS, ZoneId.IRON_GATE_CITY),
        1,
      );
      expect(ZoneTravelGraph.travelPath(ZoneId.SWAMP, ZoneId.IRON_GATE_CITY), [
        ZoneId.SWAMP,
        ZoneId.FOOTHILLS,
        ZoneId.IRON_GATE_CITY,
      ]);
      expect(
        ZoneTravelGraph().travelTime(ZoneId.FOOTHILLS, ZoneId.IRON_GATE_CITY),
        greaterThan(Duration.zero),
      );
    });

    test('is drawn east of the prairie, inside the canvas', () {
      final centre = zoneNodeCenter(ZoneId.IRON_GATE_CITY)!;
      final prairie = zoneNodeCenter(ZoneId.FOOTHILLS)!;
      expect(centre.dx, greaterThan(prairie.dx));
      expect(centre.dx, inInclusiveRange(0, kWorldMapSize.width));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
    });
  });
}
