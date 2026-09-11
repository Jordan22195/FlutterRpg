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

/// The gear screen's stats readout: where each stat comes from, rather than
/// one lump of gear bonuses. The total column is the number the game plays
/// by, so these assert the split against it rather than against arithmetic
/// the test does itself.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  Future<void> pumpGear(WidgetTester tester, GameSession session) async {
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GameSession>.value(value: session),
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
    await settle(tester);
  }

  Finder rowFor(SkillId skill) =>
      find.byKey(ValueKey('gear-stat-row-${skill.name}'));

  /// The numbers in one stat's row, left to right.
  List<String> cells(WidgetTester tester, SkillId skill) => tester
      .widgetList<Text>(
        find.descendant(of: rowFor(skill), matching: find.byType(Text)),
      )
      .map((t) => t.data ?? '')
      .toList();

  testWidgets('the stat icon rides with the total it labels', (tester) async {
    final session = buildSession();
    session.equipmentService.equipItem(
      ItemId.COPPER_HELMET.build() as EquipmentItem,
      session.saveGameData.playerData.equipmentData,
    );
    await pumpGear(tester, session);

    // one icon in the row, and it sits to the left of the total rather than
    // at the head of the row
    final icon = find.descendant(
      of: rowFor(SkillId.DEFENCE),
      matching: find.byType(IconRenderer<SkillId>),
    );
    expect(icon, findsOneWidget);

    final total = session.equipmentController
        .getStatBreakdown()
        .total[SkillId.DEFENCE];
    final totalText = find.descendant(
      of: rowFor(SkillId.DEFENCE),
      matching: find.text('$total'),
    );
    expect(tester.getCenter(icon).dx, lessThan(tester.getCenter(totalText).dx));
    // and it is past the buff column, not before the skill one
    expect(
      tester.getCenter(icon).dx,
      greaterThan(
        tester
            .getCenter(
              find.descendant(
                of: rowFor(SkillId.DEFENCE),
                matching: find.text('—'),
              ),
            )
            .dx,
      ),
    );

    session.dispose();
  });

  testWidgets('a worn piece splits into skill, gear and total', (tester) async {
    final session = buildSession();
    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    session.equipmentService.equipItem(
      helmet,
      session.saveGameData.playerData.equipmentData,
    );
    await pumpGear(tester, session);

    final defence = session.equipmentController.getStatBreakdown();
    expect(defence.gear[SkillId.DEFENCE], greaterThan(0));

    // skill level, gear bonus, no buff, then the total the game uses
    expect(cells(tester, SkillId.DEFENCE), [
      '${defence.skills[SkillId.DEFENCE]}',
      '+${defence.gear[SkillId.DEFENCE]}',
      '—',
      '${defence.total[SkillId.DEFENCE]}',
    ]);
    // and the total is the sum of what is shown, not a separate number
    expect(
      defence.total[SkillId.DEFENCE],
      defence.skills[SkillId.DEFENCE]! + defence.gear[SkillId.DEFENCE]!,
    );
    // no stance is lending anything, so that column stays out of the way
    expect(find.text('STANCE'), findsNothing);

    session.dispose();
  });

  testWidgets('a potion fills the buff column and lifts the total', (
    tester,
  ) async {
    final session = buildSession();
    session.saveGameData.inventoryData.itemMap[ItemId.MINOR_DEFENCE_POTION] = 1;
    await pumpGear(tester, session);

    // nothing worn and nothing drunk: the readout says so
    expect(find.textContaining('Nothing equipped'), findsOneWidget);

    session.inventoryController.drinkPotion(ItemId.MINOR_DEFENCE_POTION);
    await settle(tester);

    final stats = session.equipmentController.getStatBreakdown();
    final buff = stats.buffs[SkillId.DEFENCE]!;
    expect(buff, greaterThan(0));
    expect(cells(tester, SkillId.DEFENCE), [
      '${stats.skills[SkillId.DEFENCE]}',
      '—',
      '+$buff',
      '${stats.total[SkillId.DEFENCE]}',
    ]);

    session.dispose();
  });

  testWidgets('a stat nothing touches keeps out of the table', (tester) async {
    final session = buildSession();
    final pickaxe = ItemId.COPPER_PICKAXE.build() as EquipmentItem;
    session.equipmentService.equipTool(
      SkillId.MINING,
      pickaxe,
      session.saveGameData.playerData.equipmentData,
    );
    await pumpGear(tester, session);

    // the pickaxe is a mining tool, so mining is the row that appears
    expect(rowFor(SkillId.MINING), findsOneWidget);
    expect(rowFor(SkillId.DEFENCE), findsNothing);
    expect(rowFor(SkillId.WOODCUTTING), findsNothing);

    session.dispose();
  });

  testWidgets('a stance earns its own column while it is lending points', (
    tester,
  ) async {
    final session = buildSession();
    final player = session.saveGameData.playerData;
    // an offensive stance with a full boost bar lends attack off strength
    player.skillBoost = SkillId.ATTACK;
    session.playerDataService.setBoostFill(1.0, player);
    session.equipmentService.equipItem(
      ItemId.COPPER_HELMET.build() as EquipmentItem,
      player.equipmentData,
    );
    await pumpGear(tester, session);

    final stats = session.equipmentController.getStatBreakdown();
    expect(stats.stance[SkillId.ATTACK], greaterThan(0));
    expect(find.text('STANCE'), findsOneWidget);
    expect(cells(tester, SkillId.ATTACK), [
      '${stats.skills[SkillId.ATTACK]}',
      '—',
      '—',
      '+${stats.stance[SkillId.ATTACK]}',
      '${stats.total[SkillId.ATTACK]}',
    ]);

    session.dispose();
  });

  testWidgets('the table fits a phone, stance column and all', (tester) async {
    final session = buildSession();
    final player = session.saveGameData.playerData;
    player.skillBoost = SkillId.ATTACK;
    session.playerDataService.setBoostFill(1.0, player);
    for (final id in [
      ItemId.MITHRIL_HELMET,
      ItemId.MITHRIL_CHESTPLATE,
      ItemId.MITHRIL_SWORD,
    ]) {
      session.equipmentService.equipItem(
        id.build() as EquipmentItem,
        player.equipmentData,
      );
    }
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GameSession>.value(value: session),
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
    await settle(tester);

    // five columns on the narrowest phone the game ships on: an overflow
    // throws in a test, so this is the assertion
    expect(find.text('STANCE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    session.dispose();
  });

  testWidgets('the breakdown adds up to the stats the game plays by', (
    tester,
  ) async {
    // the readout and the game read the same computation: this is the
    // assertion that splitting it did not change the total
    final session = buildSession();
    final equipment = session.saveGameData.playerData.equipmentData;
    session.equipmentService.equipItem(
      ItemId.COPPER_HELMET.build() as EquipmentItem,
      equipment,
    );
    session.equipmentService.equipItem(
      ItemId.LIGHT_LEATHER_GLOVES.build() as EquipmentItem,
      equipment,
    );
    session.saveGameData.inventoryData.itemMap[ItemId.MINOR_ATTACK_POTION] = 1;
    await pumpGear(tester, session);
    session.inventoryController.drinkPotion(ItemId.MINOR_ATTACK_POTION);
    await settle(tester);

    final stats = session.equipmentController.getStatBreakdown();
    final played = session.playerDataService.getStatTotals(
      session.saveGameData.playerData,
    );

    expect(stats.total, played);
    for (final stat in stats.total.keys) {
      expect(
        stats.total[stat],
        (stats.skills[stat] ?? 0) +
            (stats.gear[stat] ?? 0) +
            (stats.buffs[stat] ?? 0) +
            (stats.stance[stat] ?? 0),
        reason: '${stat.name} does not add up',
      );
    }
    expect(equipment.armorEquipment[ArmorSlots.HANDS], isNotNull);

    session.dispose();
  });
}
