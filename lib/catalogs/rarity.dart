// ignore_for_file: constant_identifier_names

/// One ladder, used by everything that has tiers: an entity is born at a
/// rarity, and a crafted piece of equipment rolls one.
///
/// The two halves of the game read it differently, on purpose.
///
/// A monster's rarity is a step up the Fibonacci ladder: [index] is how
/// many rungs above common the variant sits, so an epic chicken is a
/// genuinely different monster three rungs along
/// (`CombatEntityDefinition.level`).
///
/// A piece of equipment's rarity is a multiplier on the stat budget its
/// definition already carries: [statMultiplier] scales it, and
/// [minStatBonus] guarantees the tier is worth something on small pieces
/// where a percentage would round away to nothing
/// (`EquipmentItemDefinition.budgetAt`).
///
/// It is also what colors the border drawn around a tile, so a run of them
/// reads at a glance.
///
/// The colors live with the tile that draws them
/// (`rarityBorderColor` in `widgets/item_stack_tile.dart`), so the catalog
/// stays free of Flutter painting.
enum Rarity {
  COMMON('', 1.0, 0),
  UNCOMMON('Uncommon', 1.2, 1),
  RARE('Rare', 1.4, 2),
  EPIC('Epic', 1.6, 3),
  LEGENDARY('Legendary', 1.8, 4);

  const Rarity(this.label, this.statMultiplier, this.minStatBonus);

  /// Display name; empty for common, which is not worth saying.
  final String label;

  /// What this tier multiplies a piece of equipment's common stat budget
  /// by. Common is 1.0, and every rung adds another fifth.
  final double statMultiplier;

  /// The least this tier may add to a piece's total stats, in whole
  /// points. A low-rung piece has a budget small enough that 1.2x rounds
  /// back to where it started; this is the floor that keeps an uncommon
  /// strictly better than the common it was rolled against.
  final int minStatBonus;
}
