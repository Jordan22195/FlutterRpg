// ignore_for_file: constant_identifier_names

/// One ladder, used by everything that has tiers: an entity is born at a
/// rarity, and a crafted piece of equipment rolls one.
///
/// Both halves of the game read it the same way: [index] is how many rungs
/// up the Fibonacci ladder this tier sits from common. A rarity variant of
/// a monster is its archetype's rung plus that step
/// (`CombatEntityDefinition.level`), and a rolled piece of equipment is its
/// definition's rung plus the same step
/// (`EquipmentItemDefinition.budgetAt`). So uncommon is one rung, rare two,
/// epic three, legendary four — for a chicken and for a helmet alike.
///
/// It is also what colors the border drawn around a tile, so a run of them
/// reads at a glance.
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
