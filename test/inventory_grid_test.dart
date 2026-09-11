import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/inventory_screen.dart';
import 'package:rpg/widgets/crafting_info_panel.dart';
import 'package:rpg/widgets/encounter_info_panel.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

/// The inventory grid draws stackables and unique equipment instances as
/// one run of tiles. Equipment used to sit in a hand-rolled wrap beside the
/// grid on every screen that had any, or be folded into the stackables by
/// id, which lost the quality each piece rolled.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  // the app has periodic timers that never settle, so fixed pumps
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget host(GameSession session, Widget child) {
    return MultiProvider(
      providers: [
        Provider<GameSession>.value(value: session),
        ChangeNotifierProvider<InventoryController>.value(
          value: session.inventoryController,
        ),
        ChangeNotifierProvider<BuffController>.value(
          value: session.buffController,
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  EquipmentItem charm(Rarity quality) {
    final piece = ItemId.CHICKEN_CHARM.build() as EquipmentItem;
    piece.quality = quality;
    return piece;
  }

  // grid-built tiles are ItemStackTile<Enum>, so match on the raw type
  Finder tiles() => find.byWidgetPredicate((w) => w is ItemStackTile);
  Finder tileFor(ItemId id, {Rarity? quality}) => find.byWidgetPredicate(
    (w) => w is ItemStackTile && w.id == id && w.quality == quality,
  );

  testWidgets('one tile per stack and per equipment instance', (tester) async {
    final session = buildSession();
    final items = [
      ObjectStack(id: ItemId.LOGS, count: 5),
      ObjectStack(id: ItemId.CHICKEN_MEAT, count: 2),
    ];
    final equipment = [charm(Rarity.COMMON), charm(Rarity.RARE)];

    await tester.pumpWidget(
      host(
        session,
        InventoryGrid(items: items, equipment: equipment, shrinkWrap: true),
      ),
    );
    await settle(tester);

    expect(tiles(), findsNWidgets(4));
    // the stack tiles carry no rolled quality; each piece carries its own
    expect(tileFor(ItemId.LOGS), findsOneWidget);
    expect(
      tileFor(ItemId.CHICKEN_CHARM, quality: Rarity.COMMON),
      findsOneWidget,
    );
    expect(tileFor(ItemId.CHICKEN_CHARM, quality: Rarity.RARE), findsOneWidget);

    // stackables lead, equipment follows
    final order = tester
        .widgetList(tiles())
        .map((w) => (w as ItemStackTile).id)
        .toList();
    expect(order, [
      ItemId.LOGS,
      ItemId.CHICKEN_MEAT,
      ItemId.CHICKEN_CHARM,
      ItemId.CHICKEN_CHARM,
    ]);

    session.dispose();
  });

  testWidgets('tapping opens the dialog for the kind of tile tapped', (
    tester,
  ) async {
    final session = buildSession();
    final piece = charm(Rarity.EPIC);

    await tester.pumpWidget(
      host(
        session,
        InventoryGrid(
          items: [ObjectStack(id: ItemId.LOGS, count: 1)],
          equipment: [piece],
          shrinkWrap: true,
        ),
      ),
    );
    await settle(tester);

    // the equipment dialog names the piece by its rolled quality
    await tester.tap(tileFor(ItemId.CHICKEN_CHARM, quality: Rarity.EPIC));
    await settle(tester);
    expect(find.text(piece.displayName), findsOneWidget);
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.text(piece.displayName), findsNothing);

    // a stack opens the plain item dialog
    await tester.tap(tileFor(ItemId.LOGS));
    await settle(tester);
    expect(find.text(ItemId.LOGS.definition.name), findsOneWidget);
    expect(find.text('Dev: stack count'), findsOneWidget);

    session.dispose();
  });

  testWidgets('tap callbacks replace the dialogs', (tester) async {
    final session = buildSession();
    final piece = charm(Rarity.UNCOMMON);
    ObjectStack? tappedStack;
    EquipmentItem? tappedPiece;

    await tester.pumpWidget(
      host(
        session,
        InventoryGrid(
          items: [ObjectStack(id: ItemId.LOGS, count: 3)],
          equipment: [piece],
          shrinkWrap: true,
          onItemTap: (stack) => tappedStack = stack,
          onEquipmentTap: (item) => tappedPiece = item,
        ),
      ),
    );
    await settle(tester);

    await tester.tap(tileFor(ItemId.LOGS));
    await settle(tester);
    expect(tappedStack?.id, ItemId.LOGS);
    expect(tappedStack?.count, 3);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(tileFor(ItemId.CHICKEN_CHARM, quality: Rarity.UNCOMMON));
    await settle(tester);
    expect(identical(tappedPiece, piece), isTrue);
    expect(find.byType(AlertDialog), findsNothing);

    session.dispose();
  });

  testWidgets('the inventory screen is one grid holding the bag', (
    tester,
  ) async {
    final session = buildSession();
    final save = session.saveGameData;
    save.inventoryData.itemMap[ItemId.LOGS] = 4;
    final piece = charm(Rarity.LEGENDARY);
    session.inventoryService.addEquipment(save.inventoryData, piece);

    await tester.pumpWidget(host(session, const InventoryScreen()));
    await settle(tester);

    expect(find.byType(InventoryGrid), findsOneWidget);
    expect(find.byType(Wrap), findsNothing);
    expect(
      find.descendant(
        of: find.byType(InventoryGrid),
        matching: tileFor(ItemId.CHICKEN_CHARM, quality: Rarity.LEGENDARY),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(InventoryGrid),
        matching: tileFor(ItemId.LOGS),
      ),
      findsOneWidget,
    );

    session.dispose();
  });

  testWidgets('the crafting and encounter panels hand their equipment to '
      'the grid', (tester) async {
    final session = buildSession();
    final items = [ObjectStack(id: ItemId.LOGS, count: 2)];
    final equipment = [charm(Rarity.RARE)];

    await tester.pumpWidget(
      host(
        session,
        ListView(
          children: [
            CraftingInfoPanel(items: items, equipment: equipment, recipeId: ''),
            EncounterInfoPanel(
              drops: items,
              equipment: equipment,
              lootLabel: 'Loot',
              emptyLootLabel: 'No loot this session',
            ),
          ],
        ),
      ),
    );
    await settle(tester);

    expect(find.byType(InventoryGrid), findsNWidgets(2));
    expect(find.byType(Wrap), findsNothing);
    // one tile per entry in each panel, each piece in its quality
    expect(
      tileFor(ItemId.CHICKEN_CHARM, quality: Rarity.RARE),
      findsNWidgets(2),
    );
    expect(tileFor(ItemId.LOGS), findsNWidgets(2));
    // the loot tab counts the piece alongside the stack
    expect(find.text('Loot · 2'), findsOneWidget);
    expect(find.text('Crafted · 2'), findsOneWidget);

    session.dispose();
  });
}
