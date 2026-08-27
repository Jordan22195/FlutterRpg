// ignore_for_file: constant_identifier_names

import 'dart:math';

/// How a combat entity spends its level budget across attack, defence and
/// hitpoints. A combat entity is defined by a level (how much stat it gets)
/// and a [CombatType] (how that stat is split), never by hand-written
/// numbers — see `CombatEntityDefinition`.
///
/// The three weights are a RATIO over their own total, not absolute
/// amounts: only each weight's share of [totalWeight] matters, so a new
/// type may use any scale it likes. Nothing here may assume the weights
/// sum to 10, even though every type below happens to.
///
/// Given `ratio = weight / totalWeight`:
///
///     attack     = ratio_att * level * 3
///     defence    = ratio_def * level * 3
///     hitpoints  = ratio_hp  * level * 5 * 3
///     level      = (attack + defence + hitpoints / 5) / 3
///
/// The ×3 is what closes the loop: the ratios sum to 1, so
/// `att + def + hp/5` is always `3 * level` and [levelOf] inverts the
/// three stats exactly, whatever the weight total. The one exception is
/// the floor below — a stat whose true share rounds to 0 is bumped to 1,
/// which can read back one level high. No type here is lopsided enough
/// for that; a very extreme new one at level 1 could be.
///
/// Unlike `EntityId`, these names are never persisted — definitions are
/// design-time only — so a type may be freely renamed or removed.
enum CombatType {
  ROCK_CRAB(1, 1, 8, 'Rock Crab'),
  GLASS_CANNON(8, 1, 1, 'Glass Cannon'),
  SHELL(1, 8, 1, 'Shell'),

  BALANCE(3, 3, 4, 'Balanced'),
  PLATE_TANK(1, 5, 4, 'Plate Tank'),
  LEATHER_TANK(2, 4, 4, 'Leather Tank'),

  CLOTH_DPS(6, 2, 2, 'Cloth DPS'),
  LEATHER_DPS(5, 3, 2, 'Leather DPS'),
  PLATE_DPS(4, 4, 2, 'Plate DPS');

  const CombatType(
    this.attackWeight,
    this.defenceWeight,
    this.hitpointWeight,
    this.label,
  );

  final int attackWeight;
  final int defenceWeight;
  final int hitpointWeight;

  /// Display name, for anything that wants to say what shape a fight is.
  final String label;

  /// The scale the three weights are read against.
  int get totalWeight => attackWeight + defenceWeight + hitpointWeight;

  int attackAt(int level) => combatAttackAt(level, attackWeight, totalWeight);

  int defenceAt(int level) =>
      combatDefenceAt(level, defenceWeight, totalWeight);

  int hitpointsAt(int level) =>
      combatHitpointsAt(level, hitpointWeight, totalWeight);

  /// The level whose budget produces these stats — the inverse of the
  /// three formulas above.
  static int levelOf({
    required int attack,
    required int defence,
    required int hitpoints,
  }) => ((attack + defence + hitpoints / 5) / 3).round();
}

// The per-level math, taking the weights explicitly so it can be exercised
// against weight totals no enum constant happens to use.

int combatAttackAt(int level, int weight, int totalWeight) =>
    _stat(level * 3 * weight, totalWeight);

int combatDefenceAt(int level, int weight, int totalWeight) =>
    _stat(level * 3 * weight, totalWeight);

int combatHitpointsAt(int level, int weight, int totalWeight) =>
    _stat(level * 3 * 5 * weight, totalWeight);

/// Rounded share of the budget, floored at 1 so nothing lands on a stat of
/// zero at low levels.
int _stat(int weighted, int totalWeight) =>
    max(1, (weighted / totalWeight).round());
