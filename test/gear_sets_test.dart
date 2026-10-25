import 'dart:convert';

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
import 'package:rpg/data/gear_set.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/gear_screen.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/utilities/image_resolver.dart';

// Saved gear sets: what is worn is saved under a name and changed back into
// in one tap, pieces coming out of the bag and what was worn going back in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameSessionFactory factory;
  late GameCatalogBundle catalogs;
  late GameSession session;

  void setLevel(GameSession s, SkillId skill, int level) {
    final data = s.saveGameData.playerData.skillData[skill];
    if (data != null) data.xp = data.xpTable[level];
  }

  setUp(() {
    factory = GameSessionFactory();
    catalogs = factory.catalog1();
    session = factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    for (final skill in SkillId.values) {
      setLevel(session, skill, 99);
    }
  });

  tearDown(() => session.dispose());

  EquipmentController controller() => session.equipmentController;
  EquipmentData gear() => session.saveGameData.playerData.equipmentData;
  List<EquipmentItem> bagList() => session.saveGameData.inventoryData.equipment;

  /// Puts a fresh [id] in the bag and returns it.
  EquipmentItem bag(ItemId id) {
    final item = id.build() as EquipmentItem;
    session.inventoryService.addEquipment(
      session.saveGameData.inventoryData,
      item,
    );
    return item;
  }

  /// Puts [id] in the bag and wears it through the real equip path.
  EquipmentItem wear(ItemId id, {ArmorSlots? toSlot}) {
    final item = bag(id);
    expect(controller().equipItem(item, toSlot: toSlot), isTrue);
    return item;
  }

  EquipmentItem wearTool(SkillId skill, ItemId id) {
    final item = bag(id);
    expect(controller().equipToolForSkill(skill, item), isTrue);
    return item;
  }

  ItemId? wornIn(ArmorSlots slot) => gear().armorEquipment[slot]?.id;

  int bagCount(ItemId id) =>
      bagList().where((e) => e.id == id).fold(0, (sum, e) => sum + e.count);

  group('saving', () {
    test('captures every worn armour slot and leaves tools out by default', () {
      wear(ItemId.COPPER_HELMET);
      wear(ItemId.FISHBONE_DAGGER);
      wearTool(SkillId.WOODCUTTING, ItemId.STONE_AXE);

      final set = controller().saveGearSet(includeTools: false)!;

      expect(set.name, 'Set 1');
      expect(
        set.armor.keys,
        unorderedEquals([ArmorSlots.HEAD, ArmorSlots.WEAPON_1H]),
      );
      expect(set.includesTools, isFalse);
      expect(set.tools, isEmpty);
      expect(controller().gearSets, hasLength(1));
    });

    test('takes the tools along when asked', () {
      wearTool(SkillId.WOODCUTTING, ItemId.STONE_AXE);
      final set = controller().saveGearSet(includeTools: true)!;
      expect(set.includesTools, isTrue);
      expect(set.tools.keys, [SkillId.WOODCUTTING]);
    });

    test('names default to the lowest free number and are trimmed', () {
      controller().saveGearSet(includeTools: false);
      controller().saveGearSet(name: '   ', includeTools: false);
      controller().saveGearSet(name: '  Combat  ', includeTools: false);
      controller().saveGearSet(name: 'x' * 40, includeTools: false);
      expect(controller().gearSets.map((s) => s.name), [
        'Set 1',
        'Set 2',
        'Combat',
        'x' * GearSet.maxNameLength,
      ]);
    });

    test('the list holds a fixed number of sets', () {
      for (var i = 0; i < EquipmentService.maxGearSets; i++) {
        expect(controller().saveGearSet(includeTools: false), isNotNull);
      }
      expect(controller().canSaveGearSet, isFalse);
      expect(controller().saveGearSet(includeTools: false), isNull);
      expect(controller().gearSets, hasLength(EquipmentService.maxGearSets));
    });

    test('rename keeps the old name on an empty one; delete removes it', () {
      controller().saveGearSet(name: 'Old', includeTools: false);
      controller().saveGearSet(name: 'Other', includeTools: false);
      controller().renameGearSet(0, '');
      expect(controller().gearSets[0].name, 'Old');
      controller().renameGearSet(0, 'Fishing');
      expect(controller().gearSets[0].name, 'Fishing');
      controller().deleteGearSet(0);
      expect(controller().gearSets.map((s) => s.name), ['Other']);
    });

    test('overwriting a set keeps its name and takes what is worn now', () {
      wear(ItemId.COPPER_HELMET);
      controller().saveGearSet(name: 'Main', includeTools: false);
      wear(ItemId.WOOL_CLOAK);
      controller().overwriteGearSet(0, includeTools: false);
      final set = controller().gearSets.single;
      expect(set.name, 'Main');
      expect(set.armor.keys, containsAll([ArmorSlots.HEAD, ArmorSlots.BACK]));
    });
  });

  group('swapping', () {
    /// Saves set A (copper helmet, dagger, topaz ring), then changes into
    /// and saves set B (mithril helmet, pitchfork, wool cloak, no ring).
    void twoSets() {
      wear(ItemId.COPPER_HELMET);
      wear(ItemId.FISHBONE_DAGGER);
      wear(ItemId.TOPAZ_RING);
      controller().saveGearSet(name: 'A', includeTools: false);

      wear(ItemId.MITHRIL_HELMET);
      wear(ItemId.PITCHFORK);
      wear(ItemId.WOOL_CLOAK);
      controller().unequipSlot(ArmorSlots.FINGER);
      controller().saveGearSet(name: 'B', includeTools: false);
    }

    test('puts the set on and the current gear back in the bag', () {
      twoSets();
      expect(controller().isWearingGearSet(1), isTrue);

      final skipped = controller().swapToGearSet(0);

      expect(skipped, isEmpty);
      expect(wornIn(ArmorSlots.HEAD), ItemId.COPPER_HELMET);
      expect(wornIn(ArmorSlots.WEAPON_1H), ItemId.FISHBONE_DAGGER);
      expect(wornIn(ArmorSlots.WEAPON_2H), isNull);
      expect(wornIn(ArmorSlots.FINGER), ItemId.TOPAZ_RING);
      // A had nothing on its back, so the cloak comes off
      expect(wornIn(ArmorSlots.BACK), isNull);
      for (final id in [
        ItemId.MITHRIL_HELMET,
        ItemId.PITCHFORK,
        ItemId.WOOL_CLOAK,
      ]) {
        expect(bagCount(id), 1, reason: '${id.name} should be in the bag');
      }
      for (final id in [
        ItemId.COPPER_HELMET,
        ItemId.FISHBONE_DAGGER,
        ItemId.TOPAZ_RING,
      ]) {
        expect(bagCount(id), 0, reason: '${id.name} should be worn');
      }
      expect(controller().isWearingGearSet(0), isTrue);
      expect(controller().isWearingGearSet(1), isFalse);

      // and back again
      expect(controller().swapToGearSet(1), isEmpty);
      expect(wornIn(ArmorSlots.HEAD), ItemId.MITHRIL_HELMET);
      expect(wornIn(ArmorSlots.WEAPON_2H), ItemId.PITCHFORK);
      expect(wornIn(ArmorSlots.BACK), ItemId.WOOL_CLOAK);
      expect(wornIn(ArmorSlots.FINGER), isNull);
      expect(bagCount(ItemId.TOPAZ_RING), 1);
    });

    test('a piece that is gone is left out, said, and its slot kept', () {
      twoSets();
      // the copper helmet is sold while B is worn
      bagList().removeWhere((e) => e.id == ItemId.COPPER_HELMET);

      final skipped = controller().swapToGearSet(0);

      expect(skipped, hasLength(1));
      expect(skipped.single.reason, GearSetSkipReason.missing);
      expect(skipped.single.piece.label, contains('Copper Helmet'));
      // the rest of the set still went on, and the head kept what it had
      expect(wornIn(ArmorSlots.HEAD), ItemId.MITHRIL_HELMET);
      expect(wornIn(ArmorSlots.WEAPON_1H), ItemId.FISHBONE_DAGGER);
      expect(wornIn(ArmorSlots.FINGER), ItemId.TOPAZ_RING);
    });

    test('a missing weapon leaves the weapon in hand, whichever kind', () {
      twoSets();
      bagList().removeWhere((e) => e.id == ItemId.FISHBONE_DAGGER);

      final skipped = controller().swapToGearSet(0);

      expect(skipped.single.reason, GearSetSkipReason.missing);
      // A's two-hand slot is empty only because A holds a dagger
      expect(wornIn(ArmorSlots.WEAPON_2H), ItemId.PITCHFORK);
      expect(wornIn(ArmorSlots.HEAD), ItemId.COPPER_HELMET);
    });

    test('a piece the player no longer has the level for is left out', () {
      twoSets();
      controller().swapToGearSet(0);
      setLevel(session, SkillId.DEFENCE, 10);

      final skipped = controller().swapToGearSet(1);

      expect(skipped, hasLength(1));
      expect(skipped.single.reason, GearSetSkipReason.locked);
      expect(skipped.single.requirement, (skill: SkillId.DEFENCE, level: 60));
      expect(wornIn(ArmorSlots.HEAD), ItemId.COPPER_HELMET);
      expect(wornIn(ArmorSlots.WEAPON_2H), ItemId.PITCHFORK);
      expect(bagCount(ItemId.MITHRIL_HELMET), 1);
    });

    test('finds a piece that folded into an identical stack in the bag', () {
      // a spare identical helmet in the bag: taking the worn one off folds
      // it into the spare's stack, and its own instance id is gone
      bag(ItemId.COPPER_HELMET);
      bag(ItemId.COPPER_HELMET);
      expect(bagList().single.count, 2);
      expect(controller().equipItem(bagList().single), isTrue);
      final worn = gear().armorEquipment[ArmorSlots.HEAD]!;
      controller().saveGearSet(includeTools: false);
      controller().unequipSlot(ArmorSlots.HEAD);
      expect(bagList().single.count, 2);
      expect(bagList().any((e) => e.instanceId == worn.instanceId), isFalse);

      expect(controller().swapToGearSet(0), isEmpty);
      expect(wornIn(ArmorSlots.HEAD), ItemId.COPPER_HELMET);
      expect(bagCount(ItemId.COPPER_HELMET), 1);
    });

    test('a ring on the wrong finger moves to the right one', () {
      wear(ItemId.TOPAZ_RING, toSlot: ArmorSlots.FINGER);
      wear(ItemId.RUBY_RING, toSlot: ArmorSlots.FINGER_2);
      controller().saveGearSet(includeTools: false);
      // swap fingers by hand
      controller().unequipSlot(ArmorSlots.FINGER);
      controller().unequipSlot(ArmorSlots.FINGER_2);
      controller().equipItem(
        bagList().firstWhere((e) => e.id == ItemId.RUBY_RING),
        toSlot: ArmorSlots.FINGER,
      );
      controller().equipItem(
        bagList().firstWhere((e) => e.id == ItemId.TOPAZ_RING),
        toSlot: ArmorSlots.FINGER_2,
      );

      expect(controller().swapToGearSet(0), isEmpty);
      expect(wornIn(ArmorSlots.FINGER), ItemId.TOPAZ_RING);
      expect(wornIn(ArmorSlots.FINGER_2), ItemId.RUBY_RING);
      expect(bagCount(ItemId.TOPAZ_RING) + bagCount(ItemId.RUBY_RING), 0);
    });

    test('tools only move when the set includes them', () {
      wearTool(SkillId.WOODCUTTING, ItemId.STONE_AXE);
      controller().saveGearSet(name: 'no tools', includeTools: false);
      controller().saveGearSet(name: 'tools', includeTools: true);
      wearTool(SkillId.WOODCUTTING, ItemId.STEEL_AXE);

      controller().swapToGearSet(0);
      expect(gear().equipedTools[SkillId.WOODCUTTING]?.id, ItemId.STEEL_AXE);

      expect(controller().swapToGearSet(1), isEmpty);
      expect(gear().equipedTools[SkillId.WOODCUTTING]?.id, ItemId.STONE_AXE);
      expect(bagCount(ItemId.STEEL_AXE), 1);
    });
  });

  group('the save file', () {
    GameSession reload(
      GameSession from, {
      Map<String, dynamic> Function(Map<String, dynamic>)? tamper,
    }) {
      var decoded =
          jsonDecode(jsonEncode(from.saveGameData.toJson()))
              as Map<String, dynamic>;
      if (tamper != null) decoded = tamper(decoded);
      return GameSessionFactory().create(
        save: SaveGameData.fromJson(decoded),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
    }

    test('sets survive a reload and still swap afterwards', () {
      wear(ItemId.COPPER_HELMET);
      wearTool(SkillId.WOODCUTTING, ItemId.STONE_AXE);
      controller().saveGearSet(name: 'Woodcutter', includeTools: true);
      wear(ItemId.MITHRIL_HELMET);
      wearTool(SkillId.WOODCUTTING, ItemId.STEEL_AXE);
      controller().saveGearSet(name: 'Plain', includeTools: false);

      final restored = reload(session);
      addTearDown(restored.dispose);
      for (final skill in SkillId.values) {
        setLevel(restored, skill, 99);
      }

      final sets = restored.equipmentController.gearSets;
      expect(sets.map((s) => s.name), ['Woodcutter', 'Plain']);
      expect(sets[0].includesTools, isTrue);
      expect(sets[0].tools.keys, [SkillId.WOODCUTTING]);
      expect(sets[1].includesTools, isFalse);
      expect(
        sets[0].armor[ArmorSlots.HEAD]!.instanceId,
        controller().gearSets[0].armor[ArmorSlots.HEAD]!.instanceId,
      );

      expect(restored.equipmentController.swapToGearSet(0), isEmpty);
      final restoredGear = restored.saveGameData.playerData.equipmentData;
      expect(
        restoredGear.armorEquipment[ArmorSlots.HEAD]?.id,
        ItemId.COPPER_HELMET,
      );
      expect(
        restoredGear.equipedTools[SkillId.WOODCUTTING]?.id,
        ItemId.STONE_AXE,
      );
    });

    test('a save written before gear sets loads with none', () {
      wear(ItemId.COPPER_HELMET);
      final restored = reload(
        session,
        tamper: (json) {
          final equipment =
              (json['playerData'] as Map<String, dynamic>)['equipmentData']
                  as Map<String, dynamic>;
          expect(equipment.remove('gearSets'), isNotNull);
          return json;
        },
      );
      addTearDown(restored.dispose);
      expect(restored.equipmentController.gearSets, isEmpty);
      expect(
        restored
            .saveGameData
            .playerData
            .equipmentData
            .armorEquipment[ArmorSlots.HEAD]
            ?.id,
        ItemId.COPPER_HELMET,
      );
    });

    test('a broken set entry is dropped without failing the load', () {
      final data = EquipmentData.fromJson({
        'gearSets': [
          'not a set',
          {
            'name': 'Kept',
            'armor': {
              'HEAD': {'instanceId': 'a', 'stackKey': 'b', 'label': 'Hat'},
              'NO_SUCH_SLOT': {'instanceId': 'a', 'stackKey': 'b'},
              'CHEST': 'garbage',
            },
          },
        ],
      });
      expect(data.gearSets, hasLength(1));
      expect(data.gearSets.single.name, 'Kept');
      expect(data.gearSets.single.armor.keys, [ArmorSlots.HEAD]);
    });
  });

  group('the gear screen', () {
    setUp(() {
      registerCatalogIconResolvers();
      EnumImageProviderLookup.register<SkillId>(
        SkillController.imageProviderFor,
      );
    });

    Future<void> pumpGear(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3000);
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

    Future<void> openMenu(WidgetTester tester, int index, String item) async {
      await tester.tap(find.byKey(ValueKey('gear-set-menu-$index')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
    }

    testWidgets('saving through the dialog adds a row', (tester) async {
      wear(ItemId.COPPER_HELMET);
      wearTool(SkillId.WOODCUTTING, ItemId.STONE_AXE);
      await pumpGear(tester);

      await tester.tap(find.byKey(const ValueKey('gear-set-save')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('gear-set-name-field')),
        'Lumberjack',
      );
      await tester.tap(find.byKey(const ValueKey('gear-set-include-tools')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('gear-set-dialog-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('gear-set-row-0')), findsOneWidget);
      expect(find.text('Lumberjack'), findsOneWidget);
      expect(find.text('2 pieces · with tools'), findsOneWidget);
      final set = controller().gearSets.single;
      expect(set.includesTools, isTrue);
      // the set being worn is marked rather than offered
      expect(find.text('Worn'), findsOneWidget);
    });

    testWidgets('Wear swaps in one tap and says what it left out', (
      tester,
    ) async {
      wear(ItemId.COPPER_HELMET);
      wear(ItemId.FISHBONE_DAGGER);
      controller().saveGearSet(name: 'A', includeTools: false);
      wear(ItemId.MITHRIL_HELMET);
      wear(ItemId.PITCHFORK);
      bagList().removeWhere((e) => e.id == ItemId.FISHBONE_DAGGER);
      await pumpGear(tester);

      await tester.tap(find.byKey(const ValueKey('gear-set-wear-0')));
      await tester.pump();

      expect(wornIn(ArmorSlots.HEAD), ItemId.COPPER_HELMET);
      expect(wornIn(ArmorSlots.WEAPON_2H), ItemId.PITCHFORK);
      expect(
        find.textContaining('Wearing A — left out Fishbone Dagger'),
        findsOneWidget,
      );
      expect(find.textContaining('no longer owned'), findsOneWidget);
    });

    testWidgets('rename and delete from the row menu', (tester) async {
      controller().saveGearSet(name: 'First', includeTools: false);
      controller().saveGearSet(name: 'Second', includeTools: false);
      await pumpGear(tester);

      await openMenu(tester, 0, 'Rename');
      await tester.enterText(
        find.byKey(const ValueKey('gear-set-name-field')),
        'Renamed',
      );
      await tester.tap(find.byKey(const ValueKey('gear-set-dialog-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Renamed'), findsOneWidget);
      expect(controller().gearSets[0].name, 'Renamed');

      await openMenu(tester, 0, 'Delete');
      await tester.tap(find.byKey(const ValueKey('gear-set-delete-confirm')));
      await tester.pumpAndSettle();
      expect(controller().gearSets.map((s) => s.name), ['Second']);
      expect(find.text('Renamed'), findsNothing);
      expect(find.byKey(const ValueKey('gear-set-row-1')), findsNothing);
    });
  });
}
