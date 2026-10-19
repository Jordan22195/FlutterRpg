import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/explore_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/segmented_tabs.dart';
import 'package:rpg/widgets/sprite_frame.dart';

/// A zone card says how hard the thing is, not what skill it trains — the
/// frame's tint and the filter chips already carry the kind. A combat
/// entity's meta line leads with its level ("Lv 3 · 1.57k"); a gathering
/// node's with the defence its skill is rolled against.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The meta line on [id]'s card, when it leads with level [level].
  Finder levelMeta(EntityId id, int level) => find.descendant(
    of: find.byKey(ValueKey(id)),
    matching: find.textContaining(RegExp('^Lv $level( · |\$)')),
  );

  /// Text rendered on [id]'s card. The resource sub-tab chips carry skill
  /// names of their own, so a card claim has to be scoped to the card.
  Finder cardText(EntityId id, String text) =>
      find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));

  Future<GameSession> pumpExplore(WidgetTester tester) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // a fight and a gathering node, side by side in the starting zone
    final zone = save.worldData.zones[save.playerData.currentZoneId]!;
    zone.discoveredEntities.add(EntityId.CHICKEN.build() as EncounterEntity);
    zone.discoveredEntities.add(EntityId.TREE.build() as EncounterEntity);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GameSession>.value(value: session),
          ChangeNotifierProvider<WorldController>.value(
            value: session.worldController,
          ),
          ChangeNotifierProvider<BuffController>.value(
            value: session.buffController,
          ),
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
          ChangeNotifierProvider<ActionTimingController>.value(
            value: session.actionTimingController,
          ),
          ChangeNotifierProvider<ActionQueueController>.value(
            value: session.actionQueueController,
          ),
          ChangeNotifierProvider<PlayerDataController>.value(
            value: session.playerDataController,
          ),
          // the status row over the art reads the encounter for its
          // damage numbers
          ChangeNotifierProvider<EncounterController>.value(
            value: session.encounterController,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ExploreScreen())),
      ),
    );
    await settle(tester);

    return session;
  }

  testWidgets('a combat card shows the entity level, not "Combat"', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    final chicken = EntityId.CHICKEN.definition as CombatEntityDefinition;
    expect(chicken.level, 3);
    expect(levelMeta(EntityId.CHICKEN, chicken.level), findsOneWidget);
    expect(cardText(EntityId.CHICKEN, 'Combat'), findsNothing);

    session.dispose();
  });

  testWidgets('a gathering card shows the node defence, not the skill name', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    final tree = EntityId.TREE.definition as EncounterEntityDefinition;
    expect(levelMeta(EntityId.TREE, tree.defence), findsOneWidget);
    expect(cardText(EntityId.TREE, 'Woodcutting'), findsNothing);

    // the pond is a gathering node too, but it lists as a place, and a
    // place says what it trains before how hard it is
    final pond = EntityId.TRANQUIL_POND.definition as FishingEntityDefinition;
    expect(
      cardText(EntityId.TRANQUIL_POND, 'Fishing · Lv ${pond.requiredLevel}'),
      findsOneWidget,
    );

    session.dispose();
  });

  testWidgets('a structure with no difficulty keeps its skill label', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    // a firepit has no stat to rank it by, so it still says what it trains
    expect(cardText(EntityId.FIREPIT, 'Firemaking'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.FIREPIT)),
        matching: find.textContaining('Lv'),
      ),
      findsNothing,
    );

    session.dispose();
  });

  test('entityLevel is the combat level, or the gathering defence', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final session = factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final world = session.worldController;

    final queen = EntityId.GOBLIN_QUEEN.build() as EncounterEntity;
    final queenDef = EntityId.GOBLIN_QUEEN.definition as CombatEntityDefinition;
    // the catalog's level, not a copy of it — a rebalance moves the number
    // without changing the claim that a combat card reads its combat level
    expect(world.entityLevel(queen), queenDef.level);

    final tree = EntityId.TREE.build() as EncounterEntity;
    expect(world.entityLevel(tree), tree.defence);

    session.actionTimingController.stop();
    session.dispose();
  });

  testWidgets('places and discoveries list under their own headings', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    final places = tester.getTopLeft(find.text('PLACES')).dy;
    final discovered = tester.getTopLeft(find.text('DISCOVERIES')).dy;
    // permanent places first, then what exploring turned up
    expect(
      places,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey(EntityId.ANVIL))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey(EntityId.ANVIL))).dy,
      lessThan(discovered),
    );
    expect(
      discovered,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey(EntityId.CHICKEN))).dy,
      ),
    );

    session.dispose();
  });

  testWidgets('no row carries a coloured stripe down its edge', (tester) async {
    final session = await pumpExplore(tester);

    // places used to wear a stripe; the frame's tint and the chevron now
    // say "place", so no row draws one
    Finder stripe(EntityId id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byWidgetPredicate(
        (w) => w is Positioned && w.width == 4 && w.child is ColoredBox,
      ),
    );
    expect(stripe(EntityId.ANVIL), findsNothing);
    expect(stripe(EntityId.CHICKEN), findsNothing);
    expect(stripe(EntityId.TREE), findsNothing);

    session.dispose();
  });

  /// Whether [id]'s card is drawn behind a blur.
  bool blurred(WidgetTester tester, EntityId id) => find
      .ancestor(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(ImageFiltered),
      )
      .evaluate()
      .isNotEmpty;

  testWidgets(
    'everything the zone can turn up is listed, the unfound blurred',
    (tester) async {
      final session = await pumpExplore(tester);

      // the starting zone's discoverables, read off the catalog: the chicken
      // and the tree were found in pumpExplore, the rest were not
      final zone = session.worldController.viewedZoneDefinition();
      final unfound = zone.discoverableEntities
          .map((e) => e.id)
          .where((id) => id != EntityId.CHICKEN && id != EntityId.TREE)
          .toList();
      expect(unfound, isNotEmpty);

      // what has been found reads plainly
      expect(blurred(tester, EntityId.CHICKEN), isFalse);
      expect(blurred(tester, EntityId.TREE), isFalse);

      // everything else is on the list, behind a blur
      for (final id in unfound) {
        expect(find.byKey(ValueKey(id)), findsOneWidget, reason: '$id');
        expect(blurred(tester, id), isTrue, reason: '$id');
      }

      session.dispose();
    },
  );

  testWidgets('found or not, every discoverable keeps its slot', (
    tester,
  ) async {
    final session = await pumpExplore(tester);
    final zone = session.worldController.viewedZoneDefinition();
    final ids = zone.discoverableEntities.map((e) => e.id).toList();

    // the order the cards sit in, top to bottom
    List<EntityId> onScreen() =>
        ids
            .where((id) => find.byKey(ValueKey(id)).evaluate().isNotEmpty)
            .toList()
          ..sort(
            (a, b) => tester
                .getTopLeft(find.byKey(ValueKey(a)))
                .dy
                .compareTo(tester.getTopLeft(find.byKey(ValueKey(b))).dy),
          );

    // clustered by kind — combat first, then the gathering skills in skill
    // order — and in the zone's own table order within a kind, whether or
    // not a card has been found
    int rank(EntityId id) {
      final e = id.build();
      if (e is CombatEntity) return -1;
      return (e as EncounterEntity).entityType.index;
    }

    final expected = List.of(ids)
      ..sort((a, b) {
        final byKind = rank(a).compareTo(rank(b));
        return byKind != 0 ? byKind : ids.indexOf(a).compareTo(ids.indexOf(b));
      });
    expect(onScreen(), expected);

    // finding one more changes how it is drawn, not where it sits
    const cow = EntityId.COW;
    expect(blurred(tester, cow), isTrue);
    session
        .saveGameData
        .worldData
        .zones[session.worldController.viewedZoneId]!
        .discoveredEntities
        .add(cow.build() as EncounterEntity);
    session.worldController.refresh();
    await settle(tester);

    expect(blurred(tester, cow), isFalse);
    expect(onScreen(), expected);

    session.dispose();
  });

  testWidgets('a discovery behind an exploration level wears a lock', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    final zone = session.worldController.viewedZoneDefinition();
    final level = session.worldController
        .zoneDetails(session.worldController.viewedZoneId)
        .explorationLevel;
    const found = {EntityId.CHICKEN, EntityId.TREE};
    final unfound = zone.discoverableEntities.where(
      (e) => !found.contains(e.id),
    );
    final gated = unfound.where((e) => e.unlockLevel > level).toList();
    final open = unfound.where((e) => e.unlockLevel <= level).toList();
    expect(gated, isNotEmpty);

    // one lock per gated card, each carrying the level it opens at
    expect(find.byIcon(Icons.lock), findsNWidgets(gated.length));
    final lockYs = tester
        .widgetList(find.byIcon(Icons.lock))
        .map((w) => tester.getCenter(find.byWidget(w)).dy)
        .toList();
    bool hasLock(EntityId id) {
      final rect = tester.getRect(find.byKey(ValueKey(id)));
      return lockYs.any((y) => rect.top < y && y < rect.bottom);
    }

    for (final entry in gated) {
      expect(hasLock(entry.id), isTrue, reason: '${entry.id}');
      expect(
        find.text('Exploration ${entry.unlockLevel}'),
        findsWidgets,
        reason: '${entry.id}',
      );
    }
    // a card the level already reaches is blurred but not locked
    for (final entry in open) {
      expect(hasLock(entry.id), isFalse, reason: '${entry.id}');
    }

    session.dispose();
  });

  testWidgets('an unfound card opens nothing', (tester) async {
    final session = await pumpExplore(tester);
    final zone = session.worldController.viewedZoneDefinition();
    final unfound = zone.discoverableEntities
        .map((e) => e.id)
        .firstWhere((id) => id != EntityId.CHICKEN && id != EntityId.TREE);
    final viewed = session.saveGameData.playerData.currentEntityViewId;

    await tester.tap(find.byKey(ValueKey(unfound)), warnIfMissed: false);
    await settle(tester);

    expect(session.saveGameData.playerData.currentEntityViewId, viewed);

    session.dispose();
  });

  testWidgets('a discovery card\'s sprite sits on the card colour', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    Color? frameFill(EntityId id) => tester
        .widget<SpriteFrame>(
          find.descendant(
            of: find.byKey(ValueKey(id)),
            matching: find.byType(SpriteFrame),
          ),
        )
        .fill;
    Color cardFill(EntityId id) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byKey(ValueKey(id)),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;

    for (final id in [EntityId.CHICKEN, EntityId.TREE]) {
      expect(frameFill(id), cardFill(id), reason: '$id');
    }

    session.dispose();
  });

  // ---------------------------------------------------------- places grid

  testWidgets('places are a three-column grid of 120pt tiles', (tester) async {
    final session = await pumpExplore(tester);
    final places = ZoneId.TUTORIAL_FARM.definition.permanentEntities;
    expect(places.length, 5, reason: 'Southglen has five places');

    Rect at(EntityId id) => tester.getRect(find.byKey(ValueKey(id)));
    final rects = [for (final id in places) at(id)];

    // three equal columns 10 apart inside the body's 16pt margins
    final width = (1000 - 2 * 16 - 2 * 10) / 3;
    for (final r in rects) {
      expect(r.width, closeTo(width, 0.01));
      expect(r.height, 120);
    }
    // filled left to right, top to bottom
    expect(rects[0].left, 16);
    expect(rects[1].left, closeTo(16 + width + 10, 0.01));
    expect(rects[2].left, closeTo(16 + 2 * (width + 10), 0.01));
    expect(rects[1].top, rects[0].top);
    expect(rects[2].top, rects[0].top);
    // the short last row stays left-aligned, unstretched
    expect(rects[3].top, rects[0].bottom + 10);
    expect(rects[3].left, 16);
    expect(rects[4].left, rects[1].left);
    expect(rects[4].width, closeTo(width, 0.01));

    // no chevrons on tiles
    for (final id in places) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(id)),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
      );
    }

    session.dispose();
  });

  testWidgets('each tile\'s frame is tinted for its kind of place', (
    tester,
  ) async {
    final session = await pumpExplore(tester);
    const colors = GameColors.standard;
    const palette = ZonePalette.meadow;

    BoxDecoration frameOf(EntityId id) =>
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byKey(ValueKey(id)),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is Container &&
                              w.constraints?.maxWidth == 64 &&
                              w.constraints?.maxHeight == 56,
                        ),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    expect(frameOf(EntityId.TRANQUIL_POND).color, palette.gatherTintFill);
    expect(frameOf(EntityId.ANVIL).color, colors.craftingTint.fill);
    expect(frameOf(EntityId.FIREPIT).color, colors.fireTint.fill);
    expect(frameOf(EntityId.FARMER).color, colors.shopTint.fill);

    // a dungeon sits on its own fill, outlined 2px in its rarity
    final dungeon = frameOf(EntityId.GRAINERY_ENTRANCE);
    expect(dungeon.color, colors.dungeonTintFill);
    final side = (dungeon.border! as Border).top;
    expect(side.width, 2);
    expect(
      side.color,
      rarityBorderColor(EntityId.GRAINERY_ENTRANCE.definition.rarity),
    );

    session.dispose();
  });

  testWidgets('each tile names itself and what it is for', (tester) async {
    final semantics = tester.ensureSemantics();
    final session = await pumpExplore(tester);

    final pond = EntityId.TRANQUIL_POND.definition as FishingEntityDefinition;
    expect(
      find.bySemanticsLabel('Pond, Fishing level ${pond.requiredLevel}'),
      findsOneWidget,
    );
    expect(find.text('Smithing'), findsOneWidget);
    expect(find.text('Buy & sell'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.GRAINERY_ENTRANCE)),
        matching: find.text('Dungeon'),
      ),
      findsOneWidget,
    );

    semantics.dispose();
    session.dispose();
  });

  testWidgets('the sections sit where the layout puts them, with no chips', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    final tabs = tester.getRect(
      find.byWidgetPredicate((w) => w is SegmentedTabs).first,
    );
    final places = tester.getRect(find.text('PLACES'));
    final firstTile = tester.getRect(
      find.byKey(const ValueKey(EntityId.TRANQUIL_POND)),
    );
    final lastTile = tester.getRect(
      find.byKey(const ValueKey(EntityId.GRAINERY_ENTRANCE)),
    );
    final discoveries = tester.getRect(find.text('DISCOVERIES'));
    final firstCard = tester.getRect(
      find.byKey(const ValueKey(EntityId.CHICKEN)),
    );

    expect(places.top - tabs.bottom, 16);
    expect(firstTile.top - places.bottom, 8);
    expect(discoveries.top - lastTile.bottom, 24);
    expect(firstCard.top - discoveries.bottom, 8);
    // 20 from the screen edge
    expect(places.left, 20);

    // the discoveries start straight under their label: no filter chips
    expect(find.text('All'), findsNothing);
    expect(find.text('Combat'), findsNothing);

    session.dispose();
  });
}
