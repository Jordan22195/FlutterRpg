import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/hearth_theme.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/action_dock.dart';
import 'package:rpg/widgets/empty_state.dart';
import 'package:rpg/widgets/hearth_chip.dart';
import 'package:rpg/widgets/hearth_nav_bar.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/list_row.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/segmented_tabs.dart';
import 'package:rpg/widgets/skil_tile.dart';
import 'package:rpg/widgets/sprite_frame.dart';

/// The Hearth shared components, each checked against the spec's numbers
/// and colour rules in both palettes where the palette matters.
void main() {
  setUpAll(() {
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
  });

  Future<void> pumpThemed(
    WidgetTester tester,
    Widget child, {
    ZonePalette palette = ZonePalette.meadow,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hearthTheme(palette),
        home: Scaffold(body: Center(child: child)),
      ),
    );
    // a palette change crossfades through AnimatedTheme; let it land
    await tester.pump(const Duration(milliseconds: 300));
  }

  BoxDecoration decorationOf(WidgetTester tester, Finder finder) {
    final container = tester.widget<Container>(finder);
    return container.decoration! as BoxDecoration;
  }

  group('SegmentedTabs', () {
    testWidgets('is 48 tall, raises the selected segment and reports taps', (
      tester,
    ) async {
      var selected = 'a';
      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 358,
            child: SegmentedTabs<String>(
              segments: const [
                TabSegment(value: 'a', label: 'Entities'),
                TabSegment(value: 'b', label: 'Loot · 0'),
                TabSegment(value: 'c', label: 'Info'),
              ],
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SegmentedTabs<String>)).height, 48);

      Color fillOf(String label) {
        final box = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      expect(fillOf('Entities'), ZonePalette.meadow.raised);
      expect(fillOf('Info'), Colors.transparent);

      await tester.tap(find.text('Info'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selected, 'c');
      expect(fillOf('Info'), ZonePalette.meadow.raised);
      expect(fillOf('Entities'), Colors.transparent);
    });
  });

  group('HearthChip', () {
    testWidgets('active is filled with text; inactive sits on the surface', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HearthChip(label: 'All', count: 9106, selected: true, onTap: () {}),
            HearthChip(
              label: 'Combat',
              count: 6082,
              selected: false,
              onTap: () {},
            ),
          ],
        ),
      );
      const p = ZonePalette.meadow;

      BoxDecoration chip(String label) =>
          tester
                  .widget<AnimatedContainer>(
                    find.ancestor(
                      of: find.text(label),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration!
              as BoxDecoration;

      expect(chip('All').color, p.text);
      expect(tester.widget<Text>(find.text('All')).style!.color, p.bg);
      expect(chip('Combat').color, p.surface);
      expect((chip('Combat').border! as Border).top.color, p.borderStrong);
      // the count is grouped and muted on an inactive chip
      expect(tester.widget<Text>(find.text('6,082')).style!.color, p.textMuted);
      expect(tester.getSize(find.byType(HearthChip).first).height, 44);
    });
  });

  group('SpriteFrame', () {
    testWidgets('each kind wears its tint, and gathering follows the zone', (
      tester,
    ) async {
      Future<BoxDecoration> frame(SpriteKind kind, ZonePalette palette) async {
        await pumpThemed(
          tester,
          SpriteFrame(id: EntityId.CHICKEN, kind: kind),
          palette: palette,
        );
        return decorationOf(
          tester,
          find.descendant(
            of: find.byType(SpriteFrame),
            matching: find.byType(Container),
          ),
        );
      }

      const colors = GameColors.standard;
      expect(
        (await frame(SpriteKind.combat, ZonePalette.meadow)).color,
        colors.combatTint.fill,
      );
      expect(
        (await frame(SpriteKind.fire, ZonePalette.meadow)).color,
        colors.fireTint.fill,
      );
      expect(
        (await frame(SpriteKind.crafting, ZonePalette.meadow)).color,
        colors.craftingTint.fill,
      );
      expect(
        (await frame(SpriteKind.gathering, ZonePalette.meadow)).color,
        ZonePalette.meadow.gatherTintFill,
      );
      expect(
        (await frame(SpriteKind.gathering, ZonePalette.forest)).color,
        ZonePalette.forest.gatherTintFill,
      );
      final combat = await frame(SpriteKind.combat, ZonePalette.meadow);
      expect(combat.borderRadius, BorderRadius.circular(12));
      expect((combat.border! as Border).top.width, 1);
    });

    testWidgets('a rare entity keeps its rarity outline', (tester) async {
      await pumpThemed(
        tester,
        const SpriteFrame(id: EntityId.GOBLIN_QUEEN, kind: SpriteKind.dungeon),
      );
      final side =
          (decorationOf(
                    tester,
                    find.descendant(
                      of: find.byType(SpriteFrame),
                      matching: find.byType(Container),
                    ),
                  ).border!
                  as Border)
              .top;
      expect(side.width, 2);
      expect(
        side.color,
        rarityBorderColor(EntityId.GOBLIN_QUEEN.definition.rarity),
      );
    });
  });

  group('ListRow', () {
    testWidgets('places are 64 tall and entities 68, on the surface', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const SizedBox(
          width: 358,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListRow(
                key: Key('place'),
                leading: SizedBox(width: 48, height: 48),
                title: 'Pond',
                meta: RowMeta(text: 'Fishing · Lv 1'),
                trailing: RowChevron(),
              ),
              ListRow(
                key: Key('entity'),
                height: ListRow.entityHeight,
                leading: SizedBox(width: 52, height: 52),
                title: 'Chicken',
                meta: RowMeta(text: 'Lv 3 · 1.57k'),
              ),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('place'))).height, 64);
      expect(tester.getSize(find.byKey(const Key('entity'))).height, 68);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(const Key('place')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, ZonePalette.meadow.surface);
      expect(
        tester.widget<Text>(find.text('Fishing · Lv 1')).style!.color,
        ZonePalette.meadow.textMuted,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.chevron_right)).color,
        ZonePalette.meadow.chevron,
      );
    });
  });

  testWidgets('EmptyState says what is missing', (tester) async {
    await pumpThemed(tester, const EmptyState(message: 'No loot this session'));
    expect(find.text('No loot this session'), findsOneWidget);
    expect(tester.getSize(find.byType(EmptyState)).height, 76);
  });

  group('HearthNavBar', () {
    testWidgets(
      'the active item sits on a raised pill; taps report the index',
      (tester) async {
        var tapped = -1;
        await tester.pumpWidget(
          MaterialApp(
            theme: hearthTheme(ZonePalette.meadow),
            home: Scaffold(
              bottomNavigationBar: HearthNavBar(
                currentIndex: 0,
                onTap: (i) => tapped = i,
                items: const [
                  HearthNavItem(icon: Icons.map_outlined, label: 'Map'),
                  HearthNavItem(icon: Icons.trending_up, label: 'Skills'),
                ],
              ),
            ),
          ),
        );
        const p = ZonePalette.meadow;

        expect(tester.getSize(find.byType(HearthNavBar)).height, 68);
        expect(tester.widget<Text>(find.text('Map')).style!.color, p.text);
        expect(
          tester.widget<Text>(find.text('Skills')).style!.color,
          p.textNavInactive,
        );
        final pill = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.byIcon(Icons.map_outlined),
            matching: find.byType(AnimatedContainer),
          ),
        );
        expect((pill.decoration! as BoxDecoration).color, p.raised);

        // each item is a full-height target, well over 44pt
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text('Skills'),
                      matching: find.byType(InkResponse),
                    )
                    .first,
              )
              .height,
          greaterThanOrEqualTo(44),
        );
        await tester.tap(find.text('Skills'));
        expect(tapped, 1);
      },
    );
  });

  testWidgets('ActionDock draws a divider on the background', (tester) async {
    await pumpThemed(
      tester,
      const ActionDock(buttons: SizedBox(height: 52)),
      palette: ZonePalette.forest,
    );
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ActionDock),
            matching: find.byType(DecoratedBox),
          )
          .last,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, ZonePalette.forest.bg);
    expect(
      (decoration.border! as Border).top.color,
      ZonePalette.forest.divider,
    );
  });

  group('with a game session', () {
    late GameSession session;

    setUp(() {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      session = factory.create(
        save: factory.newGame(catalogs),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
    });

    tearDown(() => session.dispose());

    Future<void> pumpWithSession(
      WidgetTester tester,
      Widget child, {
      ZonePalette palette = ZonePalette.meadow,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GameSession>.value(value: session),
            ChangeNotifierProvider<PlayerDataController>.value(
              value: session.playerDataController,
            ),
            ChangeNotifierProvider<ActionTimingController>.value(
              value: session.actionTimingController,
            ),
            ChangeNotifierProvider<ActionQueueController>.value(
              value: session.actionQueueController,
            ),
            ChangeNotifierProvider<WorldController>.value(
              value: session.worldController,
            ),
          ],
          child: MaterialApp(
            theme: hearthTheme(palette),
            home: Scaffold(body: Center(child: child)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('a ring shows its level, no icon, and says what it is', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpWithSession(tester, const SkillTile(id: SkillId.STAMINA));

      final level = session.playerDataController.getSkillLevel(SkillId.STAMINA);
      expect(find.text('$level'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SkillTile),
          matching: find.byType(IconRenderer<SkillId>),
        ),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Stamina, level $level'), findsOneWidget);

      // a 40pt ring with a 44pt-tall tap target
      final size = tester.getSize(find.byType(SkillTile));
      expect(size.height, greaterThanOrEqualTo(44));
      semantics.dispose();
    });

    testWidgets('the primary button wears the zone accent and its lip', (
      tester,
    ) async {
      for (final palette in [ZonePalette.meadow, ZonePalette.forest]) {
        await pumpWithSession(
          tester,
          SizedBox(
            width: 300,
            child: MomentumPrimaryButton(
              enabled: true,
              label: 'Explore',
              startActionFunction: () {},
            ),
          ),
          palette: palette,
        );
        final surface = tester.widget<RaisedSurface>(
          find.byType(RaisedSurface),
        );
        expect(surface.color, palette.accent);
        expect(surface.lipColor, palette.accentLip);
        expect(surface.depth, kActionBarLip);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.play_arrow)).color,
          palette.onAccent,
        );
      }
    });

    testWidgets('a disabled primary button drops the accent and the lip', (
      tester,
    ) async {
      await pumpWithSession(
        tester,
        SizedBox(
          width: 300,
          child: MomentumPrimaryButton(
            enabled: false,
            label: 'Explore',
            startActionFunction: () {},
          ),
        ),
      );
      final surface = tester.widget<RaisedSurface>(find.byType(RaisedSurface));
      expect(surface.color, ZonePalette.meadow.surface);
      expect(surface.lipColor, Colors.transparent);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.play_arrow)).color,
        ZonePalette.meadow.textMuted,
      );
    });

    testWidgets('with nothing trailing, the primary button runs to the edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpWithSession(
        tester,
        ActionButtonRow(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          actionButton: MomentumPrimaryButton(
            enabled: true,
            label: 'Explore',
            startActionFunction: () {},
          ),
        ),
      );
      final button = tester.getRect(find.byType(MomentumPrimaryButton));
      // 16 side padding, a 52 stop slot and a 10 gap on the left only
      expect(button.left, 16 + kActionBarSideButtonWidth + 10);
      expect(button.right, 390 - 16);
    });
  });
}
