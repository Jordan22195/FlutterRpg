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
import 'package:rpg/controllers/potion_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/explore_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/level_standing.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/segmented_tabs.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/progress_bars.dart';
import 'support/gathering_tools.dart';

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
  /// [id]'s tile reads [level] beside [skill]'s icon.
  bool showsLevel(WidgetTester tester, EntityId id, SkillId skill, int level) {
    final tile = find.byKey(ValueKey(id));
    final icon = find.descendant(
      of: tile,
      matching: find.byWidgetPredicate(
        (w) => w is IconRenderer<SkillId> && w.id == skill,
      ),
    );
    // the level, not the count chip beside it, which can read the same
    final numbers = find
        .descendant(of: tile, matching: find.text('$level'))
        .evaluate()
        .where((e) => e.findAncestorWidgetOfExactType<CountPill>() == null)
        .toList();
    if (icon.evaluate().isEmpty || numbers.isEmpty) return false;
    // side by side on one line
    final iconY = tester.getCenter(icon).dy;
    return numbers.any((e) {
      final box = e.renderObject! as RenderBox;
      final y = box.localToGlobal(box.size.center(Offset.zero)).dy;
      return (y - iconY).abs() < 4;
    });
  }

  /// Text rendered on [id]'s card. The resource sub-tab chips carry skill
  /// names of their own, so a card claim has to be scoped to the card.
  Finder cardText(EntityId id, String text) =>
      find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));

  /// [tools] equips the starter axe, pickaxe and rod, so trees, ore and
  /// the pond read as workable; off, they read as locked.
  Future<GameSession> pumpExplore(
    WidgetTester tester, {
    bool tools = true,
    // stands the player in another zone; the starting one by default
    ZoneId? zoneId,
  }) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    if (tools) equipGatheringTools(save);
    if (zoneId != null) {
      save.playerData.currentZoneId = zoneId;
      save.playerData.currentZoneViewId = zoneId;
    }
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
          ChangeNotifierProvider<PotionController>.value(
            value: session.potionController,
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
    expect(
      showsLevel(tester, EntityId.CHICKEN, SkillId.ATTACK, chicken.level),
      isTrue,
    );
    expect(cardText(EntityId.CHICKEN, 'Combat'), findsNothing);

    session.dispose();
  });

  testWidgets('a gathering card shows the node defence, not the skill name', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    final tree = EntityId.TREE.definition as EncounterEntityDefinition;
    expect(
      showsLevel(tester, EntityId.TREE, SkillId.WOODCUTTING, tree.defence),
      isTrue,
    );
    expect(cardText(EntityId.TREE, 'Woodcutting'), findsNothing);

    // the pond is a gathering node too, but it lists as a place: the
    // fishing sprite beside the level it asks for, with no words
    final pond = EntityId.TRANQUIL_POND.definition as FishingEntityDefinition;
    expect(
      showsLevel(
        tester,
        EntityId.TRANQUIL_POND,
        SkillId.FISHING,
        pond.requiredLevel,
      ),
      isTrue,
    );
    expect(cardText(EntityId.TRANQUIL_POND, 'Fishing'), findsNothing);

    session.dispose();
  });

  testWidgets('a structure with no difficulty shows its skill sprite', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    // a firepit has no stat to rank it by: it shows what it trains by the
    // skill's sprite alone, with no label and no level
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.FIREPIT)),
        matching: find.byWidgetPredicate(
          (w) => w is IconRenderer<SkillId> && w.id == SkillId.FIREMAKING,
        ),
      ),
      findsOneWidget,
    );
    expect(cardText(EntityId.FIREPIT, 'Firemaking'), findsNothing);
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

    // the order the tiles sit in: row by row, left to right
    List<EntityId> onScreen() =>
        ids
            .where((id) => find.byKey(ValueKey(id)).evaluate().isNotEmpty)
            .toList()
          ..sort((a, b) {
            final pa = tester.getTopLeft(find.byKey(ValueKey(a)));
            final pb = tester.getTopLeft(find.byKey(ValueKey(b)));
            final byRow = pa.dy.compareTo(pb.dy);
            return byRow != 0 ? byRow : pa.dx.compareTo(pb.dx);
          });

    // clustered by kind — combat first, then the gathering skills in skill
    // order — and in the zone's own table order within a kind, whether or
    // not a card has been found
    int rank(EntityId id) {
      final e = id.build();
      if (e is CombatEntity) return -1;
      return (e as EncounterEntity).entityType.index;
    }

    // fights easiest first, by combat level
    int combatLevel(EntityId id) {
      final e = id.build();
      return e is CombatEntity ? e.level : 0;
    }

    final expected = List.of(ids)
      ..sort((a, b) {
        final byKind = rank(a).compareTo(rank(b));
        if (byKind != 0) return byKind;
        final byLevel = combatLevel(a).compareTo(combatLevel(b));
        if (byLevel != 0) return byLevel;
        return ids.indexOf(a).compareTo(ids.indexOf(b));
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
    // tiles share rows, so a lock belongs to the tile it sits inside
    final locks = tester
        .widgetList(find.byIcon(Icons.lock))
        .map((w) => tester.getCenter(find.byWidget(w)))
        .toList();
    bool hasLock(EntityId id) {
      final rect = tester.getRect(find.byKey(ValueKey(id)));
      return locks.any(rect.contains);
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

  testWidgets('discoveries are the same 3-column grid of tinted tiles', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

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

    // a fight sits in the combat tint, a node in the zone's gathering tint
    expect(
      frameOf(EntityId.CHICKEN).color,
      GameColors.standard.combatTint.fill,
    );
    expect(frameOf(EntityId.TREE).color, ZonePalette.meadow.gatherTintFill);

    // the same tile and columns as the places above them
    final width = (1000 - 2 * 16 - 2 * 10) / 3;
    final zone = session.worldController.viewedZoneDefinition();
    for (final e in zone.discoverableEntities) {
      final rect = tester.getRect(find.byKey(ValueKey(e.id)));
      expect(rect.width, closeTo(width, 0.01), reason: '${e.id}');
      expect(rect.height, 120, reason: '${e.id}');
    }
    // and three to a row: the second tile sits beside the first
    final first = tester.getRect(find.byKey(const ValueKey(EntityId.CHICKEN)));
    final firstRow = zone.discoverableEntities
        .map((e) => tester.getRect(find.byKey(ValueKey(e.id))))
        .where((r) => r.top == first.top)
        .length;
    expect(firstRow, 3);

    session.dispose();
  });

  testWidgets('a long press on a discovery opens its details', (tester) async {
    final session = await pumpExplore(tester);

    await tester.longPress(find.byKey(const ValueKey(EntityId.CHICKEN)));
    await settle(tester);

    expect(find.byType(AlertDialog), findsOneWidget);

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
    // the labels are gone from the tiles; a screen reader still hears them
    expect(find.text('Smithing'), findsNothing);
    expect(find.text('Buy & sell'), findsNothing);
    expect(cardText(EntityId.GRAINERY_ENTRANCE, 'Dungeon'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.ANVIL)),
        matching: find.byWidgetPredicate(
          (w) => w is IconRenderer<SkillId> && w.id == SkillId.BLACKSMITHING,
        ),
      ),
      findsOneWidget,
    );

    // a dungeon reads its combat level the way a fight does
    final dungeonLevel = session.worldController.dungeonLevel(
      EntityId.GRAINERY_ENTRANCE.build() as DungeonEntity,
    );
    expect(dungeonLevel, isNotNull);
    expect(
      showsLevel(
        tester,
        EntityId.GRAINERY_ENTRANCE,
        SkillId.ATTACK,
        dungeonLevel!,
      ),
      isTrue,
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
    // the first tile in the grid, whichever discovery it is
    final firstCard = ZoneId.TUTORIAL_FARM.definition.discoverableEntities
        .map((e) => tester.getRect(find.byKey(ValueKey(e.id))))
        .reduce(
          (a, b) =>
              a.top < b.top || (a.top == b.top && a.left < b.left) ? a : b,
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

  testWidgets('without its tool, a tree or the pond reads as locked', (
    tester,
  ) async {
    final session = await pumpExplore(tester, tools: false);

    Finder within(EntityId id, Finder f) =>
        find.descendant(of: find.byKey(ValueKey(id)), matching: f);

    // the tree says what it wants, under a lock, and dims
    expect(within(EntityId.TREE, find.text('No Axe Equipped')), findsOneWidget);
    expect(within(EntityId.TREE, find.byIcon(Icons.lock_outline)), findsOne);
    expect(within(EntityId.TREE, find.byType(Opacity)), findsWidgets);

    // the pond, its level met, asks for a rod
    expect(
      within(EntityId.TRANQUIL_POND, find.text('No Fishing Rod Equipped')),
      findsOneWidget,
    );

    // a fight asks for nothing
    expect(
      within(EntityId.CHICKEN, find.byIcon(Icons.lock_outline)),
      findsNothing,
    );

    session.dispose();
  });

  testWidgets('a locked discovery still shows how many are standing', (
    tester,
  ) async {
    final session = await pumpExplore(tester, tools: false);
    final tree = session.worldController
        .viewedZoneEntities()
        .whereType<EncounterEntity>()
        .firstWhere((e) => e.id == EntityId.TREE);

    final pill = tester.widget<CountPill>(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.TREE)),
        matching: find.byType(CountPill),
      ),
    );
    expect(pill.count, tree.count);

    session.dispose();
  });

  testWidgets('a find flashes the tile it turned up, then fades', (
    tester,
  ) async {
    final session = await pumpExplore(tester);
    final world = session.worldController;

    double flashAlpha(EntityId id) {
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(ValueKey('find-flash-${id.name}')),
          matching: find.byKey(const ValueKey('find-flash')),
        ),
      );
      return ((box.decoration as BoxDecoration).color ?? Colors.transparent).a;
    }

    expect(flashAlpha(EntityId.TREE), 0);

    world.lastFoundEntityIds = {EntityId.TREE};
    world.lastFoundAt = DateTime.now();
    world.exploreFindSequence++;
    world.refresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // the tile found is lit; its neighbour is not
    expect(flashAlpha(EntityId.TREE), greaterThan(0));
    expect(flashAlpha(EntityId.CHICKEN), 0);

    await tester.pump(const Duration(seconds: 1));
    expect(flashAlpha(EntityId.TREE), 0);

    session.dispose();
  });

  testWidgets('a discovery\'s count sits in a chip, with no separator', (
    tester,
  ) async {
    final session = await pumpExplore(tester);
    final chicken = session.worldController
        .viewedZoneEntities()
        .whereType<CombatEntity>()
        .firstWhere((e) => e.id == EntityId.CHICKEN);

    final pill = tester.widget<CountPill>(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.CHICKEN)),
        matching: find.byType(CountPill),
      ),
    );
    expect(pill.count, chicken.count);
    // a touch larger than the 16pt pills that sit over sprites
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byKey(const ValueKey(EntityId.CHICKEN)),
              matching: find.byType(CountPill),
            ),
          )
          .height,
      18,
    );
    // the line is the icon, the level and the chip: no "·" between them
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.CHICKEN)),
        matching: find.textContaining('·'),
      ),
      findsNothing,
    );

    session.dispose();
  });

  testWidgets('fights run easiest first', (tester) async {
    final session = await pumpExplore(tester);
    final zone = session.worldController.viewedZoneDefinition();
    final fights = [
      for (final e in zone.discoverableEntities)
        if (e.id.build() case final CombatEntity c) c,
    ];
    final byPosition = List.of(fights)
      ..sort((a, b) {
        final pa = tester.getTopLeft(find.byKey(ValueKey(a.id)));
        final pb = tester.getTopLeft(find.byKey(ValueKey(b.id)));
        final byRow = pa.dy.compareTo(pb.dy);
        return byRow != 0 ? byRow : pa.dx.compareTo(pb.dx);
      });
    final levels = [for (final f in byPosition) f.level];
    expect(levels, List.of(levels)..sort());

    session.dispose();
  });

  testWidgets(
    'a discovery\'s level is coloured by how it reads against yours',
    (tester) async {
      final session = await pumpExplore(tester);
      final colors = GameColors.standard;
      Color expected(LevelStanding standing) => switch (standing) {
        LevelStanding.hard => colors.levelHard,
        LevelStanding.even => colors.levelEven,
        LevelStanding.easy => colors.levelEasy,
      };
      Color levelColor(EntityId id, int level) => tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(ValueKey(id)),
              matching: find.text('$level'),
            ),
          )
          .firstWhere((t) => t.style?.fontSize == 12 && t.style?.height == 1.1)
          .style!
          .color!;

      // a fight against the player's combat level
      final chicken = EntityId.CHICKEN.build() as CombatEntity;
      final combat = session.playerDataController.getCombatLevel();
      expect(
        levelColor(EntityId.CHICKEN, chicken.level),
        expected(LevelStanding.of(chicken.level, combat)),
      );

      // a node against the skill that works it
      final tree = EntityId.TREE.build() as EncounterEntity;
      final woodcutting = session.playerDataController.getStatTotal(
        SkillId.WOODCUTTING,
      );
      expect(
        levelColor(EntityId.TREE, tree.defence),
        expected(LevelStanding.of(tree.defence, woodcutting)),
      );

      session.dispose();
    },
  );

  testWidgets('discovery art sits a quarter closer than a place\'s', (
    tester,
  ) async {
    final session = await pumpExplore(tester);
    double zoom(EntityId id) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byKey(ValueKey(id)),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getMaxScaleOnAxis();

    expect(zoom(EntityId.CHICKEN), closeTo(1.25, 1e-9));
    expect(zoom(EntityId.ANVIL), closeTo(1.0, 1e-9));

    session.dispose();
  });

  testWidgets('the tile being worked is marked active, and only while it '
      'runs', (tester) async {
    final session = await pumpExplore(tester);

    Finder barOn(EntityId id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byKey(const ValueKey('place-tile-progress')),
    );
    expect(find.byKey(const ValueKey('place-tile-progress')), findsNothing);

    // start chopping the zone's own tree
    final zone = session
        .saveGameData
        .worldData
        .zones[session.saveGameData.playerData.currentZoneId]!;
    final tree = zone.discoveredEntities.firstWhere(
      (e) => e.id == EntityId.TREE,
    );
    session.saveGameData.playerData.currentEntityViewId = EntityId.TREE;
    session.encounterController.startEncounterActionFor(
      tree as EncounterEntity,
    );
    await settle(tester);

    // a small bar along its foot fills with the action in hand, on that
    // tile alone, with no badge over the sprite
    final progress = barOn(EntityId.TREE);
    expect(progress, findsOneWidget);
    expect(barOn(EntityId.CHICKEN), findsNothing);
    expect(find.byKey(const ValueKey('place-tile-progress')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(EntityId.TREE)),
        matching: find.byIcon(Icons.fast_forward),
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<FillBar>(
            find.descendant(of: progress, matching: find.byType(FillBar)),
          )
          .value,
      closeTo(session.actionTimingController.actionProgress, 1e-9),
    );
    expect(
      tester
          .widget<FillBar>(
            find.descendant(of: progress, matching: find.byType(FillBar)),
          )
          .value,
      greaterThan(0),
    );

    // a paused loop is working nothing
    session.actionTimingController.stop();
    await settle(tester);
    expect(find.byKey(const ValueKey('place-tile-progress')), findsNothing);

    session.dispose();
  });

  testWidgets('an unfound place waits under Places, not Discoveries', (
    tester,
  ) async {
    final session = await pumpExplore(tester, zoneId: ZoneId.SOUTHWOOD_FOREST);

    // the goblin camp is a dungeon: unfound, it is a blurred tile among
    // the places, after the ones already standing
    final camp = find.byKey(
      ValueKey('undiscovered-${EntityId.GOBLIN_CAMP.definition.name}'),
    );
    expect(camp, findsOneWidget);
    final places = tester.getTopLeft(find.text('PLACES')).dy;
    final discoveries = tester.getTopLeft(find.text('DISCOVERIES')).dy;
    final campY = tester.getTopLeft(camp).dy;
    expect(campY, greaterThan(places));
    expect(campY, lessThan(discoveries));
    expect(
      campY,
      greaterThanOrEqualTo(
        tester.getTopLeft(find.byKey(const ValueKey(EntityId.FIREPIT))).dy,
      ),
    );

    // once found it is an ordinary place tile, listed once
    final zone = session.saveGameData.worldData.zones[ZoneId.SOUTHWOOD_FOREST]!;
    zone.discoveredEntities.add(EntityId.GOBLIN_CAMP.build());
    session.worldController.notifyListeners();
    await settle(tester);
    expect(camp, findsNothing);
    final found = find.byKey(const ValueKey(EntityId.GOBLIN_CAMP));
    expect(found, findsOneWidget);
    expect(tester.getTopLeft(found).dy, lessThan(discoveries));

    session.dispose();
  });
}
