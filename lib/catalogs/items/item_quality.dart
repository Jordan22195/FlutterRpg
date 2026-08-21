/// Quality tiers for crafted equipment. Higher tiers multiply the item's
/// base stats. Crafting rolls a quality; higher crafting levels raise the
/// odds of the upper tiers.
enum ItemQuality {
  COMMON(1.0, ''),
  UNCOMMON(1.1, 'Uncommon'),
  RARE(1.2, 'Rare'),
  EPIC(1.3, 'Epic'),
  LEGENDARY(1.5, 'Legendary');

  const ItemQuality(this.statMultiplier, this.label);

  final double statMultiplier;

  /// Display prefix; empty for common.
  final String label;
}
