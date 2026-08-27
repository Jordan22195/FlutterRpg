// ignore_for_file: constant_identifier_names

/// One ladder, used by everything that has tiers: an entity is born at a
/// rarity, and a crafted piece of equipment rolls one.
///
/// For an entity it is purely cosmetic — it colors the border drawn around
/// the portrait so a run of tiles reads at a glance. For equipment it also
/// scales the item's stats, through `rarityStatMultiplier` in
/// `items/model/equipment_item.dart`; the multiplier lives there rather
/// than on the enum because it is equipment's business, not an entity's.
///
/// The colors live with the tile that draws them
/// (`rarityBorderColor` in `widgets/item_stack_tile.dart`), so the catalog
/// stays free of Flutter painting.
enum Rarity {
  COMMON(''),
  UNCOMMON('Uncommon'),
  RARE('Rare'),
  EPIC('Epic'),
  LEGENDARY('Legendary');

  const Rarity(this.label);

  /// Display name; empty for common, which is not worth saying.
  final String label;
}
