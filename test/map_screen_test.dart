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
import 'package:rpg/widgets/map_edge_painter.dart';
import 'package:rpg/widgets/map_node_token.dart';
import 'package:rpg/widgets/recipe_card.dart';

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

Finder entityTiles(WidgetTester tester) => find.descendant(
  of: find.byType(MapDetailPane),
  matching: find.byType(ItemStackTile<EntityId>),
);

/// The rule between the structures and what exploring has turned up.
Finder separators(WidgetTester tester) => find.descendant(
  of: find.byType(MapDetailPane),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.constraints?.maxWidth == 1,
  ),
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
          matching: find.byIcon(MapNodeType.SETTLEMENT.glyph),
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
          matching: find.byIcon(MapNodeType.WILDERNESS.glyph),
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
          matching: find.byIcon(MapNodeType.WILDERNESS.glyph),
        ),
        findsOneWidget,
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
      expect(find.text(MapNodeType.SETTLEMENT.label), findsOneWidget);

      // another node just swaps the contents
      await select(tester, 'TUTORIAL_FARM');
      expect(find.text(MapNodeType.SETTLEMENT.label), findsNothing);
      expect(find.text('You are here'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);

      // and tapping bare map puts the room back. The gap between the
      // meadow and the lair is empty canvas, and far enough from either
      // slot that it can't be a mis-aimed node tap.
      final farm = tester.getRect(tokenFor('TUTORIAL_FARM'));
      await tester.tapAt(farm.center + const Offset(60, 55));
      await settle(tester);
      expect(find.byType(MapDetailPane), findsNothing);
    });

    testWidgets('it previews what is standing in the place', (tester) async {
      await pumpMap(tester);
      await select(tester, 'SOUTH_HAVEN');

      // the per-node service dots moved in here, as the same entity tiles
      // the zone screen itself uses
      for (final id in [
        EntityId.ANVIL,
        EntityId.FIREPIT,
        EntityId.TRADING_POST,
      ]) {
        expect(
          find.descendant(
            of: find.byType(MapDetailPane),
            matching: find.byWidgetPredicate(
              (w) => w is ItemStackTile<EntityId> && w.id == id,
            ),
          ),
          findsOneWidget,
          reason: '${id.name} is a permanent structure of South Haven',
        );
      }
    });

    testWidgets('structures lead, discovered entities follow a rule', (
      tester,
    ) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      final zone = session.saveGameData.worldData.zones[ZoneId.TUTORIAL_FARM]!;

      // nothing found here yet: structures only, and no rule to draw
      await select(tester, 'TUTORIAL_FARM');
      final structureCount = zone.permanentEntities.length;
      expect(entityTiles(tester), findsNWidgets(structureCount));
      expect(separators(tester), findsNothing);

      // find something, and the row grows a second half behind a rule
      zone.discoveredEntities.add(EntityId.TREE.build() as EncounterEntity);
      await select(tester, 'SOUTH_HAVEN');
      await select(tester, 'TUTORIAL_FARM');

      expect(entityTiles(tester), findsNWidgets(structureCount + 1));
      expect(separators(tester), findsOneWidget);
    });

    testWidgets('a node worked down to nothing drops out of the row', (
      tester,
    ) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      final zone = session.saveGameData.worldData.zones[ZoneId.TUTORIAL_FARM]!;
      final structureCount = zone.permanentEntities.length;

      final spent = EntityId.TREE.build() as EncounterEntity;
      spent.count = 0;
      zone.discoveredEntities.add(spent);
      await select(tester, 'TUTORIAL_FARM');

      // an exhausted node isn't there any more; a zero would say it was
      expect(entityTiles(tester), findsNWidgets(structureCount));
      expect(separators(tester), findsNothing);
    });

    testWidgets('a locked node still opens, and says why it is shut', (
      tester,
    ) async {
      await pumpMap(tester);
      await select(tester, 'FOREST_MINE');

      expect(find.text('Requires Exploration 15 — you have 1'), findsOneWidget);
      expect(find.text('Requires Mining 5 — you have 1'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byType(MapDetailPane),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('it counts the hops, not just the stamina', (tester) async {
      await pumpMap(tester);
      await select(tester, 'SOUTH_HAVEN');

      // farm >5> forest >10> haven
      expect(find.text('2 hops · 15 stamina'), findsOneWidget);
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
      expect(
        here.center.dy,
        closeTo(
          viewport.center.dy +
              MapNodeToken.slotHeight / 2 -
              MapNodeToken.tokenCenterY,
          4,
        ),
      );
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

  group('travelling', () {
    testWidgets('Travel moves you, and stops there', (tester) async {
      await pumpMap(tester);
      final session = sessionOf(tester);
      session.saveGameData.playerData.stamina = 100;
      await settle(tester);

      await select(tester, 'SOUTH_HAVEN');
      await tester.tap(find.text('Travel'));
      await settle(tester);

      // the player has moved
      expect(session.worldController.currentZoneId, ZoneId.SOUTH_HAVEN);
      // but has not been marched into the zone: arriving and going in are
      // two decisions, and you might have walked here just to look
      expect(find.byType(ExploreScreen), findsNothing);
      expect(find.text('World Map'), findsOneWidget);

      // the pane stays on the place you just walked to, now offering the
      // way in rather than the way here
      expect(find.text('You are here'), findsOneWidget);
      expect(find.text('Travel'), findsNothing);
      expect(find.text('Enter'), findsOneWidget);
    });

    testWidgets('Enter is the second tap, and it opens the zone', (
      tester,
    ) async {
      await pumpMap(tester);

      await select(tester, 'TUTORIAL_FARM');
      expect(find.text('Enter'), findsOneWidget);

      await tester.tap(find.text('Enter'));
      await settle(tester);

      expect(find.byType(ExploreScreen), findsOneWidget);
    });
  });

  group('what the player can afford', () {
    testWidgets('an unaffordable trip says to rest, not just "no"', (
      tester,
    ) async {
      await pumpMap(tester);

      // a new save starts on 10 stamina and South Haven is a 15 trip
      await select(tester, 'SOUTH_HAVEN');
      expect(find.text('Rest first'), findsOneWidget);
      expect(find.text('Travel'), findsNothing);

      sessionOf(tester).saveGameData.playerData.stamina = 50;
      await settle(tester);

      expect(find.text('Rest first'), findsNothing);
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('an unaffordable hop reddens, and clears as stamina returns', (
      tester,
    ) async {
      await pumpMap(tester);
      final player = sessionOf(tester).saveGameData.playerData;

      // 10 stamina covers the 5-stamina walk to the forest
      expect(edgePainter(tester).edges.every((e) => e.affordable), isTrue);
      expect(edgePainter(tester).warningColor, RecipeCard.missingMaterialColor);

      player.stamina = 2;
      await settle(tester);

      // this is a fact about the player right now, so it lands on the road
      // out of the zone the player is standing in
      final broke = edgePainter(tester).edges.where((e) => !e.affordable);
      expect(broke, isNotEmpty);

      player.stamina = 50;
      await settle(tester);
      expect(edgePainter(tester).edges.every((e) => e.affordable), isTrue);
    });

    testWidgets('the cost badge leans toward the far end of the road', (
      tester,
    ) async {
      await pumpMap(tester);

      // biased past the midpoint so it clears the near node's two-line label
      expect(MapEdgePainter.badgePosition, greaterThan(0.5));

      final farm = zoneNodeCenter(ZoneId.TUTORIAL_FARM)!;
      final edge = edgePainter(
        tester,
      ).edges.firstWhere((e) => e.from == farm || e.to == farm);
      // the player is standing on the farm, so the road is drawn away from it
      expect(edge.from, farm);
    });
  });
}
