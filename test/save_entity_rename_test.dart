import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/game_session.dart';
import 'support/gathering_tools.dart';

// An entity id's enum name is what a save stores, so renaming or retiring
// one leaves old saves naming something the catalog no longer has. That
// must cost only the entity itself, as if its count were zero — never the
// load.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const renamed = 'GOBLIN_RENAMED';

  /// A save mid-fight in the Goblin Queen's lair: the goblin on screen, in
  /// the encounter, and filling the run's floors. Returned as JSON with the
  /// session that wrote it.
  (GameSessionFactory, Map<String, dynamic>) fightingSave() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = withGatheringTools(factory.newGame(catalogs));
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    session.inventoryService.setItemCount(
      save.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );
    expect(
      session.dungeonController.startSlot(DungeonId.GOBLIN_QUEEN_LAIR, 0),
      isTrue,
    );
    session.encounterController.doEncounterAction(1);

    // the probe relies on the goblin being everywhere an id is saved
    expect(save.encounterData.entity?.id, EntityId.GOBLIN);
    expect(save.playerData.currentEntityViewId, EntityId.GOBLIN);

    final json = jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
    session.dispose();
    return (factory, json);
  }

  /// [json] with the goblin renamed in [section] alone.
  Map<String, dynamic> renameIn(Map<String, dynamic> json, String section) {
    final copy = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    copy[section] = jsonDecode(
      jsonEncode(copy[section]).replaceAll('"GOBLIN"', '"$renamed"'),
    );
    return copy;
  }

  test('the entity on screen falls back to none', () {
    final (_, json) = fightingSave();
    final save = SaveGameData.fromJson(renameIn(json, 'playerData'));
    expect(save.playerData.currentEntityViewId, EntityId.NULL);
  });

  test('a fight against it comes back empty', () {
    final (_, json) = fightingSave();
    final save = SaveGameData.fromJson(renameIn(json, 'encounterData'));
    expect(save.encounterData.entity, isNull);
    expect(save.encounterData.isActive, isFalse);
  });

  test('a dungeon floor drops it and keeps the rest', () {
    final (_, json) = fightingSave();
    final before = SaveGameData.fromJson(json).dungeonRun;
    final run = SaveGameData.fromJson(renameIn(json, 'dungeonRun')).dungeonRun;

    expect(run.active, isTrue);
    expect(run.slots.length, before.slots.length);
    for (var i = 0; i < run.slots.length; i++) {
      final kept = before.slots[i].members
          .where((m) => m.id != EntityId.GOBLIN)
          .map((m) => m.id);
      expect(run.slots[i].members.map((m) => m.id), kept);
      expect(
        run.slots[i].index,
        lessThanOrEqualTo(run.slots[i].members.length),
      );
    }
    expect(
      before.slots.any((s) => s.members.any((m) => m.id == EntityId.GOBLIN)),
      isTrue,
    );
  });

  test('a discovery list drops it', () {
    final (_, json) = fightingSave();
    final copy = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    final zones = (copy['worldData'] as Map<String, dynamic>)['zones'];
    // plant the renamed id in the first zone's discoveries
    final zone =
        (zones is List ? zones.first : (zones as Map).values.first)
            as Map<String, dynamic>;
    (zone['discoveredEntities'] as List).add({'id': renamed, 'count': 3});

    final save = SaveGameData.fromJson(copy);
    for (final z in save.worldData.zones.values) {
      expect(
        z.discoveredEntities.map((e) => e.id.name),
        isNot(contains(renamed)),
      );
    }
  });

  test('renamed everywhere, the save still loads into a session', () {
    final (factory, json) = fightingSave();
    final copy =
        jsonDecode(jsonEncode(json).replaceAll('"GOBLIN"', '"$renamed"'))
            as Map<String, dynamic>;

    final session = factory.create(
      save: SaveGameData.fromJson(copy),
      catalogs: factory.catalog1(),
      vsync: const TestVSync(),
    );
    final save = session.saveGameData;
    expect(save.encounterData.entity, isNull);
    expect(save.playerData.currentEntityViewId, EntityId.NULL);
    // the run carries on: the session refills its floors from the catalog,
    // and the loop can fire into it
    expect(save.dungeonRun.active, isTrue);
    session.encounterController.doEncounterAction(1);
    session.dispose();
  });
}
