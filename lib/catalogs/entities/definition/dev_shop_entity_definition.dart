import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/entities/definition/shop_stock_entry.dart';
import 'package:rpg/catalogs/entities/definition/shop_entity_definition.dart';

/// A shop that sells everything, for testing.
///
/// Its shelf is not a hand-written pool: it is [ItemId] itself, walked at
/// read time, so an item added to the catalog is on sale the moment its id
/// exists and no one has to remember to list it here. [stockSlots] follows
/// the pool for the same reason — the whole catalog is always on the shelf,
/// never a random tenth of it.
class DevShopEntityDefinition extends ShopEntityDefinition {
  /// How many of a stackable the shelf carries. Equipment is a unique
  /// instance rather than a count, so it stocks [_equipmentCount] pieces.
  static const int _stackableCount = 1000;
  static const int _equipmentCount = 10;

  const DevShopEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    super.priceMarkup = 1.0,
    super.restockInterval = const Duration(minutes: 1),
  }) : super(shopStockPool: const [], stockSlots: 0);

  /// Every item in the game, in catalog order.
  ///
  /// The sentinels are skipped because they are not items anybody can hold,
  /// and coins because they are what is being spent — the same two
  /// exclusions `catalog_integrity_test` asks of every shop.
  @override
  List<ShopStockEntry> get shopStockPool => [
    for (final id in ItemId.values)
      if (id != ItemId.NULL && id != ItemId.NULL_BUFF && id != ItemId.COINS)
        ShopStockEntry(
          itemId: id,
          count: id.definition is EquipmentItemDefinition
              ? _equipmentCount
              : _stackableCount,
        ),
  ];

  /// The whole pool, every restock.
  @override
  int get stockSlots => shopStockPool.length;

  @override
  DevShopEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    double? priceMarkup,
    Duration? restockInterval,
    int? stockSlots,
    List<ShopStockEntry>? shopStockPool,
  }) {
    // stockSlots and shopStockPool are derived here, so they are ignored
    return DevShopEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      priceMarkup: priceMarkup ?? this.priceMarkup,
      restockInterval: restockInterval ?? this.restockInterval,
    );
  }
}
