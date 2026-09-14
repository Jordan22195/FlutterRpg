import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/widgets/inventory_grid.dart';

/// The dev tool that forces a piece's rarity. Rarity is part of
/// [EquipmentItem.stackKey], so setting it moves a stack to a different
/// identity rather than editing one in place — the whole stack goes over,
/// and it merges with whatever already sits at the target rarity.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryService = InventoryService();

  EquipmentItem charm(Rarity quality, {int count = 1}) {
    final piece = ItemId.CHICKEN_CHARM.build() as EquipmentItem;
    piece.quality = quality;
    piece.count = count;
    return piece;
  }

  group('inventory service', () {
    test('the whole stack changes rarity, keeping its count', () {
      final inventory = InventoryData(
        itemMap: {},
        equipment: [charm(Rarity.COMMON, count: 4)],
      );

      final moved = inventoryService.setEquipmentQuality(
        inventory,
        inventory.equipment.first,
        Rarity.EPIC,
      );

      expect(moved, isNotNull);
      expect(inventory.equipment.length, 1);
      expect(inventory.equipment.single.quality, Rarity.EPIC);
      expect(inventory.equipment.single.count, 4);
      // stats follow the new tier rather than the old one
      expect(
        moved!.effectiveSkillBonus,
        charm(Rarity.EPIC).effectiveSkillBonus,
      );
    });

    test('it merges into a stack already at that rarity', () {
      final inventory = InventoryData(
        itemMap: {},
        equipment: [
          charm(Rarity.COMMON, count: 4),
          charm(Rarity.RARE, count: 3),
        ],
      );

      final moved = inventoryService.setEquipmentQuality(
        inventory,
        inventory.equipment.first,
        Rarity.RARE,
      );

      expect(inventory.equipment.length, 1);
      expect(inventory.equipment.single.quality, Rarity.RARE);
      expect(inventory.equipment.single.count, 7);
      // the live stack comes back, not the instance that was folded away
      expect(moved, same(inventory.equipment.single));
    });

    test('a piece the inventory does not hold changes nothing', () {
      final inventory = InventoryData(itemMap: {}, equipment: []);

      expect(
        inventoryService.setEquipmentQuality(
          inventory,
          charm(Rarity.COMMON),
          Rarity.EPIC,
        ),
        isNull,
      );
      expect(inventory.equipment, isEmpty);
    });
  });

  group('the info dialog', () {
    late SaveGameData save;

    GameSession buildSession() {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      save = factory.newGame(catalogs);
      return factory.create(
        save: save,
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
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

    // the app has periodic timers that never settle, so fixed pumps
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('picking a rarity re-qualifies the stack and redraws', (
      tester,
    ) async {
      final session = buildSession();
      final inventory = save.inventoryData;
      inventory.equipment
        ..clear()
        ..add(charm(Rarity.COMMON, count: 2));

      await tester.pumpWidget(
        host(
          session,
          InventoryGrid(
            items: const [],
            equipment: inventory.equipment,
            shrinkWrap: true,
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.byType(InkWell).first);
      await settle(tester);

      expect(find.text('Dev: rarity'), findsOneWidget);
      expect(find.text('Chicken Charm'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Epic'));
      await settle(tester);

      // the stack moved wholesale, and the open dialog now describes it
      expect(inventory.equipment.single.quality, Rarity.EPIC);
      expect(inventory.equipment.single.count, 2);
      expect(find.text('Epic Chicken Charm'), findsOneWidget);

      session.dispose();
    });
  });
}
