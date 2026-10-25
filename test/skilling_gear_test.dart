import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';

// Skilling gear: a set per gathering and crafting skill and exploration, six slots, five
// tiers. Each piece is its tier's rung poured into its one skill, and asks
// for its tier's level in that skill.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const skills = [
    SkillId.FISHING,
    SkillId.MINING,
    SkillId.WOODCUTTING,
    SkillId.HERBALISM,
    SkillId.FIREMAKING,
    SkillId.COOKING,
    SkillId.BLACKSMITHING,
    SkillId.ENCHANTING,
    SkillId.JEWELCRAFTING,
    SkillId.ALCHEMY,
    SkillId.EXPLORATION,
  ];
  const slots = {
    ArmorSlots.HEAD,
    ArmorSlots.CHEST,
    ArmorSlots.LEGS,
    ArmorSlots.HANDS,
    ArmorSlots.FEET,
    ArmorSlots.BACK,
  };
  const commonStat = {
    SkillingGearTier.BASIC: 2,
    SkillingGearTier.NOVICE: 3,
    SkillingGearTier.APPRENTICE: 5,
    SkillingGearTier.ADVANCED: 8,
    SkillingGearTier.MASTER: 13,
  };
  const level = {
    SkillingGearTier.BASIC: 1,
    SkillingGearTier.NOVICE: 20,
    SkillingGearTier.APPRENTICE: 40,
    SkillingGearTier.ADVANCED: 60,
    SkillingGearTier.MASTER: 80,
  };

  final gear = {
    for (final id in ItemId.values)
      if (id.definition is SkillingGearDefinition)
        id: id.definition as SkillingGearDefinition,
  };

  test('every skill has one piece per slot at every tier', () {
    expect(gear, hasLength(skills.length * slots.length * 5));
    for (final skill in skills) {
      for (final tier in SkillingGearTier.values) {
        final set = gear.values.where(
          (d) => d.skill == skill && d.tier == tier,
        );
        expect(
          set.map((d) => d.armorSlot).toSet(),
          slots,
          reason: '${skill.name} ${tier.name}',
        );
        expect(set, hasLength(slots.length));
      }
    }
  });

  test('a common piece carries its tier\'s stat in its skill and nothing '
      'else', () {
    for (final entry in gear.entries) {
      final def = entry.value;
      expect(def.statsAt(Rarity.COMMON), {
        def.skill: commonStat[def.tier],
      }, reason: entry.key.name);
    }
  });

  test('a piece asks for its tier\'s level in its own skill', () {
    final service = EquipmentService();
    for (final entry in gear.entries) {
      final def = entry.value;
      final piece = entry.key.build() as EquipmentItem;
      final needed = level[def.tier]!;
      expect(service.requirementFor(piece), (
        skill: def.skill,
        level: needed,
      ), reason: entry.key.name);
      expect(
        service.meetsRequirement(piece, {def.skill: needed}),
        isTrue,
        reason: entry.key.name,
      );
      if (needed > 1) {
        expect(
          service.meetsRequirement(piece, {def.skill: needed - 1}),
          isFalse,
          reason: entry.key.name,
        );
      }
    }
  });

  test('ids and names follow "<Tier> <Noun>\'s <Piece>"', () {
    expect(ItemId.BASIC_FISHERS_HAT.definition.name, "Basic Fisher's Hat");
    expect(
      ItemId.MASTER_ALCHEMISTS_CLOAK.definition.name,
      "Master Alchemist's Cloak",
    );
    for (final id in gear.keys) {
      expect(id.name, startsWith(gear[id]!.tier.name), reason: id.name);
      expect(
        id.iconAsset,
        'assets/icons/items/${id.name.toLowerCase()}.png',
        reason: id.name,
      );
    }
  });

  group('the Fisherman\'s set renamed to the basic fisher\'s', () {
    test('every old name resolves to its new id', () {
      const expected = {
        'FISHERMANS_BOOTS': ItemId.BASIC_FISHERS_BOOTS,
        'FISHERMANS_HAT': ItemId.BASIC_FISHERS_HAT,
        'FISHERMANS_TUNIC': ItemId.BASIC_FISHERS_TUNIC,
        'FISHERMANS_PANTS': ItemId.BASIC_FISHERS_PANTS,
        'FISHERMANS_GLOVES': ItemId.BASIC_FISHERS_GLOVES,
        'FISHERMANS_CLOAK': ItemId.BASIC_FISHERS_CLOAK,
      };
      for (final entry in expected.entries) {
        expect(ItemId.byName(entry.key), entry.value);
      }
    });

    test('a save written before the rename loads the pieces back', () {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final save = factory.newGame(catalogs);

      final worn = ItemId.BASIC_FISHERS_HAT.build() as EquipmentItem
        ..quality = Rarity.RARE;
      save.playerData.equipmentData.armorEquipment[ArmorSlots.HEAD] = worn;
      save.inventoryData.equipment.add(
        ItemId.BASIC_FISHERS_CLOAK.build() as EquipmentItem,
      );

      // the file as the old build wrote it
      final written = jsonEncode(
        save.toJson(),
      ).replaceAll('BASIC_FISHERS_', 'FISHERMANS_');
      expect(written, contains('"FISHERMANS_HAT"'));
      expect(written, isNot(contains('BASIC_FISHERS_')));

      final session = factory.create(
        save: SaveGameData.fromJson(
          jsonDecode(written) as Map<String, dynamic>,
        ),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
      final restored = session.saveGameData;

      final hat =
          restored.playerData.equipmentData.armorEquipment[ArmorSlots.HEAD];
      expect(hat?.id, ItemId.BASIC_FISHERS_HAT);
      expect(hat?.quality, Rarity.RARE);
      expect(
        restored.inventoryData.equipment.map((e) => e.id),
        contains(ItemId.BASIC_FISHERS_CLOAK),
      );

      session.dispose();
    });
  });

  test('South Haven\'s trading post rotates every basic gloves, boots and '
      'cloak', () {
    const sold = {ArmorSlots.HANDS, ArmorSlots.FEET, ArmorSlots.BACK};
    final pieces = {
      for (final entry in gear.entries)
        if (entry.value.tier == SkillingGearTier.BASIC &&
            sold.contains(entry.value.armorSlot))
          entry.key,
    };
    expect(pieces, hasLength(skills.length * sold.length));

    final def = EntityId.TRADING_POST.definition as ShopEntityDefinition;
    final pool = def.shopStockPool.map((e) => e.itemId).toList();
    expect(pool, containsAll(pieces));
    // once each
    expect(pool.toSet(), hasLength(pool.length));

    final shopService = ShopService(inventoryService: InventoryService());
    for (final id in pieces) {
      expect(shopService.buyPrice(id, def), 1000, reason: id.name);
    }

    // over enough restocks, each one turns up on the shelf
    final seen = <ItemId>{};
    final rng = Random(7);
    var now = DateTime(2026, 1, 1);
    final shop = def.toEntity(EntityId.TRADING_POST) as ShopEntity;
    for (var i = 0; i < 300; i++) {
      shopService.restockIfDue(shop, def, now: now, rng: rng);
      seen.addAll(shop.stock.map((s) => s.itemId));
      now = now.add(def.restockInterval);
    }
    expect(seen, containsAll(pieces));
  });
}
