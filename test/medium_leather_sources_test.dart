import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';

// Medium leather comes from two places: the goblins drop its extremities,
// at their own rarity, and the trading post rotates the body pieces.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mediumLeather = {
    for (final id in ItemId.values)
      if (id.name.startsWith('MEDIUM_LEATHER_')) id,
  };
  final dropped = {for (final e in mediumLeatherMinorArmorDropTable) e.id};
  final shop = EntityId.TRADING_POST.definition as ShopEntityDefinition;
  final sold = {
    for (final e in shop.shopStockPool)
      if (mediumLeather.contains(e.itemId)) e.itemId,
  };

  test('the extremities drop and the body pieces are sold', () {
    expect(dropped, {
      ItemId.MEDIUM_LEATHER_COIF,
      ItemId.MEDIUM_LEATHER_GLOVES,
      ItemId.MEDIUM_LEATHER_BOOTS,
    });
    expect(sold, {
      ItemId.MEDIUM_LEATHER_SPAULDERS,
      ItemId.MEDIUM_LEATHER_CHEST,
      ItemId.MEDIUM_LEATHER_BELT,
      ItemId.MEDIUM_LEATHER_BRACERS,
      ItemId.MEDIUM_LEATHER_PANTS,
    });
    // between them, every piece and none twice
    expect(dropped.intersection(sold), isEmpty);
    expect(dropped.union(sold), mediumLeather);
  });

  test('every goblin variant drops the leather at its own rarity', () {
    const goblins = [
      EntityId.GOBLIN,
      EntityId.GOBLIN_UNCOMMON,
      EntityId.GOBLIN_RARE,
      EntityId.GOBLIN_EPIC,
      EntityId.GOBLIN_LEGENDARY,
    ];
    for (final id in goblins) {
      final def = id.definition as CombatEntityDefinition;
      final leather = def.itemDrops.flattened
          .where((e) => dropped.contains(e.id))
          .toList();
      expect(leather.map((e) => e.id).toSet(), dropped, reason: id.name);
      expect(leather.map((e) => e.rarity).toSet(), {
        def.rarity,
      }, reason: id.name);
    }
  });
}
