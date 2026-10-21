import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/equipment_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/potion_controller.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/gear_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';

// A gear slot wears a dot when the bag holds something the player can wear
// there whose stats add up to more than what is in it.
void main() {
  late GameSession session;

  setUp(() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    session = factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
  });

  tearDown(() => session.dispose());

  EquipmentData gear() => session.saveGameData.playerData.equipmentData;

  void setLevel(SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  void bag(ItemId id) => session.inventoryService.addEquipment(
    session.saveGameData.inventoryData,
    id.build() as EquipmentItem,
  );

  void wear(ItemId id) =>
      session.equipmentService.equipItem(id.build() as EquipmentItem, gear());

  Future<void> pumpGear(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
          ChangeNotifierProvider<BuffController>.value(
            value: session.buffController,
          ),
          ChangeNotifierProvider<PotionController>.value(
            value: session.potionController,
          ),
          ChangeNotifierProvider<EquipmentController>.value(
            value: session.equipmentController,
          ),
        ],
        child: const MaterialApp(home: GearScreen()),
      ),
    );
    await tester.pump();
  }

  Finder dotOn(String slotKey) => find.descendant(
    of: find.byKey(ValueKey(slotKey)),
    matching: find.byKey(const ValueKey('upgrade-dot')),
  );

  group('the rule', () {
    test('a stat total is everything a piece adds', () {
      final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
      expect(
        session.equipmentService.statTotal(helmet),
        helmet.effectiveSkillBonus.values.fold<int>(0, (a, b) => a + b),
      );
      expect(session.equipmentService.statTotal(null), 0);
    });

    test(
      'more, and wearable, is an upgrade; level-gated or not more is not',
      () {
        final copper = ItemId.COPPER_HELMET.build() as EquipmentItem;
        final mithril = ItemId.MITHRIL_HELMET.build() as EquipmentItem;
        final service = session.equipmentService;
        expect(
          service.statTotal(mithril),
          greaterThan(service.statTotal(copper)),
        );

        // a level-1 player can't wear the mithril yet
        expect(
          session.equipmentController.hasUpgrade(copper, [mithril]),
          isFalse,
        );
        // a trained one can
        setLevel(SkillId.DEFENCE, 99);
        expect(
          session.equipmentController.hasUpgrade(copper, [mithril]),
          isTrue,
        );
        // the same piece again is no upgrade
        expect(
          session.equipmentController.hasUpgrade(copper, [
            ItemId.COPPER_HELMET.build() as EquipmentItem,
          ]),
          isFalse,
        );
        // an empty slot takes anything wearable
        expect(session.equipmentController.hasUpgrade(null, [copper]), isTrue);
      },
    );
  });

  group('the dot', () {
    testWidgets('an empty slot with a wearable piece in the bag', (
      tester,
    ) async {
      bag(ItemId.COPPER_HELMET);
      await pumpGear(tester);
      expect(dotOn('gear-slot-${ArmorSlots.HEAD.name}'), findsOneWidget);
      // nothing in the bag for the chest
      expect(dotOn('gear-slot-${ArmorSlots.CHEST.name}'), findsNothing);
    });

    testWidgets('a better piece in the bag than the one worn', (tester) async {
      setLevel(SkillId.DEFENCE, 99);
      wear(ItemId.COPPER_HELMET);
      bag(ItemId.MITHRIL_HELMET);
      await pumpGear(tester);
      expect(dotOn('gear-slot-${ArmorSlots.HEAD.name}'), findsOneWidget);
    });

    testWidgets('no dot for a piece the player cannot wear yet', (
      tester,
    ) async {
      wear(ItemId.COPPER_HELMET);
      bag(ItemId.MITHRIL_HELMET);
      await pumpGear(tester);
      expect(dotOn('gear-slot-${ArmorSlots.HEAD.name}'), findsNothing);
    });

    testWidgets('no dot once the better piece is on', (tester) async {
      setLevel(SkillId.DEFENCE, 99);
      wear(ItemId.MITHRIL_HELMET);
      bag(ItemId.COPPER_HELMET);
      await pumpGear(tester);
      expect(dotOn('gear-slot-${ArmorSlots.HEAD.name}'), findsNothing);
    });

    testWidgets('tools get one too', (tester) async {
      bag(ItemId.STONE_AXE);
      await pumpGear(tester);
      expect(dotOn('gear-tool-${SkillId.WOODCUTTING.name}'), findsOneWidget);
      expect(dotOn('gear-tool-${SkillId.MINING.name}'), findsNothing);
    });
  });
}
