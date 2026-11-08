import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Blackmire Swamp is the wet ground east of South Haven: mudlurcs, crows,
/// oozes and the rare Murkjaw, the mirecap herb and the marsh's reagents.
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

    test('holds its roster, and nothing it outgrew', () {
      for (final id in [
        EntityId.MUDLURC,
        EntityId.SLIME,
        EntityId.CARRION_CROW,
        EntityId.FUNGAL_MONSTER,
        EntityId.OOZE,
        EntityId.MURKJAW,
        EntityId.MOSS_GOLEM,
      ]) {
        expect(
          entryFor(ZoneId.SWAMP, id),
          isNotNull,
          reason: '${id.name} should live in the swamp',
        );
      }
      // the uncommon mudlurc shared the common's art, and the scorpion was
      // a level-55 desert animal in a bog
      for (final id in [EntityId.MUDLURC_WARRIOR, EntityId.GIANT_SCORPION]) {
        expect(entryFor(ZoneId.SWAMP, id), isNull, reason: id.name);
      }
    });

    test('no two of its discoveries share a picture', () {
      final byArt = <String, List<String>>{};
      for (final e in ZoneId.SWAMP.definition.discoverableEntities) {
        byArt.putIfAbsent(e.id.iconAsset, () => []).add(e.id.name);
      }
      final shared = byArt.values.where((ids) => ids.length > 1);
      expect(shared, isEmpty, reason: 'discoveries drawn alike: $shared');
    });

    test('the harder the monster, the later it is found', () {
      final ladder = [EntityId.MUDLURC, EntityId.OOZE, EntityId.MOSS_GOLEM];
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

    test('the murkjaw is rare, and the only monster with its fang', () {
      final murkjaw = entryFor(ZoneId.SWAMP, EntityId.MURKJAW)!;
      for (final e in ZoneId.SWAMP.definition.discoverableEntities) {
        if (e.id == EntityId.MURKJAW) continue;
        if (e.id.definition is! CombatEntityDefinition) continue;
        expect(murkjaw.weight, lessThanOrEqualTo(e.weight), reason: e.id.name);
      }

      bool drops(EntityId id, ItemId item) {
        final def = id.definition as EncounterEntityDefinition;
        return {
          ...def.itemDrops.flattened.map((d) => d.id),
          for (final roll in def.bonusDrops)
            ...roll.entries.flattened.map((d) => d.id),
        }.contains(item);
      }

      final fangDroppers = [
        for (final id in EntityId.values)
          if (id.definition is EncounterEntityDefinition &&
              drops(id, ItemId.MURKJAW_FANG))
            id,
      ];
      expect(
        fangDroppers.every(
          (id) =>
              (id.definition as CombatEntityDefinition).iconAsset ==
              EntityId.MURKJAW.iconAsset,
        ),
        isTrue,
        reason: 'only murkjaws drop the fang: $fangDroppers',
      );
    });

    test('gathers herbs, wood and marsh reagents', () {
      expect(entryFor(ZoneId.SWAMP, EntityId.MIRECAP), isNotNull);
      expect(entryFor(ZoneId.SWAMP, EntityId.BOG_TREE), isNotNull);
      expect(
        ZoneId.SWAMP.definition.permanentEntities,
        containsAll([EntityId.MURKY_MARSH, EntityId.DROWNED_FEN_ENTRANCE]),
      );

      // the marsh is the River's equivalent: the same level and numbers
      final marsh = EntityId.MURKY_MARSH.definition as FishingEntityDefinition;
      final river = EntityId.RIVER.definition as FishingEntityDefinition;
      expect(marsh.requiredLevel, river.requiredLevel);
      expect(marsh.defence, river.defence);
      expect(marsh.hitpoints, river.hitpoints);
      expect(
        marsh.itemDrops.flattened.map((d) => d.id),
        containsAll([ItemId.BOG_EEL, ItemId.LEECH, ItemId.MARSH_FROG]),
      );

      // and the bog tree is willow's side-grade
      final bog = EntityId.BOG_TREE.definition as EncounterEntityDefinition;
      final willow =
          EntityId.WILLOW_TREE.definition as EncounterEntityDefinition;
      expect(bog.defence, willow.defence);
      expect(bog.hitpoints, willow.hitpoints);
    });

    test('its monsters drop something other than coins', () {
      for (final id in [
        EntityId.FUNGAL_MONSTER,
        EntityId.CARRION_CROW,
        EntityId.OOZE,
        EntityId.MURKJAW,
      ]) {
        final def = id.definition as EncounterEntityDefinition;
        final loot = {
          ...def.itemDrops.flattened.map((d) => d.id),
          for (final roll in def.bonusDrops)
            ...roll.entries.flattened.map((d) => d.id),
        }..remove(ItemId.COINS);
        expect(loot, isNotEmpty, reason: '${id.name} drops only coins');
      }
    });
  });
}
