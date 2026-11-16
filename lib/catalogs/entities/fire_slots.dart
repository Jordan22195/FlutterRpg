import 'entity_id.dart';

/// The fire slots a zone can burn fires in.
///
/// A zone that lists [EntityId.FIREPIT] among its permanent entities is a
/// place fires can be lit; it holds every slot here, and how many of them
/// may burn at once is the firemaker's [capFor]. A slot with nothing burning
/// is not shown as a place - the zone offers "Light a fire" instead.
///
/// Each slot is its own [EntityId] because fires and the crafting picks made
/// at them are keyed by entity id. [EntityId.FIREPIT] is slot 1, so a fire
/// saved before slots existed burns on in the first one.
class FireSlots {
  FireSlots._();

  static const List<EntityId> slots = [
    EntityId.FIREPIT,
    EntityId.FIREPIT_2,
    EntityId.FIREPIT_3,
    EntityId.FIREPIT_4,
    EntityId.FIREPIT_5,
  ];

  /// The Firemaking level each slot opens at, slot by slot: Fibonacci, like
  /// every other fire number.
  static const List<int> capLevels = [1, 13, 34, 55, 89];

  static bool isFireSlot(EntityId id) => slots.contains(id);

  /// How many fires may burn at once in any one zone at [firemakingLevel].
  static int capFor(int firemakingLevel) {
    var cap = 0;
    for (final level in capLevels) {
      if (firemakingLevel >= level) cap++;
    }
    // a level below 1 still has the first fire
    return cap < 1 ? 1 : cap;
  }

  /// The level the next fire opens at past [firemakingLevel], or null at
  /// the top.
  static int? nextCapLevel(int firemakingLevel) {
    for (final level in capLevels) {
      if (firemakingLevel < level) return level;
    }
    return null;
  }

  /// [ids] with [EntityId.FIREPIT] standing for every slot.
  static List<EntityId> expand(List<EntityId> ids) => [
    for (final id in ids)
      if (id == EntityId.FIREPIT) ...slots else id,
  ];
}
