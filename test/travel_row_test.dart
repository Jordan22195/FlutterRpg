import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/screens/encounter_screen.dart';
import 'package:rpg/screens/firepit_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/screens/shop_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/action_dock.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/travel_row.dart';

// Every screen in a zone the player is not standing in shows the road
// there: the stations and the zone in place of their own progress row,
// combat above its style switch, the shop under its shelves. Back home, each
// shows its own row again.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late GameSession session;

  /// Opens South Haven — a zone away from the new game's start — and in it
  /// the place called [name].
  Future<void> openAway(WidgetTester tester, String name) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    session = Provider.of<GameSession>(
      tester.element(find.byType(MapScreen)),
      listen: false,
    );
    final player = session.saveGameData.playerData;
    player.skillData[SkillId.EXPLORATION]!.xp =
        player.skillData[SkillId.EXPLORATION]!.xpTable[10];
    // something to fight there
    session.saveGameData.worldData.zones[ZoneId.SOUTH_HAVEN]!.discoveredEntities
        .add(EntityId.TREE.build() as EncounterEntity);
    await settle(tester);

    await tester.tap(
      find.byKey(ValueKey('map-node-${ZoneId.SOUTH_HAVEN.name}')),
    );
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    await tester.ensureVisible(find.text(name).first);
    await settle(tester);
    await tester.tap(find.text(name).first);
    await settle(tester);
  }

  testWidgets('a station a zone away shows the road for its timer', (
    tester,
  ) async {
    await openAway(tester, EntityId.ANVIL.definition.name);

    expect(find.byType(CraftingScreen), findsOneWidget);
    expect(find.byType(TravelRow), findsOneWidget);
    expect(find.byKey(kTravelBarKey), findsOneWidget);
    expect(find.text('Crafting'), findsNothing);
  });

  testWidgets('a firepit a zone away shows the road for its timer', (
    tester,
  ) async {
    await openAway(tester, EntityId.FIREPIT.definition.name);

    expect(find.byType(FirepitScreen), findsOneWidget);
    expect(find.byType(TravelRow), findsOneWidget);
    expect(find.text('Tending'), findsNothing);
  });

  testWidgets('a fight a zone away shows the road above the dock', (
    tester,
  ) async {
    await openAway(tester, EntityId.TREE.definition.name);

    expect(find.byType(EncounterScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ActionDock),
        matching: find.byType(TravelRow),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a shop a zone away shows the road under its shelves', (
    tester,
  ) async {
    await openAway(tester, EntityId.TRADING_POST.definition.name);

    expect(find.byType(ShopScreen), findsOneWidget);
    expect(find.byType(TravelRow), findsOneWidget);

    // and the travel button that walks it
    final button = tester.widget<MomentumPrimaryButton>(
      find.byType(MomentumPrimaryButton),
    );
    expect(button.idleIcon, Icons.directions_walk);
    expect(button.color, kTravelColor);

    final player = session.saveGameData.playerData;
    player.skillData[SkillId.STAMINA]!.xp =
        player.skillData[SkillId.STAMINA]!.xpTable[20];
    player.stamina = 200;
    await settle(tester);

    await tester.press(find.byType(MomentumPrimaryButton));
    await settle(tester);
    expect(session.worldController.isTravelling, isTrue);
    expect(session.worldController.travelTarget, ZoneId.SOUTH_HAVEN);
    expect(find.text('Travelling'), findsOneWidget);

    session.worldController.cancelTravel();
    await settle(tester);
  });

  testWidgets('at home, a station keeps its own row', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    await tester.tap(
      find.byKey(ValueKey('map-node-${ZoneId.TUTORIAL_FARM.name}')),
    );
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    await tester.tap(find.text(EntityId.ANVIL.definition.name));
    await settle(tester);

    expect(find.byType(TravelRow), findsNothing);
    expect(find.text('Crafting'), findsOneWidget);
  });
}
