import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/overflow_chip.dart';
import 'package:rpg/widgets/skil_tile.dart';
import 'package:rpg/widgets/skill_ring_row.dart';

// The three skills the action loop trains whatever the activity is, and the
// speed/strength swap that follows the stance.
void main() {
  late GameSession session;

  Future<void> pumpRings(
    WidgetTester tester, {
    required List<SkillId> skills,
    double? width,
  }) async {
    Widget row = ActivitySkillRingRow(skills: skills);
    if (width != null) {
      row = Center(
        child: SizedBox(width: width, child: row),
      );
    }
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GameSession>.value(value: session),
          ChangeNotifierProvider<PlayerDataController>.value(
            value: session.playerDataController,
          ),
        ],
        child: MaterialApp(home: Scaffold(body: row)),
      ),
    );
    await tester.pump();
  }

  List<SkillId> ringIds(WidgetTester tester) {
    return tester
        .widgetList<SkillTile>(find.byType(SkillTile))
        .map((t) => t.id)
        .toList();
  }

  setUp(() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    ItemCatalog.init();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    EnumImageProviderLookup.register<EntityId>(
      session.catalogBundle.entityCatalog.imageProviderFor,
    );
  });

  tearDown(() => session.dispose());

  testWidgets('a gathering activity shows its skill plus the loop three', (
    tester,
  ) async {
    session.playerDataController.setStance(Stance.fast);
    await pumpRings(tester, skills: [SkillId.MINING]);

    expect(ringIds(tester), [
      SkillId.MINING,
      SkillId.STAMINA,
      SkillId.SPEED,
      SkillId.RECOVERY,
    ]);
  });

  testWidgets('the strong stance swaps speed out for strength', (tester) async {
    session.playerDataController.setStance(Stance.strong);
    await pumpRings(tester, skills: [SkillId.MINING]);

    expect(ringIds(tester), contains(SkillId.STRENGTH));
    expect(ringIds(tester), isNot(contains(SkillId.SPEED)));
  });

  testWidgets('switching stance switches the ring live', (tester) async {
    session.playerDataController.setStance(Stance.strong);
    await pumpRings(tester, skills: [SkillId.WOODCUTTING]);
    expect(ringIds(tester), contains(SkillId.STRENGTH));

    session.playerDataController.setStance(Stance.fast);
    await tester.pump();

    expect(ringIds(tester), contains(SkillId.SPEED));
    expect(ringIds(tester), isNot(contains(SkillId.STRENGTH)));
  });

  // the combat stances: offensive and defensive spend strength, fast spends
  // speed. what the stance scales (attack, defence) is a separate thing from
  // what the boost itself trains, and only the latter gets a ring
  testWidgets('offensive stance shows strength, not attack twice', (
    tester,
  ) async {
    session.playerDataController.setStance(Stance.offensive);
    await pumpRings(
      tester,
      skills: [SkillId.ATTACK, SkillId.HITPOINTS, SkillId.DEFENCE],
    );

    expect(ringIds(tester), [
      SkillId.ATTACK,
      SkillId.HITPOINTS,
      SkillId.DEFENCE,
      SkillId.STAMINA,
      SkillId.STRENGTH,
      SkillId.RECOVERY,
    ]);
    expect(find.byType(OverflowChip), findsNothing);
  });

  testWidgets('defensive stance shows strength too', (tester) async {
    session.playerDataController.setStance(Stance.defensive);
    await pumpRings(
      tester,
      skills: [SkillId.ATTACK, SkillId.HITPOINTS, SkillId.DEFENCE],
    );

    expect(ringIds(tester), contains(SkillId.STRENGTH));
    expect(ringIds(tester), isNot(contains(SkillId.SPEED)));
  });

  testWidgets('the pair toggles as a combat stance switches', (tester) async {
    const combat = [SkillId.ATTACK, SkillId.HITPOINTS, SkillId.DEFENCE];

    session.playerDataController.setStance(Stance.fast);
    await pumpRings(tester, skills: combat);
    expect(ringIds(tester), contains(SkillId.SPEED));
    expect(ringIds(tester), isNot(contains(SkillId.STRENGTH)));

    session.playerDataController.setStance(Stance.offensive);
    await tester.pump();
    expect(ringIds(tester), contains(SkillId.STRENGTH));
    expect(ringIds(tester), isNot(contains(SkillId.SPEED)));

    session.playerDataController.setStance(Stance.defensive);
    await tester.pump();
    expect(ringIds(tester), contains(SkillId.STRENGTH));

    session.playerDataController.setStance(Stance.fast);
    await tester.pump();
    expect(ringIds(tester), contains(SkillId.SPEED));
    expect(ringIds(tester), isNot(contains(SkillId.STRENGTH)));
  });

  testWidgets('six rings stay on one line, shrinking rather than folding '
      'away or overflowing', (tester) async {
    // the width an encounter screen actually leaves the row on a 360pt
    // phone, once its 16pt padding is taken off both sides
    session.playerDataController.setStance(Stance.fast);
    await pumpRings(
      tester,
      width: 328,
      skills: [SkillId.ATTACK, SkillId.HITPOINTS, SkillId.DEFENCE],
    );

    // all six are drawn: none folded into a +N chip
    expect(ringIds(tester).length, 6);
    expect(find.byType(OverflowChip), findsNothing);

    // and they shrank to fit, rather than overflowing the row (an overflow
    // would already have failed this test)
    final tile = tester.widget<SkillTile>(find.byType(SkillTile).first);
    expect(tile.size, lessThan(40));
    expect(tile.size, greaterThanOrEqualTo(28));
  });
}
