import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'support/gathering_tools.dart';

// What a level gates: a zone's discoveries open up across the Exploration
// levels between it and the next zone, a fishing spot waits on a Fishing
// level, and each spot's fish open up one at a time after it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------- discoveries

  group('zone discoveries', () {
    // the zones a player progresses through, by the Exploration level they
    // ask for. dev zones sit outside the ladder
    final ladder =
        ZoneId.values
            .where(
              (z) =>
                  !z.name.startsWith('DEV_') &&
                  z != ZoneId.NULL &&
                  z.definition.type == MapNodeType.WILDERNESS &&
                  z.definition.discoverableEntities.isNotEmpty,
            )
            .toList()
          ..sort(
            (a, b) => a.definition.explorationLevel.compareTo(
              b.definition.explorationLevel,
            ),
          );

    /// The Exploration level of the next zone up, or five past the last.
    int nextLevel(ZoneId zone) {
      final level = zone.definition.explorationLevel;
      for (final z in ladder) {
        if (z.definition.explorationLevel > level) {
          return z.definition.explorationLevel;
        }
      }
      return level + 5;
    }

    test('the ladder has the zones it should', () {
      expect(ladder, contains(ZoneId.TUTORIAL_FARM));
      expect(ladder, contains(ZoneId.FOOTHILLS));
    });

    for (final zone in [
      ZoneId.TUTORIAL_FARM,
      ZoneId.SOUTHWOOD_FOREST,
      ZoneId.FOREST_MINE,
      ZoneId.DARKWOOD_FOREST,
      ZoneId.SWAMP,
      ZoneId.CHALLENGING_MOUNTAIN,
      ZoneId.FOOTHILLS,
    ]) {
      test(
        '${zone.name} opens at its own level and stops short of the next',
        () {
          final def = zone.definition;
          final unlocks = def.discoverableEntities
              .map((e) => e.unlockLevel)
              .toList();

          // the first find is there the moment you can enter
          expect(unlocks.reduce((a, b) => a < b ? a : b), def.explorationLevel);
          // and the last opens up before the next zone does
          for (final level in unlocks) {
            expect(level, greaterThanOrEqualTo(def.explorationLevel));
            expect(level, lessThan(nextLevel(zone)));
          }
        },
      );
    }
  });

  // ---------------------------------------------------------- fishing data

  group('fishing spots', () {
    const spots = {
      EntityId.TRANQUIL_POND: 1,
      EntityId.CREEK: 10,
      EntityId.RIVER: 20,
      EntityId.DEEP_POND: 50,
      EntityId.LAKE: 60,
      EntityId.OCEAN: 80,
    };

    FishingEntityDefinition def(EntityId id) =>
        id.definition as FishingEntityDefinition;

    test('each spot asks for its Fishing level', () {
      for (final MapEntry(key: id, value: level) in spots.entries) {
        expect(def(id).requiredLevel, level, reason: '$id');
      }
    });

    test('a spot\'s first fish opens with it; the rest step up toward the '
        'next spot', () {
      final ordered = spots.keys.toList();
      for (var i = 0; i < ordered.length; i++) {
        final spot = def(ordered[i]);
        final next = i + 1 < ordered.length
            ? def(ordered[i + 1]).requiredLevel
            : 100;
        final levels = spot.itemDrops.map((f) => f.unlockLevel).toList();

        expect(levels.first, spot.requiredLevel, reason: spot.name);
        for (var j = 1; j < levels.length; j++) {
          expect(levels[j], greaterThan(levels[j - 1]), reason: spot.name);
        }
        expect(levels.last, lessThan(next), reason: spot.name);
      }
    });

    test('a spot\'s defence matches its gate, as an herb\'s does', () {
      for (final id in spots.keys) {
        expect(def(id).defence, def(id).requiredLevel, reason: '$id');
      }
    });

    test('a fish cooks at the Fishing level that catches it', () {
      final cooking = GameSessionFactory()
          .catalog1()
          .recipeCatalog
          .recipesForSkill(SkillId.COOKING);
      var checked = 0;
      for (final id in spots.keys) {
        for (final fish in def(id).itemDrops) {
          final recipes = cooking.where((r) => r.inputs.containsKey(fish.id));
          for (final recipe in recipes) {
            expect(
              recipe.levelRequirement,
              fish.unlockLevel,
              reason: '${recipe.id} cooks ${fish.id.name}',
            );
            checked++;
          }
        }
      }
      expect(checked, greaterThanOrEqualTo(10));
    });

    test('every fish has one home', () {
      final homes = <ItemId, EntityId>{};
      for (final id in spots.keys) {
        for (final fish in def(id).itemDrops) {
          expect(
            homes.containsKey(fish.id),
            isFalse,
            reason: '${fish.id} is in ${homes[fish.id]} and $id',
          );
          homes[fish.id] = id;
        }
      }
    });

    test('the creek is Southwood Forest\'s spot, in place of the river', () {
      final southwood = ZoneId.SOUTHWOOD_FOREST.definition;
      expect(southwood.permanentEntities, contains(EntityId.CREEK));
      expect(southwood.permanentEntities, isNot(contains(EntityId.RIVER)));
    });
  });

  // ---------------------------------------------------------- fishing play

  group('fishing gates', () {
    GameSession buildSession() {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      return factory.create(
        save: withGatheringTools(factory.newGame(catalogs)),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
    }

    void setLevel(GameSession session, SkillId skill, int level) {
      final data = session.saveGameData.playerData.skillData[skill]!;
      data.xp = data.xpTable[level];
    }

    void fishAt(GameSession session, EntityId id) {
      final save = session.saveGameData;
      session.explorationService.addEntityToCurrentZone(
        id,
        1,
        save.playerData,
        save.worldData,
      );
      final entity =
          session.explorationService.getEntity(
                id,
                save.playerData.currentZoneId,
                save.worldData,
              )
              as EncounterEntity;
      session.encounterService.setEncounterEntity(save.encounterData, entity);
    }

    // a long stretch of casts, settled in one pass the way offline time is
    EncounterActionResult cast(GameSession session, int casts) {
      final save = session.saveGameData;
      return session.encounterSystem.executeFishingAction(
        playerState: save.playerData,
        encounter: save.encounterData,
        world: save.worldData,
        playerInventory: save.inventoryData,
        actionCount: casts,
        offline: true,
      );
    }

    Set<ItemId> caught(EncounterActionResult result) =>
        result.items.map((stack) => stack.id as ItemId).toSet();

    test('below a spot\'s level, casting there catches nothing', () {
      final session = buildSession();
      // well under the river's 20: the rod in hand adds Fishing of its own
      setLevel(session, SkillId.FISHING, 12);
      fishAt(session, EntityId.RIVER);

      expect(
        session.encounterSystem.meetsLevelRequirement(
          session.saveGameData.playerData,
          EntityId.RIVER,
        ),
        isFalse,
      );
      final result = cast(session, 500);
      expect(result.items, isEmpty);
      expect(result.actionsPerformed, 0);

      session.dispose();
    });

    test('at the spot\'s level only its first fish bites', () {
      final session = buildSession();
      setLevel(session, SkillId.FISHING, 1);
      fishAt(session, EntityId.TRANQUIL_POND);

      // carp opens at 5, so a level-1 angler lands minnows alone
      expect(caught(cast(session, 2000)), {ItemId.MINNOW});

      session.dispose();
    });

    test('a fish opens up at its own level', () {
      final session = buildSession();
      setLevel(session, SkillId.FISHING, 5);
      fishAt(session, EntityId.TRANQUIL_POND);

      expect(caught(cast(session, 2000)), {ItemId.MINNOW, ItemId.CARP});

      session.dispose();
    });

    test('the zone card and the screen read the same gate', () {
      final session = buildSession();
      // the rod in hand adds Fishing of its own, so stay well under 10
      setLevel(session, SkillId.FISHING, 5);

      expect(session.worldController.requiredLevelFor(EntityId.CREEK), 10);
      expect(
        session.worldController.meetsEntityRequirement(EntityId.CREEK),
        isFalse,
      );
      setLevel(session, SkillId.FISHING, 10);
      expect(
        session.worldController.meetsEntityRequirement(EntityId.CREEK),
        isTrue,
      );

      session.dispose();
    });
  });
}
