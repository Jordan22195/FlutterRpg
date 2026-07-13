import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/main.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/inventory_screen.dart';
import 'package:rpg/services/file_manager_service.dart';

// Boots the real app from a save carrying ui state and verifies the
// player lands back on the screen they force-closed on.
// Fixed pumps instead of pumpAndSettle for the same reason as
// screen_navigation_test: BuffController's periodic timer never settles.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

// round-trips the save through JSON, exactly like a write to disk
Map<String, dynamic> toRawSave(SaveGameData save) {
  return jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
}

SaveGameData newSave() {
  final factory = GameSessionFactory();
  return factory.newGame(factory.catalog1());
}

void main() {
  testWidgets('relaunch restores the map tab stack down to the entity '
      'screen', (tester) async {
    final save = newSave();
    save.playerData.currentZoneId = ZoneId.STARTING_FOREST;
    save.playerData.currentEntityViewId = EntityId.ANVIL;
    save.uiState.tabIndex = 0;
    save.uiState.mapRouteStack = ['explore', 'crafting'];

    await tester.pumpWidget(
      MyApp(rawSave: toRawSave(save), fileManagerService: FileManagerService()),
    );
    await settle(tester);

    // lands on the anvil's crafting screen
    expect(find.text('BLACKSMITHING'), findsOneWidget);

    // the restored stack pops back through explore
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await settle(tester);
    expect(find.text('The Forest'), findsOneWidget);
  });

  testWidgets('an entity missing from the zone falls back to the nearest '
      'restorable ancestor', (tester) async {
    final save = newSave();
    save.playerData.currentZoneId = ZoneId.STARTING_FOREST;
    // goblins are discovered entities; a new game hasn't found one
    save.playerData.currentEntityViewId = EntityId.GOBLIN;
    save.uiState.tabIndex = 0;
    save.uiState.mapRouteStack = ['explore', 'encounter'];

    await tester.pumpWidget(
      MyApp(rawSave: toRawSave(save), fileManagerService: FileManagerService()),
    );
    await settle(tester);

    // explore screen restored, encounter screen skipped
    expect(find.text('The Forest'), findsOneWidget);
    expect(find.text('Action'), findsNothing);
  });

  testWidgets('relaunch restores the active tab', (tester) async {
    final save = newSave();
    save.uiState.tabIndex = 2;

    await tester.pumpWidget(
      MyApp(rawSave: toRawSave(save), fileManagerService: FileManagerService()),
    );
    await settle(tester);

    // the inventory tab is the one on stage
    expect(find.byType(InventoryScreen), findsOneWidget);
  });
}
