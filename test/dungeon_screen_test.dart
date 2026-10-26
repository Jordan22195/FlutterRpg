import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/entities/entities.dart';
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
import 'package:rpg/widgets/dungeon_floor_card.dart';
import 'package:rpg/widgets/dungeon_floor_track.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/sprite_frame.dart';
import 'package:rpg/theme/game_colors.dart';

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

// the floor list is taller than the test surface
Future<void> scrollList(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(CustomScrollView).last, Offset(0, dy));
  await settle(tester);
}

// a floor's card, found by its name
Finder floorCard(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(DungeonFloorCard));

// a floor other than the current one is a row until it is tapped open
Future<void> openFloor(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await settle(tester);
  await tester.tap(find.text(name));
  await settle(tester);
}

// the open floor's big button is what enters it
Future<void> tapFloorButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await settle(tester);
  await tester.tap(find.text(label));
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
  testWidgets('a dungeon with art opens on it', (tester) async {
    final art = DungeonId.WOLF_DEN.iconAsset;
    // the art is real io, so it loads outside the fake clock — and before
    // the screen mounts, so the header finds it ready
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () =>
          precacheImage(AssetImage(art), tester.element(find.byType(SizedBox))),
    );

    await openDungeonFromSave(tester, DungeonId.WOLF_DEN);

    final header = find.byType(ArtHeader);
    expect(tester.widget<ArtHeader>(header).artAsset, art);
    expect(tester.getSize(header).height, DungeonScreen.headerHeight);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a floor\'s boss gets the boss row, and only the boss', (
    tester,
  ) async {
    await openDungeonFromSave(tester, DungeonId.WOLF_DEN);

    // nothing cleared yet, so the first floor is the open one
    final card = floorCard('Cave Entrance');
    expect(tester.widget<DungeonFloorCard>(card).expanded, isTrue);
    final bosses = find.descendant(of: card, matching: find.byType(BossRow));
    expect(bosses, findsOneWidget);
    expect(tester.widget<BossRow>(bosses).entity.id, EntityId.CAVE_BEAR);
    expect(
      find.descendant(of: bosses, matching: find.text('BOSS')),
      findsOneWidget,
    );
    // marked by a gold frame and a gold label, not the red pill
    expect(
      find.descendant(of: bosses, matching: find.byType(BossRibbon)),
      findsNothing,
    );
    final frame = find.descendant(
      of: bosses,
      matching: find.byType(SpriteFrame),
    );
    expect(tester.widget<SpriteFrame>(frame).isBoss, isTrue);
    final gold =
        tester
                .widget<Container>(
                  find
                      .descendant(of: frame, matching: find.byType(Container))
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect((gold.border! as Border).top.color, GameColors.bossFrame);
    expect((gold.border! as Border).top.width, 2);
    expect(
      tester
          .widget<Text>(
            find.descendant(of: bosses, matching: find.text('BOSS')),
          )
          .style!
          .color,
      GameColors.bossLabel,
    );
    expect(
      tester.getSemantics(bosses),
      containsSemantics(
        label:
            'Cave Bear, boss, level ${(EntityId.CAVE_BEAR.build() as CombatEntity).level}',
        isButton: true,
        hasTapAction: true,
      ),
    );

    // the queue in front of it draws as ordinary tiles in the grid
    final tiles = tester
        .widgetList<DiscoveryTile>(
          find.descendant(of: card, matching: find.byType(DiscoveryTile)),
        )
        .toList();
    expect(tiles.map((t) => t.entity.id), [
      EntityId.GOBLIN_UNCOMMON,
      EntityId.GOBLIN_RARE,
    ]);
    expect(tiles.map((t) => t.boss), [false, false]);
    expect(find.text('FLOOR 1 · 2 + BOSS'), findsOneWidget);
    expect(find.text('Fight Floor 1'), findsOneWidget);

    // the floors behind it are rows until they are opened
    final second = floorCard('Deep Lair');
    expect(tester.widget<DungeonFloorCard>(second).expanded, isFalse);
    expect(
      find.descendant(of: second, matching: find.byType(DiscoveryTile)),
      findsNothing,
    );
    await openFloor(tester, 'Deep Lair');
    expect(tester.widget<DungeonFloorCard>(second).expanded, isTrue);
    expect(
      find.descendant(of: second, matching: find.byType(DiscoveryTile)),
      findsWidgets,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the loop selector switches the dungeon\'s loop mode', (
    tester,
  ) async {
    await openDungeonFromSave(tester, DungeonId.SPIDER_DEN);
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    final progress = session.saveGameData.dungeonProgress;

    expect(find.text('Loop floor'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(progress.loopsDungeon(DungeonId.SPIDER_DEN), isFalse);

    await tester.tap(find.text('Loop dungeon'));
    await settle(tester);
    expect(progress.loopsDungeon(DungeonId.SPIDER_DEN), isTrue);

    await tester.tap(find.text('Loop floor'));
    await settle(tester);
    expect(progress.loopsDungeon(DungeonId.SPIDER_DEN), isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('reset asks first, then relocks the floors below the first', (
    tester,
  ) async {
    const id = DungeonId.SPIDER_DEN;
    await openDungeonFromSave(tester, id);
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    final progress = session.saveGameData.dungeonProgress;

    // nothing to lose yet: no question asked
    await tester.tap(find.text('Reset'));
    await settle(tester);
    expect(find.text('Reset to Floor 1?'), findsNothing);

    progress.recordRun(id, 0);
    session.dungeonController.refresh();
    await settle(tester);
    expect(find.text('Floor 2 of 2'), findsOneWidget);

    // cancelling keeps the run
    await tester.tap(find.text('Reset'));
    await settle(tester);
    expect(find.text('Reset to Floor 1?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(progress.hasCleared(id, 0), isTrue);

    await tester.tap(find.text('Reset'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await settle(tester);
    expect(progress.hasCleared(id, 0), isFalse);
    expect(progress.runsFor(id, 0), 1);
    expect(find.text('Floor 1 of 2'), findsOneWidget);
    expect(find.text('Complete Webbed Thicket to unlock'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the chest card counts the run and claims what waits', (
    tester,
  ) async {
    const id = DungeonId.SPIDER_DEN;
    await openDungeonFromSave(tester, id);
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    final progress = session.saveGameData.dungeonProgress;

    await tester.ensureVisible(find.text('Spider Den Chest'));
    await settle(tester);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('Clear all 2 floors in one run'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Claim ')), findsNothing);

    progress.recordRun(id, 0);
    session.dungeonController.refresh();
    await settle(tester);
    expect(find.text('1 / 2'), findsOneWidget);

    // two runs' chests waiting
    progress.earnChest(id);
    progress.resetRun(id);
    progress.earnChest(id);
    session.dungeonController.refresh();
    await settle(tester);
    expect(find.text('×2'), findsOneWidget);

    await tapFloorButton(tester, 'Claim 2 chests');
    expect(find.text('2 Spider Den Chests'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byWidgetPredicate((w) => w is ItemStackTile),
      ),
      findsWidgets,
    );
    expect(progress.chestsWaiting(id), 0);
    await tester.tap(find.text('Close'));
    await settle(tester);

    // this run's chest is taken: another needs a reset
    expect(find.textContaining(RegExp(r'^Claim ')), findsNothing);
    expect(find.text('Claimed · Reset to earn it again'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

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

    // first floor at the top, gated by the key: its pill and the badge over
    // its blurred grid both say so
    expect(find.text('Warren Entrance'), findsOneWidget);
    expect(find.text('Requires Goblin Queen Key'), findsNWidgets(2));
    expect(find.text('Floor 1 of 3'), findsOneWidget);

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

    // and its grid is blurred, with the lock and the reason over the blur
    final firstFloor = floorCard('Warren Entrance');
    Finder inFloor(Finder f) => find.descendant(of: firstFloor, matching: f);
    expect(inFloor(find.byType(ImageFiltered)), findsOneWidget);
    expect(inFloor(find.byIcon(Icons.lock)), findsWidgets);
    expect(inFloor(find.text('Fight Floor 1')), findsNothing);
    final reason = tester.getCenter(
      inFloor(find.text('Requires Goblin Queen Key')).last,
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
    await tester.ensureVisible(inFloor(find.byType(DiscoveryTile)).first);
    await settle(tester);
    await tester.tap(inFloor(find.byType(DiscoveryTile)).first);
    await settle(tester);
    expect(find.text('Close'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await settle(tester);

    // cancelling the confirm leaves the key in the bag
    await tapFloorButton(tester, 'Fight Floor 1');
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
    await tapFloorButton(tester, 'Fight Floor 1');
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
    // the cleared floor folds to a row and the next one opens
    expect(
      tester.widget<DungeonFloorCard>(floorCard('Deep Warren')).expanded,
      isTrue,
    );
    expect(find.text('Floor 2 of 3'), findsOneWidget);
    expect(find.text('Cleared'), findsOneWidget);

    // the lap count went with the reset; the lifetime tally stands
    await openFloor(tester, 'Warren Entrance');
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

    // the boss floor is locked: a dashed row until it is opened
    expect(find.text('Complete Deep Warren to unlock'), findsOneWidget);
    final bossCard = floorCard("Queen's Chamber");
    expect(tester.widget<DungeonFloorCard>(bossCard).expanded, isFalse);
    await openFloor(tester, "Queen's Chamber");

    // open, its creatures are there but blurred, and offer no way in
    expect(
      find.descendant(of: bossCard, matching: find.byType(DiscoveryTile)),
      findsWidgets,
    );
    final bossTile = find.descendant(
      of: bossCard,
      matching: find.byType(BossRow),
    );
    expect(tester.widget<BossRow>(bossTile).entity.id, EntityId.GOBLIN_QUEEN);
    expect(
      find.ancestor(of: bossTile, matching: find.byType(ImageFiltered)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bossCard, matching: find.textContaining('Floor 3')),
      findsNothing,
    );
    await tester.ensureVisible(bossTile);
    await settle(tester);

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
    final card = floorCard(floor.name);
    // the card offers to fight the floor; tapping it enters, nothing more
    expect(
      find.descendant(of: card, matching: find.text('Fight Floor 1')),
      findsOneWidget,
    );

    await tapFloorButton(tester, 'Fight Floor 1');

    // on the floor's screen, facing its first member, and nothing running.
    // the header is the floor's; the member's name stands on the stage
    // under the floor's track
    expect(find.byType(EncounterScreen), findsOneWidget);
    final header = tester.widget<ArtHeader>(find.byType(ArtHeader));
    expect(header.title, floor.name);
    expect(header.subtitle, 'Spider Den · Floor 1 of 2');
    expect(find.byType(DungeonFloorTrack), findsOneWidget);
    expect(find.text(floor.displayed!.name), findsOneWidget);
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
    final card = floorCard(floor.name);
    expect(bar, findsOneWidget);
    expect(find.descendant(of: card, matching: bar), findsOneWidget);
    expect(tester.widget<DungeonFloorCard>(card).active, isTrue);
    expect(
      find.descendant(of: card, matching: find.textContaining('Fighting · ')),
      findsOneWidget,
    );

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
    expect(tester.widget<DungeonFloorCard>(card).active, isFalse);

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
    final card = floorCard(live.name);
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

  testWidgets('a floor keeps looping while the player looks at a firepit', (
    tester,
  ) async {
    await openDungeonFromSave(tester, DungeonId.SPIDER_DEN);
    final session = sessionOf(tester, at: find.byType(DungeonScreen));
    makeStrong(session);

    const id = DungeonId.SPIDER_DEN;
    final progress = session.saveGameData.dungeonProgress;
    final player = session.saveGameData.playerData;
    session.dungeonController.startSlot(id, 0);
    await settle(tester);
    expect(session.saveGameData.dungeonRun.runningSlot, 0);

    // what opening a place in the zone does: the firepit is the entity in
    // view, and the controllers hear the view changed
    player.currentEntityViewId = EntityId.FIREPIT;
    session.encounterController.onEntityViewChanged();
    session.craftingController.onEntityViewChanged();

    // the floor is still the running action, and the screen on top is the
    // firepit's rather than the floor's member
    expect(session.saveGameData.dungeonRun.runningSlot, 0);
    expect(session.encounterController.isViewingActiveEncounter(), isFalse);
    expect(session.encounterController.queueRemaining(), isEmpty);

    // a whole lap goes by: members hand on, the floor refills, and the loop
    // keeps swinging
    var ticks = 0;
    while (progress.runsFor(id, 0) == 0 && ticks < 20000) {
      session.encounterController.doEncounterAction(1);
      ticks++;
    }
    expect(progress.runsFor(id, 0), 1);
    expect(session.saveGameData.dungeonRun.runningSlot, 0);
    expect(session.actionTimingController.isRunning, isTrue);
    // and the hand-offs never pulled the view off the firepit
    expect(player.currentEntityViewId, EntityId.FIREPIT);

    // back on the floor's own screen, it reads as the running fight again
    session.encounterController.viewRunningFloor();
    expect(session.encounterController.isViewingActiveEncounter(), isTrue);

    session.actionTimingController.stop();
    await settle(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
