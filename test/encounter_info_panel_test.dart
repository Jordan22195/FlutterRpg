import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/encounter_info_panel.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

// The loot tab lays out the whole haul at its own height: the encounter
// screen scrolls, so the grid never scrolls inside its card.
void main() {
  testWidgets('a big haul shows every row, with no scroll of its own', (
    tester,
  ) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final session = factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    // far more than one row's worth of drops
    final drops = [
      for (final id in ItemId.values.where((i) => i != ItemId.NULL).take(20))
        ObjectStack<ItemId>(id: id, count: 3),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BuffController>.value(
            value: session.buffController,
          ),
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EncounterInfoPanel(
                drops: drops,
                lootLabel: 'Loot',
                emptyLootLabel: 'No loot this session',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // every tile is laid out — none waiting below an inner scroll
    expect(
      find.descendant(
        of: find.byType(InventoryGrid),
        matching: find.byWidgetPredicate((w) => w is ItemStackTile),
      ),
      findsNWidgets(drops.length),
    );

    // and the grid itself does not scroll
    final grid = tester.widget<GridView>(
      find.descendant(
        of: find.byType(InventoryGrid),
        matching: find.byType(GridView),
      ),
    );
    expect(grid.shrinkWrap, isTrue);
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    // it is as tall as its rows, well past the old fixed 80
    expect(tester.getSize(find.byType(InventoryGrid)).height, greaterThan(80));

    session.dispose();
  });
}
