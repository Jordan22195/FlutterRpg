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
    final pond = EntityId.TRANQUIL_POND.definition as EncounterEntityDefinition;
    expect(
      cardText(EntityId.TRANQUIL_POND, 'Fishing · Lv ${pond.defence}'),
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
    final discovered = tester.getTopLeft(find.text('DISCOVERED')).dy;
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
}
