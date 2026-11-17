import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/explore_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/map_detail_pane.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/progress_bars.dart';
import 'package:rpg/widgets/map_edge_painter.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/map_node_token.dart';
import 'package:rpg/widgets/pixel_sprites.dart';
import 'package:rpg/widgets/art_header.dart';
import 'package:rpg/theme/hearth_text.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/hearth_nav_bar.dart';
import 'support/gathering_tools.dart';

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

/// The whole 800x760 map plus the detail pane, so every node is on screen
/// and tappable rather than scrolled out of the viewport.
Future<void> pumpMap(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // empty raw save triggers the new-game fallback
  await tester.pumpWidget(
    MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
  );
  await settle(tester);
}

/// The time chip sharing a row with the bar at [barKey].
ActionTimeChip chipBeside(WidgetTester tester, Key barKey) {
  return tester.widget<ActionTimeChip>(
    find.descendant(
      of: find
          .ancestor(
            of: find.byKey(barKey),
            matching: find.byType(ActionTimerRow),
          )
          .first,
      matching: find.byType(ActionTimeChip),
    ),
  );
}

Finder tokenFor(String enumName) => find.byKey(ValueKey('map-node-$enumName'));

MapNodeToken tokenWidget(WidgetTester tester, String enumName) =>
    tester.widget<MapNodeToken>(tokenFor(enumName));

MapEdgePainter edgePainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MapEdgePainter,
    ),
  );
  return paint.painter! as MapEdgePainter;
}

/// The pixel token drawn inside a node, open (type glyph showing) or shut.
Finder badge({MapNodeType? type, required bool locked}) =>
    find.byWidgetPredicate(
      (w) =>
          w is MapNodeBadge &&
          w.locked == locked &&
          (type == null || w.type.group == type),
    );

Finder entityTiles(WidgetTester tester) => find.descendant(
  of: find.byType(MapDetailPane),
  matching: find.byType(ItemStackTile<EntityId>),
);

Future<void> select(WidgetTester tester, String enumName) async {
  await tester.tap(tokenFor(enumName));
  await settle(tester);
}

