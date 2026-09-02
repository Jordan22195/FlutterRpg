import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
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

// The catalog's fastest heavy hitter: a 1.0s swing interval (nothing swings
// sooner), an attack a starting player cannot survive one of, and enough hp
// to outlast anything the player can do back - so the player is the one who
// dies. Its stats come off its definition, so retuning it is free.
CombatEntity lethalEnemy() => EntityId.IMP_LEGENDARY.build() as CombatEntity;

// long enough to cover a real swing interval, which the catalog measures in
// whole seconds rather than the milliseconds a fabricated enemy could use
const deathFrames = 300;
const deathFrameGap = Duration(milliseconds: 5);

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
    for (var i = 0; i < deathFrames; i++) {
      encounter.onActionTimingFrame();
      if (encounter.deathSequence > 0) return;
      await Future<void>.delayed(deathFrameGap);
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
    // (selecting the token fills the detail pane; the pane's button travels)
    await tester.tap(find.byKey(const ValueKey('map-node-TUTORIAL_FARM')));
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text('World Map'), findsNothing);

    // die: frames need real time between them for the enemy to swing
    expect(encounter.startEncounterActionFor(lethalEnemy()), isTrue);
    for (var i = 0; i < deathFrames && encounter.deathSequence == 0; i++) {
      encounter.onActionTimingFrame();
      await tester.runAsync(() => Future<void>.delayed(deathFrameGap));
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

  test('a hit the player cannot survive kills through a bag of food', () async {
    final session = buildSession();
    final save = session.saveGameData;

    // a full bag of the best food in reach
    session.inventoryService.setItemCount(
      save.inventoryData,
      ItemId.COOKED_CHICKEN,
      50,
    );
    save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;

    final entity = lethalEnemy();
    save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities.add(
      entity,
    );
    expect(session.encounterController.startEncounterActionFor(entity), isTrue);

    await fightUntilDeath(session.encounterController);

    // the death check runs before the eat, so food cannot pull the player
    // back from a swing they had no hp for
    expect(session.encounterController.deathSequence, 1);
    expect(save.playerData.hitpoints, 1);

    // one eat per swing is what would happen if the eat came first; the
    // killing blow gets none, so the eats always come up at least one short.
    // Counted against the swings rather than pinned at "no food eaten",
    // because damage is a uniform roll: even a 1464-attack imp can roll low
    // enough to leave the player standing, and being topped up between hits
    // is the very behaviour the ordering is meant to allow.
    final swings = session.encounterController.entityAttackSequence;
    final eaten =
        50 -
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.COOKED_CHICKEN,
        );
    expect(swings, greaterThan(0));
    expect(
      eaten,
      lessThan(swings),
      reason: 'the killing blow left no room to eat',
    );

    session.dispose();
  });
}
