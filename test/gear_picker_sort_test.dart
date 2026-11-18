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
import 'package:rpg/widgets/equipment_picker.dart';

// Tapping a gear slot opens its picker whether or not something is worn
// there, and the picker sorts its candidates by any stat they carry.
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
    for (final skill in SkillId.values) {
      final data = session.saveGameData.playerData.skillData[skill];
      if (data != null) data.xp = data.xpTable[99];
    }
  });

  tearDown(() => session.dispose());

  EquipmentData gear() => session.saveGameData.playerData.equipmentData;

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

  final headTile = find.byKey(ValueKey('gear-slot-${ArmorSlots.HEAD.name}'));
  final sheet = find.byType(BottomSheet);

  Finder inPicker(String text) =>
      find.descendant(of: sheet, matching: find.text(text));

  /// The candidates' names, top to bottom, as the picker lists them.
  List<String> listed(WidgetTester tester, List<EquipmentItem> candidates) {
    double dy(String name) => tester.getTopLeft(inPicker(name)).dy;
    final names = [for (final c in candidates) c.displayName];
    names.sort((a, b) => dy(a).compareTo(dy(b)));
    return names;
  }

  testWidgets('tapping a filled slot opens its picker', (tester) async {
    wear(ItemId.COPPER_HELMET);
    bag(ItemId.IRON_HELMET);
    await pumpGear(tester);

    await tester.tap(headTile);
    await tester.pumpAndSettle();

    expect(sheet, findsOneWidget);
    final iron = ItemId.IRON_HELMET.build() as EquipmentItem;
    expect(inPicker(iron.displayName), findsOneWidget);
  });

  testWidgets('each card names its slot, one hand or two', (tester) async {
    wear(ItemId.COPPER_SWORD);
    bag(ItemId.COPPER_GREATSWORD);
    await pumpGear(tester);

    await tester.tap(
      find.byKey(ValueKey('gear-slot-${ArmorSlots.WEAPON_1H.name}')),
    );
    await tester.pumpAndSettle();

    final slots = [
      for (final w in tester.widgetList<Text>(
        find.descendant(
          of: sheet,
          matching: find.byKey(const ValueKey('equipment-card-slot')),
        ),
      ))
        w.data,
    ];
    expect(slots, containsAll(['One-handed weapon', 'Two-handed weapon']));
  });

  testWidgets('tapping an empty slot opens its picker', (tester) async {
    bag(ItemId.IRON_HELMET);
    await pumpGear(tester);

    await tester.tap(headTile);
    await tester.pumpAndSettle();

    expect(sheet, findsOneWidget);
  });

  testWidgets('a tool tile opens its picker when a tool is worn', (
    tester,
  ) async {
    await pumpGear(tester);
    final toolTiles = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('gear-tool-'),
    );
    expect(toolTiles, findsWidgets);
    await tester.tap(toolTiles.first);
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
  });

  testWidgets('the sort chips reorder the candidates by that stat', (
    tester,
  ) async {
    // bagged out of tier order, so the bag's own order is not the sorted one
    final ids = [ItemId.STEEL_HELMET, ItemId.COPPER_HELMET, ItemId.IRON_HELMET];
    ids.forEach(bag);
    await pumpGear(tester);
    await tester.tap(headTile);
    await tester.pumpAndSettle();

    final candidates = [for (final id in ids) id.build() as EquipmentItem];
    final keys = EquipmentSortKey.forItems(candidates);
    expect(keys, isNotEmpty);

    for (final key in keys) {
      await tester.tap(find.byKey(ValueKey('equipment-sort-${key.id}')));
      await tester.pumpAndSettle();
      final shown = listed(tester, candidates);
      final values = [
        for (final name in shown)
          key.valueOf(candidates.firstWhere((c) => c.displayName == name)),
      ];
      for (var i = 1; i < values.length; i++) {
        expect(
          values[i - 1] >= values[i],
          isTrue,
          reason: 'sorted by ${key.label}: $shown',
        );
      }
      // tapping the chosen chip again puts the bag's order back
      await tester.tap(find.byKey(ValueKey('equipment-sort-${key.id}')));
      await tester.pumpAndSettle();
    }
  });

  test('sort chips run in the stat lines\' order', () {
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
        for (final k in EquipmentSortKey.forItems([sword])) k.id,
      ],
      [
        'damage',
        'dps',
        'speed',
        'ATTACK',
        'DEFENCE',
        'STRENGTH',
        'SPEED',
        'STAMINA',
        'RECOVERY',
      ],
    );
  });

  test('weapons sort fastest first by speed', () {
    final items = [
      for (final id in [
        ItemId.PITCHFORK,
        ItemId.FISHBONE_DAGGER,
        ItemId.GOBLIN_SCEPTER,
      ])
        id.build() as EquipmentItem,
    ];
    final speed = EquipmentSortKey.forItems(
      items,
    ).firstWhere((k) => k.id == 'speed');
    final sorted = speed.sort(items).cast<WeaponItem>();
    for (var i = 1; i < sorted.length; i++) {
      expect(sorted[i - 1].actionInterval <= sorted[i].actionInterval, isTrue);
    }
  });
}
