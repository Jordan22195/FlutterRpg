import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/equipment_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/equipment_info_dialog.dart';
import 'package:rpg/widgets/stat_chip.dart';

// An equipment piece's details are set against the piece wearing it would
// take off: its own slot for armour, the weapon in hand for a weapon, the
// tool for its skill, the weaker ring for a ring.
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
  EquipmentItem piece(ItemId id) => id.build() as EquipmentItem;
  EquipmentItem wear(ItemId id) {
    final item = piece(id);
    session.equipmentService.equipItem(item, gear());
    return item;
  }

  group('what an item is measured against', () {
    test('armour: its own slot', () {
      final worn = wear(ItemId.COPPER_HELMET);
      expect(
        session.equipmentService.counterpartFor(
          piece(ItemId.IRON_HELMET),
          gear(),
        ),
        same(worn),
      );
      expect(
        session.equipmentService.counterpartFor(
          piece(ItemId.COPPER_CHESTPLATE),
          gear(),
        ),
        isNull,
      );
    });

    test('a weapon: whatever is in hand, one hand or two', () {
      final greatsword = wear(ItemId.COPPER_GREATSWORD);
      expect(
        session.equipmentService.counterpartFor(
          piece(ItemId.COPPER_DAGGER),
          gear(),
        ),
        same(greatsword),
      );
    });

    test('a tool: the tool for its skill', () {
      final axe = piece(ItemId.STONE_AXE);
      gear().equipedTools[SkillId.WOODCUTTING] = axe;
      expect(
        session.equipmentService.counterpartFor(piece(ItemId.IRON_AXE), gear()),
        same(axe),
      );
      expect(
        session.equipmentService.counterpartFor(
          piece(ItemId.STONE_PICKAXE),
          gear(),
        ),
        isNull,
      );
    });

    test('a ring: the weaker of two, and nothing while a finger is free', () {
      final service = session.equipmentService;
      final gold = piece(ItemId.TOPAZ_RING);
      final diamond = piece(ItemId.SAPPHIRE_RING);
      gear().armorEquipment[ArmorSlots.FINGER] = gold;
      expect(service.counterpartFor(piece(ItemId.RUBY_RING), gear()), isNull);

      gear().armorEquipment[ArmorSlots.FINGER_2] = diamond;
      final weaker = service.statTotal(gold) <= service.statTotal(diamond)
          ? gold
          : diamond;
      expect(
        service.counterpartFor(piece(ItemId.RUBY_RING), gear()),
        same(weaker),
      );
    });
  });

  group('the popup', () {
    Future<void> open(WidgetTester tester, EquipmentItem item) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<InventoryController>.value(
              value: session.inventoryController,
            ),
            ChangeNotifierProvider<BuffController>.value(
              value: session.buffController,
            ),
            ChangeNotifierProvider<EquipmentController>.value(
              value: session.equipmentController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showEquipmentInfoDialog(context, item),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
    }

    Iterable<StatChip> chips(WidgetTester tester) =>
        tester.widgetList<StatChip>(find.byType(StatChip));

    testWidgets('a better piece shows its gain on each stat', (tester) async {
      wear(ItemId.COPPER_HELMET);
      await open(tester, piece(ItemId.MITHRIL_HELMET));

      expect(
        chips(tester).any(
          (chip) =>
              chip.deltaText != null &&
              chip.deltaText!.startsWith('+') &&
              chip.deltaColor == statGainColor,
        ),
        isTrue,
      );
      // the stats speak for themselves: no line naming what they are set
      // against, and no total
      expect(find.textContaining('Compared with'), findsNothing);
      expect(find.textContaining('Total'), findsNothing);
    });

    testWidgets('a worse piece reads as a loss', (tester) async {
      wear(ItemId.MITHRIL_HELMET);
      await open(tester, piece(ItemId.COPPER_HELMET));

      expect(
        chips(tester).any(
          (chip) =>
              chip.deltaText != null &&
              chip.deltaText!.startsWith('−') &&
              chip.deltaColor == statLossColor,
        ),
        isTrue,
      );
    });

    testWidgets('the piece being worn shows no deltas', (tester) async {
      final worn = wear(ItemId.COPPER_HELMET);
      await open(tester, worn);

      expect(chips(tester).every((chip) => chip.deltaText == null), isTrue);
      expect(find.text('Equipped'), findsNothing);
    });

    testWidgets('over an empty slot there is nothing to compare', (
      tester,
    ) async {
      await open(tester, piece(ItemId.COPPER_HELMET));
      expect(chips(tester).every((chip) => chip.deltaText == null), isTrue);
      expect(find.text('Nothing equipped here'), findsNothing);
    });

    testWidgets('the coin value is the same size as the stats', (tester) async {
      final helmet = piece(ItemId.COPPER_HELMET);
      await open(tester, helmet);

      final value = tester.widget<StatChip>(
        find.byKey(const ValueKey('equipment-value')),
      );
      expect(value.value, '${helmet.value}');
      expect(value.fontSize, 20);
      final stat = chips(tester).firstWhere((c) => !identical(c, value));
      expect(
        tester.getSize(find.byKey(const ValueKey('equipment-value'))).height,
        tester.getSize(find.byWidget(stat)).height,
      );
    });

    testWidgets('the stats run one to a line, at full size', (tester) async {
      wear(ItemId.COPPER_HELMET);
      await open(tester, piece(ItemId.MITHRIL_HELMET));

      final chips = find.byType(StatChip);
      expect(chips, findsWidgets);
      final rects = [
        for (var i = 0; i < chips.evaluate().length; i++)
          tester.getRect(chips.at(i)),
      ];
      for (var i = 1; i < rects.length; i++) {
        // stacked: each below the last, starting at the same left edge
        expect(rects[i].top, greaterThanOrEqualTo(rects[i - 1].bottom));
        expect(rects[i].left, rects[0].left);
      }
      // much bigger than the picker's 12pt chips
      for (final chip in tester.widgetList<StatChip>(chips)) {
        expect(chip.fontSize, 20);
      }
    });
  });
}
