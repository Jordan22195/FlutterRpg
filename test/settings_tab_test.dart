import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/main.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
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

Map<String, dynamic> newRawSave({int tabIndex = 0}) {
  final factory = GameSessionFactory();
  final save = factory.newGame(factory.catalog1());
  save.uiState.tabIndex = tabIndex;
  return jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
}

void main() {
  testWidgets('the settings tab opens the settings screen and is saved as '
      'the active tab', (tester) async {
    // phone width: six tabs have to share the bar
    tester.view.physicalSize = const Size(375, 812) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(
        rawSave: newRawSave(),
        fileManagerService: FileManagerService(store: MemorySaveStore()),
      ),
    );
    await settle(tester);
    expect(find.byType(SettingsScreen), findsNothing);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await settle(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    final session = tester
        .element(find.byType(SettingsScreen))
        .read<GameSession>();
    expect(session.saveGameData.uiState.tabIndex, 5);
  });

  testWidgets('relaunch restores the settings tab', (tester) async {
    await tester.pumpWidget(
      MyApp(
        rawSave: newRawSave(tabIndex: 5),
        fileManagerService: FileManagerService(store: MemorySaveStore()),
      ),
    );
    await settle(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets(
    'starting a save over confirms, then boots a fresh save that keeps '
    'the debug cap',
    (tester) async {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      save.uiState.tabIndex = 5;
      final attack = save.playerData.skillData[SkillId.ATTACK]!;
      attack.xp = attack.xpTable[30];
      save.debugSettings.maxSkillLevel = 7;

      await tester.pumpWidget(
        MyApp(
          rawSave:
              jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
          fileManagerService: FileManagerService(store: MemorySaveStore()),
        ),
      );
      await settle(tester);

      // cancelling keeps the game as it was
      await tester.tap(find.byKey(const ValueKey('settings-reset-save')));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      GameSession session() =>
          tester.element(find.byType(MainShell)).read<GameSession>();
      expect(
        session().saveGameData.playerData.skillData[SkillId.ATTACK]!.xp,
        attack.xp,
      );

      await tester.tap(find.byKey(const ValueKey('settings-reset-save')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('new-game-confirm')));
      await settle(tester);

      final fresh = session().saveGameData;
      expect(fresh.playerData.skillData[SkillId.ATTACK]!.xp, 0);
      expect(fresh.debugSettings.maxSkillLevel, 7);
      // a fresh save opens on the map tab
      expect(find.byType(SettingsScreen), findsNothing);
    },
  );

  testWidgets('the debug max skill level switch and slider set the cap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        rawSave: newRawSave(tabIndex: 5),
        fileManagerService: FileManagerService(store: MemorySaveStore()),
      ),
    );
    await settle(tester);
    final session = tester
        .element(find.byType(SettingsScreen))
        .read<GameSession>();
    expect(session.saveGameData.debugSettings.maxSkillLevel, isNull);

    await tester.tap(find.byKey(const ValueKey('settings-skill-cap-switch')));
    await settle(tester);
    expect(
      session.saveGameData.debugSettings.maxSkillLevel,
      SettingsScreen.defaultSkillLevelCap,
    );

    // dragging the slider all the way left lands on level 1
    await tester.drag(
      find.byKey(const ValueKey('settings-skill-cap-slider')),
      const Offset(-1000, 0),
    );
    await settle(tester);
    expect(session.saveGameData.debugSettings.maxSkillLevel, 1);

    await tester.tap(find.byKey(const ValueKey('settings-skill-cap-switch')));
    await settle(tester);
    expect(session.saveGameData.debugSettings.maxSkillLevel, isNull);
  });
}
