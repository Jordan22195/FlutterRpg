import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/skil_tile.dart';

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

    // enter the forest -> explore screen
    await tester.tap(find.text('Forest'));
    await settle(tester);
    expect(find.text('The Forest'), findsOneWidget);
    expect(find.text('Anvil'), findsOneWidget);
    expect(find.text('Pond'), findsOneWidget);

    // ---- Crafting screen (anvil) ----
    await tester.tap(find.text('Anvil'));
    await settle(tester);
    expect(find.text('BLACKSMITHING'), findsOneWidget);
    expect(find.text('Craft'), findsOneWidget);

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

    // back to explore
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await settle(tester);
    expect(find.text('The Forest'), findsOneWidget);

    // ---- Encounter screen (pond) ----
    await tester.tap(find.text('Pond'));
    await settle(tester);
    expect(find.text('Action'), findsOneWidget);

    // run the fishing action for a few seconds of game time, then stop
    await tester.tap(find.text('Action'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text('Stop'));
    await settle(tester);

    // ---- Skills tab ----
    await tester.tap(find.text('Skills'));
    await settle(tester);
    expect(find.byType(SkillTile), findsWidgets);

    // open a skill detail screen and go back
    await tester.tap(find.byType(SkillTile).first);
    await settle(tester);
    expect(find.textContaining('Level :'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // ---- Inventory tab ----
    await tester.tap(find.text('Inventory'));
    await settle(tester);
    expect(find.text('Inventory'), findsWidgets);

    // ---- Gear tab ----
    await tester.tap(find.text('Gear'));
    await settle(tester);
    expect(find.text('HEAD'), findsOneWidget);

    // open the equipment dialog for a slot and close it
    await tester.tap(find.text('HEAD'));
    await settle(tester);
    expect(find.text('Select Item'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await settle(tester);

    // unmount so the session disposes its timer and ticker
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
