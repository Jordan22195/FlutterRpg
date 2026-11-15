import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/zones/zones.dart';

/// The two mountain ranges past Ironroot Hills and Redwall Bluffs, and
/// Saddlegate, the pass town that joins them. Their zone monsters run 144
/// to 233; 377 belongs to their dungeon bosses alone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ranges = [ZoneId.GREYSPINE_MOUNTAIN, ZoneId.ASHRIDGE_MOUNTAINS];
  const dungeonOf = {
    ZoneId.GREYSPINE_MOUNTAIN: DungeonId.SPINEHOLD_CAVERNS,
    ZoneId.ASHRIDGE_MOUNTAINS: DungeonId.ASHEN_VAULTS,
  };

  List<CombatEntityDefinition> zoneMonsters(ZoneId zone) => [
    for (final e in zone.definition.discoverableEntities)
      if (e.id.definition is CombatEntityDefinition)
        e.id.definition as CombatEntityDefinition,
  ];

  group('Mountain ranges', () {
    test('both ranges outrank Ironroot Hills', () {
      for (final zone in ranges) {
        expect(
          zone.definition.explorationLevel,
          greaterThan(ZoneId.IRONROOT_HILLS.definition.explorationLevel),
          reason: zone.name,
        );
        expect(zone.definition.xpPerExplore, greaterThan(0));
      }
    });

    test('Saddlegate is a settlement with the crafting tables', () {
      final town = ZoneId.SADDLEGATE.definition;
      expect(town.type, MapNodeType.SETTLEMENT);
      expect(town.discoverableEntities, isEmpty);
      expect(
        town.permanentEntities,
        containsAll([
          EntityId.FIREPIT,
          EntityId.ANVIL,
          EntityId.ENCHANTING_BENCH,
          EntityId.ALCHEMY_STATION,
        ]),
      );
    });

    test('Greyspine is reached from the hills, Ashridge from the bluffs', () {
      expect(
        ZoneTravelGraph.travelHops(
          ZoneId.IRONROOT_HILLS,
          ZoneId.GREYSPINE_MOUNTAIN,
        ),
        1,
      );
      expect(
        ZoneTravelGraph.travelHops(
          ZoneId.REDWALL_BLUFFS,
          ZoneId.ASHRIDGE_MOUNTAINS,
        ),
        1,
      );
    });

    test('the two ranges are joined through Saddlegate', () {
      expect(
        ZoneTravelGraph.travelPath(
          ZoneId.GREYSPINE_MOUNTAIN,
          ZoneId.ASHRIDGE_MOUNTAINS,
        ),
        [
          ZoneId.GREYSPINE_MOUNTAIN,
          ZoneId.SADDLEGATE,
          ZoneId.ASHRIDGE_MOUNTAINS,
        ],
      );
      // the town sits in the pass: the walk down into either range is
      // shorter than the climb up into them
      for (final zone in ranges) {
        expect(
          ZoneTravelGraph.edgeTravelTime(ZoneId.SADDLEGATE, zone),
          lessThan(
            ZoneTravelGraph.edgeTravelTime(
              ZoneId.IRONROOT_HILLS,
              ZoneId.GREYSPINE_MOUNTAIN,
            ),
          ),
        );
      }
    });

    test('the ranges lie east of the hills and the bluffs', () {
      final hills = zoneNodeCenter(ZoneId.IRONROOT_HILLS)!;
      final bluffs = zoneNodeCenter(ZoneId.REDWALL_BLUFFS)!;
      final greyspine = zoneNodeCenter(ZoneId.GREYSPINE_MOUNTAIN)!;
      final ashridge = zoneNodeCenter(ZoneId.ASHRIDGE_MOUNTAINS)!;
      final town = zoneNodeCenter(ZoneId.SADDLEGATE)!;
      expect(greyspine.dx, greaterThan(hills.dx));
      expect(ashridge.dx, greaterThan(bluffs.dx));
      // Saddlegate sits between them, north to south
      expect(town.dy, greaterThan(greyspine.dy));
      expect(town.dy, lessThan(ashridge.dy));
      for (final c in [greyspine, ashridge, town]) {
        expect(c.dx, inInclusiveRange(0, kWorldMapSize.width));
        expect(c.dy, inInclusiveRange(0, kWorldMapSize.height));
      }
    });

    test('zone monsters run 144 to 233', () {
      for (final zone in ranges) {
        final levels = zoneMonsters(zone).map((m) => m.level).toSet();
        expect(levels, {144, 233}, reason: zone.name);
      }
    });

    test('each range has its dungeon, whose bosses alone stand at 377', () {
      for (final zone in ranges) {
        final dungeon = dungeonOf[zone]!;
        final entrance = zone.definition.permanentEntities
            .map((e) => e.definition)
            .whereType<DungeonEntityDefinition>()
            .single;
        expect(entrance.dungeonId, dungeon);

        final cards = dungeon.definition.entries;
        expect(cards, hasLength(3));
        for (final card in cards) {
          final defs = [
            for (final ref in card.entities)
              ref.entityId.definition as CombatEntityDefinition,
          ];
          final boss = defs.last;
          expect(boss.isDungeonBoss, isTrue, reason: card.name);
          expect(boss.level, 377, reason: card.name);
          for (final regular in defs.take(defs.length - 1)) {
            expect(regular.isDungeonBoss, isFalse);
            expect(regular.level, lessThanOrEqualTo(233), reason: card.name);
          }
        }
      }
    });
  });
}
