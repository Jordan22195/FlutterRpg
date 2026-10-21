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
import 'package:rpg/widgets/icon_renderer.dart';

// One-handed and two-handed weapons share one tile on the gear screen: only
// one is ever held, so the tile shows whichever it is and its picker offers
// both kinds.
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

  final weaponTile = find.byKey(
    ValueKey('gear-slot-${ArmorSlots.WEAPON_1H.name}'),
  );

  Finder iconIn(Finder tile, ItemId id) => find.descendant(
    of: tile,
    matching: find.byWidgetPredicate((w) => w is IconRenderer && w.id == id),
  );

  Finder inPicker(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  testWidgets('there is one weapon tile, not one per hand count', (
    tester,
  ) async {
    await pumpGear(tester);
    expect(weaponTile, findsOneWidget);
    expect(
      find.byKey(ValueKey('gear-slot-${ArmorSlots.WEAPON_2H.name}')),
      findsNothing,
    );
  });

  testWidgets('the tile shows a two-handed weapon as well as a one-handed', (
    tester,
  ) async {
    wear(ItemId.PITCHFORK);
    await pumpGear(tester);
    expect(iconIn(weaponTile, ItemId.PITCHFORK), findsOneWidget);
  });

  testWidgets('its picker offers both kinds and swaps between them', (
    tester,
  ) async {
    wear(ItemId.FISHBONE_DAGGER);
    bag(ItemId.PITCHFORK);
    bag(ItemId.GOBLIN_SCEPTER);
    await pumpGear(tester);

    // a worn weapon selects on the first tap and opens the picker from the
    // detail card, as every slot does
    await tester.tap(weaponTile);
    await tester.pump();
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    final pitchfork = ItemId.PITCHFORK.build() as EquipmentItem;
    final scepter = ItemId.GOBLIN_SCEPTER.build() as EquipmentItem;
    expect(inPicker(pitchfork.displayName), findsOneWidget);
    expect(inPicker(scepter.displayName), findsOneWidget);

    // taking the two-hander puts it in the same tile, dagger off
    await tester.tap(inPicker(pitchfork.displayName));
    await tester.pumpAndSettle();
    expect(gear().armorEquipment[ArmorSlots.WEAPON_2H]?.id, ItemId.PITCHFORK);
    expect(gear().armorEquipment[ArmorSlots.WEAPON_1H], isNull);
    expect(iconIn(weaponTile, ItemId.PITCHFORK), findsOneWidget);

    // and taking it off empties the tile, whichever hand slot it was in
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.textContaining(RegExp('unequip', caseSensitive: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(gear().armorEquipment[ArmorSlots.WEAPON_2H], isNull);
    expect(iconIn(weaponTile, ItemId.PITCHFORK), findsNothing);
  });

  testWidgets('a two-hander in the bag lights the dot on the one tile', (
    tester,
  ) async {
    bag(ItemId.PITCHFORK);
    await pumpGear(tester);
    expect(
      find.descendant(
        of: weaponTile,
        matching: find.byKey(const ValueKey('upgrade-dot')),
      ),
      findsOneWidget,
    );
  });
}
