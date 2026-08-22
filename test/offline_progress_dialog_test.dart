import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
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

// a save force-closed mid-fight, [away] ago: a tree in the starting zone
// with the woodcutting encounter bound to it
Map<String, dynamic> savedMidEncounter(Duration away) {
  final factory = GameSessionFactory();
  final catalogs = factory.catalog1();
  final save = factory.newGame(catalogs);
  final session = factory.create(
    save: save,
    catalogs: catalogs,
    vsync: const TestVSync(),
  );

  final tree = EntityId.TREE.build() as EncounterEntity;
  save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities.add(
    tree,
  );
  session.encounterController.startEncounterActionFor(tree);
  save.playerData.lastActionTime = DateTime.now().subtract(away);

  final raw = toRawSave(save);
  session.actionTimingController.stop();
  session.dispose();
  return raw;
}

// a save force-closed mid-fight against something that fights back, [away]
// ago: a flock of chickens, and no food to see the player through them
Map<String, dynamic> savedMidCombat(Duration away) {
  final factory = GameSessionFactory();
  final catalogs = factory.catalog1();
  final save = factory.newGame(catalogs);
  final session = factory.create(
    save: save,
    catalogs: catalogs,
    vsync: const TestVSync(),
  );

  final chicken = EntityId.CHICKEN.build() as EncounterEntity;
  chicken.count = 1000;
  save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities.add(
    chicken,
  );
  session.encounterController.startEncounterActionFor(chicken);
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
    // five minutes at the interval a fresh player explores at - the bench
    // default, divided by the fast stance's speed curve
    final service = ActionTimingService();
    final interval = service.getCurrentActionDuration(
      ActionTimingData()
        ..maxInterval = service.maxIntervalFor(
          equippedInterval: null,
          speedStance: true,
          speedStat: 1,
        ),
    );
    final explores =
        const Duration(minutes: 5).inMicroseconds ~/ interval.inMicroseconds;
    expect(find.text('$explores'), findsOneWidget);
    expect(find.text('Exploration'), findsOneWidget);
    // what the walk turned up: the meadow's entities, counted
    expect(find.text('DISCOVERED'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('coming back to a running encounter reports its kills', (
    tester,
  ) async {
    final raw = savedMidEncounter(const Duration(minutes: 5));

    await tester.pumpWidget(
      MyApp(rawSave: raw, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    expect(find.text('While you were away'), findsOneWidget);
    // what it felled: a total on the away line, and tiles of its own
    expect(find.text('Defeated'), findsOneWidget);
    expect(find.text('DEFEATED'), findsOneWidget);
    expect(find.text('Woodcutting'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('dying while away is reported once, not twice', (tester) async {
    final raw = savedMidCombat(const Duration(hours: 1));

    await tester.pumpWidget(
      MyApp(rawSave: raw, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    // one modal, and it says what happened
    expect(find.text('While you were away'), findsOneWidget);
    expect(find.text('Died'), findsOneWidget);
    expect(find.textContaining('Chicken'), findsWidgets);
    // the shell's own bare death dialog stands down for it
    expect(find.text('You died'), findsNothing);

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
