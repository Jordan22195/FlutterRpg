import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/entity_details.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

/// What the encounter screen's info tab reports about the player's own side
/// of the fight — in particular the damage rate, which is the number the
/// incoming section's rate is read against.
void main() {
  late GameSession session;
  late SaveGameData save;

  setUp(() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    save = factory.newGame(catalogs);
    session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
  });

  tearDown(() => session.dispose());

  void setLevel(SkillId skill, int level) {
    final data = save.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  EntityDetails detailsFor(EntityId id) =>
      session.worldController.entityDetails(id.build() as EncounterEntity);

  group('the player damage rate', () {
    test('is the average damage over one action interval', () {
      final details = detailsFor(EntityId.GOBLIN);

      expect(details.playerActionInterval, greaterThan(0));
      expect(
        details.playerDamagePerSecond,
        closeTo(
          details.playerAverageDamage / details.playerActionInterval,
          1e-9,
        ),
      );
    });

    test('reads against the interval the idle timer would show', () {
      final goblin = EntityId.GOBLIN.build() as EncounterEntity;
      final expected =
          session.actionTimingController
              .idleActionDurationFor(goblin.entityType)
              .inMicroseconds /
          1e6;

      expect(detailsFor(EntityId.GOBLIN).playerActionInterval, expected);
    });

    test('rises with the level that drives the damage roll', () {
      setLevel(SkillId.ATTACK, 1);
      final low = detailsFor(EntityId.GOBLIN).playerDamagePerSecond;
      setLevel(SkillId.ATTACK, 60);
      final high = detailsFor(EntityId.GOBLIN).playerDamagePerSecond;

      expect(low, greaterThan(0));
      expect(high, greaterThan(low));
    });

    test('is zero where actions do not roll damage', () {
      // a fishing spot never depletes and a herb is picked in one action,
      // so neither has a damage rate to report
      expect(detailsFor(EntityId.TRANQUIL_POND).playerDamagePerSecond, 0);
    });
  });

  group('the info tab', () {
    Future<void> pumpInfo(WidgetTester tester, EntityId id) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GameSession>.value(value: session),
            ChangeNotifierProvider<WorldController>.value(
              value: session.worldController,
            ),
            // the drop rows are real item tiles, and tapping one opens the
            // item dialog off these two
            ChangeNotifierProvider<InventoryController>.value(
              value: session.inventoryController,
            ),
            ChangeNotifierProvider<BuffController>.value(
              value: session.buffController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EntityInfoBody(entity: id.build() as EncounterEntity),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the damage rate under the player attack rolls', (
      tester,
    ) async {
      setLevel(SkillId.ATTACK, 40);
      await pumpInfo(tester, EntityId.GOBLIN);

      // section headings render upper case
      expect(find.text('YOUR ATTACKS'), findsOneWidget);
      // one row in the player's section, one in the entity's
      expect(find.text('Damage per second'), findsNWidgets(2));

      final details = detailsFor(EntityId.GOBLIN);
      expect(
        find.text(details.playerDamagePerSecond.toStringAsFixed(1)),
        findsWidgets,
      );
    });

    // The drop rows are ordinary item tiles: framed by the quality the drop
    // rolls, the way the bag frames that piece, and opening the same item
    // dialog on a tap. The table is where you go to decide whether a
    // monster is worth killing, which is exactly when you want to read what
    // it drops.
    group('the drop table uses item tiles', () {
      /// The frame around the icon on the row for [label]. Each row is one
      /// ItemStackTile, which paints its border into the first DecoratedBox
      /// under it.
      BoxDecoration frameFor(WidgetTester tester, String label) {
        final tile = find.ancestor(
          of: find.text(label),
          matching: find.byType(Row),
        );
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(of: tile.first, matching: find.byType(DecoratedBox))
              .first,
        );
        return box.decoration as BoxDecoration;
      }

      testWidgets('a common drop falls back to the theme outline', (
        tester,
      ) async {
        await pumpInfo(tester, EntityId.GOBLIN);

        // the goblin's fish are not equipment, so they carry no quality
        final border = frameFor(tester, 'Cooked Carp').border as Border;
        expect(border.top.color, isNot(rarityBorderColor(Rarity.UNCOMMON)));
        expect(border.top.width, 1);
      });

      testWidgets('a rolled drop is framed in its own colour', (tester) async {
        await pumpInfo(tester, EntityId.GOBLIN_LEGENDARY);

        // the goblin queen stamps LEGENDARY on the gear it drops
        final dagger = ironToolsDropTable.first.id.definition.name;
        final border = frameFor(tester, 'Legendary $dagger').border as Border;
        expect(border.top.color, rarityBorderColor(Rarity.LEGENDARY));
        // a coloured tier is drawn thicker, so it reads across a list
        expect(border.top.width, 2);
      });

      testWidgets('every row is a tile, with no count badge on it', (
        tester,
      ) async {
        await pumpInfo(tester, EntityId.GOBLIN);

        final details = detailsFor(EntityId.GOBLIN);
        expect(
          find.byType(ItemStackTile<ItemId>),
          findsNWidgets(details.drops.length),
        );
        // a drop is a range, and the column to the right of the icon is the
        // one that can say "1-5" - a badge could only ever contradict it
        for (final tile in tester.widgetList<ItemStackTile<ItemId>>(
          find.byType(ItemStackTile<ItemId>),
        )) {
          expect(tile.count, 0);
        }
      });

      testWidgets('tapping a drop opens that item\'s dialog', (tester) async {
        await pumpInfo(tester, EntityId.GOBLIN);

        final carp = cookedFishDropTable.first.id;
        final tile = find.byWidgetPredicate(
          (w) => w is ItemStackTile<ItemId> && w.id == carp,
        );
        // the drop table sits at the bottom of a long body, so the row has
        // to be brought on screen before the tap can land on it
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();

        // the item dialog is its own route on top of the info body
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(carp.definition.name),
          ),
          findsWidgets,
        );
      });

      testWidgets('the tile is handed the quality the drop rolls', (
        tester,
      ) async {
        await pumpInfo(tester, EntityId.GOBLIN_LEGENDARY);

        // the frame is the tile's own business - what this row owes it is
        // the right quality to draw
        final dagger = ironToolsDropTable.first.id;
        final tile = tester.widget<ItemStackTile<ItemId>>(
          find.byWidgetPredicate(
            (w) => w is ItemStackTile<ItemId> && w.id == dagger,
          ),
        );
        expect(tile.quality, Rarity.LEGENDARY);

        // and the fish, which are not equipment, roll no quality at all
        final carp = cookedFishDropTable.first.id;
        final fishTile = tester.widget<ItemStackTile<ItemId>>(
          find.byWidgetPredicate(
            (w) => w is ItemStackTile<ItemId> && w.id == carp,
          ),
        );
        expect(fishTile.quality, Rarity.COMMON);
      });

      testWidgets('the dialog prices the stats at the rolled quality', (
        tester,
      ) async {
        // the bug this guards: the dialog used to read statsAt off the
        // *definition's* declared quality, so every rarity of a charm
        // showed the common one's numbers
        await pumpInfo(tester, EntityId.BIG_RED);

        final charm = ItemId.CHICKEN_CHARM.definition;
        final rareStats = (charm as EquipmentItemDefinition).statsAt(
          Rarity.RARE,
        );
        expect(
          rareStats.values.first,
          greaterThan(charm.statsAt(Rarity.COMMON).values.first),
          reason: 'the fixture needs a charm whose tiers actually differ',
        );

        final tile = find.byWidgetPredicate(
          (w) =>
              w is ItemStackTile<ItemId> &&
              w.id == ItemId.CHICKEN_CHARM &&
              w.quality == Rarity.RARE,
        );
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();

        for (final stat in rareStats.entries) {
          expect(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('${stat.value}'),
            ),
            findsWidgets,
            reason: '${stat.key.name} should read ${stat.value} at RARE',
          );
        }
      });
    });

    testWidgets('a gathering node reports one, a fishing spot none', (
      tester,
    ) async {
      await pumpInfo(tester, EntityId.TREE);
      // no incoming section on a tree, so the only rate is the player's
      expect(find.text('Damage per second'), findsOneWidget);

      await pumpInfo(tester, EntityId.TRANQUIL_POND);
      expect(find.text('Damage per second'), findsNothing);
    });
  });
}
