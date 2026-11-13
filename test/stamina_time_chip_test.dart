import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/progress_bars.dart';

// The stamina row's time-left chip: how long what is left lasts at the boost
// being held, and nothing while the boost isn't spending any.
void main() {
  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  // the fast stance with the bar held full
  void holdSpeedBoost(GameSession session) {
    session.saveGameData.actionTimingData
      ..boostingSpeed = true
      ..buttonHeld = true
      ..maxBoostMultiplier = 2.0
      ..percentOfMaxBoost = 1.0;
  }

  test('a held speed boost lasts stamina over its drain per second', () {
    final session = buildSession();
    final timing = session.actionTimingController;
    session.saveGameData.playerData.stamina = 100;

    // an empty bar is worth nothing, so there is no clock
    expect(timing.staminaTimeLeft, isNull);
    expect(timing.staminaSpending, isFalse);

    holdSpeedBoost(session);
    final drain = ActionTimingService().boostDrain(
      timing.getCurrentSpeedMultiplier(),
      speedStance: true,
      ceiling: session.saveGameData.actionTimingData.maxBoostMultiplier,
    );
    expect(drain, greaterThan(0));
    expect(
      timing.staminaTimeLeft!.inMilliseconds,
      closeTo(100 / drain * 1000, 1),
    );

    // let go, it still reads what the bar is worth where it sits - but
    // nothing is spending it
    session.saveGameData.actionTimingData.buttonHeld = false;
    expect(
      timing.staminaTimeLeft!.inMilliseconds,
      closeTo(100 / drain * 1000, 1),
    );
    expect(timing.staminaSpending, isFalse);

    // locked rather than held drains just the same
    session.saveGameData.actionTimingData.boostLocked = true;
    expect(timing.staminaTimeLeft, isNotNull);
    expect(timing.staminaSpending, isTrue);

    // and a bar at rest spends nothing
    session.saveGameData.actionTimingData.percentOfMaxBoost = 0;
    expect(timing.staminaTimeLeft, isNull);
    session.dispose();
  });

  test('a strength boost only spends while actions fire', () {
    final session = buildSession();
    session.saveGameData.playerData.stamina = 100;
    holdSpeedBoost(session);
    session.saveGameData.actionTimingData.boostingSpeed = false;

    // paid by the swing: idle, no swing comes
    expect(session.actionTimingController.staminaTimeLeft, isNull);
    session.dispose();
  });

  testWidgets('the chip holds the stamina bar\'s left end all the time', (
    tester,
  ) async {
    final session = buildSession();
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    session.saveGameData.playerData.stamina = 100;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ActionTimingController>.value(
            value: session.actionTimingController,
          ),
          ChangeNotifierProvider<PlayerDataController>.value(
            value: session.playerDataController,
          ),
          ChangeNotifierProvider<EncounterController>.value(
            value: session.encounterController,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProgressBars())),
      ),
    );
    await tester.pump();

    final row = find.byKey(const ValueKey('status-stamina'));
    final chip = find.descendant(
      of: row,
      matching: find.byKey(const ValueKey('stamina-time-chip')),
    );
    final bar = find.descendant(of: row, matching: find.byType(FillBar));

    // nothing spending it: the chip is still there, reading forever
    expect(chip, findsOneWidget);
    expect(find.descendant(of: chip, matching: find.text('∞')), findsOneWidget);
    // left of the bar, which starts past it
    expect(tester.getRect(chip).right, lessThan(tester.getRect(bar).left));
    final resting = tester.getRect(bar);

    holdSpeedBoost(session);
    session.actionTimingController.notifyListeners();
    await tester.pump();
    final left = session.actionTimingController.staminaTimeLeft!;
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    expect(
      find.descendant(
        of: chip,
        matching: find.text('${left.inMinutes}:$seconds'),
      ),
      findsOneWidget,
    );
    // the bar holds still as the chip starts counting
    expect(tester.getRect(bar), resting);

    // let go with the bar still up: the time stays, the bar's projection
    session.saveGameData.actionTimingData.buttonHeld = false;
    session.actionTimingController.notifyListeners();
    await tester.pump();
    expect(
      find.descendant(
        of: chip,
        matching: find.text('${left.inMinutes}:$seconds'),
      ),
      findsOneWidget,
    );

    // and once the bar has emptied, forever
    session.saveGameData.actionTimingData.percentOfMaxBoost = 0;
    session.actionTimingController.notifyListeners();
    await tester.pump();
    expect(find.descendant(of: chip, matching: find.text('∞')), findsOneWidget);
    expect(tester.getRect(bar), resting);
    session.dispose();
  });
  testWidgets('the chip reads m:ss, then hours, then days', (tester) async {
    Future<void> reads(Duration left, String text) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StaminaTimeChip(left: left)),
        ),
      );
      expect(find.text(text), findsOneWidget, reason: '$left');
    }

    await reads(const Duration(minutes: 2, seconds: 5), '2:05');
    await reads(const Duration(hours: 1, minutes: 52), '1h 52m');
    await reads(const Duration(hours: 23, minutes: 59), '23h 59m');
    await reads(const Duration(hours: 30), '1d 6h');
    await reads(const Duration(days: 12, hours: 3, minutes: 40), '12d 3h');
  });
}
