import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/dungeon_screen.dart';
import 'package:rpg/screens/encounter_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/entity_queue_card.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

// Fixed pumps (the app has periodic timers that never settle).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

GameSession sessionOf(WidgetTester tester, {Finder? at}) =>
    Provider.of<GameSession>(
      tester.element(at ?? find.byType(MapScreen)),
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

// the floor list is a lazy ListView taller than the test surface
Future<void> scrollList(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView).last, Offset(0, dy));
  await settle(tester);
}

// boots the app straight onto a dungeon's floor list, which is the only
// cheap way to reach the zone dungeons — their entrances are found by
// exploring
Future<void> openDungeonFromSave(WidgetTester tester, DungeonId id) async {
  final factory = GameSessionFactory();
  final save = factory.newGame(factory.catalog1());
  save.uiState.tabIndex = 0;
  save.uiState.mapRouteStack = ['dungeon'];
  save.uiState.dungeonId = id;

  await tester.pumpWidget(
    MyApp(
      rawSave: jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
      fileManagerService: FileManagerService(),
    ),
  );
  await settle(tester);
}

// tapping a map node selects it; the detail pane's button is what enters
Future<void> openLair(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('map-node-GOBLIN_QUEEN_LAIR')));
  await settle(tester);
  await tester.tap(find.text('Enter'));
  await settle(tester);
}

void main() {
  testWidgets('landmark lists its floors top to bottom, key gates the first', (
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

    // first floor at the top, gated by the key
    expect(find.text('Warren Entrance'), findsOneWidget);
    expect(find.text('Requires Goblin Queen Key'), findsOneWidget);

    await scrollList(tester, -400);
    expect(find.text('Complete Warren Entrance to unlock'), findsOneWidget);
    expect(find.text('Complete Deep Warren to unlock'), findsOneWidget);
    expect(find.text("Queen's Chamber"), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the first floor shows the key, and the spend is confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    final session = sessionOf(tester);
    await openLair(tester);

    // no key yet: the floor says so and can't be started
    expect(find.text('No key'), findsOneWidget);

    session.inventoryService.setItemCount(
      session.saveGameData.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );
    makeStrong(session);
    // the inventory write doesn't notify the dungeon controller
    session.dungeonController.refresh();
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

  testWidgets('a floor card counts its runs once it has been cleared', (
    tester,
  ) async {
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

    // nothing run yet, so the card has no tally to show
    expect(find.textContaining('this session'), findsNothing);

    // drive a floor's worth of kills straight through the controller
    const id = DungeonId.GOBLIN_QUEEN_LAIR;
    final progress = session.saveGameData.dungeonProgress;
    session.dungeonController.startSlot(id, 0);
    var ticks = 0;
    while (progress.runsFor(id, 0) == 0 && ticks < 20000) {
      session.encounterController.doEncounterAction(1);
      ticks++;
    }
    // the floor never stops itself, so hand the loop over to something else
    session.dungeonController.resetRunningFloor();
    await settle(tester);

    expect(progress.runsFor(id, 0), 1);
    // the lap count went with the reset; the lifetime tally stands
    expect(find.text('1 run'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a locked floor still opens its entities details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    await openLair(tester);
    await scrollList(tester, -400);

    // the boss floor is locked; tapping its boss tile is how the drops are
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

  testWidgets('there are no floor-behaviour toggles left', (tester) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    await openLair(tester);

    // you always loop the floor you are in, so neither choice exists
    expect(find.text('Continue to next floor'), findsNothing);
    expect(find.text('Repeat this floor'), findsNothing);
    expect(find.byType(Switch), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('backing out of a dungeon asks nothing and keeps the floor '
      'running', (tester) async {
    await openDungeonFromSave(tester, DungeonId.SPIDER_DEN);

    // restored onto the floor list, the map screen underneath it is not
    // built, so the session comes off the dungeon screen itself
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    makeStrong(session);

    session.dungeonController.startSlot(DungeonId.SPIDER_DEN, 0);
    await settle(tester);
    expect(session.saveGameData.dungeonRun.runningSlot, 0);
    final live = session.saveGameData.dungeonRun.slots[0];

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await settle(tester);

    // no confirm, and nothing was given up: the floor is still swinging
    expect(find.text('Leave dungeon?'), findsNothing);
    expect(find.byType(DungeonScreen), findsNothing);
    expect(session.saveGameData.dungeonRun.runningSlot, 0);
    expect(identical(session.saveGameData.dungeonRun.slots[0], live), isTrue);
    expect(session.actionTimingController.isRunning, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
