/// Combat numbers the player and the monsters share, so a fight is tuned in
/// one place and both sides move together.
library;

import 'dart:math';

import 'skill_data.dart';

/// Hitpoints one point of the hitpoints stat is worth. A monster's
/// hitpoint weight and the player's Hitpoints level are both stat points;
/// this turns either into a pool of health. Raising it makes every fight
/// longer on both sides at once.
const int hitpointsPerStatPoint = 3;

/// The player's health pool for these stat totals: their Hitpoints stat —
/// level, gear and buffs together — times [hitpointsPerStatPoint].
int maxHitpointsFrom(Map<SkillId, int> stats) =>
    (stats[SkillId.HITPOINTS] ?? 1) * hitpointsPerStatPoint;

// ---- the swing: weapon damage times the attack multiplier ----

/// The Attack (or gathering skill) that doubles a swing's damage. The
/// multiplier is `1 + sqrt(attack / this)`: strongest early (1.32× at 1,
/// 2× at this value) and flattening late (3× at 40, 4.15× at 99), so it
/// does not run away stacked on a weapon's own tier.
const double attackForDoubleDamage = 10;

/// What an attacking stat multiplies a weapon's damage by.
double attackMultiplier(int attack) =>
    1 + sqrt((attack < 0 ? 0 : attack) / attackForDoubleDamage);

/// A weapon's damage per second of swing, by the rung it is made from:
/// stone (-1), copper (0), iron, steel, mithril, adamant, rune, dragon (6)
/// and on. A gentle ladder rather than the fib one, because the attack
/// multiplier already grows with level; fib damage on top of it compounds
/// to a late game far faster than today's. Calibrated so a 1h sword in the
/// fast stance keeps the pace of the old dagger.
const List<double> weaponDamageByRung = [
  2, 3, 4, 5, 6, 7, 9, 10, 12, 14, 16, //
];

/// The rung [weaponDamageByRung] starts at.
const int weaponDamageFirstRung = -1;

/// The damage per second of swing a weapon made from [rung] carries.
double weaponDamageForRung(int rung) {
  final index = (rung - weaponDamageFirstRung).clamp(
    0,
    weaponDamageByRung.length - 1,
  );
  return weaponDamageByRung[index];
}

/// Tools hit nodes, not monsters: an axe or pickaxe carries this share of a
/// weapon's damage on the same rung, which keeps gathering at the pace it
/// had before swings carried damage.
const double toolDamageScale = 0.5;

/// What a bare-handed swing deals before the attack multiplier.
const double unarmedDamage = 2;

/// How much of a stance's boost a swing gets when nothing is equipped to
/// set it — the middle of the weapon types'.
const double unarmedAffinity = 0.75;
