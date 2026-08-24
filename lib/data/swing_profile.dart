/// The two rolls one of the player's swings makes against one entity, and
/// the arithmetic a batched fight does with them.
///
/// A settle cannot roll a swing at a time, so it works in expected landing
/// hits rather than expected damage. The distinction matters because the two
/// halves of a swing behave differently:
///
///   * **Hits are whole, and overkill is discarded.**
///     [EncounterService.calculateAttackDamage] caps a roll at the target's
///     remaining hitpoints, so a kill is worth the pool it emptied and never
///     more, however far past it the roll would have gone.
///   * **Misses are not whole.** They add nothing to the hits a kill needs;
///     they only make each of those hits cost more than one action.
///
/// Folding the two together into a single "average damage per action" and
/// dividing a hitpoint pool by it is what used to let one action pay for
/// several kills, back when the player out-damaged the pool.
class SwingProfile {
  /// The share of swings that land at all.
  final double hitChance;

  /// The top of the uniform 1..maxHit damage roll a landing swing makes.
  final int maxHit;

  SwingProfile({required this.hitChance, required this.maxHit});

  /// What a landing swing deals on average.
  double get damagePerHit => (1 + maxHit) / 2.0;

  /// Beyond this pool size the table is extrapolated rather than built. Its
  /// slope is flat by then - the overshoot that bends the first few entries
  /// is a fixed cost, not one that grows with the pool - so the only thing a
  /// longer table buys is the memory it sits in.
  static const int _tableLimit = 4096;

  /// E[hits] indexed by pool size, grown on demand. `_window` trails it with
  /// the running sum of the last [maxHit] entries.
  final List<double> _expected = [0.0];
  double _window = 0.0;

  /// Expected landing hits to take [hitpoints] off.
  ///
  /// Not the pool divided by [damagePerHit] and rounded up. A swing rolls
  /// uniformly in 1..maxHit, so the question is how many rolls it takes to
  /// reach the pool, and the answer sits above the mean: 5 hitpoints against
  /// a 1..9 roll is a kill 5 times in 9, which comes to 1.52 hits, not the 1
  /// that rounding up 5/5 suggests. Rounding up under-counts by a third in
  /// that range, and a settle that under-counts the cost of a kill pays out
  /// more kills than the fight earned.
  ///
  ///     E[n] = 1 + (1/maxHit) * sum over d in 1..maxHit of E[n-d]
  ///
  /// with E of nothing left to remove being 0. Always at least 1: a pool
  /// worth a fraction of a swing still takes a swing to empty.
  double hitsToRemove(int hitpoints) {
    if (hitpoints <= 0) return 0;
    if (hitpoints > _tableLimit) {
      // past the bend the curve is a straight line of slope 1/damagePerHit
      return hitsToRemove(_tableLimit) +
          (hitpoints - _tableLimit) / damagePerHit;
    }
    while (_expected.length <= hitpoints) {
      final n = _expected.length;
      _window += _expected[n - 1];
      if (n - 1 - maxHit >= 0) _window -= _expected[n - 1 - maxHit];
      _expected.add(1 + _window / maxHit);
    }
    return _expected[hitpoints];
  }

  /// The actions [hits] landing swings cost, the misses between them
  /// included. Always more than one action a hit, because a hit chance is
  /// capped below 1 - which is what keeps a batch from ever paying out more
  /// kills than it fired actions.
  double actionsForHits(double hits) => hits / hitChance;

  /// The landing swings [actions] are worth.
  double hitsForActions(int actions) => actions * hitChance;
}
