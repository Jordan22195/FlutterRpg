import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/screens/firepit_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/boss_arena.dart';
import 'package:rpg/widgets/stage_buff_icons.dart';
import 'package:rpg/widgets/stage_panel.dart';

import 'combat_screen_test.dart' show openChickenFight, settle;

// The buffs on the player, as the stage's corner icons and the sheet behind
// them show them: what each lends, and which fire a stronger one outranks.
void main() {
  const zone = ZoneId.TUTORIAL_FARM;

  FireItem fire(ItemId id, DateTime at) =>
      (id.build() as FireItem)..lightAt(at);

  BuffItem potion(ItemId id) => id.build() as BuffItem;

  group('BuffService.activeBuffs', () {
    test('of two fires on one stat only the stronger counts, and the '
        'outranked one goes last', () {
      final service = BuffService();
      final data = BuffData();
      final now = DateTime.now();
      service.setZoneBuff(
        fire(ItemId.BONFIRE_SPEED, now),
        data,
        zone,
        EntityId.FIREPIT,
      );
      service.setZoneBuff(
        fire(ItemId.OAK_BONFIRE_SPEED, now),
        data,
        zone,
        EntityId.FIREPIT_2,
      );
      service.addBuff(potion(ItemId.MINOR_STAMINA_POTION), data);

      final buffs = service.activeBuffs(data, zone, at: now);

      expect(buffs.map((b) => b.id), [
        ItemId.MINOR_STAMINA_POTION,
        ItemId.OAK_BONFIRE_SPEED,
        ItemId.BONFIRE_SPEED,
      ]);
      expect(buffs[0].zoneBuff, isFalse);
      expect(buffs[1].zoneBuff, isTrue);
      expect(buffs[1].outranked, isFalse);
      expect(buffs[2].outranked, isTrue);

      // and the counted effects add up to what the stat totals use
      final counted = <SkillId, int>{};
      for (final buff in buffs) {
        for (final e in buff.effects.where((e) => e.counted)) {
          counted[e.stat] = (counted[e.stat] ?? 0) + e.amount;
        }
      }
      expect(counted, service.getBuffedStatTotal(data, zone, at: now));
    });

    test('a buff past its end is left out before the sweep removes it', () {
      final service = BuffService();
      final data = BuffData();
      final now = DateTime.now();
      service.addBuff(
        potion(ItemId.MINOR_SPEED_POTION)
          ..expirationTime = now.subtract(const Duration(seconds: 1)),
        data,
      );
      expect(service.activeBuffs(data, zone, at: now), isEmpty);
    });

    test("another zone's fires are not on the player", () {
      final service = BuffService();
      final data = BuffData();
      final now = DateTime.now();
      service.setZoneBuff(
        fire(ItemId.BONFIRE_SPEED, now),
        data,
        ZoneId.values.firstWhere((z) => z != zone && z != ZoneId.NULL),
        EntityId.FIREPIT,
      );
      expect(service.activeBuffs(data, zone, at: now), isEmpty);
    });
  });

  group('StageBuffIcons', () {
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
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<BuffController>.value(
          value: session.buffController,
          child: const MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: StageBuffIcons(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    void drink(ItemId id) => session.buffService.addBuff(
      potion(id),
      session.saveGameData.playerData.buffData,
    );

    testWidgets('draws nothing with no buffs up', (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('stage-buff-icons')), findsNothing);
    });

    testWidgets('one icon per buff, with its time left, and a tap target '
        'of at least 44pt', (tester) async {
      drink(ItemId.MINOR_SPEED_POTION);
      drink(ItemId.MINOR_STAMINA_POTION);
      await pump(tester);

      expect(
        find.byKey(const ValueKey('stage-buff-MINOR_SPEED_POTION')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('stage-buff-MINOR_STAMINA_POTION')),
        findsOneWidget,
      );
      // a three-minute potion, just drunk
      expect(find.text('2m'), findsNWidgets(2));

      final target = tester.getSize(
        find.byKey(const ValueKey('stage-buff-icons')),
      );
      expect(target.width, greaterThanOrEqualTo(44));
      expect(target.height, greaterThanOrEqualTo(44));
    });

    testWidgets('past five, the last slot folds the rest into +N', (
      tester,
    ) async {
      for (final id in [
        ItemId.MINOR_SPEED_POTION,
        ItemId.MINOR_FISHING_POTION,
        ItemId.MINOR_DEFENCE_POTION,
        ItemId.MINOR_STAMINA_POTION,
        ItemId.MINOR_RECOVERY_POTION,
        ItemId.ATTACK_POTION,
      ]) {
        drink(id);
      }
      await pump(tester);

      expect(find.byType(StageBuffIcon), findsNWidgets(4));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('a tap opens every buff in the sheet', (tester) async {
      drink(ItemId.MINOR_SPEED_POTION);
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('stage-buff-icons')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Active buffs · 1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buff-row-MINOR_SPEED_POTION')),
        findsOneWidget,
      );
      expect(find.text('+5 Speed'), findsWidgets);
    });

    testWidgets("the boss arena carries them under the boss's name, "
        'filling from the left', (tester) async {
      drink(ItemId.MINOR_SPEED_POTION);
      drink(ItemId.MINOR_STAMINA_POTION);
      final boss = EntityId.CAVE_BEAR.build() as CombatEntity;
      await tester.pumpWidget(
        ChangeNotifierProvider<BuffController>.value(
          value: session.buffController,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => BossArena(
                  boss: boss,
                  floorNumber: 1,
                  buffs: StageBuffIcons.ifAny(context, fromLeft: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final arena = tester.getRect(find.byType(BossArena));
      final name = tester.getRect(find.text(boss.name));
      final first = tester.getRect(
        find.byKey(const ValueKey('stage-buff-MINOR_SPEED_POTION')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('stage-buff-MINOR_STAMINA_POTION')),
      );
      expect(first.left - arena.left, lessThan(20));
      expect(first.top, greaterThanOrEqualTo(name.bottom));
      expect(second.left, greaterThan(first.left));
    });

    testWidgets('a long press shows what the buff is doing', (tester) async {
      drink(ItemId.MINOR_SPEED_POTION);
      await pump(tester);

      await tester.longPress(
        find.byKey(const ValueKey('stage-buff-MINOR_SPEED_POTION')),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.richMessage!.toPlainText(), contains('+5 Speed'));
      expect(tooltip.richMessage!.toPlainText(), contains('Everywhere'));
    });
  });

  testWidgets('the fight stage carries the buff icons in its corner', (
    tester,
  ) async {
    final (:session, chicken: _) = await openChickenFight(tester);
    expect(find.byType(StageBuffIcons), findsNothing);

    session.buffService.addBuff(
      potion(ItemId.MINOR_SPEED_POTION),
      session.saveGameData.playerData.buffData,
    );
    session.buffController.refresh();
    await settle(tester);

    final icons = find.descendant(
      of: find.byType(StagePanel),
      matching: find.byType(StageBuffIcons),
    );
    expect(icons, findsOneWidget);
    // pinned top-right
    final stage = tester.getRect(find.byType(StagePanel));
    final rect = tester.getRect(icons);
    expect(stage.right - rect.right, lessThan(16));
    expect(rect.top - stage.top, lessThan(16));
  });

  group('crafting stages', () {
    const zoneId = ZoneId.TUTORIAL_FARM;

    /// Boots the app, drinks a potion, and walks to [tile] in the starting
    /// zone the way a player would.
    Future<void> openStation(WidgetTester tester, String tile) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
      );
      await settle(tester);
      final session = Provider.of<GameSession>(
        tester.element(find.byType(MapScreen)),
        listen: false,
      );
      session.buffService.addBuff(
        potion(ItemId.MINOR_SPEED_POTION),
        session.saveGameData.playerData.buffData,
      );
      await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
      await settle(tester);
      await tester.tap(find.text('Enter'));
      await settle(tester);
      await tester.tap(find.text(tile));
      await settle(tester);
    }

    void expectIconsOnStage(WidgetTester tester) {
      expect(
        find.descendant(
          of: find.byType(StagePanel),
          matching: find.byKey(const ValueKey('stage-buff-MINOR_SPEED_POTION')),
        ),
        findsOneWidget,
      );
    }

    testWidgets('a crafting station shows them on its stage', (tester) async {
      await openStation(tester, EntityId.ANVIL.definition.name);
      expect(find.byType(CraftingScreen), findsOneWidget);
      expectIconsOnStage(tester);
    });

    testWidgets('the firepit shows them on its stage', (tester) async {
      await openStation(tester, 'Light a fire');
      expect(find.byType(FirepitScreen), findsOneWidget);
      expectIconsOnStage(tester);
    });
  });
}
