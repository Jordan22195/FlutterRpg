import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/explore_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/stat_chip.dart';

/// A zone card says how hard the thing is, not what skill it trains — the
/// icon already carries the skill. A combat entity shows its level beside
/// the attack icon; a gathering node shows the defence its skill is
/// rolled against.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The value of the chip on [id]'s card.
  Finder chipValue(EntityId id, String value) => find.descendant(
    of: find.byKey(ValueKey(id)),
    matching: find.descendant(
      of: find.byType(StatChip),
      matching: find.text(value),
    ),
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
    expect(chicken.level, 2);
    expect(chipValue(EntityId.CHICKEN, '${chicken.level}'), findsOneWidget);
    expect(cardText(EntityId.CHICKEN, 'Combat'), findsNothing);

    session.dispose();
  });

  testWidgets('a gathering card shows the node defence, not the skill name', (
    tester,
  ) async {
    final session = await pumpExplore(tester);

    final tree = EntityId.TREE.definition as EncounterEntityDefinition;
    expect(chipValue(EntityId.TREE, '${tree.defence}'), findsOneWidget);
    expect(cardText(EntityId.TREE, 'Woodcutting'), findsNothing);

    // the pond is a gathering node too, even though it lists as a structure
    final pond = EntityId.TRANQUIL_POND.definition as EncounterEntityDefinition;
    expect(
      chipValue(EntityId.TRANQUIL_POND, '${pond.defence}'),
      findsOneWidget,
    );
    expect(cardText(EntityId.TRANQUIL_POND, 'Fishing'), findsNothing);

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
        matching: find.byType(StatChip),
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
    expect(world.entityLevel(queen), 28);

    final tree = EntityId.TREE.build() as EncounterEntity;
    expect(world.entityLevel(tree), tree.defence);

    session.actionTimingController.stop();
    session.dispose();
  });
}
