import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/entity_queue.dart';
import 'package:rpg/theme/hearth_theme.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/dungeon_floor_track.dart';
import 'package:rpg/widgets/sprite_frame.dart';

/// The floor track over a dungeon fight: what it counts, and how it marks
/// the member being fought.
void main() {
  setUpAll(registerCatalogIconResolvers);

  /// The Spider Den's second floor, built as a run builds it: uncommon
  /// spiders, zombies, then the Broodmother.
  EntityQueue lair() {
    final entry = DungeonId.SPIDER_DEN.definition.entries[1];
    return EntityQueue(
      name: entry.name,
      members: [
        for (final ref in entry.entities)
          (ref.entityId.build() as EncounterEntity)..count = ref.count,
      ],
    );
  }

  Future<void> pumpTrack(WidgetTester tester, EntityQueue floor) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hearthTheme(ZonePalette.forest),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DungeonFloorTrack(
              floor: floor,
              fullCounts: DungeonFloorTrack.fullCountsFor(
                DungeonId.SPIDER_DEN,
                1,
                floor,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  test('full counts come from the floor entry, member by member', () {
    expect(
      DungeonFloorTrack.fullCountsFor(DungeonId.SPIDER_DEN, 1, lair()),
      [15, 6, 1],
    );
  });

  testWidgets('counts kills toward the boss, not the boss itself', (
    tester,
  ) async {
    final floor = lair();
    // the spiders are down and two zombies of six with them
    floor.index = 1;
    floor.members[1].count = 4;
    await pumpTrack(tester, floor);

    expect(find.text('17 / 21 kills'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'cleared$')),
      findsOneWidget,
      reason: 'the spiders are the only member behind the player',
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Broodmother, boss, upcoming$')),
      findsOneWidget,
    );
  });

  testWidgets('on the boss the bar is full and the boss is the one fought', (
    tester,
  ) async {
    final floor = lair();
    floor.index = 2;
    for (final member in floor.members.take(2)) {
      member.count = 0;
    }
    await pumpTrack(tester, floor);

    expect(find.text('21 / 21 · Boss'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Broodmother, boss, fighting now$')),
      findsOneWidget,
    );
    // it keeps its gold frame while it is fought
    final frames = tester.widgetList<SpriteFrame>(find.byType(SpriteFrame));
    expect(frames.where((f) => f.isBoss), hasLength(1));
  });
}
