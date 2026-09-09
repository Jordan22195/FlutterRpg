import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/progress_bars.dart';

/// The banner's boost readout. The two stances buy different things, so
/// they read differently: a strength stance adds flat stat points and shows
/// `+n`, the fast stance buys rate and shows a multiplier. Both show what
/// the stance is worth standing still rather than nothing - the label used
/// to collapse to a flat "1.00x" the moment the boost bar emptied, which
/// hid the idle half of both curves.
void main() {
  /// The skill sprites drawn in the readout, in the order they appear.
  List<SkillId?> renderedIcons() => find
      .descendant(
        of: find.byType(ActionIntervalTimer),
        matching: find.byType(IconRenderer<SkillId>),
      )
      .evaluate()
      .map((e) => (e.widget as IconRenderer<SkillId>).id)
      .toList();

  void setLevel(PlayerData player, SkillId skill, int level) {
    final data = player.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  /// Pumps just the readout, which needs only the two controllers.
  Future<GameSession> pumpLabel(
    WidgetTester tester,
    void Function(SaveGameData save) setup,
  ) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    setup(save);

    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ActionTimingController>.value(
            value: session.actionTimingController,
          ),
          ChangeNotifierProvider<PlayerDataController>.value(
            value: session.playerDataController,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ActionIntervalTimer())),
        ),
      ),
    );
    await tester.pump();

    return session;
  }

  testWidgets('a strength stance reads +n, in whole points', (tester) async {
    final session = await pumpLabel(tester, (save) {
      final player = save.playerData;
      setLevel(player, SkillId.STRENGTH, 16);
      setLevel(player, SkillId.MINING, 20);
      // the stance lands on whatever the open entity is worked with
      player.currentEntityViewId = EntityId.COPPER;
      player.stance = Stance.strong;
      player.skillBoost = SkillId.MINING;
    });

    // standing still is the idle curve: 16 ^ 0.75 is exactly 8
    expect(find.text('+8'), findsOneWidget);
    // and no multiplier anywhere - that reading is retired for this stance
    expect(find.textContaining('x'), findsNothing);

    // strength says where the points come from, mining where they land
    expect(renderedIcons(), [SkillId.STRENGTH, SkillId.MINING]);

    session.dispose();
  });

  testWidgets('a full boost bar reads the max curve', (tester) async {
    final session = await pumpLabel(tester, (save) {
      final player = save.playerData;
      setLevel(player, SkillId.STRENGTH, 16);
      setLevel(player, SkillId.MINING, 20);
      player.currentEntityViewId = EntityId.COPPER;
      player.stance = Stance.strong;
      player.skillBoost = SkillId.MINING;
      // as the frame loop leaves it with the bar held full
      player.boostFill = 1.0;
    });

    // 16 ^ 1 + 1
    expect(find.text('+17'), findsOneWidget);

    session.dispose();
  });

  testWidgets('a fast stance standing still reads its idle cut, not 1.00x', (
    tester,
  ) async {
    final session = await pumpLabel(tester, (save) {
      final player = save.playerData;
      setLevel(player, SkillId.SPEED, 25);
      player.stance = Stance.fast;
      player.skillBoost = SkillId.SPEED;
    });

    // the speed stat already divides the interval by this much before any
    // of the bar is filled - it lived only in the interval before, so the
    // banner reported a flat 1.00x for a player who was demonstrably faster
    final idle = 1 + speedIdleBonus(25);
    expect(idle, greaterThan(1.0));
    expect(find.text('${idle.toStringAsFixed(2)}x'), findsOneWidget);
    expect(find.text('1.00x'), findsNothing);

    // speed is spent on speed, so there is no second stat to name - the
    // icon must not be drawn twice
    expect(renderedIcons(), [SkillId.SPEED]);

    session.dispose();
  });

  testWidgets('momentum multiplies on top of the idle cut', (tester) async {
    // the interval is divided by each in turn, so the label is their
    // product. that is also what keeps the readout continuous: it starts at
    // the idle cut and climbs, rather than jumping as the bar leaves zero
    final session = await pumpLabel(tester, (save) {
      setLevel(save.playerData, SkillId.SPEED, 25);
      save.playerData.stance = Stance.fast;
      save.playerData.skillBoost = SkillId.SPEED;
      // as the frame loop leaves it with the bar held full
      save.actionTimingData.percentOfMaxBoost = 1.0;
      save.actionTimingData.maxBoostMultiplier = 1 + speedStatBonus(25);
    });

    final total = (1 + speedIdleBonus(25)) * (1 + speedStatBonus(25));
    expect(find.text('${total.toStringAsFixed(2)}x'), findsOneWidget);

    session.dispose();
  });
}
