import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';

/// Reedwater Vale, Mudmouth Delta and Saltwind Coast are the zones off the
/// west side of Southwood Forest: a river valley to its south-west, the
/// delta west of the valley and the open coast south of the delta.
///
/// Each holds a monster roster on its own band of the level ladder:
/// Reedwater 13–34, Mudmouth 21–55, Saltwind 34–89.
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
        ZoneTravelGraph.travelPath(ZoneId.TUTORIAL_FARM, ZoneId.SALTWIND_COAST),
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
      final levels = [for (final z in chain) z.definition.explorationLevel];
      expect(levels, orderedEquals([...levels]..sort()));
      expect(levels.toSet().length, levels.length);
    });

    test('each holds its chosen monster roster', () {
      List<EntityId> roster(ZoneId zone) => [
        for (final e in zone.definition.discoverableEntities)
          if (e.id.definition is CombatEntityDefinition) e.id,
      ];
      expect(roster(ZoneId.REEDWATER_VALE), [
        EntityId.RIVER_TOAD,
        EntityId.WATER_STRIDER,
        EntityId.MUDLURC_FISHER,
        EntityId.SNAPPING_TURTLE,
      ]);
      expect(roster(ZoneId.MUDMOUTH_DELTA), [
        EntityId.MUD_CRAB,
        EntityId.MIRE_HIPPO,
        EntityId.CROCODILE,
      ]);
      expect(roster(ZoneId.SALTWIND_COAST), [
        EntityId.SHORE_CRAB,
        EntityId.NAGA,
        EntityId.TIDAL_ELEMENTAL,
        EntityId.SEA_SERPENT,
      ]);
    });

    test('each monster sits in its zone\'s level band', () {
      const bands = {
        ZoneId.REEDWATER_VALE: (13, 34),
        ZoneId.MUDMOUTH_DELTA: (21, 55),
        ZoneId.SALTWIND_COAST: (34, 89),
      };
      for (final MapEntry(key: zone, value: (lo, hi)) in bands.entries) {
        for (final e in zone.definition.discoverableEntities) {
          final def = e.id.definition;
          if (def is! CombatEntityDefinition) continue;
          expect(
            def.level,
            inInclusiveRange(lo, hi),
            reason: '${e.id.name} in ${zone.name}',
          );
        }
      }
    });

    test('every new monster drops something', () {
      for (final zone in chain.skip(1)) {
        for (final e in zone.definition.discoverableEntities) {
          final def = e.id.definition;
          if (def is! CombatEntityDefinition) continue;
          // a reagent part counts: it is most of what these monsters leave
          expect(
            [...def.itemDrops, ...def.rolledBonusDrops],
            isNotEmpty,
            reason: '${e.id.name} has no loot',
          );
        }
      }
    });
  });
}
