/// How a dungeon is reached. A dungeon is a list of floors; clearing a floor
/// unlocks it permanently, and the floor you start keeps looping until you
/// start something else.
/// - [TRANSIENT]: discovered while exploring; free; the entrance stays in
///   the zone once found.
/// - [ZONE]: a permanent entrance inside a zone; free.
/// - [LANDMARK]: shown on the world map; the first floor costs a key the
///   first time it is started, and never again.
///
/// Orthogonal to what a floor does — every dungeon's floors repeat and
/// unlock the same way. This is only how you get there.
enum DungeonType { TRANSIENT, ZONE, LANDMARK }
