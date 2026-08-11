import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/encounter_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/entity_queue_card.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

// Fixed pumps (the app has periodic timers that never settle).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

GameSession sessionOf(WidgetTester tester) => Provider.of<GameSession>(
  tester.element(find.byType(MapScreen)),
  listen: false,
);

void makeStrong(GameSession session) {
  for (final id in [SkillId.ATTACK, SkillId.DEFENCE, SkillId.HITPOINTS]) {
    final s = session.saveGameData.playerData.skillData[id]!;
    s.xp = s.xpTable[99];
  }
  session.saveGameData.playerData.hitpoints = session.playerDataService
      .getStatTotals(session.saveGameData.playerData)[SkillId.HITPOINTS]!;
}

// the card list is a lazy ListView taller than the test surface
Future<void> scrollList(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView).last, Offset(0, dy));
  await settle(tester);
}

Future<void> openLair(WidgetTester tester) async {
  await tester.tap(find.text("Goblin Queen's Lair"));
  await settle(tester);
}

void main() {
  testWidgets('landmark lists its cards top to bottom, key gates the first', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    await openLair(tester);

    // no lobby: the list is the dungeon
    expect(find.text('Enter'), findsNothing);
    expect(find.text('Enter (uses key)'), findsNothing);
    expect(find.text('Boss rewards'), findsNothing);

    // first card at the top, gated by the key rather than by a floor
    expect(find.text('Warren Entrance'), findsOneWidget);
    expect(find.text('Requires Goblin Queen Key'), findsOneWidget);

    await scrollList(tester, -400);
    expect(find.text('Complete Warren Entrance to unlock'), findsOneWidget);
    expect(find.text('Complete Deep Warren to unlock'), findsOneWidget);
    expect(find.text("Queen's Chamber"), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the first card shows the key, and the spend is confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    final session = sessionOf(tester);
    await openLair(tester);

    // no key yet: the card says so and can't be started
    expect(find.text('No key'), findsOneWidget);

    session.inventoryService.setItemCount(
      session.saveGameData.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );
    makeStrong(session);
    // the inventory write doesn't notify the dungeon controller; poke it so
    // the card re-reads the bag, leaving the preference where it was
    session.dungeonController.autoAdvance = true;
    session.dungeonController.autoAdvance = false;
    await settle(tester);
    expect(find.text('Key ready'), findsOneWidget);

    // cancelling the confirm leaves the key in the bag
    await tester.tap(find.text('Warren Entrance'));
    await settle(tester);
    expect(find.text('Spend 1 Goblin Queen Key?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(
      session.inventoryService.getItemCount(
        session.saveGameData.inventoryData,
        ItemId.GOBLIN_QUEEN_KEY,
      ),
      1,
    );
    expect(session.saveGameData.dungeonRun.runningSlot, -1);

    // accepting charges it, and the card says so afterwards
    await tester.tap(find.text('Warren Entrance'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Spend key'));
    await settle(tester);

    expect(
      session.inventoryService.getItemCount(
        session.saveGameData.inventoryData,
        ItemId.GOBLIN_QUEEN_KEY,
      ),
      0,
    );
    expect(find.byType(EncounterScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the loot tab shows what the run has dropped', (tester) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    final session = sessionOf(tester);
    makeStrong(session);
    session.inventoryService.setItemCount(
      session.saveGameData.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );

    await openLair(tester);

    // nothing run yet
    await tester.tap(find.text('Loot · 0'));
    await settle(tester);
    expect(find.text('Nothing dropped this run yet'), findsOneWidget);

    // drive a card's worth of kills straight through the controller
    session.dungeonController.startSlot(0);
    var ticks = 0;
    while (session.actionTimingController.isRunning && ticks < 20000) {
      session.encounterController.doEncounterAction();
      ticks++;
    }
    await settle(tester);

    expect(session.dungeonController.runLoot(), isNotEmpty);
    expect(find.text('Nothing dropped this run yet'), findsNothing);
    expect(find.byType(InventoryGrid), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a locked card still opens its entities details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    await openLair(tester);
    await scrollList(tester, -400);

    // the boss card is locked; tapping its boss tile is how the drops are
    // read now that the rewards section is gone
    final bossCard = find.ancestor(
      of: find.text("Queen's Chamber"),
      matching: find.byType(EntityQueueCard),
    );
    // byType can't match a generic widget's raw type
    final bossTile = find
        .descendant(
          of: bossCard,
          matching: find.byWidgetPredicate((w) => w is ItemStackTile),
        )
        .last;
    await tester.tap(bossTile);
    await settle(tester);

    expect(find.text('Goblin Queen'), findsWidgets);
    expect(find.text('Close'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the continue-to-next-floor toggle persists', (tester) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    final session = sessionOf(tester);
    await openLair(tester);

    expect(session.saveGameData.uiState.dungeonAutoAdvance, isFalse);
    await tester.tap(find.byType(Switch));
    await settle(tester);

    // it is a preference, not run state: it lives in the saved ui state so
    // it outlives the run
    expect(session.saveGameData.uiState.dungeonAutoAdvance, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('leaving a dungeon confirms first, then resets the run', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    final session = sessionOf(tester);
    await openLair(tester);

    expect(session.saveGameData.dungeonRun.active, isTrue);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await settle(tester);
    expect(find.text('Leave dungeon?'), findsOneWidget);

    // backing out of the confirm keeps the run
    await tester.tap(find.text('Stay'));
    await settle(tester);
    expect(session.saveGameData.dungeonRun.active, isTrue);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Leave'));
    await settle(tester);

    expect(session.saveGameData.dungeonRun.active, isFalse);
    expect(session.saveGameData.dungeonRun.slots, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
