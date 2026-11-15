import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';

/// The three peaks above the mountain ranges: Frostcrown, Stormcrown and
/// Moltenspire. Their zone monsters run 233 to 377; 610 belongs to their
/// dungeon bosses alone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // each peak, the place it is climbed from, and its dungeon
  const peaks = {
    ZoneId.FROSTCROWN_PEAKS: (
      ZoneId.GREYSPINE_MOUNTAIN,
      DungeonId.HOARFROST_HOLLOW,
    ),
    ZoneId.STORMCROWN_PEAKS: (ZoneId.SADDLEGATE, DungeonId.THUNDERHALL),
    ZoneId.MOLTENSPIRE_PEAKS: (
      ZoneId.ASHRIDGE_MOUNTAINS,
      DungeonId.THE_CALDERA,
    ),
  };

  List<CombatEntityDefinition> zoneMonsters(ZoneId zone) => [
    for (final e in zone.definition.discoverableEntities)
      if (e.id.definition is CombatEntityDefinition)
        e.id.definition as CombatEntityDefinition,
  ];

  double weightOf(ZoneId zone, EntityId entity) => zone
      .definition
      .discoverableEntities
      .where((e) => e.id == entity)
      .fold(0.0, (sum, e) => sum + e.weight);

  group('High peaks', () {
    test('every peak outranks the mountains', () {
      for (final zone in peaks.keys) {
        expect(
          zone.definition.explorationLevel,
          greaterThan(ZoneId.GREYSPINE_MOUNTAIN.definition.explorationLevel),
          reason: zone.name,
        );
      }
    });

    test('each peak is one road up from where it is climbed', () {
      peaks.forEach((zone, info) {
        expect(ZoneTravelGraph.travelHops(info.$1, zone), 1, reason: zone.name);
        expect(ZoneTravelGraph.isReachable(ZoneId.TUTORIAL_FARM, zone), isTrue);
      });
    });

    test('the peaks lie east of the ranges', () {
      for (final zone in peaks.keys) {
        final c = zoneNodeCenter(zone)!;
        expect(c.dx, greaterThan(zoneNodeCenter(ZoneId.SADDLEGATE)!.dx));
        expect(c.dx, inInclusiveRange(0, kWorldMapSize.width));
      }
    });

    test('zone monsters run 233 to 377', () {
      for (final zone in peaks.keys) {
        final levels = zoneMonsters(zone).map((m) => m.level).toSet();
        expect(levels, {233, 377}, reason: zone.name);
      }
    });

    test('each peak has its dungeon, whose bosses alone stand at 610', () {
      peaks.forEach((zone, info) {
        final entrance = zone.definition.permanentEntities
            .map((e) => e.definition)
            .whereType<DungeonEntityDefinition>()
            .single;
        expect(entrance.dungeonId, info.$2);

        final cards = info.$2.definition.entries;
        expect(cards, hasLength(3));
        for (final card in cards) {
          final defs = [
            for (final ref in card.entities)
              ref.entityId.definition as CombatEntityDefinition,
          ];
          expect(defs.last.isDungeonBoss, isTrue, reason: card.name);
          expect(defs.last.level, 610, reason: card.name);
          for (final regular in defs.take(defs.length - 1)) {
            expect(regular.isDungeonBoss, isFalse);
            expect(regular.level, lessThanOrEqualTo(377), reason: card.name);
          }
        }
      });
    });

    test('the new monsters are 610 bosses', () {
      for (final id in [
        EntityId.FROST_GIANT,
        EntityId.FROST_WYRM,
        EntityId.THUNDERBIRD,
        EntityId.STORM_GIANT,
      ]) {
        final def = id.definition as CombatEntityDefinition;
        expect(def.level, 610, reason: id.name);
        expect(def.isDungeonBoss, isTrue, reason: id.name);
      }
    });

    test('Moltenspire holds the richest dragonite seam', () {
      final molten = weightOf(
        ZoneId.MOLTENSPIRE_PEAKS,
        EntityId.DRAGONITE_VEIN,
      );
      for (final zone in [ZoneId.FROSTCROWN_PEAKS, ZoneId.STORMCROWN_PEAKS]) {
        final w = weightOf(zone, EntityId.DRAGONITE_VEIN);
        expect(w, greaterThan(0), reason: zone.name);
        expect(molten, greaterThan(w), reason: zone.name);
      }
    });
  });
}
