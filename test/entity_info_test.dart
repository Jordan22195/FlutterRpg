import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/controllers/potion_controller.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/entity_details.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/encounter_service.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';
import 'package:rpg/widgets/info_section.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/stat_chip.dart';

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

    test('rises with the momentum the held button is holding', () {
      // the fast stance is the one that spends the boost on the interval,
      // which is what the rate is divided by
      save.playerData.stance = Stance.fast;
      final resting = detailsFor(EntityId.GOBLIN).playerDamagePerSecond;

      save.actionTimingData.boostingSpeed = true;
      save.actionTimingData.maxBoostMultiplier = 2.0;
      save.actionTimingData.percentOfMaxBoost = 1.0;

      // twice the swing rate for the same damage roll is twice the dps: the
      // bug this guards read the idle interval, so a full bar moved nothing
      expect(
        detailsFor(EntityId.GOBLIN).playerDamagePerSecond,
        closeTo(resting * 2, 1e-6),
      );
    });

    test('rises with what a strength stance lends', () {
      // a strength boost lends flat attack and multiplies the max hit rather
      // than shortening the interval, so it reaches the rate through both
      setLevel(SkillId.ATTACK, 30);
      setLevel(SkillId.STRENGTH, 40);
      save.playerData.stance = Stance.strong;
      save.playerData.skillBoost = SkillId.ATTACK;

      save.playerData.boostFill = 0.0;
      final resting = detailsFor(EntityId.GOBLIN);
      save.playerData.boostFill = 1.0;
      final boosted = detailsFor(EntityId.GOBLIN);

      expect(boosted.playerSkillLevel, greaterThan(resting.playerSkillLevel));
      expect(boosted.playerMaxHit, greaterThan(resting.playerMaxHit));
      expect(
        boosted.playerDamagePerSecond,
        greaterThan(resting.playerDamagePerSecond),
      );
      // the max hit is the swing off the lent attack, times the stance's
      // multiplier - the same number the roll uses
      expect(
        boosted.playerMaxHit,
        EncounterService().weaponMaxHit(
          damage: boosted.playerSwingDamage,
          attack: boosted.playerSkillLevel,
          defense: boosted.entity.defence,
          multiplier: session.playerDataService.strengthDamageMultiplier(
            save.playerData,
          ),
        ),
      );
    });

    test('is zero where actions do not roll damage', () {
      // a fishing spot never depletes and a herb is picked in one action,
      // so neither has a damage rate to report
      expect(detailsFor(EntityId.TRANQUIL_POND).playerDamagePerSecond, 0);
    });
  });

  group('the info tab', () {
    Future<void> pumpInfo(
      WidgetTester tester,
      EntityId id, {
      bool showImage = true,
    }) async {
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
            // the body watches this one so the rates track the boost
            ChangeNotifierProvider<ActionTimingController>.value(
              value: session.actionTimingController,
            ),
            // and this one, with the two above, so they track a potion
            ChangeNotifierProvider<PotionController>.value(
              value: session.potionController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EntityInfoBody(
                  entity: id.build() as EncounterEntity,
                  showImage: showImage,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the header reads the entity\'s own level, not a gate', (
      tester,
    ) async {
      Finder chip(String value) => find.descendant(
        of: find.byType(StatChip),
        matching: find.text(value),
      );

      // a goblin: its combat level, where there used to be a 0
      final goblin = EntityId.GOBLIN.build() as CombatEntity;
      await pumpInfo(tester, EntityId.GOBLIN);
      expect(chip('${goblin.level}'), findsOneWidget);
      expect(chip('0'), findsNothing);

      // an herb: its defence, and the level it asks for named as a gate
      final tarromin = EntityId.TARROMIN.build() as EncounterEntity;
      await pumpInfo(tester, EntityId.TARROMIN);
      expect(chip('${tarromin.defence}'), findsOneWidget);
      final gate = (EntityId.TARROMIN.definition as EncounterEntityDefinition)
          .requiredLevel;
      expect(find.textContaining('Requires Lv $gate'), findsOneWidget);
    });

    testWidgets('the popup shows the entity; the info tab leaves it out', (
      tester,
    ) async {
      Finder picture() => find.byWidgetPredicate(
        (w) => w is ItemStackTile && w.id == EntityId.GOBLIN,
      );

      await pumpInfo(tester, EntityId.GOBLIN);
      expect(picture(), findsOneWidget);

      // the encounter screen's tab: the goblin already stands on the stage
      await pumpInfo(tester, EntityId.GOBLIN, showImage: false);
      expect(picture(), findsNothing);
      // the details are all still there
      expect(find.text('COMBAT STATS'), findsOneWidget);
    });

    testWidgets('a fight reads as one column of six stats', (tester) async {
      setLevel(SkillId.ATTACK, 40);
      await pumpInfo(tester, EntityId.GOBLIN);

      // section headings render upper case
      expect(find.text('COMBAT STATS'), findsOneWidget);
      // one column: no side-by-side you and them
      expect(find.text('YOU'), findsNothing);
      expect(find.text('THEM'), findsNothing);

      final details = detailsFor(EntityId.GOBLIN);
      final rows = {
        'Hit chance': formatPercent(details.playerHitChance),
        'Block chance': formatPercent(details.blockChance),
        'Max hit': '${details.playerMaxHit}',
        'Max take': '${details.entityMaxHit}',
        'DPS': formatDecimal(details.playerDamagePerSecond),
        'Actions to kill': details.actionsToKill.toStringAsFixed(2),
      };

      // in that order, each with its value on its own line
      double? lastY;
      for (final entry in rows.entries) {
        final label = find.text(entry.key);
        expect(label, findsOneWidget, reason: entry.key);
        final y = tester.getCenter(label).dy;
        if (lastY != null) expect(y, greaterThan(lastY), reason: entry.key);
        lastY = y;
        final value = find.text(entry.value);
        expect(value, findsWidgets, reason: entry.key);
        expect(
          find
              .text(entry.value)
              .evaluate()
              .any(
                (e) =>
                    ((e.renderObject! as RenderBox)
                                .localToGlobal(Offset.zero)
                                .dy -
                            tester.getTopLeft(label).dy)
                        .abs() <
                    4,
              ),
          isTrue,
          reason: '${entry.key} value on its line',
        );
      }

      // the kill count keeps its fraction
      expect(rows['Actions to kill'], matches(RegExp(r'^\d+\.\d\d$')));

      // the rows the column replaced are gone
      expect(find.text('Miss chance'), findsNothing);
      expect(find.text('Avg damage'), findsNothing);
      expect(find.text('Damage per second'), findsNothing);
    });

    testWidgets('a fight\'s debug section names its combat type', (
      tester,
    ) async {
      await pumpInfo(tester, EntityId.GOBLIN);

      final def = EntityId.GOBLIN.definition as CombatEntityDefinition;
      expect(find.text('DEBUG'), findsOneWidget);
      expect(find.text('Combat type'), findsOneWidget);
      expect(find.text(def.combatType.label), findsOneWidget);
      // below the stats it explains
      expect(
        tester.getTopLeft(find.text('DEBUG')).dy,
        greaterThan(tester.getTopLeft(find.text('COMBAT STATS')).dy),
      );
    });

    testWidgets('a gathering node has no combat debug', (tester) async {
      await pumpInfo(tester, EntityId.TRANQUIL_POND);
      expect(find.text('Combat type'), findsNothing);
    });

    testWidgets('a fishing spot reads in catches, not damage', (tester) async {
      // well past the pond, so a cast can run a pool over
      setLevel(SkillId.FISHING, 60);
      await pumpInfo(tester, EntityId.TRANQUIL_POND);

      final details = detailsFor(EntityId.TRANQUIL_POND);
      expect(details.playerMaxCatch, greaterThan(1));
      expect(
        details.playerMaxCatch,
        EncounterService().catchesFor(
          details.playerMaxHit,
          details.entity.maxHitPoints,
        ),
      );

      final catchChance = find.text('Catch chance');
      final maxCatch = find.text('Max catch');
      expect(catchChance, findsOneWidget);
      expect(maxCatch, findsOneWidget);
      expect(
        tester.getCenter(maxCatch).dy,
        greaterThan(tester.getCenter(catchChance).dy),
      );
      expect(find.text(formatPercent(details.playerHitChance)), findsWidgets);
      expect(find.text('${details.playerMaxCatch}'), findsWidgets);

      for (final gone in ['Success chance', 'Fail chance', 'Avg damage']) {
        expect(find.text(gone), findsNothing, reason: gone);
      }

      // the debug section under the casts: the pool's hp and the cast's max
      // damage, which max catch is worked out from
      expect(find.text('DEBUG'), findsOneWidget);
      final poolHp = find.text('Pool hp');
      final maxHit = find.text('Max hit');
      expect(poolHp, findsOneWidget);
      expect(maxHit, findsOneWidget);
      expect(
        tester.getCenter(poolHp).dy,
        greaterThan(tester.getCenter(maxCatch).dy),
      );
      expect(
        tester.getCenter(maxHit).dy,
        greaterThan(tester.getCenter(poolHp).dy),
      );
      expect(find.text('${details.entity.maxHitPoints}'), findsWidgets);
      expect(find.text('${details.playerMaxHit}'), findsWidgets);

      // the average a cast lands, misses and all, to two places - checked
      // against the engine's own mean rather than worked out again here
      final service = EncounterService();
      final average =
          details.playerHitChance *
          service.meanCatchesPerHit(
            details.playerMaxHit,
            details.entity.maxHitPoints,
          );
      expect(details.playerAverageCatches, closeTo(average, 1e-9));
      final avgRow = find.text('Avg catches / cast');
      expect(avgRow, findsOneWidget);
      expect(
        tester.getCenter(avgRow).dy,
        greaterThan(tester.getCenter(maxHit).dy),
      );
      expect(find.text(average.toStringAsFixed(2)), findsWidgets);

      // and an hour of it, at the cast rate the dialog divides by
      expect(
        details.playerCatchesPerHour,
        closeTo(average * 3600 / details.playerActionInterval, 1e-9),
      );
      final perHour = find.text('Catches / hour');
      expect(perHour, findsOneWidget);
      expect(
        tester.getCenter(perHour).dy,
        greaterThan(tester.getCenter(avgRow).dy),
      );
      expect(
        find.text(details.playerCatchesPerHour.toStringAsFixed(0)),
        findsWidgets,
      );

      // and the xp those catches pay: the weighted fish the earned level
      // reaches, each catch worth one of them
      final pond =
          EntityId.TRANQUIL_POND.definition as EncounterEntityDefinition;
      final table = pond.dropTableAt(60);
      var weight = 0.0;
      var xp = 0.0;
      for (final entry in table) {
        weight += entry.weight;
        xp += entry.weight * entry.id.id.definition.xpValue * entry.count;
      }
      expect(details.xpPerCatch, closeTo(xp / weight, 1e-9));
      expect(
        details.playerXpPerHour,
        closeTo(details.playerCatchesPerHour * xp / weight, 1e-6),
      );
      final xpRow = find.text('Xp / hour');
      expect(xpRow, findsOneWidget);
      expect(
        tester.getCenter(xpRow).dy,
        greaterThan(tester.getCenter(perHour).dy),
      );
      expect(
        find.text(details.playerXpPerHour.toStringAsFixed(0)),
        findsWidgets,
      );
    });

    testWidgets('drinking a potion refreshes the numbers at once', (
      tester,
    ) async {
      setLevel(SkillId.FISHING, 60);
      await pumpInfo(tester, EntityId.TRANQUIL_POND);

      // the value on the Max hit row: a text at the label's height
      String? maxHitValue() {
        final y = tester.getCenter(find.text('Max hit')).dy;
        for (final e in find.byType(Text).evaluate()) {
          final text = e.widget as Text;
          if (text.data == null || text.data == 'Max hit') continue;
          final box = e.renderObject! as RenderBox;
          final mid = box.localToGlobal(box.size.center(Offset.zero)).dy;
          if ((mid - y).abs() < 4) return text.data;
        }
        return null;
      }

      final before = detailsFor(EntityId.TRANQUIL_POND).playerMaxHit;
      expect(maxHitValue(), '$before');

      // drunk from the item dialog, with no action running to tick
      expect(session.actionTimingController.isRunning, isFalse);
      session.saveGameData.inventoryData.itemMap[ItemId.MINOR_FISHING_POTION] =
          1;
      expect(
        session.inventoryController.drinkPotion(ItemId.MINOR_FISHING_POTION),
        isTrue,
      );
      // one frame, well short of the buff tick's second
      await tester.pump();

      final after = detailsFor(EntityId.TRANQUIL_POND).playerMaxHit;
      expect(after, greaterThan(before));
      expect(maxHitValue(), '$after');
    });

    testWidgets('a fish past your level shows locked in the drop table', (
      tester,
    ) async {
      // carp opens at 5. a potion lifts the total past it, but the fish
      // open on the level earned, so it stays shut
      setLevel(SkillId.FISHING, 1);
      session.saveGameData.inventoryData.itemMap[ItemId.MINOR_FISHING_POTION] =
          1;
      session.inventoryController.drinkPotion(ItemId.MINOR_FISHING_POTION);
      await pumpInfo(tester, EntityId.TRANQUIL_POND);

      final drops = detailsFor(EntityId.TRANQUIL_POND).drops;
      final minnow = drops.singleWhere((d) => d.itemId == ItemId.MINNOW);
      final carp = drops.singleWhere((d) => d.itemId == ItemId.CARP);
      // the odds are the ones a cast has now: the minnow is the whole table
      expect(minnow.locked, isFalse);
      expect(minnow.chance, 1.0);
      expect(carp.locked, isTrue);
      expect(carp.lockedUntil, 5);
      expect(carp.chance, 0);

      final carpRow = find.byKey(const ValueKey('drop-CARP-COMMON-locked'));
      await tester.ensureVisible(carpRow);
      expect(carpRow, findsOneWidget);
      expect(
        find.descendant(of: carpRow, matching: find.text('Lv 5')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: carpRow, matching: find.byIcon(Icons.lock)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Opacity>(
              find
                  .descendant(of: carpRow, matching: find.byType(Opacity))
                  .first,
            )
            .opacity,
        lessThan(1),
      );
      expect(find.byKey(const ValueKey('drop-MINNOW-COMMON')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('drop-MINNOW-COMMON-locked')),
        findsNothing,
      );

      // at 5 it opens, with real odds
      setLevel(SkillId.FISHING, 5);
      await pumpInfo(tester, EntityId.TRANQUIL_POND);
      final opened = detailsFor(
        EntityId.TRANQUIL_POND,
      ).drops.singleWhere((d) => d.itemId == ItemId.CARP);
      expect(opened.locked, isFalse);
      expect(opened.chance, closeTo(0.5 / 1.5, 1e-9));
      expect(
        find.byKey(const ValueKey('drop-CARP-COMMON-locked')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('drop-CARP-COMMON')), findsOneWidget);
    });

    testWidgets('leaves the entity stat block to the encounter screen', (
      tester,
    ) async {
      await pumpInfo(tester, EntityId.GOBLIN);

      // hitpoints, level and remaining count are all on the screen around
      // this panel already; repeating them here only made it longer
      expect(find.text('STATS'), findsNothing);
      expect(find.text('Hitpoints'), findsNothing);
      expect(find.text('Remaining'), findsNothing);
      expect(find.text('Attack speed'), findsNothing);
    });

    testWidgets('the damage rate follows the boost while it is held', (
      tester,
    ) async {
      setLevel(SkillId.ATTACK, 40);
      save.playerData.stance = Stance.fast;
      await pumpInfo(tester, EntityId.GOBLIN);

      final resting = detailsFor(EntityId.GOBLIN).playerDamagePerSecond;
      expect(find.text(resting.toStringAsFixed(1)), findsWidgets);

      // fill the bar the way a held button does, and tick the controller
      // the way the frame loop does
      save.actionTimingData.boostingSpeed = true;
      save.actionTimingData.maxBoostMultiplier = 2.0;
      save.actionTimingData.percentOfMaxBoost = 1.0;
      session.actionTimingController.notifyListeners();
      await tester.pump();

      final boosted = detailsFor(EntityId.GOBLIN).playerDamagePerSecond;
      expect(boosted, greaterThan(resting));
      expect(find.text(boosted.toStringAsFixed(1)), findsWidgets);
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
      // nothing swings back at a tree, so the table drops the second column
      expect(find.text('Damage per second'), findsOneWidget);
      expect(find.text('YOU'), findsNothing);

      await pumpInfo(tester, EntityId.TRANQUIL_POND);
      expect(find.text('Damage per second'), findsNothing);
    });
  });
}
