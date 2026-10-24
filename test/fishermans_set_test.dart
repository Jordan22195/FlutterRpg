import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';

// The Fisherman's set: six pieces of +2 fishing each. Half drop off the Wolf
// Den's bosses, half rotate through the trading post at 1,000 coins.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const slots = {
    ItemId.FISHERMANS_BOOTS: ArmorSlots.FEET,
    ItemId.FISHERMANS_HAT: ArmorSlots.HEAD,
    ItemId.FISHERMANS_TUNIC: ArmorSlots.CHEST,
    ItemId.FISHERMANS_PANTS: ArmorSlots.LEGS,
    ItemId.FISHERMANS_GLOVES: ArmorSlots.HANDS,
    ItemId.FISHERMANS_CLOAK: ArmorSlots.BACK,
  };

  test('every piece is +2 fishing and nothing else, each in its own slot', () {
    for (final entry in slots.entries) {
      final def = entry.key.definition as EquipmentItemDefinition;
      expect(def.armorSlot, entry.value, reason: entry.key.name);
      expect(def.statsAt(Rarity.COMMON), {
        SkillId.FISHING: 2,
      }, reason: entry.key.name);
    }
  });

  test('the boots, hat and tunic drop off the Wolf Den\'s bosses', () {
    const bosses = {
      EntityId.FOREST_WOLF_RARE: ItemId.FISHERMANS_BOOTS,
      EntityId.FUNGAL_MONSTER_UNCOMMON: ItemId.FISHERMANS_HAT,
      EntityId.NAGA: ItemId.FISHERMANS_TUNIC,
    };
    final den = DungeonId.WOLF_DEN.definition.entries;

    for (final boss in bosses.entries) {
      // a boss is its card's last member
      expect(
        den.map((card) => card.entities.last.entityId),
        contains(boss.key),
        reason: '${boss.key.name} is not a Wolf Den boss',
      );
      final def = boss.key.definition as EncounterEntityDefinition;
      final rolls = def.bonusDrops.where(
        (roll) => roll.entries.any((e) => e.id == boss.value),
      );
      expect(rolls, hasLength(1), reason: boss.key.name);
      expect(rolls.single.chance, 0.1);
    }
  });

  test('the pants, gloves and cloak rotate through the trading post at 1k', () {
    final def = EntityId.TRADING_POST.definition as ShopEntityDefinition;
    final pool = def.shopStockPool.map((e) => e.itemId).toList();
    const sold = [
      ItemId.FISHERMANS_PANTS,
      ItemId.FISHERMANS_GLOVES,
      ItemId.FISHERMANS_CLOAK,
    ];
    expect(pool, containsAll(sold));
    // more than the shelf holds, so a restock rotates what is on it
    expect(pool.length, greaterThan(def.stockSlots));

    final shopService = ShopService(inventoryService: InventoryService());
    for (final id in sold) {
      expect(shopService.buyPrice(id, def), 1000, reason: id.name);
    }

    // over enough restocks, each one turns up on the shelf
    final seen = <ItemId>{};
    final rng = Random(7);
    var now = DateTime(2026, 1, 1);
    final shop = def.toEntity(EntityId.TRADING_POST) as ShopEntity;
    for (var i = 0; i < 50; i++) {
      shopService.restockIfDue(shop, def, now: now, rng: rng);
      seen.addAll(shop.stock.map((s) => s.itemId));
      now = now.add(def.restockInterval);
    }
    expect(seen, containsAll(sold));
  });
}
