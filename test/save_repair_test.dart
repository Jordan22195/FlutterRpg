import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/game_session.dart';

void main() {
  test('loading repairs entities duplicated as permanent and discovered', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);

    final farm = save.worldData.zones[ZoneId.TUTORIAL_FARM]!;

    // corrupt the save the way older versions did: the pond (permanent)
    // also sits in the discovered list with a non-zero count
    final duplicate = EntityId.TRANQUIL_POND.build() as EncounterEntity;
    duplicate.count = 3;
    farm.discoveredEntities.add(duplicate);

    // and a doubled permanent entry
    farm.permanentEntities.add(EntityId.TRANQUIL_POND.build());

    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    // exactly one pond remains, in the permanent list only
    expect(
      farm.permanentEntities.where((e) => e.id == EntityId.TRANQUIL_POND),
      hasLength(1),
    );
    expect(
      farm.discoveredEntities.where((e) => e.id == EntityId.TRANQUIL_POND),
      isEmpty,
    );

    // legitimately discovered entities are untouched
    final tree = EntityId.TREE.build();
    farm.discoveredEntities.add(tree);
    expect(farm.discoveredEntities, contains(tree));

    session.dispose();
  });

  group('a zone drops discovered entities its content no longer defines', () {
    // the filter lives in Zone.fromJson, so every case here has to go
    // through the save file rather than mutating the session in place
    SaveGameData roundTrip(SaveGameData save) {
      return SaveGameData.fromJson(
        jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
      );
    }

    test('an entity that belongs to another zone is dropped', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());

      final farm = save.worldData.zones[ZoneId.TUTORIAL_FARM]!;

      // a legitimate farm find, with a count worth checking survives intact
      final tree = EntityId.TREE.build() as EncounterEntity;
      tree.count = 4;
      farm.discoveredEntities.add(tree);

      // and one the farm never offered - a Southwood discoverable. its id
      // still parses, so only a catalog check can catch it
      final goblin = EntityId.GOBLIN.build() as EncounterEntity;
      goblin.count = 2;
      farm.discoveredEntities.add(goblin);

      final loaded = roundTrip(save).worldData.zones[ZoneId.TUTORIAL_FARM]!;

      expect(
        loaded.discoveredEntities.where((e) => e.id == EntityId.GOBLIN),
        isEmpty,
      );
      final loadedTree = loaded.discoveredEntities.singleWhere(
        (e) => e.id == EntityId.TREE,
      );
      expect((loadedTree as EncounterEntity).count, 4);
    });

    test('an entry still gated behind an unlock level survives', () {
      // unlockLevel gates what the zone can roll, not what a save may keep -
      // a player who found the scarecrow keeps it at any level
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());

      final farm = save.worldData.zones[ZoneId.TUTORIAL_FARM]!;
      farm.discoveredEntities.add(EntityId.ROTWOOD_SCARECROW.build());

      final loaded = roundTrip(save).worldData.zones[ZoneId.TUTORIAL_FARM]!;

      expect(
        loaded.discoveredEntities.where(
          (e) => e.id == EntityId.ROTWOOD_SCARECROW,
        ),
        hasLength(1),
      );
    });

    test('a permanent entity is left for the dedup pass, not filtered out', () {
      // an entity promoted from discoverable to permanent must reach
      // GameSessionFactory.create so the permanent/discovered repair resolves
      // it the way it always has, rather than vanishing here
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final save = factory.newGame(catalogs);

      final pond = EntityId.TRANQUIL_POND.build() as EncounterEntity;
      pond.count = 3;
      save.worldData.zones[ZoneId.TUTORIAL_FARM]!.discoveredEntities.add(pond);

      final reloaded = roundTrip(save);
      expect(
        reloaded.worldData.zones[ZoneId.TUTORIAL_FARM]!.discoveredEntities
            .where((e) => e.id == EntityId.TRANQUIL_POND),
        hasLength(1),
      );

      final session = factory.create(
        save: reloaded,
        catalogs: catalogs,
        vsync: const TestVSync(),
      );

      final farm = reloaded.worldData.zones[ZoneId.TUTORIAL_FARM]!;
      expect(
        farm.permanentEntities.where((e) => e.id == EntityId.TRANQUIL_POND),
        hasLength(1),
      );
      expect(
        farm.discoveredEntities.where((e) => e.id == EntityId.TRANQUIL_POND),
        isEmpty,
      );

      session.dispose();
    });
  });
}
