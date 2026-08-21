import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/explore_screen.dart';
import 'package:rpg/screens/main_shell.dart';
import 'package:rpg/services/file_manager_service.dart';

// Fixed pumps instead of pumpAndSettle: the session's periodic timers
// never settle. Long enough to finish M3 route transitions (800ms).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

// An enemy that swings almost immediately, hits hard, and outlasts
// anything the player can do to it - so the player is the one who dies.
CombatEntity lethalEnemy() {
  return CombatEntity(
    id: EntityId.CHICKEN,
    name: 'Test enemy',
    count: 1,
    defence: 0,
    hitpoints: 100000,
    attack: 100000,
    attackInterval: 0.001,
  );
}

void main() {
  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  // the enemy swing timer runs off the wall clock, so frames have to be
  // spaced by real time for an attack to land
  Future<void> fightUntilDeath(EncounterController encounter) async {
    for (var i = 0; i < 100; i++) {
      encounter.onActionTimingFrame();
      if (encounter.deathSequence > 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test(
    'dying in an encounter ends the action and bumps the death sequence',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final session = buildSession();
      final player = session.saveGameData.playerData;
      final encounter = session.encounterController;

      expect(encounter.startEncounterActionFor(lethalEnemy()), isTrue);
      expect(encounter.deathSequence, 0);

      await fightUntilDeath(encounter);

      expect(encounter.deathSequence, 1);
      // the loop stops and the player is left on 1 hp, not 0
      expect(session.actionTimingController.isRunning, isFalse);
      expect(player.hitpoints, 1);

      session.dispose();
    },
  );

  testWidgets('dying unwinds the map tab to the map screen and says so', (
    tester,
  ) async {
    // empty raw save triggers the new-game fallback
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    final shellContext = tester.element(find.byType(MainShell));
    final session = Provider.of<GameSession>(shellContext, listen: false);
    final encounter = session.encounterController;

    // enter the current zone so the map tab has a screen pushed on it
    // (the marker icon picks out the zone the player is standing in)
    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.location_on),
        matching: find.byType(ElevatedButton),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text('World Map'), findsNothing);

    // die: frames need real time between them for the enemy to swing
    expect(encounter.startEncounterActionFor(lethalEnemy()), isTrue);
    for (var i = 0; i < 100 && encounter.deathSequence == 0; i++) {
      encounter.onActionTimingFrame();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(encounter.deathSequence, 1);
    await settle(tester);

    // back on the map screen, with the notice
    expect(find.text('You died'), findsOneWidget);
    expect(find.text('World Map'), findsOneWidget);
    expect(find.byType(ExploreScreen), findsNothing);

    // the notice dismisses
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('You died'), findsNothing);

    // the saved ui state followed the player back to the map tab root
    expect(session.saveGameData.uiState.tabIndex, 0);
    expect(session.saveGameData.uiState.mapRouteStack, isEmpty);

    // unmount so the session disposes its timers and ticker
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
