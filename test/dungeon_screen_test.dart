import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/dungeon_screen.dart';
import 'package:rpg/screens/encounter_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/art_header.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/discovery_tile.dart';
import 'package:rpg/widgets/entity_queue_card.dart';
import 'package:rpg/widgets/fill_bar.dart';

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
  // the page's own list, not a floor's sideways row of tiles
  await tester.drag(
    find
        .byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.vertical,
        )
        .last,
    Offset(0, dy),
  );
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

    // and its row is blurred, with the lock and the reason over the blur
    final firstFloor = find.ancestor(
      of: find.text('Warren Entrance'),
      matching: find.byType(EntityQueueCard),
    );
    Finder inFloor(Finder f) => find.descendant(of: firstFloor, matching: f);
    expect(inFloor(find.byType(ImageFiltered)), findsOneWidget);
    expect(inFloor(find.byIcon(Icons.lock)), findsOneWidget);
    final reason = tester.getCenter(
      inFloor(find.text('Requires Goblin Queen Key')),
    );
    final blur = tester.getRect(inFloor(find.byType(ImageFiltered)));
    expect(blur.contains(reason), isTrue);

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

    // open now, so nothing is hidden, and a tile opens its details
    expect(inFloor(find.byType(ImageFiltered)), findsNothing);
    expect(inFloor(find.byIcon(Icons.lock)), findsNothing);
    await tester.tap(inFloor(find.byType(DiscoveryTile)).first);
    await settle(tester);
    expect(find.text('Close'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await settle(tester);

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

  testWidgets('a locked floor keeps its entities hidden', (tester) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    await openLair(tester);
    await scrollList(tester, -400);

    // the boss floor is locked: its tiles are blurred and take no taps
    final bossCard = find.ancestor(
      of: find.text("Queen's Chamber"),
      matching: find.byType(EntityQueueCard),
    );
    // the floor's creatures are discovery tiles in one sideways row
    final tiles = find.descendant(
      of: bossCard,
      matching: find.byType(DiscoveryTile),
    );
    expect(tiles, findsWidgets);
    final row = tester.widget<ListView>(
      find.descendant(of: bossCard, matching: find.byType(ListView)),
    );
    expect(row.scrollDirection, Axis.horizontal);

    final bossTile = find
        .ancestor(of: find.text('Goblin Queen'), matching: tiles)
        .first;
    await tester.ensureVisible(bossTile);
    await settle(tester);

    // the queen keeps her rarity outline on the new tile, as on the old one
    final frame =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: bossTile,
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is Container &&
                              w.constraints?.maxWidth == 64 &&
                              w.constraints?.maxHeight == 56,
                        ),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    final side = (frame.border! as Border).top;
    expect(side.width, 2);
    expect(
      side.color,
      rarityBorderColor(EntityId.GOBLIN_QUEEN.definition.rarity),
    );
    expect(side.color, isNotNull);
    // the blur takes the tap, so nothing opens
    await tester.tap(bossTile, warnIfMissed: false);
    await settle(tester);
    expect(find.text('Close'), findsNothing);

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

  testWidgets('entering a floor opens it without fighting; the action '
      'button starts it', (tester) async {
    await openDungeonFromSave(tester, DungeonId.SPIDER_DEN);
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    makeStrong(session);

    final floor = session.dungeonController.slotsFor(DungeonId.SPIDER_DEN)[0];
    final card = find.ancestor(
      of: find.text(floor.name),
      matching: find.byType(EntityQueueCard),
    );
    // the card offers to enter, not to play
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.login)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.play_arrow)),
      findsNothing,
    );

    await tester.tap(find.text(floor.name));
    await settle(tester);

    // on the floor's screen, facing its first member, and nothing running
    expect(find.byType(EncounterScreen), findsOneWidget);
    expect(
      tester.widget<ArtHeader>(find.byType(ArtHeader)).title,
      floor.displayed!.name,
    );
    expect(session.saveGameData.dungeonRun.runningSlot, -1);
    expect(session.actionTimingController.isRunning, isFalse);
    Finder buttonIcon(IconData icon) => find.descendant(
      of: find.byType(MomentumPrimaryButton),
      matching: find.byIcon(icon),
    );
    expect(buttonIcon(Icons.play_arrow), findsOneWidget);

    // the action button is what starts it
    await tester.tap(find.byType(MomentumPrimaryButton));
    await settle(tester);
    expect(session.saveGameData.dungeonRun.runningSlot, 0);
    expect(session.actionTimingController.isRunning, isTrue);
    expect(buttonIcon(Icons.fast_forward), findsOneWidget);

    // and once it runs, a press carries on with it rather than starting it
    // over: there is no floor left waiting to start
    expect(session.encounterController.floorToStart, isNull);
    final live = session.saveGameData.dungeonRun.slots[0];
    await tester.tap(find.byType(MomentumPrimaryButton));
    await settle(tester);
    expect(identical(session.saveGameData.dungeonRun.slots[0], live), isTrue);
    expect(session.saveGameData.dungeonRun.runningSlot, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the floor being fought is marked active, and only while it '
      'runs', (tester) async {
    await openDungeonFromSave(tester, DungeonId.SPIDER_DEN);
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    makeStrong(session);

    final bar = find.byKey(const ValueKey('queue-card-progress'));
    expect(bar, findsNothing);

    session.dungeonController.startSlot(DungeonId.SPIDER_DEN, 0);
    await settle(tester);

    // the running floor's card alone carries the bar, ringed in the accent
    final floor = session.dungeonController.slotsFor(DungeonId.SPIDER_DEN)[0];
    final card = find.ancestor(
      of: find.text(floor.name),
      matching: find.byType(EntityQueueCard),
    );
    expect(bar, findsOneWidget);
    expect(find.descendant(of: card, matching: bar), findsOneWidget);
    expect(tester.widget<EntityQueueCard>(card).active, isTrue);
    final shape =
        tester
                .widget<Card>(
                  find.descendant(of: card, matching: find.byType(Card)),
                )
                .shape!
            as RoundedRectangleBorder;
    expect(shape.side.width, 2);

    // the bar fills with the action in hand
    await tester.pump(const Duration(milliseconds: 300));
    final fill = tester.widget<FillBar>(
      find.descendant(of: bar, matching: find.byType(FillBar)),
    );
    expect(
      fill.value,
      closeTo(session.actionTimingController.actionProgress, 1e-9),
    );

    // a paused loop is fighting nothing
    session.actionTimingController.stop();
    await settle(tester);
    expect(bar, findsNothing);
    expect(tester.widget<EntityQueueCard>(card).active, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a floor that laps shows its refilled counts', (tester) async {
    await openDungeonFromSave(tester, DungeonId.SPIDER_DEN);
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    makeStrong(session);

    const id = DungeonId.SPIDER_DEN;
    final progress = session.saveGameData.dungeonProgress;
    session.dungeonController.startSlot(id, 0);
    await settle(tester);

    // a full lap straight through the controller, with nothing else poking
    // the list: the lap alone has to tell it the floor was rebuilt
    var ticks = 0;
    while (progress.runsFor(id, 0) == 0 && ticks < 20000) {
      session.encounterController.doEncounterAction(1);
      ticks++;
    }
    expect(progress.runsFor(id, 0), 1);
    await tester.pump();

    // the card draws the refilled floor, every member back at full count
    final live = session.saveGameData.dungeonRun.slots[0];
    final card = find.ancestor(
      of: find.text(live.name),
      matching: find.byType(EntityQueueCard),
    );
    final shown = tester
        .widgetList<DiscoveryTile>(
          find.descendant(of: card, matching: find.byType(DiscoveryTile)),
        )
        .map((t) => t.entity)
        .toList();
    expect(shown, isNotEmpty);
    for (final entity in shown) {
      expect(
        live.members.any((m) => identical(m, entity)),
        isTrue,
        reason: '${entity.name} is from the spent floor',
      );
    }
    // the first member may have taken a hit since the refill; the rest are
    // untouched, at the counts the floor is defined with
    final def = id.definition.entries[0].entities;
    for (int i = 1; i < shown.length && i < def.length; i++) {
      expect(shown[i].count, def[i].count, reason: shown[i].name);
    }
    expect(shown.first.count, greaterThan(0));

    // and the tally line moved with it
    expect(find.text('1 run · 1 this session'), findsOneWidget);

    session.actionTimingController.stop();
    await settle(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
