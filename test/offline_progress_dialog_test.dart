import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';

// Coming back to a running action: the first frame settles the time away and
// the shell reports it, whichever screen the app was closed on.
//
// Fixed pumps instead of pumpAndSettle, as everywhere else in the widget
// tests: BuffController's periodic timer never settles.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

Map<String, dynamic> toRawSave(SaveGameData save) {
  return jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
}

// a save force-closed mid-explore, [away] ago
Map<String, dynamic> savedMidExplore(Duration away) {
  final factory = GameSessionFactory();
  final catalogs = factory.catalog1();
  final save = factory.newGame(catalogs);
  final session = factory.create(
    save: save,
    catalogs: catalogs,
    vsync: const TestVSync(),
  );

  session.worldController.startExplore();
  // starting stamps the clock, so the gap is opened after it
  save.playerData.lastActionTime = DateTime.now().subtract(away);

  final raw = toRawSave(save);
  session.actionTimingController.stop();
  session.dispose();
  return raw;
}

void main() {
  testWidgets('coming back to a running explore reports what it earned', (
    tester,
  ) async {
    final raw = savedMidExplore(const Duration(minutes: 5));

    await tester.pumpWidget(
      MyApp(rawSave: raw, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    expect(find.text('While you were away'), findsOneWidget);
    // 5 minutes at the 3s default interval, and the xp it paid
    expect(find.text('100'), findsOneWidget);
    expect(find.text('Exploration'), findsOneWidget);
    // what the walk turned up: the meadow's entities, counted
    expect(find.text('DISCOVERED'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the report is dismissed for good', (tester) async {
    final raw = savedMidExplore(const Duration(minutes: 5));

    await tester.pumpWidget(
      MyApp(rawSave: raw, fileManagerService: FileManagerService()),
    );
    await settle(tester);
    expect(find.text('While you were away'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);

    expect(find.text('While you were away'), findsNothing);

    // the loop is still running, and its frames must not raise it again
    await settle(tester);
    await settle(tester);
    expect(find.text('While you were away'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
