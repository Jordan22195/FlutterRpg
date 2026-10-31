import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/dungeon_run.dart';
import 'package:rpg/data/floor_clear_summary.dart';
import 'package:rpg/theme/hearth_theme.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/floor_clear_panel.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/loot_pop.dart';

// A floor's summary tells the boss's drops apart from the rest of the
// floor's: two labelled rows, the boss's first, its tiles brought in one
// at a time.
void main() {
  setUpAll(registerCatalogIconResolvers);

  test('a lap keeps the boss\'s drops apart, and a new lap clears both', () {
    final run = DungeonRun()
      ..addLapLoot([ObjectStack(id: ItemId.LOGS, count: 2)])
      ..addLapLoot([ObjectStack(id: ItemId.COINS, count: 5)], boss: true)
      ..addLapLoot([ObjectStack(id: ItemId.COINS, count: 3)], boss: true)
      ..addLapLoot([ObjectStack(id: ItemId.COINS, count: 1)]);

    Map<Object, int> counts(List<ObjectStack> l) => {
      for (final s in l) s.id: s.count,
    };
    expect(counts(run.lapLoot), {ItemId.LOGS: 2, ItemId.COINS: 1});
    expect(counts(run.lapBossLoot), {ItemId.COINS: 8});

    run.beginLap(watched: true);
    expect(run.lapLoot, isEmpty);
    expect(run.lapBossLoot, isEmpty);
  });

  FloorClearSummary summary({
    required bool boss,
    List<ObjectStack> loot = const [],
    List<ObjectStack> bossLoot = const [],
  }) => FloorClearSummary(
    dungeonId: DungeonId.WOLF_DEN,
    floorIndex: 0,
    floorName: 'The Den',
    lastMemberId: EntityId.CAVE_BEAR,
    lastMemberName: 'Cave Bear',
    boss: boss,
    defeated: 6,
    time: null,
    damageTaken: null,
    bestTimeBefore: null,
    leastDamageBefore: null,
    clears: 1,
    sessionClears: 1,
    loot: loot,
    bossLoot: bossLoot,
    endsAt: DateTime.now(),
  );

  Future<void> pumpPanel(WidgetTester tester, FloorClearSummary s) =>
      tester.pumpWidget(
        MaterialApp(
          theme: hearthTheme(ZonePalette.forest),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FloorClearPanel(summary: s),
            ),
          ),
        ),
      );

  /// How opaque each tile of [row]'s loot is, in order.
  List<double> opacities(WidgetTester tester, String row) {
    final tiles = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == row,
      ),
      matching: find.byType(ItemStackTile),
    );
    return [
      for (final tile in tiles.evaluate())
        tester
            .widgetList<Opacity>(
              find.ancestor(
                of: find.byWidget(tile.widget),
                matching: find.byType(Opacity),
              ),
            )
            .fold<double>(1, (o, f) => o * f.opacity),
    ];
  }

  testWidgets('the boss\'s loot and the floor\'s each get a labelled row, '
      'the boss\'s revealed one tile at a time', (tester) async {
    await pumpPanel(
      tester,
      summary(
        boss: true,
        loot: [
          ObjectStack(id: ItemId.LOGS, count: 4),
          ObjectStack(id: ItemId.COPPER_ORE, count: 2),
        ],
        bossLoot: [
          ObjectStack(id: ItemId.COINS, count: 50),
          ObjectStack(id: ItemId.COPPER_HELMET, count: 1),
          ObjectStack(id: ItemId.MINOR_SPEED_POTION, count: 1),
        ],
      ),
    );

    expect(find.text('BOSS LOOT'), findsOneWidget);
    expect(find.text('FLOOR LOOT'), findsOneWidget);
    expect(find.text('52 items'), findsOneWidget);
    expect(find.text('6 items'), findsOneWidget);
    // the boss's row comes first
    expect(
      tester.getTopLeft(find.text('BOSS LOOT')).dy,
      lessThan(tester.getTopLeft(find.text('FLOOR LOOT')).dy),
    );

    // the floor's loot is there at once; the boss's waits its turn
    expect(opacities(tester, 'floor loot'), [1.0, 1.0]);
    expect(opacities(tester, 'boss loot'), [0.0, 0.0, 0.0]);

    // on the chest's timing: each tile a beat behind the one before
    await tester.pump(LootPop.step ~/ 2);
    final first = opacities(tester, 'boss loot');
    expect(first[0], greaterThan(0));
    expect(first[1], 0.0);

    // at the first tile's full pop
    await tester.pump(LootPop.pop - LootPop.step ~/ 2);
    final later = opacities(tester, 'boss loot');
    expect(later[0], 1.0);
    expect(later[1], inExclusiveRange(0.0, 1.0));
    expect(later[2], inExclusiveRange(0.0, later[1]));

    await tester.pumpAndSettle();
    expect(opacities(tester, 'boss loot'), [1.0, 1.0, 1.0]);
  });

  testWidgets(
    'a rebuild leaves revealed loot alone; a new summary replays it',
    (tester) async {
      final bossLoot = [
        ObjectStack(id: ItemId.COINS, count: 50),
        ObjectStack(id: ItemId.COPPER_HELMET, count: 1),
      ];
      final first = summary(boss: true, bossLoot: bossLoot);
      await pumpPanel(tester, first);
      await tester.pumpAndSettle();
      expect(opacities(tester, 'boss loot'), [1.0, 1.0]);

      // the screen redraws the panel every frame the loop is held
      for (var i = 0; i < 5; i++) {
        await pumpPanel(tester, first);
        await tester.pump(const Duration(milliseconds: 16));
        expect(opacities(tester, 'boss loot'), [1.0, 1.0]);
      }

      await pumpPanel(tester, summary(boss: true, bossLoot: bossLoot));
      expect(opacities(tester, 'boss loot'), [0.0, 0.0]);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('a boss that dropped nothing says so', (tester) async {
    await pumpPanel(
      tester,
      summary(boss: true, loot: [ObjectStack(id: ItemId.LOGS, count: 1)]),
    );
    expect(find.text('Cave Bear dropped nothing'), findsOneWidget);
    expect(find.text('FLOOR LOOT'), findsOneWidget);
  });

  testWidgets('a floor with no boss has only the floor\'s row', (tester) async {
    await pumpPanel(
      tester,
      summary(boss: false, loot: [ObjectStack(id: ItemId.LOGS, count: 1)]),
    );
    expect(find.text('BOSS LOOT'), findsNothing);
    expect(find.text('FLOOR LOOT'), findsOneWidget);
    expect(opacities(tester, 'floor loot'), [1.0]);
  });
}
