import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/skill_grid_tile.dart';

// Boots the real app (new-game save) and taps through every screen.
// Uses fixed pumps instead of pumpAndSettle because BuffController
// ticks a periodic timer that never settles.
// Pumps enough frames to finish route transitions (M3 fade-forwards
// runs 800ms) plus a trailing frame so IgnorePointer re-enables input.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('tap through all screens', (WidgetTester tester) async {
    // empty raw save triggers the new-game fallback
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    // ---- Map tab ----
    expect(find.text('World Map'), findsOneWidget);

    // open the zone the player is standing in. Walking somewhere else is
    // map_screen_test's job; this one only needs a zone whose fixtures it
    // can tap through, so it takes the starting one and reads its contents
    // off the catalog rather than naming them
    const zoneId = ZoneId.TUTORIAL_FARM;
    final zoneName = zoneId.definition.name;
    final anvil = EntityId.ANVIL.definition.name;
    final pond = EntityId.TRANQUIL_POND.definition.name;
    expect(
      zoneId.definition.permanentEntities,
      containsAll([EntityId.ANVIL, EntityId.TRANQUIL_POND]),
      reason: 'this walk-through needs a zone with an anvil and a pond',
    );

    await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
    await settle(tester);
    // one button, and it never moves you
    expect(find.text('Travel'), findsNothing);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    expect(find.text(zoneName), findsWidgets);
    expect(find.text(anvil), findsOneWidget);

    // ---- Crafting screen (anvil) ----
    await tester.tap(find.text(anvil));
    await settle(tester);
    expect(find.text('BLACKSMITHING'), findsOneWidget);
    // the action bar is there, but nothing is picked to make yet
    expect(find.text('Crafting'), findsWidgets);
    expect(find.text('Select a recipe'), findsOneWidget);

    // open the recipe picker and select the first recipe
    // (scroll the card into view first; it can sit below the fold)
    await tester.ensureVisible(find.text('Select a recipe'));
    await settle(tester);
    await tester.tap(find.text('Select a recipe'));
    await settle(tester);
    expect(find.text('Select Recipe'), findsOneWidget);
    final dialogCards = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(RecipeCard),
    );
    expect(dialogCards, findsWidgets);
    await tester.tap(dialogCards.first);
    await settle(tester);
    expect(find.text('Select Recipe'), findsNothing);
    // the picked recipe replaced the empty slot, and brought its session
    // panel with it
    expect(find.text('Select a recipe'), findsNothing);
    expect(find.text('Crafted · 0'), findsOneWidget);

    // back to explore
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await settle(tester);
    expect(find.text(zoneName), findsWidgets);

    // ---- Encounter screen (pond) ----
    await tester.scrollUntilVisible(
      find.text(pond),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(pond));
    await settle(tester);

    // the action bar's buttons are icons, not labels: the primary button
    // idles on a play arrow, and the stop button only exists while an
    // action is running
    expect(find.byType(ActionOrTravelButton), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);

    // run the fishing action for a few seconds of game time, then stop
    await tester.tap(find.byIcon(Icons.play_arrow));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(
      find.byIcon(Icons.stop),
      findsOneWidget,
      reason: 'the stop button should appear once the action is running',
    );
    await tester.tap(find.byIcon(Icons.stop));
    await settle(tester);
    expect(find.byIcon(Icons.stop), findsNothing);

    // ---- Skills tab ----
    await tester.tap(find.text('Skills'));
    await settle(tester);
    expect(find.byType(SkillGridTile), findsWidgets);

    // open a skill detail screen and go back
    await tester.tap(find.byType(SkillGridTile).first);
    await settle(tester);
    // the header carries the level and the skill's own description
    expect(find.textContaining('Level '), findsWidgets);
    expect(find.textContaining('to next level'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(SkillGridTile), findsWidgets);

    // ---- Inventory tab ----
    await tester.tap(find.text('Inventory'));
    await settle(tester);
    expect(find.text('Inventory'), findsWidgets);

    // ---- Gear tab ----
    await tester.tap(find.text('Gear'));
    await settle(tester);
    expect(find.text('HEAD'), findsOneWidget);

    // open the slot's equipment sheet and close it again
    await tester.tap(find.text('HEAD'));
    await settle(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Change head'), findsOneWidget);
    expect(find.text('CURRENTLY EQUIPPED'), findsOneWidget);
    // a new game has nothing to put in the slot, and the sheet says so
    // rather than opening empty
    expect(find.text('Nothing equipped'), findsOneWidget);
    expect(find.text('No items for this slot'), findsOneWidget);

    // it is a modal sheet: the system back button is what dismisses it
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Change head'), findsNothing);
    expect(find.text('HEAD'), findsOneWidget);

    // unmount so the session disposes its timer and ticker
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
