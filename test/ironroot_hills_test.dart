import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Ironroot Hills is the front range east of the prairie: the rung above
/// Stormgrass, reached through Iron Gate City, the city at its foot, and the
/// home of the old foothills roster.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hills = ZoneId.IRONROOT_HILLS.definition;

  WeightedDropTableEntry<EntityId>? entryFor(EntityId entity) {
    for (final e in hills.discoverableEntities) {
      if (e.id == entity) return e;
    }
    return null;
  }

  group('Ironroot Hills', () {
    test('goes by its name and outranks the prairie', () {
      expect(hills.name, 'Ironroot Hills');
      expect(
        hills.explorationLevel,
        greaterThan(ZoneId.FOOTHILLS.definition.explorationLevel),
      );
      expect(hills.xpPerExplore, greaterThan(0));
    });

    test('is reached through Iron Gate City, just outside it', () {
      expect(
        ZoneTravelGraph.travelPath(ZoneId.FOOTHILLS, ZoneId.IRONROOT_HILLS),
        [ZoneId.FOOTHILLS, ZoneId.IRON_GATE_CITY, ZoneId.IRONROOT_HILLS],
      );
      // the city sits at the foot of the hills: the walk out of town is
      // shorter than the road in from the prairie
      expect(
        ZoneTravelGraph.edgeTravelTime(
          ZoneId.IRON_GATE_CITY,
          ZoneId.IRONROOT_HILLS,
        ),
        lessThan(
          ZoneTravelGraph.edgeTravelTime(
            ZoneId.FOOTHILLS,
            ZoneId.IRON_GATE_CITY,
          ),
        ),
      );
    });

    test('lies east of the prairie, with Iron Gate City just west of it', () {
      final prairie = zoneNodeCenter(ZoneId.FOOTHILLS)!;
      final city = zoneNodeCenter(ZoneId.IRON_GATE_CITY)!;
      final centre = zoneNodeCenter(ZoneId.IRONROOT_HILLS)!;
      expect(centre.dx, greaterThan(prairie.dx));
      expect(city.dx, greaterThan(prairie.dx));
      expect(city.dx, lessThan(centre.dx));
      expect(centre.dx, inInclusiveRange(0, kWorldMapSize.width));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
    });

    test('holds the old foothills roster', () {
      for (final id in [
        EntityId.HARPY,
        EntityId.IMP,
        EntityId.TROLL,
        EntityId.HILL_GIANT,
      ]) {
        expect(entryFor(id), isNotNull, reason: '${id.name} lives here');
      }
    });

    test('has a firepit and rock worth mining', () {
      expect(hills.permanentEntities, contains(EntityId.FIREPIT));
      expect(entryFor(EntityId.COAL_VEIN), isNotNull);
      expect(entryFor(EntityId.ADAMANTITE_VEIN), isNotNull);
    });
  });
}
