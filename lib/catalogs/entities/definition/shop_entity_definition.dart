import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/entities/definition/shop_stock_entry.dart';
import 'package:rpg/catalogs/entities/model/shop_entity.dart';
import 'package:rpg/catalogs/entities/definition/entity_definition.dart';

class ShopEntityDefinition extends EntityDefinition {
  /// Buy price multiplier applied to an item's value (1.25 = 25% over).
  final double priceMarkup;

  /// How often the shop rerolls its stock.
  final Duration restockInterval;

  /// How many random item stacks a restock puts on the shelf.
  final int stockSlots;

  /// List of items the shop restocks from
  final List<ShopStockEntry> shopStockPool;

  const ShopEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    required this.shopStockPool,
    this.priceMarkup = 1.25,
    this.restockInterval = const Duration(hours: 6),
    this.stockSlots = 10,
  });

  @override
  ShopEntity toEntity(EntityId id) => ShopEntity(id: id);

  @override
  ShopEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    double? priceMarkup,
    Duration? restockInterval,
    int? stockSlots,
    List<ShopStockEntry>? shopStockPool,
  }) {
    return ShopEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      priceMarkup: priceMarkup ?? this.priceMarkup,
      restockInterval: restockInterval ?? this.restockInterval,
      stockSlots: stockSlots ?? this.stockSlots,
      shopStockPool: shopStockPool ?? this.shopStockPool,
    );
  }
}