void main() {
  group('map nodes', () {
    testWidgets('every token is the same size whatever the place is called', (
      tester,
    ) async {
      await pumpMap(tester);

      // the old buttons sized to their text, so a long name shoved its
      // neighbours off the road
      final short = tester.getSize(tokenFor('SOUTHWOOD_FOREST'));
      final long = tester.getSize(tokenFor('GOBLIN_QUEEN_LAIR'));

      expect(long, short);
      expect(short.width, MapNodeToken.slotWidth);
      expect(short.height, MapNodeToken.slotHeight);
    });

    testWidgets('the layout leaves room for a token and its label', (
      tester,
    ) async {
      // a pure data check, so it guards the layout against future edits
      // rather than against this one rendering
      for (var i = 0; i < kWorldMapNodes.length; i++) {
        for (var j = i + 1; j < kWorldMapNodes.length; j++) {
          final gap =
              (kWorldMapNodes[i].center - kWorldMapNodes[j].center).distance;
          expect(
            gap,
            greaterThanOrEqualTo(kMinNodeSpacing),
            reason:
                '${kWorldMapNodes[i].name} and ${kWorldMapNodes[j].name} '
                'are only ${gap.toStringAsFixed(0)}px apart',
          );
        }
      }
    });

    testWidgets('a node states what a place is, never what it costs', (
      tester,
    ) async {
      await pumpMap(tester);

      // no stamina readout of any kind on a token: cost is the edge's job
      expect(
        find.descendant(
          of: find.byType(MapNodeToken),
          matching: find.byIcon(Icons.bolt),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(MapNodeToken),
          matching: find.byWidgetPredicate(
            (w) => w is IconRenderer<SkillId> && w.id == SkillId.STAMINA,
          ),
        ),
        findsNothing,
      );

      // an open node is a glyph and a name and nothing else — no cost, no
      // "EXPLORATION 1", no service dots
      expect(
        find.descendant(
          of: tokenFor('SOUTH_HAVEN'),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tokenFor('SOUTH_HAVEN'),
          matching: badge(type: MapNodeType.TOWN, locked: false),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a locked node is a padlock, not a badged one', (tester) async {
      await pumpMap(tester);

      // the mine wants Mining 5 and Exploration 15; a new save has neither
      final mine = tokenWidget(tester, 'FOREST_MINE');
      expect(mine.isLocked, isTrue);

      // the padlock replaces the whole token: no type glyph survives
      expect(
        find.descendant(
          of: tokenFor('FOREST_MINE'),
          matching: find.byIcon(Icons.lock),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tokenFor('FOREST_MINE'),
          matching: badge(locked: false),
        ),
        findsNothing,
      );

      // and it names the gate: the skill's own icon with the level wanted
      expect(mine.lockSkill, SkillId.EXPLORATION);
      expect(mine.lockLevel, 15);
      expect(
        find.descendant(
          of: tokenFor('FOREST_MINE'),
          matching: find.byWidgetPredicate(
            (w) => w is IconRenderer<SkillId> && w.id == SkillId.EXPLORATION,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tokenFor('FOREST_MINE'), matching: find.text('15')),
        findsOneWidget,
      );
    });

    testWidgets('"you are here" is its own state, not the type icon', (
      tester,
    ) async {
      await pumpMap(tester);

      expect(tokenWidget(tester, 'TUTORIAL_FARM').isCurrent, isTrue);
      expect(tokenWidget(tester, 'SOUTH_HAVEN').isCurrent, isFalse);
      expect(tokenWidget(tester, 'TUTORIAL_FARM').isLocked, isFalse);

      // the marker sits alongside the type glyph rather than replacing it,
      // so where you are and what it is are both still readable
      expect(
        find.descendant(
          of: tokenFor('TUTORIAL_FARM'),
          matching: badge(type: MapNodeType.WILDERNESS, locked: false),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tokenFor('TUTORIAL_FARM'),
          matching: find.text('YOU'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tokenFor('SOUTH_HAVEN'),
          matching: find.text('YOU'),
        ),
        findsNothing,
      );
    });
  });

  group('the detail pane', () {
    testWidgets('it swaps content instead of covering the map', (tester) async {
      await pumpMap(tester);

      // nothing selected: no pane at all, and the map has the room
      expect(find.byType(MapDetailPane), findsNothing);

      await select(tester, 'SOUTH_HAVEN');

      // it is a pane, not a dialog: it is docked clear of the canvas rather
      // than floated over it, so the map stays whole while you read
      final pane = tester.getRect(find.byType(MapDetailPane));
      final canvas = tester.getRect(find.byType(InteractiveViewer));
      expect(pane.top, greaterThanOrEqualTo(canvas.bottom));
      expect(pane.height, MapDetailPane.height);
      expect(find.byType(MapNodeToken), findsNWidgets(kWorldMapNodes.length));
      expect(find.text('South Haven'), findsWidgets);
      expect(find.byTooltip(MapNodeType.TOWN.label), findsOneWidget);

      // another node just swaps the contents
      await select(tester, 'TUTORIAL_FARM');
      expect(find.byTooltip(MapNodeType.TOWN.label), findsNothing);
      expect(find.byTooltip('You are here'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);

      // and tapping bare map puts the room back. The gap between the
      // meadow and the lair is empty canvas, and far enough from either
      // slot that it can't be a mis-aimed node tap.
      final farm = tester.getRect(tokenFor('TUTORIAL_FARM'));
      await tester.tapAt(farm.center + const Offset(60, 55));
      await settle(tester);
      expect(find.byType(MapDetailPane), findsNothing);
    });

    testWidgets('picking a zone recolours the map, bars and nav bar', (
      tester,
    ) async {
      await pumpMap(tester);
      ZonePalette? paletteAt(Finder f) =>
          Theme.of(tester.element(f.first)).extension<ZonePalette>();
      final map = find.byType(InteractiveViewer);
      final bars = find.byType(ProgressBars);
      final nav = find.byType(HearthNavBar);
      final home = ZoneId.TUTORIAL_FARM.definition.palette;
      final haven = ZoneId.SOUTH_HAVEN.definition.palette;

      // nothing picked: everything wears the zone the player is in
      for (final f in [map, bars, nav]) {
        expect(paletteAt(f), home);
      }

      // a pick recolours the whole screen, not just the canvas
      await select(tester, 'SOUTH_HAVEN');
      for (final f in [map, bars, nav]) {
        expect(paletteAt(f), haven);
      }

      // leaving the map tab hands the colours back...
      await tester.tap(find.text('Skills'));
      await settle(tester);
      expect(paletteAt(nav), home);

      // ...and coming back with the zone still picked puts them on again
      await tester.tap(find.text('Map'));
      await settle(tester);
      expect(paletteAt(nav), haven);

      // letting go of the pick hands them back for good
      final farm = tester.getRect(tokenFor('TUTORIAL_FARM'));
      await tester.tapAt(farm.center + const Offset(60, 55));
      await settle(tester);
      for (final f in [map, bars, nav]) {
        expect(paletteAt(f), home);
      }
    });

    testWidgets('entering the picked zone keeps its colours', (tester) async {
      await pumpMap(tester);
      await select(tester, 'SOUTH_HAVEN');
      await tester.tap(find.text('Enter'));
      await settle(tester);

      // the explore screen wears the zone it shows, the same palette
      expect(
        Theme.of(
          tester.element(find.byType(ExploreScreen)),
        ).extension<ZonePalette>(),
        ZoneId.SOUTH_HAVEN.definition.palette,
      );
    });

    testWidgets('it previews what the zone holds, not what you have found', (
      tester,
    ) async {
      await pumpMap(tester);
      Finder inPane(Finder f) =>
          find.descendant(of: find.byType(MapDetailPane), matching: f);
      final details = sessionOf(
        tester,
      ).worldController.zoneDetails(ZoneId.TUTORIAL_FARM);
      final reachable = details.entities.where((d) => !d.locked).toList();
      final hidden = details.entities.length - reachable.length;
      expect(reachable, isNotEmpty);

      await select(tester, 'TUTORIAL_FARM');

      // every discovery your Exploration reaches, by its own icon, found
      // or not — and the rest kept back as one count
      for (final d in reachable) {
        expect(inPane(find.byTooltip(d.name)), findsWidgets);
      }
      if (hidden > 0) {
        expect(inPane(find.byTooltip('$hidden still hidden')), findsOneWidget);
      }
      expect(entityTiles(tester), findsNothing);
    });

    testWidgets('a locked node still opens, and says why it is shut', (
      tester,
    ) async {
      await pumpMap(tester);
      await select(tester, 'FOREST_MINE');

      // a red lock chip per unmet gate: the skill's icon and the level
      expect(find.byTooltip('Requires Exploration 15'), findsOneWidget);
      expect(find.byTooltip('Requires Mining 5'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byType(MapDetailPane),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('it states the walk time', (tester) async {
      await pumpMap(tester);
      await select(tester, 'SOUTH_HAVEN');

      // farm >2.5s> forest >5s> haven, and no stamina: walking is free
      expect(find.byTooltip('Walk'), findsOneWidget);
      expect(find.text('7.5s'), findsOneWidget);
    });

    testWidgets('it is the zone banner: its art, title and colours', (
      tester,
    ) async {
      await pumpMap(tester);
      await select(tester, 'SOUTH_HAVEN');
      final def = ZoneId.SOUTH_HAVEN.definition;
      Finder inPane(Finder f) =>
          find.descendant(of: find.byType(MapDetailPane), matching: f);

      // the zone's scene art behind it, pixel-crisp
      final art = tester.widget<Image>(inPane(find.byType(Image)).first);
      expect((art.image as AssetImage).assetName, def.iconAsset);
      expect(art.filterQuality, FilterQuality.none);

      // the name in the same pixel title the zone screen wears
      final title = tester.widget<Text>(inPane(find.text(def.name)));
      expect(title.style?.fontFamily, HearthText.title.fontFamily);

      // and the Enter button in the zone's own accent
      final enter = tester.widget<ElevatedButton>(
        inPane(find.byType(ElevatedButton)),
      );
      expect(
        enter.style?.backgroundColor?.resolve(const <WidgetState>{}),
        def.palette.accent,
      );
    });

    testWidgets('a zone with a level gate shows no level chip', (tester) async {
      await pumpMap(tester);
      await select(tester, 'SOUTHWOOD_FOREST');

      expect(
        find.descendant(
          of: find.byType(MapDetailPane),
          matching: find.byType(ArtHeaderChip),
        ),
        findsNothing,
      );
    });
  });

  group('the canvas', () {
    testWidgets('it opens framed on where the player is standing', (
      tester,
    ) async {
      await pumpMap(tester);

      // the map is bigger than the window; opening it at the canvas origin
      // would leave the player looking at an empty corner
      final viewport = tester.getRect(find.byType(InteractiveViewer));
      final here = tester.getRect(tokenFor('TUTORIAL_FARM'));

      expect(here.center.dx, closeTo(viewport.center.dx, 4));
      // the meadow sits near the map's top edge, and the map's edge never
      // pulls in past the viewport's, so vertically it is only kept in view
      expect(here.top, greaterThanOrEqualTo(viewport.top));
      expect(here.bottom, lessThanOrEqualTo(viewport.bottom));
    });

    testWidgets('reframing pans, and leaves the zoom alone', (tester) async {
      await pumpMap(tester);

      // zoom in by pinching, and measure it as the on-screen distance
      // between two nodes a fixed distance apart on the canvas
      double spread() =>
          (tester.getRect(tokenFor('SOUTHWOOD_FOREST')).center -
                  tester.getRect(tokenFor('SOUTH_HAVEN')).center)
              .distance;

      final unzoomed = spread();
      final gesture1 = await tester.startGesture(const Offset(400, 400));
      final gesture2 = await tester.startGesture(const Offset(500, 400));
      await gesture1.moveTo(const Offset(320, 400));
      await gesture2.moveTo(const Offset(580, 400));
      await gesture1.up();
      await gesture2.up();
      await settle(tester);

      final zoomed = spread();
      expect(zoomed, greaterThan(unzoomed), reason: 'the pinch should zoom');

      final session = sessionOf(tester);
      session.saveGameData.playerData.stamina = 100;
      expect(
        session.worldController.travelToZone(ZoneId.SOUTH_HAVEN),
        isTrue,
        reason: 'the trip has to actually happen for this to test anything',
      );
      await settle(tester);

      // travelling re-centres the map, but how far in the player is zoomed
      // is their setting and survives the trip
      expect(spread(), closeTo(zoomed, 0.5));
    });

    testWidgets('it reframes when the player moves', (tester) async {
      await pumpMap(tester);
      final before = tester.getRect(tokenFor('SOUTH_HAVEN'));

      final session = sessionOf(tester);
      session.saveGameData.playerData.stamina = 100;
      session.worldController.travelToZone(ZoneId.SOUTH_HAVEN);
      await settle(tester);

      // travelling pushes the explore screen over the map, but the map
      // underneath has re-centred on where the player now is
      final after = tester.getRect(tokenFor('SOUTH_HAVEN'));
      expect(after, isNot(before));
    });
  });

  group('entering', () {
    testWidgets('Enter opens a zone you have not walked to', (tester) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      session.saveGameData.playerData.stamina = 100;
      await settle(tester);

      await select(tester, 'SOUTH_HAVEN');
      // one button, and it never moves you
      expect(find.text('Travel'), findsNothing);
      await tester.tap(find.text('Enter'));
      await settle(tester);

      // you are reading South Haven while still standing in the farm
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(session.worldController.viewedZoneId, ZoneId.SOUTH_HAVEN);
      expect(session.worldController.currentZoneId, ZoneId.TUTORIAL_FARM);
      expect(find.text('South Haven'), findsWidgets);
    });

    testWidgets('Enter costs nothing and leaves the action alone', (
      tester,
    ) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      final player = session.saveGameData.playerData;

      // something already running back home
      session.worldController.startExplore();
      await settle(tester);
      expect(session.actionTimingController.isRunning, isTrue);

      // a new save is capped at 10 stamina and South Haven is a 15 trip, so
      // a fare charged here would clamp the pool to empty
      await select(tester, 'SOUTH_HAVEN');
      await tester.tap(find.text('Enter'));
      await settle(tester);

      expect(player.stamina, greaterThan(0));
      expect(player.currentZoneId, ZoneId.TUTORIAL_FARM);
      // the axe is still swinging back home
      expect(
        session.actionTimingController.isRunningAction(
          session.worldController.doExplore,
        ),
        isTrue,
      );
    });

    testWidgets('the zone you are standing in still opens', (tester) async {
      await pumpMap(tester);

      await select(tester, 'TUTORIAL_FARM');
      expect(find.byTooltip('You are here'), findsOneWidget);

      await tester.tap(find.text('Enter'));
      await settle(tester);

      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('backing out points the view at the world again', (
      tester,
    ) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      session.saveGameData.playerData.stamina = 100;
      await settle(tester);

      await select(tester, 'SOUTH_HAVEN');
      await tester.tap(find.text('Enter'));
      await settle(tester);
      expect(session.worldController.viewedZoneId, ZoneId.SOUTH_HAVEN);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(session.worldController.viewedZoneId, ZoneId.TUTORIAL_FARM);
    });

    testWidgets('the action button becomes the way there', (tester) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      final player = session.saveGameData.playerData;
      // enough pool and exploration to be let into South Haven
      player.skillData[SkillId.STAMINA]!.xp =
          player.skillData[SkillId.STAMINA]!.xpTable[20];
      player.skillData[SkillId.EXPLORATION]!.xp =
          player.skillData[SkillId.EXPLORATION]!.xpTable[10];
      player.stamina = 200;
      await settle(tester);

      await select(tester, 'SOUTH_HAVEN');
      await tester.tap(find.text('Enter'));
      await settle(tester);

      // the purple button is gone: there is nothing to work here until you
      // have walked here
      final button = tester.widget<MomentumPrimaryButton>(
        find.byType(MomentumPrimaryButton),
      );
      expect(button.color, kTravelColor);
      expect(button.idleIcon, Icons.directions_walk);

      // the road has taken the explore row's slot, before a step has been
      // taken, and it is the travel button's own colour
      var road = tester.widget<FillBar>(find.byKey(kTravelBarKey));
      expect(road.foregroundColor, kTravelColor);
      expect(road.value, 0.0);
      expect(find.text('Exploring'), findsNothing);
      expect(find.text('Travel'), findsOneWidget);
      // and the status row carries no road of its own
      expect(
        find.descendant(
          of: find.byType(ProgressBars),
          matching: find.byKey(kTravelBarKey),
        ),
        findsNothing,
      );

      // the chip reads the whole trip, as the explore chip reads a whole
      // explore: 7.5s of road, cut by the speed stat
      final trip = chipBeside(tester, kTravelBarKey).duration;
      expect(trip, lessThan(const Duration(milliseconds: 7500)));
      expect(trip, greaterThan(const Duration(seconds: 5)));

      // pressing it pays the fare and puts the road on the clock
      await tester.press(find.byType(MomentumPrimaryButton));
      await settle(tester);

      expect(player.stamina, lessThan(200));
      expect(session.worldController.isTravelling, isTrue);
      expect(session.worldController.travelTarget, ZoneId.SOUTH_HAVEN);
      road = tester.widget<FillBar>(find.byKey(kTravelBarKey));
      expect(road.value, greaterThan(0.0));
      expect(find.text('Travelling'), findsOneWidget);
      // under way, the chip still reads the whole trip, not what is left of
      // it: the bar is what fills
      expect(
        chipBeside(tester, kTravelBarKey).duration,
        session.worldController.travelInterval(),
      );
      expect(
        chipBeside(tester, kTravelBarKey).duration,
        greaterThan(const Duration(seconds: 5)),
      );

      session.worldController.cancelTravel();
      await settle(tester);
    });

    testWidgets('a fight a zone away is walked to, and then decided on', (
      tester,
    ) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      // the tree wants an axe once the walk is done
      equipGatheringTools(session.saveGameData);
      final player = session.saveGameData.playerData;
      player.skillData[SkillId.STAMINA]!.xp =
          player.skillData[SkillId.STAMINA]!.xpTable[20];
      player.skillData[SkillId.EXPLORATION]!.xp =
          player.skillData[SkillId.EXPLORATION]!.xpTable[10];
      player.stamina = 200;

      // something worth walking to, standing in the next zone over
      final tree = EntityId.TREE.build() as EncounterEntity;
      session
          .saveGameData
          .worldData
          .zones[ZoneId.SOUTH_HAVEN]!
          .discoveredEntities
          .add(tree);
      await settle(tester);

      await select(tester, 'SOUTH_HAVEN');
      await tester.tap(find.text('Enter'));
      await settle(tester);

      // open the tree from a zone away — the encounter screen resolves it
      // in the zone on screen, not the one the player is standing in. the
      // zone's art opens as a full square, so scroll the tile into view
      await tester.ensureVisible(find.text('Tree').first);
      await settle(tester);
      await tester.tap(find.text('Tree').first);
      await settle(tester);

      // hold the travel button all the way there, and keep holding it
      final gesture = await tester.press(find.byType(MomentumPrimaryButton));
      expect(session.worldController.isTravelling, isTrue);

      // the haven road is 7.5s of walking, and the boost only shortens it
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await settle(tester);

      // arrived — and standing there. the finger never came off the button
      // and the tree was on screen the whole way, and still nothing swings:
      // where to go and what to do there are two decisions
      expect(session.worldController.currentZoneId, ZoneId.SOUTH_HAVEN);
      expect(session.actionTimingController.isRunning, isFalse);
      expect(session.worldController.isTravelling, isFalse);
      // and the road is gone, because there is no road left
      expect(find.byKey(kTravelBarKey), findsNothing);

      await gesture.up();
      await settle(tester);
      expect(session.actionTimingController.isRunning, isFalse);

      // the button is the screen's own again, and it is what starts the work
      final button = tester.widget<MomentumPrimaryButton>(
        find.byType(MomentumPrimaryButton),
      );
      expect(button.color, isNot(kTravelColor));

      await tester.press(find.byType(MomentumPrimaryButton));
      await settle(tester);
      expect(session.actionTimingController.isRunning, isTrue);
      expect(
        session.saveGameData.actionTimingData.boundAction?.entityId,
        EntityId.TREE,
      );

      session.actionTimingController.stop();
      await settle(tester);
    });

    testWidgets('no road to show, the row is the explore timer', (
      tester,
    ) async {
      await pumpMap(tester);

      // standing in the place you are reading: nothing to walk
      await select(tester, 'TUTORIAL_FARM');
      await tester.tap(find.text('Enter'));
      await settle(tester);

      expect(find.byKey(kTravelBarKey), findsNothing);
      // idle, the row reads as the thing to do rather than the thing doing
      final row = find.byKey(const ValueKey('explore-row'));
      expect(
        find.descendant(of: row, matching: find.text('Explore')),
        findsOneWidget,
      );
      expect(find.text('Exploring'), findsNothing);
    });

    testWidgets('the road takes the explore row\'s place, not a new one', (
      tester,
    ) async {
      await pumpMap(tester);
      final player = sessionOf(tester).saveGameData.playerData;
      player.skillData[SkillId.EXPLORATION]!.xp =
          player.skillData[SkillId.EXPLORATION]!.xpTable[10];
      await settle(tester);

      // standing in the zone on screen: the explore row
      await select(tester, 'TUTORIAL_FARM');
      await tester.tap(find.text('Enter'));
      await settle(tester);
      final exploreRow = tester.getRect(find.byType(ActionTimerRow));
      final banner = tester.getSize(find.byType(ProgressBars));
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);

      // a zone away: the road, in exactly the same place
      await select(tester, 'SOUTH_HAVEN');
      await tester.tap(find.text('Enter'));
      await settle(tester);

      expect(find.byType(ActionTimerRow), findsOneWidget);
      expect(find.byKey(kTravelBarKey), findsOneWidget);
      expect(tester.getRect(find.byType(ActionTimerRow)), exploreRow);
      // and the status row is the size it always was
      expect(tester.getSize(find.byType(ProgressBars)), banner);
    });

    testWidgets('the way into a locked place is shut', (tester) async {
      await pumpMap(tester);
      sessionOf(tester).saveGameData.playerData.stamina = 200;
      await settle(tester);

      await select(tester, 'SWAMP');
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enter'),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('screen transitions', () {
    testWidgets('a screen in transit has solid ground under it', (
      tester,
    ) async {
      await pumpMap(tester);

      await select(tester, 'TUTORIAL_FARM');
      await tester.tap(find.text('Enter'));
      // start the transition and stop half way through it, rather than
      // settling: the whole problem only exists while the animation runs
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // both screens are on screen at once — which is what makes the canvas
      // matter. neither carries a Scaffold of its own, so without one the
      // map would be read straight through the zone sliding over it
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byType(ExploreScreen), findsOneWidget);

      final ground = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.byType(ExploreScreen),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(ground.color.a, 1.0);
      expect(
        ground.color,
        Theme.of(
          tester.element(find.byType(ExploreScreen)),
        ).scaffoldBackgroundColor,
      );

      await settle(tester);
    });

    testWidgets('and so does one on its way out', (tester) async {
      await pumpMap(tester);

      await select(tester, 'TUTORIAL_FARM');
      await tester.tap(find.text('Enter'));
      await settle(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byType(ExploreScreen), findsOneWidget);
      final ground = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.byType(ExploreScreen),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(ground.color.a, 1.0);

      await settle(tester);
    });
  });

  group('the roads', () {
    testWidgets('an empty tank still opens every reachable place', (
      tester,
    ) async {
      await pumpMap(tester);
      sessionOf(tester).saveGameData.playerData.stamina = 0;
      await settle(tester);

      await select(tester, 'SOUTH_HAVEN');
      final open = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Enter'),
      );
      expect(open.onPressed, isNotNull);
    });

    testWidgets('each road is labelled with its walk time', (tester) async {
      await pumpMap(tester);

      final farm = zoneNodeCenter(ZoneId.TUTORIAL_FARM)!;
      final edge = edgePainter(
        tester,
      ).edges.firstWhere((e) => e.from == farm || e.to == farm);
      expect(edge.time, const Duration(milliseconds: 2500));
    });

    testWidgets('a road is drawn away from the node you stand on', (
      tester,
    ) async {
      await pumpMap(tester);

      final farm = zoneNodeCenter(ZoneId.TUTORIAL_FARM)!;
      final edge = edgePainter(
        tester,
      ).edges.firstWhere((e) => e.from == farm || e.to == farm);
      // the player is standing on the farm, so the road is drawn away from it
      expect(edge.from, farm);
    });
  });

  group('node types', () {
    testWidgets('each kind of place has its own token shape', (tester) async {
      await pumpMap(tester);

      expect(
        tokenWidget(tester, 'SOUTHWOOD_FOREST').type.group,
        MapNodeType.WILDERNESS,
      );
      expect(tokenWidget(tester, 'SOUTH_HAVEN').type, MapNodeType.TOWN);
      expect(tokenWidget(tester, 'FOREST_MINE').type, MapNodeType.SKILLING);
      // a lair is a landmark, but it reads as wilderness on the map
      expect(
        tokenWidget(tester, 'GOBLIN_QUEEN_LAIR').type.group,
        MapNodeType.WILDERNESS,
      );

      expect(MapNodeType.WILDERNESS.frame, MapNodeFrame.DIAMOND);
      expect(MapNodeType.TOWN.frame, MapNodeFrame.SHIELD);
      expect(MapNodeType.SKILLING.frame, MapNodeFrame.ROUND);
    });

    testWidgets('the filter rail fades a kind of place without removing it', (
      tester,
    ) async {
      await pumpMap(tester);
      expect(tokenWidget(tester, 'SOUTH_HAVEN').dimmed, isFalse);

      await tester.tap(find.bySemanticsLabel('Town places'));
      await settle(tester);

      expect(tokenWidget(tester, 'SOUTH_HAVEN').dimmed, isTrue);
      expect(tokenWidget(tester, 'SOUTHWOOD_FOREST').dimmed, isFalse);
      expect(find.byType(MapNodeToken), findsNWidgets(kWorldMapNodes.length));
    });

    testWidgets('picking a zone draws the way there in gold', (tester) async {
      await pumpMap(tester);
      expect(edgePainter(tester).edges.where((e) => e.onRoute), isEmpty);

      await select(tester, 'SOUTH_HAVEN');

      final route = ZoneTravelGraph.travelPath(
        ZoneId.TUTORIAL_FARM,
        ZoneId.SOUTH_HAVEN,
      );
      expect(
        edgePainter(tester).edges.where((e) => e.onRoute).length,
        route.length - 1,
      );
    });

    testWidgets('with nothing picked, the map says where you are', (
      tester,
    ) async {
      await pumpMap(tester);
      expect(find.text('YOU ARE AT'), findsOneWidget);

      await select(tester, 'SOUTH_HAVEN');
      expect(find.text('YOU ARE AT'), findsNothing);
    });
  });

  group('zone combat range', () {
    testWidgets('a zone with fights shows its lowest to highest fight level', (
      tester,
    ) async {
      await pumpMap(tester);
      final world = sessionOf(tester).worldController;

      // every zone's range is read off its creatures and dungeons,
      // permanent and discoverable — a dungeon at its toughest fight —
      // and is null only where nothing fights
      var dungeonCounted = false;
      for (final zone in ZoneId.values) {
        final def = zone.definition;
        final levels = <int>[];
        for (final id in [
          ...def.permanentEntities,
          for (final e in def.discoverableEntities) e.id,
        ]) {
          final entity = id.definition;
          if (entity is CombatEntityDefinition) levels.add(entity.level);
          if (entity is DungeonEntityDefinition) {
            final fights = [
              for (final entry in entity.dungeonId.definition.entries)
                for (final ref in entry.entities)
                  if (ref.entityId.definition
                      case final CombatEntityDefinition c)
                    c.level,
            ];
            if (fights.isNotEmpty) {
              levels.add(fights.reduce((a, b) => a > b ? a : b));
              dungeonCounted = true;
            }
          }
        }
        final range = world.zoneCombatLevelRange(zone);
        if (levels.isEmpty) {
          expect(range, isNull, reason: zone.name);
        } else {
          expect(range!.min, levels.reduce((a, b) => a < b ? a : b));
          expect(range.max, levels.reduce((a, b) => a > b ? a : b));
        }
      }
      // some zone holds a dungeon, so the dungeon path is exercised
      expect(dungeonCounted, isTrue);

      // and the pane shows it beside the walk
      final fighting = kWorldMapNodes.whereType<ZoneNode>().firstWhere(
        (n) => world.zoneCombatLevelRange(n.id) != null,
      );
      await select(tester, fighting.id.name);
      final range = world.zoneCombatLevelRange(fighting.id)!;
      final label = range.min == range.max
          ? '${range.min}'
          : '${range.min}–${range.max}';
      expect(find.byTooltip('Combat level $label'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('zone-combat-range')),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    });
  });
}
