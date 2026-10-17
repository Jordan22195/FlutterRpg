import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/encounter_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/action_dock.dart';
import 'package:rpg/widgets/art_header.dart';
import 'package:rpg/widgets/eat_food_button.dart';
import 'package:rpg/widgets/empty_state.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/stage_panel.dart';
import 'package:rpg/widgets/stance_button.dart';
import 'package:rpg/widgets/status_row.dart';

// The combat screen sits under its zone's art strip — always collapsed —
// with the creature on a stage, the two fighters' rows, the tabs, and the
// style switch riding in the dock with Stop, Start and Eat.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('a fight in the meadow wears the Hearth layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    // a chicken turned up in the starting zone
    const zoneId = ZoneId.TUTORIAL_FARM;
    final session = Provider.of<GameSession>(
      tester.element(find.byType(MapScreen)),
      listen: false,
    );
    final chicken = EntityId.CHICKEN.build() as EncounterEntity;
    session.saveGameData.worldData.zones[zoneId]!.discoveredEntities.add(
      chicken,
    );

    await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text(chicken.name),
      100,
      // the page's own scroll, not the horizontal chip row inside it
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // built isn't on screen: bring the row fully into the viewport
    await tester.ensureVisible(find.text(chicken.name));
    await settle(tester);
    await tester.tap(find.text(chicken.name));
    await settle(tester);

    expect(find.byType(EncounterScreen), findsOneWidget);

    // the shell's app bar steps aside for the collapsed art strip, which
    // carries the status row, the creature's name, its zone and its level
    expect(find.byType(AppBar), findsNothing);
    final header = tester.widget<ArtHeader>(find.byType(ArtHeader));
    expect(header.collapse, 1);
    expect(header.title, chicken.name);
    expect(header.subtitle, zoneId.definition.name);
    expect(header.backLabel, 'Back to ${zoneId.definition.name}');
    expect(
      find.descendant(
        of: find.byType(ArtHeader),
        matching: find.byType(StatusRow),
      ),
      findsOneWidget,
    );
    final level = (chicken as CombatEntity).level;
    expect(find.text('Lv $level'), findsOneWidget);

    // the creature stands on a combat-tinted stage, with how many are left
    // as a bare number in the corner
    final stage = tester.widget<StagePanel>(find.byType(StagePanel));
    expect(stage.tint, GameColors.standard.combatTint);
    expect(find.byType(StageCountPill), findsOneWidget);

    // both hp bars are the hp colour, on the track
    final hpBars = tester
        .widgetList<FillBar>(find.byType(FillBar))
        .where((bar) => bar.height == 22)
        .toList();
    expect(hpBars, hasLength(2));
    for (final bar in hpBars) {
      expect(bar.foregroundColor, GameColors.standard.hp);
      expect(bar.backgroundColor, ZonePalette.meadow.track);
    }
    expect(find.text('Enemy'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);

    // the tabs, opening on an empty loot list
    expect(find.text('Loot · 0'), findsOneWidget);
    expect(find.text('Skills'), findsWidgets);
    expect(find.textContaining('Buffs'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(
      find.widgetWithText(EmptyState, 'No loot this session'),
      findsOneWidget,
    );

    // the style switch rides in the dock, above Stop, Start and Eat
    final dock = find.byType(ActionDock);
    expect(
      find.descendant(of: dock, matching: find.byType(StanceButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dock, matching: find.byType(EatFoodButton)),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(EatFoodButton)).width,
      greaterThanOrEqualTo(92),
    );

    // and back goes back to the zone, under its open art again
    await tester.tap(find.byTooltip('Back to ${zoneId.definition.name}'));
    await settle(tester);
    expect(find.byType(EncounterScreen), findsNothing);
    expect(find.byType(ArtHeader), findsOneWidget);
  });
}
