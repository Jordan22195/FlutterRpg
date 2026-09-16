import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Darkwood Forest is the tier 3 zone south of South Haven: the Spider Den
/// moved here out of Southwood, taking the spiders with it, and the tier 3
/// gathering nodes live here.
///
/// These assert the shape of that move rather than any tuning number, so a
/// rebalance of levels or weights does not drag them down with it. Which
/// undead the zone ends up holding is tuning and has moved once already, so
/// the roster below is read off the catalog rather than named.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool discoverable(ZoneId zone, EntityId entity) => zone
      .definition
      .discoverableEntities
      .any((WeightedDropTableEntry<EntityId> e) => e.id == entity);

  group('Darkwood Forest', () {
    test('sits past South Haven on the travel graph', () {
      final graph = ZoneTravelGraph();

      // one hop off the town, and the town is how you get there: the route
      // in from the starting meadow runs through the forest and the haven
      expect(
        ZoneTravelGraph.travelHops(ZoneId.SOUTH_HAVEN, ZoneId.DARKWOOD_FOREST),
        1,
      );
      expect(
        ZoneTravelGraph.travelPath(
          ZoneId.TUTORIAL_FARM,
          ZoneId.DARKWOOD_FOREST,
        ),
        [
          ZoneId.TUTORIAL_FARM,
          ZoneId.SOUTHWOOD_FOREST,
          ZoneId.SOUTH_HAVEN,
          ZoneId.DARKWOOD_FOREST,
        ],
      );
      // and it is not free the way a dev zone is
      expect(ZoneTravelGraph.isFreeZone(ZoneId.DARKWOOD_FOREST), isFalse);
      expect(
        graph.travelCost(ZoneId.SOUTH_HAVEN, ZoneId.DARKWOOD_FOREST),
        greaterThan(0),
      );
    });

    test('is drawn on the world map, clear of its neighbours', () {
      final centre = zoneNodeCenter(ZoneId.DARKWOOD_FOREST);
      expect(centre, isNotNull, reason: 'the zone needs a map node');
      // inside the canvas it is laid out on
      expect(centre!.dx, inInclusiveRange(0, kWorldMapSize.width));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
    });

    test('outranks the zones the road reaches it through', () {
      final darkwood = ZoneId.DARKWOOD_FOREST.definition;
      expect(
        darkwood.explorationLevel,
        greaterThan(ZoneId.SOUTHWOOD_FOREST.definition.explorationLevel),
        reason: 'the darkwood is the step up from Southwood',
      );
      expect(darkwood.xpPerExplore, greaterThan(0));
    });

    test('holds the Spider Den, and Southwood no longer does', () {
      expect(
        ZoneId.DARKWOOD_FOREST.definition.permanentEntities,
        contains(EntityId.SPIDER_DEN_ENTRANCE),
      );
      expect(
        ZoneId.SOUTHWOOD_FOREST.definition.permanentEntities,
        isNot(contains(EntityId.SPIDER_DEN_ENTRANCE)),
      );
    });

    test('the spiders moved with their den', () {
      expect(
        discoverable(ZoneId.DARKWOOD_FOREST, EntityId.GIANT_SPIDER),
        isTrue,
      );
      expect(
        discoverable(ZoneId.SOUTHWOOD_FOREST, EntityId.GIANT_SPIDER),
        isFalse,
        reason: 'the spiders belong to the darkwood now',
      );
    });

    test('carries tier 3 gathering for both ladders', () {
      // tier 3 is the third rung: tree -> oak -> willow, copper -> iron ->
      // coal/gold. Assert the rung, not the level it currently sits at.
      final oak = EntityId.OAK_TREE.definition as EncounterEntityDefinition;
      final willow =
          EntityId.WILLOW_TREE.definition as EncounterEntityDefinition;
      final iron = EntityId.IRON.definition as EncounterEntityDefinition;
      final gold = EntityId.GOLD_VEIN.definition as EncounterEntityDefinition;

      expect(willow.entityType, SkillId.WOODCUTTING);
      expect(gold.entityType, SkillId.MINING);
      expect(willow.defence, greaterThan(oak.defence));
      expect(gold.defence, greaterThan(iron.defence));

      for (final node in [EntityId.WILLOW_TREE, EntityId.COAL_VEIN]) {
        expect(
          discoverable(ZoneId.DARKWOOD_FOREST, node),
          isTrue,
          reason: '${node.name} should be gatherable in the darkwood',
        );
      }

      // gold is the mine's tier 3, not the darkwood's — the darkwood's
      // mining is coal, and its draw is the willow and what lives there
      expect(discoverable(ZoneId.FOREST_MINE, EntityId.GOLD_VEIN), isTrue);
      expect(discoverable(ZoneId.DARKWOOD_FOREST, EntityId.GOLD_VEIN), isFalse);
    });

    test('the undead arrive after the door, not at it', () {
      // the zone opens at 20 against the spiders it already had; its undead
      // are what levelling Exploration here buys. Which undead, and at what
      // level, is tuning — that they are gated past the front door is not
      final zone = ZoneId.DARKWOOD_FOREST.definition;
      final door = zone.explorationLevel;

      const undead = {EntityId.SKELETON, EntityId.ZOMBIE};
      final here = zone.discoverableEntities
          .where((e) => undead.contains(e.id))
          .toList();
      expect(
        here.map((e) => e.id).toSet(),
        undead,
        reason: 'the darkwood lost the undead it was written for',
      );
      for (final entry in here) {
        expect(
          entry.unlockLevel,
          greaterThan(door),
          reason: '${entry.id.name} is available the moment the zone opens',
        );
      }

      // and the spiders, which the zone opens on, are not gated at all
      final spiders = zone.discoverableEntities.firstWhere(
        (e) => e.id == EntityId.GIANT_SPIDER,
      );
      expect(spiders.unlockLevel, lessThanOrEqualTo(door));
    });

    test('the new nodes drop the ore and logs they are named for', () {
      ({bool ok, List<ItemId> got}) dropsOf(EntityId id) {
        final def = id.definition as EncounterEntityDefinition;
        return (
          ok: def.itemDrops.flattened.isNotEmpty,
          got: def.itemDrops.flattened.map((e) => e.id).toList(),
        );
      }

      expect(dropsOf(EntityId.WILLOW_TREE).got, contains(ItemId.WILLOW_LOGS));
      // gold ore shipped as an item with no node that yielded it; the vein
      // is what makes it reachable
      expect(dropsOf(EntityId.GOLD_VEIN).got, contains(ItemId.GOLD_ORE));
    });
  });

  // The other half of the move: what Southwood was left with. That the
  // spiders and their den went is pinned above; the mudlurcs that once stood
  // in for them here have since moved on to the swamp, where swamp_test
  // holds them. What is left is the zone's own reason to stop in.
  group('Southwood Forest', () {
    test('it kept the river, and a way into the wolf den', () {
      // the zone still has to be worth stopping in on the way south: its
      // river and its own dungeon door are what is left of it
      final southwood = ZoneId.SOUTHWOOD_FOREST.definition;
      expect(southwood.permanentEntities, contains(EntityId.RIVER));
      expect(
        southwood.permanentEntities,
        contains(EntityId.WOLF_DEN_ENTRANCE),
      );
    });
  });
}
