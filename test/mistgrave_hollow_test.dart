import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/item_drop_type.dart';

/// Mistgrave Hollow is the haunted cemetery south of the darkwood, at
/// Stormgrass Prairie's tier: exploration 35, the dead at 55 and 89, and
/// the Haunted Ruins — an abandoned monastery — whose three floors each end
/// in a level-144 boss. It is a combat zone; there is nothing to gather.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hollow = ZoneId.MISTGRAVE_HOLLOW.definition;
  final ruins = DungeonId.HAUNTED_RUINS.definition;

  CombatEntityDefinition combat(EntityId id) =>
      id.definition as CombatEntityDefinition;

  Iterable<EntityId> discoverable() =>
      hollow.discoverableEntities.map((e) => e.id);

  group('Mistgrave Hollow', () {
    test('lies south of the darkwood, a dead end off it', () {
      expect(
        ZoneTravelGraph.travelHops(
          ZoneId.DARKWOOD_FOREST,
          ZoneId.MISTGRAVE_HOLLOW,
        ),
        1,
      );
      expect(
        ZoneTravelGraph.travelPath(
          ZoneId.TUTORIAL_FARM,
          ZoneId.MISTGRAVE_HOLLOW,
        ),
        [
          ZoneId.TUTORIAL_FARM,
          ZoneId.SOUTHWOOD_FOREST,
          ZoneId.SOUTH_HAVEN,
          ZoneId.DARKWOOD_FOREST,
          ZoneId.MISTGRAVE_HOLLOW,
        ],
      );
      // the road is walked the same either way
      expect(
        ZoneTravelGraph.edgeTravelTime(
          ZoneId.DARKWOOD_FOREST,
          ZoneId.MISTGRAVE_HOLLOW,
        ),
        ZoneTravelGraph.edgeTravelTime(
          ZoneId.MISTGRAVE_HOLLOW,
          ZoneId.DARKWOOD_FOREST,
        ),
      );
      expect(zoneNodeCenter(ZoneId.MISTGRAVE_HOLLOW), isNotNull);
    });

    test("sits on Stormgrass Prairie's tier", () {
      final prairie = ZoneId.FOOTHILLS.definition;
      expect(hollow.name, 'Mistgrave Hollow');
      expect(hollow.explorationLevel, prairie.explorationLevel);
      expect(hollow.xpPerExplore, prairie.xpPerExplore);
    });

    test('keeps a fire and the way into the ruins', () {
      // a firepit in a zone opens all five of its fire slots
      expect(hollow.permanentEntities, [
        ...FireSlots.slots,
        EntityId.HAUNTED_RUINS_ENTRANCE,
      ]);
    });

    test('turns up only the dead, at 55 and 89 (the zombie at 34)', () {
      expect(discoverable(), [
        EntityId.RESTLESS_SKELETON,
        EntityId.ZOMBIE,
        EntityId.GRAVE_GHOUL,
        EntityId.WAILING_BANSHEE,
        EntityId.MIST_WRAITH,
      ]);
      for (final id in discoverable()) {
        expect(combat(id).level, anyOf(34, 55, 89), reason: id.name);
        // only the plain zombie, lowered in the rebalance, runs at 34
        if (combat(id).level == 34) expect(id, EntityId.ZOMBIE);
        expect(combat(id).isDungeonBoss, isFalse, reason: id.name);
      }
    });

    test('gates the 89s past its door, the way the prairie does', () {
      for (final e in hollow.discoverableEntities) {
        final def = combat(e.id);
        if (def.level <= 55) {
          expect(e.unlockLevel, hollow.explorationLevel, reason: e.id.name);
        } else {
          expect(
            e.unlockLevel,
            greaterThan(hollow.explorationLevel),
            reason: e.id.name,
          );
        }
      }
    });
  });

  group('Haunted Ruins', () {
    test('is entered from the hollow', () {
      final entrance =
          EntityId.HAUNTED_RUINS_ENTRANCE.definition as DungeonEntityDefinition;
      expect(entrance.dungeonId, DungeonId.HAUNTED_RUINS);
      expect(ruins.name, 'Haunted Ruins');
      expect(ruins.type, DungeonType.ZONE);
    });

    test('runs three floors, each ending in a level-144 boss', () {
      expect(ruins.entries.map((c) => c.name), [
        'The Graveyard Gate',
        'The Silent Nave',
        'The Ossuary',
      ]);
      expect(ruins.entries.map((c) => c.entities.last.entityId), [
        EntityId.THE_GRAVEKEEPER,
        EntityId.THE_SHROUDED_WRAITH,
        EntityId.THE_UNDYING_ABBOT,
      ]);
      for (final card in ruins.entries) {
        final boss = card.entities.last;
        expect(boss.count, 1, reason: card.name);
        expect(combat(boss.entityId).isDungeonBoss, isTrue, reason: card.name);
        expect(combat(boss.entityId).level, 144, reason: card.name);
        for (final ref in card.entities.take(card.entities.length - 1)) {
          final def = combat(ref.entityId);
          expect(def.isDungeonBoss, isFalse, reason: ref.entityId.name);
          expect(def.level, anyOf(34, 55, 89), reason: ref.entityId.name);
        }
      }
    });

    test('fills a full clear with as many fights as Tempest Reach', () {
      int fights(DungeonDefinition d) => [
        for (final card in d.entries)
          for (final ref in card.entities) ref.count,
      ].fold(0, (a, b) => a + b);
      expect(fights(ruins), fights(DungeonId.TEMPEST_REACH.definition));
    });

    test('pays a chest on a full clear', () {
      expect(ruins.chestRolls, isNotEmpty);
      for (final roll in ruins.chestRolls) {
        expect(roll.entries, isNotEmpty);
      }
    });
  });

  test('every monster in the hollow and the ruins drops something', () {
    // an empty table is not rollable: the roller hands back a cast that
    // throws, so a monster with nothing to drop cannot be fought
    final monsters = {
      ...discoverable(),
      for (final card in ruins.entries)
        for (final ref in card.entities) ref.entityId,
    };
    for (final id in monsters) {
      expect(combat(id).itemDrops.flattened, isNotEmpty, reason: id.name);
    }
  });
}
