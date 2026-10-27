import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/controllers/save_slot_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/main_shell.dart';
import 'package:rpg/screens/settings_screen.dart';
import 'package:rpg/services/file_manager_service.dart';

import 'support/memory_save_store.dart';

// Fixed pumps instead of pumpAndSettle for the same reason as
// screen_navigation_test: BuffController's periodic timer never settles.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

SaveGameData newSave({String slotId = 'slot_1'}) {
  final factory = GameSessionFactory();
  return factory.newGame(factory.catalog1(), slotId: slotId);
}

// boots the app the way main() does: index first, then the active slot
Future<void> bootApp(WidgetTester tester, FileManagerService files) async {
  final index = await files.loadIndex();
  final raw = await files.loadSlot(index.activeSlotId);
  await tester.pumpWidget(
    MyApp(rawSave: raw, fileManagerService: files, saveSlots: index),
  );
  await settle(tester);
}

GameSession liveSession(WidgetTester tester) =>
    tester.element(find.byType(MainShell)).read<GameSession>();

SaveSlotController slotController(WidgetTester tester) =>
    tester.element(find.byType(MainShell)).read<SaveSlotController>();

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Settings'));
  await settle(tester);
}

void main() {
  group('FileManagerService slots', () {
    test('a first launch with no saves starts a single empty slot', () async {
      final store = MemorySaveStore();
      final files = FileManagerService(store: store);

      final index = await files.loadIndex();

      expect(index.activeSlotId, 'slot_1');
      expect(index.slots.map((s) => s.id), ['slot_1']);
      expect(await files.loadSlot('slot_1'), isEmpty);
      // the index is written, so the next launch reads it back
      expect(store.peek(FileManagerService.indexName), isNotNull);
    });

    test(
      'the pre-slot save becomes the first slot and is left in place',
      () async {
        final store = MemorySaveStore();
        final legacy = newSave();
        final attack = legacy.playerData.skillData[SkillId.ATTACK]!;
        attack.xp = attack.xpTable[12];
        await store.write(FileManagerService.legacyName, legacy.toJson());
        final files = FileManagerService(store: store);

        final index = await files.loadIndex();
        final slot = SaveGameData.fromJson(await files.loadSlot('slot_1'));

        expect(index.activeSlotId, 'slot_1');
        expect(slot.playerData.skillData[SkillId.ATTACK]!.xp, attack.xp);
        expect(store.peek(FileManagerService.legacyName), isNotNull);

        // a second launch reads the index rather than migrating again
        store.documents.remove(FileManagerService.legacyName);
        final again = await files.loadIndex();
        expect(again.slots.map((s) => s.id), ['slot_1']);
      },
    );
  });

  testWidgets('a new save switches to a fresh game and keeps the old one', (
    tester,
  ) async {
    final store = MemorySaveStore();
    final files = FileManagerService(store: store);
    await bootApp(tester, files);

    final attack = liveSession(
      tester,
    ).saveGameData.playerData.skillData[SkillId.ATTACK]!;
    attack.xp = attack.xpTable[20];

    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-new-save')));
    await settle(tester);

    // the new slot is the one running, with a fresh game in it
    final fresh = liveSession(tester).saveGameData;
    expect(fresh.slotId, 'slot_2');
    expect(fresh.playerData.skillData[SkillId.ATTACK]!.xp, 0);
    expect(slotController(tester).activeSlotId, 'slot_2');
    expect(slotController(tester).slots.map((s) => s.name), [
      'Save 1',
      'Save 2',
    ]);

    // the save that was left was written on the way out
    final left = SaveGameData.fromJson(await files.loadSlot('slot_1'));
    expect(left.playerData.skillData[SkillId.ATTACK]!.xp, attack.xp);
    expect(
      slotController(tester).slots.first.totalLevel,
      greaterThan(slotController(tester).slots.last.totalLevel),
    );

    // and switching back puts its progress back
    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-save-slot_1')));
    await settle(tester);
    final back = liveSession(tester).saveGameData;
    expect(back.slotId, 'slot_1');
    expect(back.playerData.skillData[SkillId.ATTACK]!.xp, attack.xp);
  });

  testWidgets('swapping back to a save pays out the time spent away as '
      'offline progress', (tester) async {
    final store = MemorySaveStore();
    final files = FileManagerService(store: store);
    await bootApp(tester, files);

    // slot 1 is exploring when it is left
    liveSession(tester).worldController.startExplore();
    await settle(tester);
    expect(liveSession(tester).actionTimingController.isRunning, isTrue);

    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-new-save')));
    await settle(tester);

    // left with its action still running, so coming back owes the gap
    final leftRaw = store.peek(FileManagerService.slotName('slot_1'))!;
    final left = SaveGameData.fromJson(leftRaw);
    expect(left.actionTimingData.running, isTrue);

    // ten minutes spent in the other save
    left.playerData.lastActionTime = DateTime.now().subtract(
      const Duration(minutes: 10),
    );
    await files.saveSlot('slot_1', left.toJson());

    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-save-slot_1')));
    await settle(tester);
    // the boot, the resume and the settle each take a frame or more, and
    // the dialog waits for the frame after the settle
    await settle(tester);

    expect(find.text('While you were away'), findsOneWidget);
    expect(liveSession(tester).actionTimingController.isRunning, isTrue);
  });

  testWidgets('starting a save over leaves the other saves alone', (
    tester,
  ) async {
    final store = MemorySaveStore();
    final other = newSave(slotId: 'slot_1');
    final otherAttack = other.playerData.skillData[SkillId.ATTACK]!;
    otherAttack.xp = otherAttack.xpTable[15];
    final files = FileManagerService(store: store);
    await files.loadIndex();
    await files.saveSlot('slot_1', other.toJson());
    await bootApp(tester, files);

    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-new-save')));
    await settle(tester);
    final attack = liveSession(
      tester,
    ).saveGameData.playerData.skillData[SkillId.ATTACK]!;
    attack.xp = attack.xpTable[30];

    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-reset-save')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('new-game-confirm')));
    await settle(tester);

    final reset = liveSession(tester).saveGameData;
    expect(reset.slotId, 'slot_2');
    expect(reset.playerData.skillData[SkillId.ATTACK]!.xp, 0);
    final untouched = SaveGameData.fromJson(await files.loadSlot('slot_1'));
    expect(untouched.playerData.skillData[SkillId.ATTACK]!.xp, otherAttack.xp);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('a save is tagged from its 3-dot menu, and the tag sticks', (
    tester,
  ) async {
    final store = MemorySaveStore();
    final files = FileManagerService(store: store);
    await bootApp(tester, files);

    await openSettings(tester);
    // untagged saves draw no chip
    expect(
      find.byKey(const ValueKey('settings-save-tag-slot_1')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('settings-save-menu-slot_1')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('settings-save-change-tag')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('settings-tag-field')),
      '  Ironman  ',
    );
    await tester.tap(find.byKey(const ValueKey('settings-tag-save')));
    await settle(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('settings-save-tag-slot_1')),
        matching: find.text('Ironman'),
      ),
      findsOneWidget,
    );

    // it is in the index on disk, trimmed, so a relaunch keeps it
    final reloaded = await FileManagerService(store: store).loadIndex();
    expect(reloaded.slot('slot_1')!.tag, 'Ironman');

    // a blank tag clears it
    await slotController(tester).setTag('slot_1', '   ');
    await settle(tester);
    expect(
      find.byKey(const ValueKey('settings-save-tag-slot_1')),
      findsNothing,
    );
    expect(
      (await FileManagerService(store: store).loadIndex()).slot('slot_1')!.tag,
      isEmpty,
    );
  });
}
