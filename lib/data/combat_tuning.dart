/// Combat numbers the player and the monsters share, so a fight is tuned in
/// one place and both sides move together.
library;

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
