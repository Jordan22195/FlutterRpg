import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/zones/zones.dart';

/// Reedwater Vale, Mudmouth Delta and Saltwind Coast are the skeleton zones
/// off the west side of Southwood Forest: a river valley to its south-west, the
/// delta west of the valley and the open coast south of the delta.
///
/// They hold no entities yet, so these assert only where they sit and that
/// they stay empty until content is chosen on purpose.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const chain = [
    ZoneId.SOUTHWOOD_FOREST,
    ZoneId.REEDWATER_VALE,
    ZoneId.MUDMOUTH_DELTA,
    ZoneId.SALTWIND_COAST,
  ];

  group('west coast zones', () {
    test('run in a chain off Southwood Forest', () {
      expect(
        ZoneTravelGraph.travelPath(
          ZoneId.TUTORIAL_FARM,
          ZoneId.SALTWIND_COAST,
        ),
        [ZoneId.TUTORIAL_FARM, ...chain],
      );
      for (final zone in chain.skip(1)) {
        expect(ZoneTravelGraph.isFreeZone(zone), isFalse);
      }
    });

    test('are laid out south-west, west and south of each other', () {
      Offset c(ZoneId z) => zoneNodeCenter(z)!;
      final southwood = c(ZoneId.SOUTHWOOD_FOREST);
      final valley = c(ZoneId.REEDWATER_VALE);
      final delta = c(ZoneId.MUDMOUTH_DELTA);
      final coast = c(ZoneId.SALTWIND_COAST);

      expect(valley.dx, lessThan(southwood.dx));
      expect(valley.dy, greaterThan(southwood.dy));
      expect(delta.dx, lessThan(valley.dx));
      expect(coast.dy, greaterThan(delta.dy));

      for (final z in chain.skip(1)) {
        final p = c(z);
        expect(p.dx, inInclusiveRange(0, kWorldMapSize.width));
        expect(p.dy, inInclusiveRange(0, kWorldMapSize.height));
      }
    });

    test('climb in exploration level out from Southwood', () {
      final levels = [
        for (final z in chain) z.definition.explorationLevel,
      ];
      expect(levels, orderedEquals([...levels]..sort()));
      expect(levels.toSet().length, levels.length);
    });

    test('hold no entities yet', () {
      for (final zone in chain.skip(1)) {
        expect(zone.definition.permanentEntities, isEmpty);
        expect(zone.definition.discoverableEntities, isEmpty);
      }
    });
  });
}
