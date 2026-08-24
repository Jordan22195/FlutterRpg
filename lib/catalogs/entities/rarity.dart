// ignore_for_file: constant_identifier_names

/// How rare an entity is. Purely cosmetic: it colors the border drawn
/// around the entity's portrait so a run of tiles reads at a glance, in the
/// same ladder crafted equipment uses for [ItemQuality] — green, blue,
/// purple, orange, with common left uncolored.
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
