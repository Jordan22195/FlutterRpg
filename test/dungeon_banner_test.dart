import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/hearth_theme.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/dungeon_banner.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

/// A dungeon's banner over the zone grid: its uniques greyed until
/// collected, edged in the best rarity had, checked once that's the best
/// there is, and a "+N" past five that lists every rarity of every one.
void main() {
  setUpAll(registerCatalogIconResolvers);

  final grainery = DungeonId.GRAINERY.definition.uniques;
  final wolfDen = DungeonId.WOLF_DEN.definition;

  Future<List<String>> pumpBanner(
    WidgetTester tester, {
    DungeonId dungeonId = DungeonId.GRAINERY,
    List<ItemId>? uniques,
    Map<ItemId, Set<Rarity>> obtained = const {},
    int? level = 13,
    bool levelMet = true,
    ZonePalette palette = ZonePalette.meadow,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: hearthTheme(palette),
        home: Scaffold(
          body: Center(
            child: DungeonBanner(
              dungeonId: dungeonId,
              name: 'The Grainery',
              level: level,
              levelMet: levelMet,
              uniques: uniques ?? dungeonId.definition.uniques,
              obtainedRarities: (id) => obtained[id],
              onTap: () => taps.add('tap'),
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  Finder slot(ItemId id) => find.byKey(ValueKey('dungeon-loot-${id.name}'));

  test('every listed unique drops at a rarity its dungeon names', () {
    // the Wolf Den's set pieces and its trash monsters' two are all there
    expect(wolfDen.uniques, hasLength(10));
    // its bosses' and chest's pieces at uncommon and rare; the cloak and
    // belt its trash carry at uncommon alone
    for (final id in wolfDen.uniques) {
      expect(
        wolfDen.dropRaritiesOf(id),
        id == ItemId.WOLF_DEN_CLOAK || id == ItemId.WOLF_HIDE_BELT
            ? [Rarity.UNCOMMON]
            : [Rarity.UNCOMMON, Rarity.RARE],
        reason: id.name,
      );
    }
    for (final d in DungeonId.values) {
      for (final id in d.definition.uniques) {
        final drops = d.definition.dropRaritiesOf(id);
        expect(drops, isNotEmpty, reason: '${d.name} ${id.name}');
        // lowest first
        expect(
          drops.map((r) => r.index).toList(),
          [...drops.map((r) => r.index)]..sort(),
        );
      }
    }
  });

  testWidgets('grey until had; edged in its rarity once had; checked only at '
      'its best', (tester) async {
    final [none, low, best, ..._] = wolfDen.uniques;
    await pumpBanner(
      tester,
      dungeonId: DungeonId.WOLF_DEN,
      obtained: {
        low: {Rarity.UNCOMMON},
        best: {Rarity.UNCOMMON, Rarity.RARE},
      },
    );

    Finder within(ItemId id, Finder f) =>
        find.descendant(of: slot(id), matching: f);
    final grey = find.byKey(const ValueKey('dungeon-loot-unobtained'));
    final check = find.byKey(const ValueKey('dungeon-loot-check'));
    Color? edge(ItemId id) {
      final box = tester
          .widgetList<Container>(within(id, find.byType(Container)))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == Colors.black.withValues(alpha: 0.33));
      return (box.border as Border?)?.top.color;
    }

    // never had: grey, faded, no edge, no check
    expect(within(none, grey), findsOneWidget);
    expect(tester.widget<Opacity>(within(none, grey)).opacity, 0.4);
    expect(within(none, find.byType(ColorFiltered)), findsOneWidget);
    expect(within(none, check), findsNothing);
    expect(edge(none), isNull);

    // had below its best: in colour, edged in what was had, no check
    expect(within(low, grey), findsNothing);
    expect(within(low, find.byType(ColorFiltered)), findsNothing);
    expect(within(low, check), findsNothing);
    expect(edge(low), rarityBorderColor(Rarity.UNCOMMON));

    // had at its best: edged in it, and checked as a cleared floor is
    expect(edge(best), rarityBorderColor(Rarity.RARE));
    final mark = find.descendant(
      of: within(best, check),
      matching: find.byIcon(Icons.check),
    );
    expect(mark, findsOneWidget);
    expect(tester.widget<Icon>(mark).color, GameColors.clearedColor);

    // the item's own icon is in every slot
    for (final id in [none, low, best]) {
      expect(
        within(
          id,
          find.byWidgetPredicate(
            (w) => w is IconRenderer<ItemId> && w.id == id && w.size == 20,
          ),
        ),
        findsOneWidget,
      );
    }
    // only the piece at its best counts toward the tally
    expect(find.text('1/${wolfDen.uniques.length}'), findsOneWidget);
  });

  testWidgets('a piece had before rarities were kept is collected, not '
      'checked', (tester) async {
    final id = wolfDen.uniques.first;
    await pumpBanner(tester, dungeonId: DungeonId.WOLF_DEN, obtained: {id: {}});
    expect(
      find.descendant(
        of: slot(id),
        matching: find.byKey(const ValueKey('dungeon-loot-unobtained')),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('dungeon-loot-check')), findsNothing);
  });

  testWidgets('the check hangs off the slot\'s bottom-right corner', (
    tester,
  ) async {
    final id = wolfDen.uniques.first;
    await pumpBanner(
      tester,
      dungeonId: DungeonId.WOLF_DEN,
      obtained: {
        id: {Rarity.RARE},
      },
    );
    final box = tester.getRect(slot(id));
    final check = tester.getRect(
      find.byKey(const ValueKey('dungeon-loot-check')),
    );
    expect(box.size, const Size(26, 26));
    expect(check.size, const Size(14, 14));
    expect(check.right, box.right + 4);
    expect(check.bottom, box.bottom + 4);
  });

  testWidgets('five uniques fit; past five the last slot is +N', (
    tester,
  ) async {
    expect(grainery, hasLength(5));
    await pumpBanner(tester);
    for (final id in grainery) {
      expect(slot(id), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('dungeon-loot-more')), findsNothing);

    final ten = wolfDen.uniques;
    await pumpBanner(
      tester,
      dungeonId: DungeonId.WOLF_DEN,
      obtained: {
        ten[9]: {Rarity.RARE},
      },
    );
    for (final id in ten.take(4)) {
      expect(slot(id), findsOneWidget);
    }
    for (final id in ten.skip(4)) {
      expect(slot(id), findsNothing);
    }
    final more = find.byKey(const ValueKey('dungeon-loot-more'));
    expect(more, findsOneWidget);
    expect(find.descendant(of: more, matching: find.text('+6')), findsOne);
    expect(tester.getSize(more), const Size(26, 26));
    // a piece past the cut still counts
    expect(find.text('1/10'), findsOneWidget);
  });

  testWidgets('+N lists a gear card for every rarity of every unique', (
    tester,
  ) async {
    final ids = wolfDen.uniques;
    final had = {
      ids[1]: {Rarity.UNCOMMON},
      ids[8]: {Rarity.UNCOMMON, Rarity.RARE},
    };
    final taps = await pumpBanner(
      tester,
      dungeonId: DungeonId.WOLF_DEN,
      obtained: had,
    );

    await tester.tap(find.byKey(const ValueKey('dungeon-loot-more')));
    await tester.pumpAndSettle();
    expect(taps, isEmpty);

    final sheet = find.byType(DungeonUniquesList);
    expect(sheet, findsOneWidget);
    // a card per rarity each drops at (two for most, one for the trash
    // pieces), three of them had
    final total = ids.fold(0, (n, id) => n + wolfDen.dropRaritiesOf(id).length);
    expect(total, 18);
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('The Grainery uniques · 3/$total'),
      ),
      findsOneWidget,
    );
    final scrollable = find.descendant(
      of: sheet,
      matching: find.byType(Scrollable),
    );
    for (final id in ids) {
      for (final rarity in wolfDen.dropRaritiesOf(id)) {
        final card = find.byKey(
          ValueKey('dungeon-unique-${id.name}-${rarity.name}'),
        );
        await tester.scrollUntilVisible(card, 60, scrollable: scrollable);
        final picker = tester.widget<EquipmentPickerCard>(card);
        // the piece as it drops at that rarity
        expect(picker.item.id, id);
        expect(picker.item.quality, rarity);
        Finder inCard(Finder f) => find.descendant(of: card, matching: f);
        // its icon, name, slot and stats, as the gear picker shows them
        expect(inCard(find.text(id.definition.name)), findsOneWidget);
        expect(
          inCard(find.byKey(const ValueKey('equipment-card-slot'))),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(
                inCard(find.byKey(const ValueKey('dungeon-unique-rarity'))),
              )
              .data,
          rarity.label,
        );
        final got = had[id]?.contains(rarity) ?? false;
        expect(
          inCard(find.byKey(const ValueKey('dungeon-unique-check'))),
          got ? findsOneWidget : findsNothing,
          reason: '${id.name} ${rarity.name}',
        );
        expect(
          inCard(find.text('Not yet')),
          got ? findsNothing : findsOneWidget,
          reason: '${id.name} ${rarity.name}',
        );
      }
    }
  });

  testWidgets('the dungeon\'s scene fills the card, as the map\'s preview '
      'is filled', (tester) async {
    await pumpBanner(tester);
    final artInk = find.byKey(const ValueKey('dungeon-banner-art'));
    final art = tester.widget<Ink>(artInk).decoration! as BoxDecoration;
    final image = art.image!;
    expect(
      (image.image as AssetImage).assetName,
      DungeonId.GRAINERY.definition.iconAsset,
    );
    expect(image.fit, BoxFit.cover);
    expect(image.filterQuality, FilterQuality.none);
    // the art fills the whole card, not a sprite in a frame
    expect(tester.getSize(artInk), tester.getSize(find.byType(DungeonBanner)));
    expect(
      find.byWidgetPredicate((w) => w is IconRenderer<DungeonId>),
      findsNothing,
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    // nothing running here, so no progress along the foot
    expect(find.byKey(const ValueKey('dungeon-banner-progress')), findsNothing);
  });

  testWidgets('the whole card is one button that reads its state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final uniques = wolfDen.uniques.take(5).toList();
    final taps = await pumpBanner(
      tester,
      dungeonId: DungeonId.WOLF_DEN,
      uniques: uniques,
      obtained: {
        uniques[0]: {Rarity.RARE},
        uniques[1]: {Rarity.UNCOMMON},
      },
    );

    expect(
      find.bySemanticsLabel(
        'The Grainery, dungeon, combat level 13, '
        '1 of 5 unique items at their best rarity',
      ),
      findsOneWidget,
    );
    final card = tester.getRect(find.byType(DungeonBanner));
    expect(card.height, greaterThanOrEqualTo(112));

    // each piece is a button of its own inside it
    expect(
      find.bySemanticsLabel(
        '${uniques[0].definition.name}, collected at its best rarity',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        '${uniques[1].definition.name}, collected, Rare still to find',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('${uniques[2].definition.name}, not collected'),
      findsOneWidget,
    );

    // the name and the art on the right both go in
    await tester.tap(find.text('The Grainery'));
    final card2 = tester.getRect(find.byType(DungeonBanner));
    await tester.tapAt(card2.centerRight - const Offset(24, 0));
    expect(taps, ['tap', 'tap']);

    semantics.dispose();
  });

  testWidgets('the level reads green when met and the shortfall colour when '
      'not', (tester) async {
    Color levelColor() => tester
        .widget<Text>(find.byKey(const ValueKey('dungeon-banner-level')))
        .style!
        .color!;

    await pumpBanner(tester);
    final context = tester.element(find.byType(DungeonBanner));
    expect(levelColor(), context.gameColors.levelEasy);

    await pumpBanner(tester, levelMet: false);
    expect(levelColor(), context.gameColors.levelHard);
  });

  testWidgets('the banner wears the zone it stands in', (tester) async {
    BoxDecoration ink(String key) =>
        tester.widget<Ink>(find.byKey(ValueKey(key))).decoration!
            as BoxDecoration;
    BoxDecoration card() => ink('dungeon-banner-art');

    final seen = <Color>{};
    for (final palette in [ZonePalette.meadow, ZonePalette.saltwind]) {
      await pumpBanner(tester, palette: palette);
      // the app's theme eases from one zone's to the next
      await tester.pumpAndSettle();
      // the scrim is the zone's own background, heavy under the text and
      // clearing toward the art
      final scrim =
          (ink('dungeon-banner-scrim').gradient! as LinearGradient).colors;
      expect(scrim.first, palette.bg.withValues(alpha: 0.96));
      expect(scrim.last, palette.bg.withValues(alpha: 0.1));
      expect(card().color, palette.bg);
      expect(
        tester.widget<Text>(find.text('The Grainery')).style!.color,
        palette.text,
      );
      seen.add((card().border! as Border).top.color);
    }
    // the edge takes each zone's own scene colour
    expect(seen.length, 2);
  });
}
