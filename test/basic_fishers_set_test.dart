import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';

// The basic fisher's set: six pieces of +2 fishing each. The pants, gloves
// and cloak rotate through the trading post at 1,000 coins; the Wolf Den's
// drops are in wolf_den_bosses_test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const slots = {
    ItemId.BASIC_FISHERS_BOOTS: ArmorSlots.FEET,
    ItemId.BASIC_FISHERS_HAT: ArmorSlots.HEAD,
    ItemId.BASIC_FISHERS_TUNIC: ArmorSlots.CHEST,
    ItemId.BASIC_FISHERS_PANTS: ArmorSlots.LEGS,
    ItemId.BASIC_FISHERS_GLOVES: ArmorSlots.HANDS,
    ItemId.BASIC_FISHERS_CLOAK: ArmorSlots.BACK,
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

  test('the pants, gloves and cloak rotate through the trading post at 1k', () {
    final def = EntityId.TRADING_POST.definition as ShopEntityDefinition;
    final pool = def.shopStockPool.map((e) => e.itemId).toList();
    const sold = [
      ItemId.BASIC_FISHERS_PANTS,
      ItemId.BASIC_FISHERS_GLOVES,
      ItemId.BASIC_FISHERS_CLOAK,
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
