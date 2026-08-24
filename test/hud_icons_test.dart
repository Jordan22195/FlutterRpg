import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/data/skill_data.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/progress_bars.dart';

// Fixed pumps (the app has periodic timers that never settle).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

Finder skillIcon(SkillId id) => find.descendant(
  of: find.byType(ProgressBars),
  matching: find.byWidgetPredicate(
    (w) => w is IconRenderer<SkillId> && w.id == id,
  ),
);

void main() {
  testWidgets('each HUD number wears the face of what it measures', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    expect(find.byType(ProgressBars), findsOneWidget);

    // The bar used to read one lightning bolt three times over: stamina, the
    // action-speed boost and the tick length. Two of those are not stamina,
    // and a shared glyph said they were.
    expect(
      find.descendant(
        of: find.byType(ProgressBars),
        matching: find.byIcon(Icons.bolt),
      ),
      findsNothing,
    );

    expect(skillIcon(SkillId.STAMINA), findsOneWidget);
    expect(skillIcon(SkillId.SPEED), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProgressBars),
        matching: find.byIcon(Icons.timer),
      ),
      findsOneWidget,
    );
  });
}
