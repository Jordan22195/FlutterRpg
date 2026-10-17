import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/art_header.dart';
import 'package:rpg/widgets/progress_bars.dart';
import 'package:rpg/widgets/status_row.dart';

// The zone screen draws the status row over its own art, so the shell's app
// bar steps aside while it is on top and comes back everywhere else.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('the zone screen carries the status row instead of the app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    // on the map, the shell's app bar carries the row
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(ProgressBars), findsOneWidget);
    expect(find.byType(StatusRow), findsNothing);

    const zoneId = ZoneId.TUTORIAL_FARM;
    await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);

    // in the zone, the app bar is gone and the art header carries the row —
    // exactly one, so the two never show at once
    expect(find.byType(AppBar), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ArtHeader),
        matching: find.byType(StatusRow),
      ),
      findsOneWidget,
    );
    expect(find.byType(ProgressBars), findsOneWidget);

    // and back on the map, the app bar returns
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(StatusRow), findsNothing);
  });
}
