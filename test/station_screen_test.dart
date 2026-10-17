import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/widgets/action_dock.dart';
import 'package:rpg/widgets/art_header.dart';
import 'package:rpg/widgets/empty_state.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/stage_panel.dart';
import 'package:rpg/widgets/status_row.dart';

// The crafting stations sit under their zone's art strip, always
// collapsed: the station on a tinted stage, the recipe, the timer and
// rings, the tabs, and a dock whose button names its action.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  const zoneId = ZoneId.TUTORIAL_FARM;

  Future<void> openStation(WidgetTester tester, EntityId station) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    await tester.tap(find.text(station.definition.name));
    await settle(tester);
  }

  void expectStripHeader(WidgetTester tester, String title) {
    expect(find.byType(AppBar), findsNothing);
    final header = tester.widget<ArtHeader>(find.byType(ArtHeader));
    expect(header.collapse, 1);
    expect(header.title, title);
    expect(header.subtitle, zoneId.definition.name);
    expect(header.backLabel, 'Back to ${zoneId.definition.name}');
    expect(
      find.descendant(
        of: find.byType(ArtHeader),
        matching: find.byType(StatusRow),
      ),
      findsOneWidget,
    );
  }

  testWidgets('the firepit names its fire and its action', (tester) async {
    await openStation(tester, EntityId.FIREPIT);

    expectStripHeader(tester, 'Firepit');
    expect(
      find.descendant(
        of: find.byType(ArtHeaderChip),
        matching: find.text('Firemaking'),
      ),
      findsOneWidget,
    );

    final stage = tester.widget<StagePanel>(find.byType(StagePanel));
    expect(stage.tint, GameColors.standard.fireTint);

    // the action is named on the button's face, and nowhere above the dock
    expect(
      find.descendant(
        of: find.byType(MomentumPrimaryButton),
        matching: find.text('Light Fire'),
      ),
      findsOneWidget,
    );
    expect(find.text('Light Fire'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ActionDock),
        matching: find.byType(MomentumPrimaryButton),
      ),
      findsOneWidget,
    );

    expect(find.text('Cooked · 0'), findsOneWidget);
    expect(
      find.widgetWithText(EmptyState, 'Nothing cooked this session'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back to ${zoneId.definition.name}'));
    await settle(tester);
    expect(find.byType(StagePanel), findsNothing);
  });

  testWidgets('the anvil names itself and the skill it trains', (tester) async {
    await openStation(tester, EntityId.ANVIL);

    expectStripHeader(tester, EntityId.ANVIL.definition.name);
    expect(
      find.descendant(
        of: find.byType(ArtHeaderChip),
        matching: find.text('Blacksmithing'),
      ),
      findsOneWidget,
    );

    final stage = tester.widget<StagePanel>(find.byType(StagePanel));
    expect(stage.tint, GameColors.standard.craftingTint);
    expect(
      find.descendant(
        of: find.byType(MomentumPrimaryButton),
        matching: find.text('Craft'),
      ),
      findsOneWidget,
    );
  });
}
