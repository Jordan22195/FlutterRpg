import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/main.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/progress_bars.dart';
import 'support/gathering_tools.dart';

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

/// The bar and the readout pieces of the status-row line keyed [key].
FillBar barOf(WidgetTester tester, String key) => tester.widget<FillBar>(
  find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(FillBar),
  ),
);

/// Every icon and line of text on [key]'s row sits centred on its bar.
void expectAlignedWithBar(WidgetTester tester, String key) {
  final row = find.byKey(ValueKey(key));
  final barY = tester
      .getCenter(find.descendant(of: row, matching: find.byType(FillBar)))
      .dy;
  final parts = [
    ...find.descendant(of: row, matching: find.byType(Text)).evaluate(),
    ...find
        .descendant(
          of: row,
          matching: find.byWidgetPredicate((w) => w is IconRenderer<SkillId>),
        )
        .evaluate(),
  ];
  expect(parts, isNotEmpty, reason: key);
  for (final e in parts) {
    final box = e.renderObject! as RenderBox;
    final y = box.localToGlobal(box.size.center(Offset.zero)).dy;
    expect((y - barY).abs(), lessThan(1.5), reason: '$key: ${e.widget}');
  }
}

void main() {
  testWidgets('each HUD number wears the face of what it measures', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    expect(find.byType(ProgressBars), findsOneWidget);

    // The bar used to read the same lightning bolt for stamina and for the
    // action-speed boost, which made the boost look like a second kind of
    // stamina. Each number now wears its own stat's sprite.
    expect(
      find.descendant(
        of: find.byType(ProgressBars),
        matching: find.byIcon(Icons.bolt),
      ),
      findsNothing,
    );

    expect(skillIcon(SkillId.STAMINA), findsOneWidget);
    expect(skillIcon(SkillId.SPEED), findsOneWidget);
  });

  testWidgets('a fight puts the hp bar and amount on top of the row', (
    tester,
  ) async {
    // a phone's width, where the row is tightest
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);
    final session = Provider.of<GameSession>(
      tester.element(find.byType(MapScreen)),
      listen: false,
    );
    equipGatheringTools(session.saveGameData);
    final hp = find.byKey(const ValueKey('status-hp'));

    // idle: no hp row, stamina at full size, each readout on its bar's line
    expect(hp, findsNothing);
    expect(barOf(tester, 'status-stamina').height, 8);
    expectAlignedWithBar(tester, 'status-stamina');
    expectAlignedWithBar(tester, 'status-boost');
    // and the readouts start at one x, so the bars run one length
    expect(
      tester
          .getTopRight(
            find.descendant(
              of: find.byKey(const ValueKey('status-stamina')),
              matching: find.byType(FillBar),
            ),
          )
          .dx,
      tester
          .getTopRight(
            find.descendant(
              of: find.byKey(const ValueKey('status-boost')),
              matching: find.byType(FillBar),
            ),
          )
          .dx,
    );

    final zone = session
        .saveGameData
        .worldData
        .zones[session.saveGameData.playerData.currentZoneId]!;

    // working a tree is not a fight, so the row stays as it was
    final tree = EntityId.TREE.build() as EncounterEntity;
    zone.discoveredEntities.add(tree);
    session.encounterController.startEncounterActionFor(tree);
    await settle(tester);
    expect(hp, findsNothing);
    session.actionTimingController.stop();

    // a fight puts it on top, in the hp colour, with the amount beside it
    final chicken = EntityId.CHICKEN.build() as EncounterEntity;
    zone.discoveredEntities.add(chicken);
    session.encounterController.startEncounterActionFor(chicken);
    await settle(tester);
    expect(hp, findsOneWidget);
    final player = session.saveGameData.playerData;
    final max = session.playerDataController.getStatTotal(SkillId.HITPOINTS);
    expect(
      find.descendant(
        of: hp,
        matching: find.text('${player.hitpoints} / $max'),
      ),
      findsOneWidget,
    );
    final bar = tester.widget<FillBar>(
      find.descendant(of: hp, matching: find.byType(FillBar)),
    );
    expect(bar.foregroundColor, GameColors.standard.hp);
    expect(bar.value, closeTo(player.hitpoints / max, 1e-9));
    // above the stamina bar it sits on
    final stamina = find.descendant(
      of: find.byType(ProgressBars),
      matching: find.byType(FillBar),
    );
    expect(
      tester.getCenter(hp).dy,
      lessThan(tester.getCenter(stamina.at(1)).dy),
    );

    // the heart sits to the left of the amount, both on the bar's line
    final heart = find.descendant(
      of: hp,
      matching: find.byWidgetPredicate(
        (w) => w is IconRenderer<SkillId> && w.id == SkillId.HITPOINTS,
      ),
    );
    expect(heart, findsOneWidget);
    expect(
      tester.getCenter(heart).dx,
      lessThan(
        tester
            .getCenter(
              find.descendant(
                of: hp,
                matching: find.text('${player.hitpoints} / $max'),
              ),
            )
            .dx,
      ),
    );
    expectAlignedWithBar(tester, 'status-hp');

    // stamina slims down to make room, readout and all, still on its line
    expect(barOf(tester, 'status-stamina').height, 4);
    final staminaIcon = tester.widget<IconRenderer<SkillId>>(
      skillIcon(SkillId.STAMINA),
    );
    expect(staminaIcon.size, 12);
    expectAlignedWithBar(tester, 'status-stamina');
    expectAlignedWithBar(tester, 'status-boost');

    // and it goes with the fight
    session.actionTimingController.stop();
    await settle(tester);
    expect(hp, findsNothing);
    expect(barOf(tester, 'status-stamina').height, 8);
    expect(
      tester.widget<IconRenderer<SkillId>>(skillIcon(SkillId.STAMINA)).size,
      16,
    );
  });
}
