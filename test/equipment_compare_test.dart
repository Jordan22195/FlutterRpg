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
import 'package:rpg/widgets/equipment_picker.dart';

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

    Iterable<EquipmentStatLine> rows(WidgetTester tester) => tester
        .widgetList<EquipmentStatRow>(find.byType(EquipmentStatRow))
        .map((row) => row.line);

    testWidgets('a better piece shows its gain on each stat', (tester) async {
      wear(ItemId.COPPER_HELMET);
      await open(tester, piece(ItemId.MITHRIL_HELMET));

      expect(
        rows(tester).any(
          (line) =>
              line.delta != null && line.delta!.startsWith('+') && line.gain,
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
        rows(tester).any(
          (line) =>
              line.delta != null && line.delta!.startsWith('−') && !line.gain,
        ),
        isTrue,
      );
    });

    testWidgets('a stat it takes away shows the loss, not a zero', (
      tester,
    ) async {
      final worn = wear(ItemId.COPPER_HELMET);
      final taken = worn.effectiveSkillBonus.entries.firstWhere(
        (e) => e.value > 0,
      );
      // any piece measured against the worn helmet that lacks one of its
      // stats
      final other = ItemId.values
          .map((id) => id.build())
          .whereType<EquipmentItem>()
          .where(
            (p) =>
                session.equipmentService.counterpartFor(p, gear()) == worn &&
                (p.effectiveSkillBonus[taken.key] ?? 0) == 0,
          )
          .firstOrNull;
      expect(
        other,
        isNotNull,
        reason: "no piece drops a stat the worn one has",
      );
      await open(tester, other!);

      final row = find.byKey(ValueKey('stat-${taken.key.name}'));
      expect(row, findsOneWidget);
      final line = tester.widget<EquipmentStatRow>(row).line;
      expect(line.lost, isTrue);
      // the loss sits where the value would, and no bare 0 is drawn
      expect(
        find.descendant(of: row, matching: find.text('−${taken.value}')),
        findsOneWidget,
      );
      expect(find.descendant(of: row, matching: find.text('0')), findsNothing);
    });

    testWidgets('onyx shows its xp bonus, set against the onyx worn', (
      tester,
    ) async {
      wear(ItemId.ONYX_NECKLACE); // round necklace: +3%
      await open(tester, piece(ItemId.ONYX_RADIANT_NECKLACE)); // +34%

      final xp = tester
          .widget<EquipmentStatRow>(find.byKey(const ValueKey('stat-chip-xp')))
          .line;
      expect(xp.value, '+34% xp');
      expect(xp.delta, '+31%');
      expect(xp.gain, isTrue);
    });

    testWidgets('a stat gem shows no xp line', (tester) async {
      await open(tester, piece(ItemId.RUBY_RADIANT_RING));
      expect(find.byKey(const ValueKey('stat-chip-xp')), findsNothing);
    });

    testWidgets('the piece being worn shows no deltas', (tester) async {
      final worn = wear(ItemId.COPPER_HELMET);
      await open(tester, worn);

      expect(rows(tester).every((line) => line.delta == null), isTrue);
      expect(find.text('Equipped'), findsNothing);
    });

    testWidgets('over an empty slot there is nothing to compare', (
      tester,
    ) async {
      await open(tester, piece(ItemId.COPPER_HELMET));
      expect(rows(tester).every((line) => line.delta == null), isTrue);
      expect(find.text('Nothing equipped here'), findsNothing);
    });

    testWidgets('a weapon lists its swing figures above its stats', (
      tester,
    ) async {
      wear(ItemId.COPPER_GREATSWORD);
      await open(tester, piece(ItemId.COPPER_DAGGER));

      final all = rows(tester).toList();
      final firstStat = all.indexWhere((line) => !line.weapon);
      final lastWeapon = all.lastIndexWhere((line) => line.weapon);
      expect(lastWeapon, greaterThanOrEqualTo(0));
      if (firstStat >= 0) expect(lastWeapon, lessThan(firstStat));
      expect(find.byKey(const ValueKey('stat-chip-dps')), findsOneWidget);
    });

    test('lines run damage, dps, swing, then atk def str spd stam rec', () {
      final sword = WeaponItem(
        id: ItemId.COPPER_GREATSWORD,
        enchantBonus: {
          SkillId.RECOVERY: 1,
          SkillId.STAMINA: 1,
          SkillId.SPEED: 1,
          SkillId.STRENGTH: 1,
          SkillId.DEFENCE: 1,
          SkillId.ATTACK: 1,
        },
      );
      expect(
        [
          for (final line in equipmentStatLines(sword, null))
            (line.key as ValueKey<String>).value,
        ],
        [
          'stat-chip-damage',
          'stat-chip-dps',
          'stat-chip-speed',
          'stat-ATTACK',
          'stat-DEFENCE',
          'stat-STRENGTH',
          'stat-SPEED',
          'stat-STAMINA',
          'stat-RECOVERY',
        ],
      );
    });

    testWidgets('the header names the slot, one hand, two or off-hand', (
      tester,
    ) async {
      for (final (id, label) in [
        (ItemId.COPPER_SWORD, 'One-handed weapon'),
        (ItemId.COPPER_GREATSWORD, 'Two-handed weapon'),
        (ItemId.COPPER_SHIELD, 'Off-hand'),
        (ItemId.COPPER_HELMET, 'Head'),
      ]) {
        await open(tester, piece(id));
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('equipment-slot')))
              .data,
          label,
        );
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the coin value sits under the stats', (tester) async {
      final helmet = piece(ItemId.COPPER_HELMET);
      await open(tester, helmet);

      final value = find.byKey(const ValueKey('equipment-value'));
      expect(
        find.descendant(of: value, matching: find.text('${helmet.value}')),
        findsOneWidget,
      );
      final lastRow = find.byType(EquipmentStatRow).last;
      expect(
        tester.getRect(value).top,
        greaterThanOrEqualTo(tester.getRect(lastRow).bottom),
      );
    });

    testWidgets('the dev tools start folded away', (tester) async {
      await open(tester, piece(ItemId.COPPER_HELMET));
      expect(find.text('Dev: rarity'), findsNothing);
      await tester.tap(find.text('Dev tools'));
      await tester.pumpAndSettle();
      expect(find.text('Dev: rarity'), findsOneWidget);
    });
  });
}
