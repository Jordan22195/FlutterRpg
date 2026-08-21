/// How a dungeon is reached, and what leaving it costs. A dungeon is a list
/// of cards worked through in order; a run lives only while you stay in the
/// dungeon, and every type resets its run on leave.
/// - [TRANSIENT]: discovered while exploring; free; cards are one-shot.
///   Leaving consumes the entrance — the dungeon is gone from the zone.
/// - [ZONE]: a permanent entrance inside a zone; free; cards are
///   repeatable, so a cleared card can be re-tapped to farm it.
/// - [LANDMARK]: shown on the world map; the first card costs a key; cards
///   are one-shot. Leaving spends the run, so re-entry costs another key.
enum DungeonType { TRANSIENT, ZONE, LANDMARK }
