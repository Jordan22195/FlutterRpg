// ignore_for_file: constant_identifier_names

/// One ladder, used by everything that has tiers: an entity is born at a
/// rarity, and a crafted piece of equipment rolls one.
///
/// The two halves of the game read it differently, on purpose.
///
/// A monster's rarity is cosmetic: it picks the border its portrait is
/// drawn with and nothing else. Its level is its own rung
/// (`CombatEntityDefinition.fibLevel`).
///
/// A piece of gear's rarity splits into two halves of one budget. The
/// primary half — attack, defence, or a skilling piece's skill — is the
/// material's budget scaled by [primaryMultiplier]; the secondary half is
/// [secondaryRolls] separate rolls, each worth a fifth of that same budget
/// and each landing on one core stat. A legendary can put all four on one
/// stat or spread them across four (`EquipmentItemDefinition.budgetAt`,
/// `EquipmentItem.secondaryRolls`).
///
/// Jewellery is the exception: it keeps the older ladder, a single
/// multiplier on the whole budget ([statMultiplier], floored by
/// [minStatBonus]).
///
/// It is also what colors the border drawn around a tile, so a run of them
/// reads at a glance.
///
/// The colors live with the tile that draws them
/// (`rarityBorderColor` in `widgets/item_stack_tile.dart`), so the catalog
/// stays free of Flutter painting.
enum Rarity {
  /// Below the ladder: worthless byproducts (burnt food, an old boot).
  /// Only items sit here; nothing rolls it and nothing raises into it.
  JUNK('Junk', 1.0, 0, 1.0, 0, 0),
  COMMON('', 1.0, 0, 1.0, 0, 0),
  UNCOMMON('Uncommon', 1.2, 1, 1.0, 0, 1),
  RARE('Rare', 1.4, 2, 1.2, 1, 2),
  EPIC('Epic', 1.6, 3, 1.4, 2, 3),
  LEGENDARY('Legendary', 1.8, 4, 1.6, 3, 4);

  const Rarity(
    this.label,
    this.statMultiplier,
    this.minStatBonus,
    this.primaryMultiplier,
    this.minPrimaryBonus,
    this.secondaryRolls,
  );

  /// Display name; empty for common, which is not worth saying.
  final String label;

  /// Jewellery's ladder: what this tier multiplies a piece of jewellery's
  /// common budget by. Common is 1.0, and every rung adds another fifth.
  /// Everything else worn reads [primaryMultiplier] and [secondaryRolls].
  final double statMultiplier;

  /// Jewellery's floor: the least this tier may add to the piece's total,
  /// in whole points, so a low rung where 1.2x rounds away still moves.
  final int minStatBonus;

  /// What this tier multiplies a piece of gear's primary budget by — its
  /// attack, defence or skill, and a weapon's damage. Uncommon pays its
  /// step in a secondary roll instead, so it sits level with common here.
  final double primaryMultiplier;

  /// The least this tier adds to a piece's primary stats over common, in
  /// whole points, so a low rung where 1.2x rounds away still moves.
  final int minPrimaryBonus;

  /// How many core-stat rolls a piece of gear at this tier carries, each
  /// worth [secondaryRollShare] of its material budget. Rolled per piece.
  final int secondaryRolls;

  /// The share of a piece's material budget one secondary roll is worth.
  static const double secondaryRollShare = 0.2;

  /// How many rungs above common this tier sits: common is 0, legendary 4,
  /// and junk -1. Read this, not [index], for anything that scales with
  /// the ladder, so junk sitting below common shifts nothing.
  int get rung => index - COMMON.index;

  /// The tiers something can roll or be raised through, common to
  /// legendary; junk is left out.
  static final List<Rarity> ladder = values.sublist(COMMON.index);

  /// This rarity [steps] rungs further up, stopping at legendary.
  Rarity raisedBy(int steps) =>
      Rarity.values[(index + steps).clamp(0, Rarity.values.length - 1)];
}
