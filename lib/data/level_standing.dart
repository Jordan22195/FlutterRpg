/// How an entity's level reads against the player's: well above it, about
/// even with it, or well below it.
enum LevelStanding {
  hard,
  even,
  easy;

  /// [entityLevel] read against [playerLevel], both on the same scale — a
  /// creature's combat level against the player's, a node's level against
  /// the skill that works it.
  ///
  /// The levels climb a Fibonacci ladder, so the gap is read as a ratio: half
  /// as high again or more is hard, two-thirds or less is easy. A gap under
  /// two levels is always even, so the first rungs (1 against 2) don't read
  /// as a wall.
  static LevelStanding of(int entityLevel, int playerLevel) {
    final player = playerLevel < 1 ? 1 : playerLevel;
    final gap = entityLevel - player;
    if (gap.abs() < 2) return even;
    final ratio = entityLevel / player;
    if (ratio >= 1.5) return hard;
    if (ratio <= 2 / 3) return easy;
    return even;
  }
}
