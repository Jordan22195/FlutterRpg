import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Copperdust Flats is the high desert south of the prairie, and the
/// prairie's equal in difficulty. Redwall Bluffs lies east of it, one tier
/// harder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final flats = ZoneId.COPPERDUST_FLATS.definition;
  final bluffs = ZoneId.REDWALL_BLUFFS.definition;
  final prairie = ZoneId.FOOTHILLS.definition;

  bool holds(ZoneId zone, EntityId entity) => zone
      .definition
      .discoverableEntities
      .any((WeightedDropTableEntry<EntityId> e) => e.id == entity);

  group('Copperdust Flats', () {
    test('goes by its name and matches the prairie', () {
      expect(flats.name, 'Copperdust Flats');
      expect(flats.explorationLevel, prairie.explorationLevel);
      expect(flats.xpPerExplore, prairie.xpPerExplore);
      expect(flats.permanentEntities, contains(EntityId.FIREPIT));
    });

    test('is one road south of the prairie', () {
      expect(
        ZoneTravelGraph.travelHops(ZoneId.FOOTHILLS, ZoneId.COPPERDUST_FLATS),
        1,
      );
      final centre = zoneNodeCenter(ZoneId.COPPERDUST_FLATS)!;
      final north = zoneNodeCenter(ZoneId.FOOTHILLS)!;
      expect(centre.dy, greaterThan(north.dy));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
    });

    test('is home to desert animals, and gold in the rock', () {
      for (final id in [
        EntityId.RATTLESNAKE,
        EntityId.GIANT_SCORPION,
        EntityId.GOLD_VEIN,
      ]) {
        expect(holds(ZoneId.COPPERDUST_FLATS, id), isTrue, reason: id.name);
      }
    });
  });

  group('Redwall Bluffs', () {
    test('goes by its name and is one tier harder than the flats', () {
      expect(bluffs.name, 'Redwall Bluffs');
      expect(bluffs.explorationLevel, greaterThan(flats.explorationLevel));
      expect(
        bluffs.explorationLevel,
        ZoneId.IRONROOT_HILLS.definition.explorationLevel,
      );
      expect(bluffs.permanentEntities, contains(EntityId.FIREPIT));
    });

    test('is reached across the flats and lies east of them', () {
      expect(
        ZoneTravelGraph.travelPath(ZoneId.FOOTHILLS, ZoneId.REDWALL_BLUFFS),
        [ZoneId.FOOTHILLS, ZoneId.COPPERDUST_FLATS, ZoneId.REDWALL_BLUFFS],
      );
      final centre = zoneNodeCenter(ZoneId.REDWALL_BLUFFS)!;
      final west = zoneNodeCenter(ZoneId.COPPERDUST_FLATS)!;
      expect(centre.dx, greaterThan(west.dx));
      expect(centre.dx, inInclusiveRange(0, kWorldMapSize.width));
    });

    test('holds the cliff roster', () {
      for (final id in [
        EntityId.GARGOYLE,
        EntityId.BASILISK,
        EntityId.GRIFFIN,
      ]) {
        expect(holds(ZoneId.REDWALL_BLUFFS, id), isTrue, reason: id.name);
      }
    });
  });
}
