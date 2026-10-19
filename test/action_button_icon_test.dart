import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/primary_button.dart';

// The action button says what it will do and whether it is doing it: the
// zone's explore button wears a compass at rest, and any screen whose own
// action is running shows fast-forward — while a screen whose action is not
// the running one keeps its resting icon.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

Finder buttonIcon(IconData icon) => find.descendant(
  of: find.byType(MomentumPrimaryButton),
  matching: find.byIcon(icon),
);

void main() {
  testWidgets('compass at rest, fast-forward while this screen runs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    const zoneId = ZoneId.TUTORIAL_FARM;
    await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);

    // at rest the explore button wears the compass, not play
    expect(buttonIcon(Icons.explore_outlined), findsOneWidget);
    expect(buttonIcon(Icons.play_arrow), findsNothing);

    // once exploring here, it shows fast-forward with no finger on it
    await tester.tap(find.byType(MomentumPrimaryButton));
    await settle(tester);
    expect(buttonIcon(Icons.fast_forward), findsOneWidget);
    expect(buttonIcon(Icons.explore_outlined), findsNothing);

    // the pond's action is not the one running, so its button rests on play
    final pond = EntityId.TRANQUIL_POND.definition.name;
    await tester.ensureVisible(find.text(pond));
    await settle(tester);
    await tester.tap(find.text(pond));
    await settle(tester);
    expect(buttonIcon(Icons.play_arrow), findsOneWidget);
    expect(buttonIcon(Icons.fast_forward), findsNothing);

    // until it is started, and then it is running too
    await tester.tap(find.byType(MomentumPrimaryButton));
    await settle(tester);
    expect(buttonIcon(Icons.fast_forward), findsOneWidget);

    // stopping puts it back to rest
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await settle(tester);
    expect(buttonIcon(Icons.play_arrow), findsOneWidget);
  });
}
