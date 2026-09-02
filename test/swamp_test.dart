import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Blackmire Swamp is the wet ground east of South Haven, and the home the
/// mudlurc and fungal monster archetypes were written for.
///
/// Its roster spans four tiers, so most of it is gated behind the zone's own
/// front door by exploration level rather than by a second zone. These
/// assert that shape rather than the tuning numbers, so a rebalance of
/// weights or levels does not drag them down with it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WeightedDropTableEntry<EntityId>? entryFor(ZoneId zone, EntityId entity) {
    for (final e in zone.definition.discoverableEntities) {
      if (e.id == entity) return e;
    }
    return null;
  }

  int levelOf(EntityId id) => (id.definition as CombatEntityDefinition).level;

  group('Blackmire Swamp', () {
    test('sits one hop east of South Haven', () {
      final graph = ZoneTravelGraph();

      expect(ZoneTravelGraph.travelHops(ZoneId.SOUTH_HAVEN, ZoneId.SWAMP), 1);
      expect(ZoneTravelGraph.travelPath(ZoneId.TUTORIAL_FARM, ZoneId.SWAMP), [
        ZoneId.TUTORIAL_FARM,
        ZoneId.SOUTHWOOD_FOREST,
        ZoneId.SOUTH_HAVEN,
        ZoneId.SWAMP,
      ]);
      // and it is not free the way a dev zone is
      expect(ZoneTravelGraph.isFreeZone(ZoneId.SWAMP), isFalse);
      expect(
        graph.travelCost(ZoneId.SOUTH_HAVEN, ZoneId.SWAMP),
        greaterThan(0),
      );
    });

    test('is drawn on the world map, inside the canvas', () {
      final centre = zoneNodeCenter(ZoneId.SWAMP);
      expect(centre, isNotNull, reason: 'the zone needs a map node');
      expect(centre!.dx, inInclusiveRange(0, kWorldMapSize.width));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
    });

    test('outranks the town the road reaches it through', () {
      final swamp = ZoneId.SWAMP.definition;
      expect(
        swamp.explorationLevel,
        greaterThan(ZoneId.SOUTH_HAVEN.definition.explorationLevel),
      );
      expect(swamp.xpPerExplore, greaterThan(0));
    });

    test('has a firepit, the way every wilderness zone does', () {
      expect(
        ZoneId.SWAMP.definition.permanentEntities,
        contains(EntityId.FIREPIT),
      );
    });

    test('holds the roster the archetypes were written for', () {
      for (final id in [
        EntityId.MUDLURC,
        EntityId.FUNGAL_MONSTER,
        EntityId.MUDLURC_WARRIOR,
        EntityId.GIANT_SCORPION,
        EntityId.MOSS_GOLEM,
      ]) {
        expect(
          entryFor(ZoneId.SWAMP, id),
          isNotNull,
          reason: '${id.name} should live in the swamp',
        );
      }
    });

    test('the harder the monster, the later it is found', () {
      // the roster spans mudlurcs to a moss golem, so the zone gates itself
      // rather than needing a second zone to hold the top of its own range
      final ladder = [
        EntityId.MUDLURC,
        EntityId.GIANT_SCORPION,
        EntityId.MOSS_GOLEM,
      ];
      for (var i = 1; i < ladder.length; i++) {
        expect(
          levelOf(ladder[i]),
          greaterThan(levelOf(ladder[i - 1])),
          reason: 'the ladder itself is out of order',
        );
        expect(
          entryFor(ZoneId.SWAMP, ladder[i])!.unlockLevel,
          greaterThan(entryFor(ZoneId.SWAMP, ladder[i - 1])!.unlockLevel),
          reason: '${ladder[i].name} should unlock after ${ladder[i - 1].name}',
        );
      }
    });

    test('its monsters drop something other than coins', () {
      // the roster shipped with coin stubs; the ones placed in a zone are
      // the ones worth fighting for a reason
      for (final id in [EntityId.FUNGAL_MONSTER, EntityId.GIANT_SCORPION]) {
        final def = id.definition as EncounterEntityDefinition;
        final loot = {
          ...def.itemDrops.map((d) => d.id),
          for (final roll in def.bonusDrops) ...roll.entries.map((d) => d.id),
        }..remove(ItemId.COINS);
        expect(loot, isNotEmpty, reason: '${id.name} drops only coins');
      }
    });
  });
}
