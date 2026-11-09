import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';

import 'support/memory_save_store.dart';

/// A save must survive the catalog changing under it. Every save writes a
/// world entry for every zone, so renaming a zone used to fail the whole
/// load — and the bootstrap then started a new game and autosaved it over
/// the player's save. These pin the three defences: renamed zones resolve,
/// unknown zones are dropped, and a save that still can't load is copied
/// aside before anything can overwrite it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final factory = GameSessionFactory();

  /// A real save with some progress on it, as JSON, the way it sits on disk.
  Map<String, dynamic> savedGame() {
    final save = factory.newGame(factory.catalog1(), slotId: 'slot_1');
    final attack = save.playerData.skillData[SkillId.ATTACK]!;
    attack.xp = attack.xpTable[30];
    return jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
  }

  /// [raw] with [from]'s world entry and the player's position written under
  /// the name [to] instead — what a save from before a rename looks like.
  Map<String, dynamic> withZoneNamed(
    Map<String, dynamic> raw,
    ZoneId from,
    String to,
  ) {
    final zones = raw['worldData']['zones'] as Map<String, dynamic>;
    final entry = Map<String, dynamic>.from(zones.remove(from.name) as Map);
    entry['id'] = to;
    zones[to] = entry;
    raw['playerData']['currentZoneId'] = to;
    raw['playerData']['currentZoneViewId'] = to;
    return raw;
  }

  SaveGameData load(Map<String, dynamic> raw) {
    final save = SaveGameData.fromJson(raw);
    factory.create(
      save: save,
      catalogs: factory.catalog1(),
      vsync: const TestVSync(),
    );
    return save;
  }

  group('a renamed zone', () {
    test('every old name resolves, and none shadows a live zone', () {
      for (final entry in ZoneId.renamed.entries) {
        expect(ZoneId.byName(entry.key), entry.value);
        expect(
          ZoneId.values.map((z) => z.name),
          isNot(contains(entry.key)),
          reason: '${entry.key} is a live zone name, not a former one',
        );
      }
    });

    test('a save from before the rename loads into the new zone', () {
      final raw = withZoneNamed(
        savedGame(),
        ZoneId.IRON_GATE_CITY,
        'GLIMMERFORD',
      );

      final save = load(raw);

      expect(save.playerData.currentZoneId, ZoneId.IRON_GATE_CITY);
      expect(save.playerData.currentZoneViewId, ZoneId.IRON_GATE_CITY);
      expect(save.worldData.zones.keys, contains(ZoneId.IRON_GATE_CITY));
      final attack = save.playerData.skillData[SkillId.ATTACK]!;
      expect(attack.xp, attack.xpTable[30], reason: 'progress is kept');
    });
  });

  group('a zone the catalog no longer has', () {
    test('is dropped, and the rest of the save loads', () {
      final raw = withZoneNamed(
        savedGame(),
        ZoneId.IRONROOT_HILLS,
        'SOME_RETIRED_ZONE',
      );

      final save = load(raw);

      // standing in it puts you back at the start rather than losing the save
      expect(save.playerData.currentZoneId, ZoneId.TUTORIAL_FARM);
      // and the zone that really exists is rebuilt from the catalog
      expect(save.worldData.zones.keys, contains(ZoneId.IRONROOT_HILLS));
      final attack = save.playerData.skillData[SkillId.ATTACK]!;
      expect(attack.xp, attack.xpTable[30], reason: 'progress is kept');
    });
  });

  group('a save that cannot be loaded at all', () {
    testWidgets('is copied aside before a new game can replace it', (
      tester,
    ) async {
      final store = MemorySaveStore();
      final files = FileManagerService(store: store);
      final index = await files.loadIndex();

      // broken past what the loader tolerates
      final raw = savedGame()..remove('playerData');
      await files.saveSlot(index.activeSlotId, raw);

      await tester.pumpWidget(
        MyApp(
          rawSave: await files.loadSlot(index.activeSlotId),
          fileManagerService: files,
          saveSlots: index,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final copies = store.documents.keys
          .where((name) => name.startsWith('save_slot_1_unreadable_'))
          .toList();
      expect(copies, hasLength(1), reason: 'the unreadable save is kept');
      expect(store.peek(copies.single), raw);

      // the game started fresh and is free to autosave; the copy stays put
      await tester.pump(const Duration(seconds: 31));
      expect(store.peek(copies.single), raw);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an empty slot is a first run, and keeps no copy', (
      tester,
    ) async {
      final store = MemorySaveStore();
      final files = FileManagerService(store: store);
      final index = await files.loadIndex();

      await tester.pumpWidget(
        MyApp(
          rawSave: await files.loadSlot(index.activeSlotId),
          fileManagerService: files,
          saveSlots: index,
        ),
      );
      await tester.pump();

      expect(
        store.documents.keys.where((n) => n.contains('_unreadable_')),
        isEmpty,
      );

      await tester.pumpWidget(const SizedBox());
    });
  });
}
