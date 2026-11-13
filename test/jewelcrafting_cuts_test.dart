import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/data/jewelcrafting_recipes.dart';
import 'package:rpg/catalogs/recipes/recipe_catalog.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/jewellery_icon.dart';

ItemId jewellery(GemType gem, GemCut cut, JewellerySetting setting) =>
    ItemId.values.singleWhere((id) {
      final def = id.definition;
      return def is JewelleryDefinition &&
          def.gem == gem &&
          def.cut == cut &&
          def.setting == setting;
    });

JewelleryDefinition defOf(GemType gem, GemCut cut, JewellerySetting setting) =>
    jewellery(gem, cut, setting).definition as JewelleryDefinition;

EquipmentItem piece(ItemId id, Rarity rarity) =>
    (id.build() as EquipmentItem)..quality = rarity;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ladder', () {
    test('every gem unlocks its six cuts in increasing order', () {
      for (final gem in GemType.values) {
        expect(gem.cutLevels, hasLength(GemCut.values.length));
        for (var i = 1; i < gem.cutLevels.length; i++) {
          expect(gem.cutLevels[i], greaterThan(gem.cutLevels[i - 1]));
        }
      }
    });

    test('the 42 unlocks never share a level', () {
      final levels = [for (final gem in GemType.values) ...gem.cutLevels];
      expect(levels, hasLength(42));
      expect(levels.toSet(), hasLength(42));
    });
  });

  group('catalog', () {
    test('one id per gem x cut x setting', () {
      final defs = ItemId.values
          .map((id) => id.definition)
          .whereType<JewelleryDefinition>()
          .toList();
      expect(defs, hasLength(84));
      for (final gem in GemType.values) {
        for (final cut in GemCut.values) {
          for (final setting in JewellerySetting.values) {
            expect(() => jewellery(gem, cut, setting), returnsNormally);
          }
        }
      }
    });

    test('the round cuts keep the ids saves already hold', () {
      expect(
        jewellery(GemType.RUBY, GemCut.ROUND, JewellerySetting.RING),
        ItemId.RUBY_RING,
      );
      expect(
        jewellery(GemType.ONYX, GemCut.ROUND, JewellerySetting.NECKLACE),
        ItemId.ONYX_NECKLACE,
      );
      expect(ItemId.RUBY_RADIANT_RING.definition.name, 'Radiant Ruby Ring');
    });

    test('every piece has exactly one recipe, gated by its cut level', () {
      final recipes = RecipeCatalog().recipesForSkill(SkillId.JEWELCRAFTING);
      for (final id in ItemId.values) {
        final def = id.definition;
        if (def is! JewelleryDefinition) continue;
        final making = recipes
            .where((r) => r.output.any((o) => o.id == id))
            .toList();
        expect(making, hasLength(1), reason: id.name);
        final recipe = making.single;
        final level = def.gem.levelFor(def.cut);
        expect(recipe.levelRequirement, level);
        expect(recipe.xp, jewelcraftingXpAt(level));
        expect(recipe.inputs, {def.gem.gemItem: 1, def.setting.goldBase: 1});
      }
    });

    test('round recipes keep their old ids; other cuts name the cut', () {
      final ids = RecipeCatalog()
          .recipesForSkill(SkillId.JEWELCRAFTING)
          .map((r) => r.id)
          .toSet();
      expect(ids, containsAll(['jc_topaz_ring', 'jc_onyx_necklace']));
      expect(ids, contains('jc_ruby_radiant_ring'));
      expect(ids, hasLength(84));
    });

    test('the gold bases are blacksmithed, and a good craft makes more', () {
      final catalog = RecipeCatalog();
      for (final id in ['forge_gold_ring', 'forge_gold_necklace']) {
        final recipe = catalog.recipeById(id);
        expect(recipe.skill, SkillId.BLACKSMITHING, reason: id);
        expect(recipe.rollsBonusOutput, isTrue, reason: id);
      }
      expect(catalog.recipeById('forge_gold_ring').inputs, {
        ItemId.GOLD_BAR: 1,
      });
      expect(catalog.recipeById('forge_gold_necklace').inputs, {
        ItemId.GOLD_BAR: 2,
      });
    });

    test('xp per craft doubles every 14 levels', () {
      expect(jewelcraftingXpAt(1), 21);
      expect(jewelcraftingXpAt(81), 1103);
      expect(jewelcraftingXpAt(99), 2690);
    });
  });

  group('stats', () {
    Map<SkillId, int> stats(
      GemType gem,
      GemCut cut,
      JewellerySetting setting, [
      Rarity rarity = Rarity.COMMON,
    ]) => piece(jewellery(gem, cut, setting), rarity).effectiveSkillBonus;

    test('the cut is the Fibonacci rung', () {
      const ring = JewellerySetting.RING;
      expect(stats(GemType.RUBY, GemCut.ROUND, ring), {SkillId.STRENGTH: 3});
      expect(stats(GemType.RUBY, GemCut.SQUARE, ring), {SkillId.STRENGTH: 5});
      expect(stats(GemType.RUBY, GemCut.RADIANT, ring), {SkillId.STRENGTH: 34});
    });

    test('a necklace sits a rung above the ring', () {
      expect(stats(GemType.RUBY, GemCut.RADIANT, JewellerySetting.NECKLACE), {
        SkillId.STRENGTH: 55,
      });
    });

    test('rarity scales a piece like blacksmithed gear', () {
      final byRarity = [
        for (final r in Rarity.values)
          stats(
            GemType.RUBY,
            GemCut.RADIANT,
            JewellerySetting.RING,
            r,
          )[SkillId.STRENGTH],
      ];
      expect(byRarity, [34, 41, 48, 54, 61]);
    });

    test('each gem carries its own stat', () {
      const ring = JewellerySetting.RING;
      const round = GemCut.ROUND;
      expect(stats(GemType.TOPAZ, round, ring).keys, [SkillId.SPEED]);
      expect(stats(GemType.SAPPHIRE, round, ring).keys, [SkillId.STAMINA]);
      expect(stats(GemType.EMERALD, round, ring).keys, [SkillId.RECOVERY]);
      expect(stats(GemType.RUBY, round, ring).keys, [SkillId.STRENGTH]);
      expect(stats(GemType.DIAMOND, round, ring).keys, [SkillId.DEFENCE]);
      expect(stats(GemType.DRAGONSTONE, round, ring).keys, [SkillId.ATTACK]);
      expect(stats(GemType.ONYX, GemCut.RADIANT, ring), isEmpty);
    });
  });

  group('onyx', () {
    test('xp percent is the stat ladder a rung down, scaled by rarity', () {
      const ring = JewellerySetting.RING;
      final cuts = [
        for (final cut in GemCut.values)
          defOf(GemType.ONYX, cut, ring).xpPercentAt(Rarity.COMMON),
      ];
      expect(cuts, [2, 3, 5, 8, 13, 21]);
      expect(
        defOf(GemType.ONYX, GemCut.RADIANT, ring).xpPercentAt(Rarity.LEGENDARY),
        38,
      );
      expect(
        defOf(
          GemType.ONYX,
          GemCut.RADIANT,
          JewellerySetting.NECKLACE,
        ).xpPercentAt(Rarity.LEGENDARY),
        61,
      );
      expect(
        defOf(GemType.RUBY, GemCut.RADIANT, ring).xpPercentAt(Rarity.COMMON),
        0,
      );
    });

    test('worn onyx boosts every xp award by its percent', () {
      final service = PlayerDataService(
        buffService: BuffService(),
        equpmentService: EquipmentService(),
        skillService: SkillService(),
      );
      final PlayerData player = GameSessionFactory()
          .newGame(GameSessionFactory().catalog1())
          .playerData;
      final equipment = player.equipmentData;
      equipment.armorEquipment[ArmorSlots.FINGER] = piece(
        ItemId.ONYX_RADIANT_RING,
        Rarity.COMMON,
      ); // +21
      equipment.armorEquipment[ArmorSlots.NECK] = piece(
        ItemId.ONYX_NECKLACE,
        Rarity.COMMON,
      ); // round necklace: rung 2 -> +3
      expect(EquipmentService().xpPercentBonus(equipment), 24);

      final before = player.skillData[SkillId.MINING]!.xp;
      final paid = service.applyXp(player, {SkillId.MINING: 100});
      expect(paid[SkillId.MINING], closeTo(124, 1e-9));
      expect(player.skillData[SkillId.MINING]!.xp - before, closeTo(124, 1e-9));
    });

    test('no onyx, no change', () {
      expect(EquipmentService().xpPercentBonus(EquipmentData()), 0);
    });
  });

  test('core gems drop evenly; the special gems are rarer, onyx rarest', () {
    double weight(ItemId id) =>
        gemDropTable.singleWhere((e) => e.id == id).weight;
    final core = [
      ItemId.TOPAZ,
      ItemId.SAPPHIRE,
      ItemId.EMERALD,
      ItemId.RUBY,
    ].map(weight).toSet();
    expect(core, hasLength(1));
    expect(weight(ItemId.DIAMOND), weight(ItemId.DRAGONSTONE));
    expect(weight(ItemId.DIAMOND), lessThan(core.single));
    expect(weight(ItemId.ONYX), lessThan(weight(ItemId.DIAMOND)));
  });

  group('icons', () {
    test('every layer sprite is on disk', () {
      for (final path in [
        for (final cut in GemCut.values) cut.overlayAsset,
        for (final setting in JewellerySetting.values) setting.baseAsset,
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    testWidgets('a piece draws its base with the tinted cut on top', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: IconRenderer(size: 64, id: ItemId.RUBY_RADIANT_NECKLACE),
          ),
        ),
      );

      expect(find.byType(JewelleryIcon), findsOneWidget);
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => (i.image as AssetImage).assetName)
          .toList();
      expect(assets, [
        'assets/icons/jewellery/necklace_base.png',
        'assets/icons/jewellery/cut_radiant.png',
      ]);
      final filter = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(
        filter.colorFilter,
        ColorFilter.mode(GemType.RUBY.color, BlendMode.modulate),
      );
    });

    testWidgets('anything else keeps its single sprite', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: IconRenderer(size: 64, id: ItemId.RUBY),
        ),
      );
      expect(find.byType(JewelleryIcon), findsNothing);
    });
  });
}
