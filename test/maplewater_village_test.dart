import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/zones/world_map_layout.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';

/// Maplewater Village is the fishing village on the shore of Maplewater Lake.
void main() {
  final town = ZoneId.MAPLEWATER_VILLAGE.definition;

  ShopEntityDefinition shopDef(EntityId id) =>
      id.definition as ShopEntityDefinition;

  group('Maplewater Village', () {
    test(
      'is a settlement with a trading post, a fishing shop and a lumber mill',
      () {
        expect(town.name, 'Maplewater Village');
        expect(town.type, MapNodeType.TOWN);
        expect(
          town.permanentEntities,
          containsAll([
            EntityId.MAPLEWATER_TRADING_POST,
            EntityId.FISHING_SHOP,
            EntityId.LUMBER_MILL,
          ]),
        );
        expect(town.discoverableEntities, isEmpty);
      },
    );

    test('is a short walk from the lake, and reached through it', () {
      expect(
        ZoneTravelGraph.travelHops(
          ZoneId.MAPLEWATER_LAKE,
          ZoneId.MAPLEWATER_VILLAGE,
        ),
        1,
      );
      expect(
        ZoneTravelGraph.travelPath(ZoneId.SWAMP, ZoneId.MAPLEWATER_VILLAGE),
        [ZoneId.SWAMP, ZoneId.MAPLEWATER_LAKE, ZoneId.MAPLEWATER_VILLAGE],
      );
    });

    test('is drawn beside the lake, clear of every other node', () {
      final centre = zoneNodeCenter(ZoneId.MAPLEWATER_VILLAGE)!;
      final lake = zoneNodeCenter(ZoneId.MAPLEWATER_LAKE)!;
      expect((centre - lake).distance, lessThan(160));
      expect(centre.dx, inInclusiveRange(0, kWorldMapSize.width));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
      for (final node in kWorldMapNodes) {
        if (node.center == centre) continue;
        expect(
          (node.center - centre).distance,
          greaterThanOrEqualTo(kMinNodeSpacing),
          reason: '${node.name} is too close to the village',
        );
      }
    });
  });

  group('Fishing Shop', () {
    final def = shopDef(EntityId.FISHING_SHOP);
    final pool = {for (final e in def.shopStockPool) e.itemId: e.count};

    test('stocks 500 of every raw fish up through catfish', () {
      for (final fish in [
        ItemId.MINNOW,
        ItemId.CARP,
        ItemId.CRAYFISH,
        ItemId.BLUEGILL,
        ItemId.TROUT,
        ItemId.PIKE,
        ItemId.BOG_EEL,
        ItemId.SALMON,
        ItemId.CATFISH,
      ]) {
        expect(pool[fish], 500, reason: fish.name);
      }
      expect(pool.containsKey(ItemId.BASS), isFalse);
    });

    test('sells rods up to mithril, and no fisher\'s set', () {
      // the fisher's sets come only out of sunken caches
      expect(
        pool.keys.where((id) => id.name.contains('FISHERS_')),
        isEmpty,
      );
      expect(
        pool.keys,
        containsAll([
          ItemId.SIMPLE_FISHING_ROD,
          ItemId.COPPER_FISHING_ROD,
          ItemId.IRON_FISHING_ROD,
          ItemId.STEEL_FISHING_ROD,
          ItemId.MITHRIL_FISHING_ROD,
        ]),
      );
      expect(pool.containsKey(ItemId.ADAMANT_FISHING_ROD), isFalse);
    });

    test('shelves the whole pool every restock', () {
      final shop = def.toEntity(EntityId.FISHING_SHOP);
      ShopService(
        inventoryService: InventoryService(),
      ).restockIfDue(shop, def, now: DateTime(2026, 1, 1), rng: Random(1));
      expect(shop.stock.length, pool.length);
    });
  });

  group('Lumber Mill', () {
    final def = shopDef(EntityId.LUMBER_MILL);

    test('shelves every log the game has, 500 of each', () {
      final shop = def.toEntity(EntityId.LUMBER_MILL);
      ShopService(
        inventoryService: InventoryService(),
      ).restockIfDue(shop, def, now: DateTime(2026, 1, 1), rng: Random(1));
      final counts = {for (final s in shop.stock) s.itemId: s.count};
      expect(counts, {
        ItemId.LOGS: 500,
        ItemId.OAK_LOGS: 500,
        ItemId.WILLOW_LOGS: 500,
        ItemId.BOG_LOGS: 500,
        ItemId.MAPLE_LOGS: 500,
        ItemId.YEW_LOGS: 500,
      });
    });
  });
}
