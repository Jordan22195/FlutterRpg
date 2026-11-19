import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../catalogs/zones/zones.dart';
import '../data/buff_data.dart';
import '../services/buff_service.dart';

/// Fires, and the firepits they burn in.
///
/// A fire is not an entity — it is a [FireItem] zone buff keyed to the firepit
/// that owns it. That means a firepit holds exactly one fire at a time, the
/// fire slots in a zone (see [FireSlots]) burn independently, and a fire's remaining time survives
/// save/load without any entity state to keep in sync.
class FiremakingSystem {
  final BuffService _buffService;

  FiremakingSystem({required BuffService buffService})
    : _buffService = buffService;

  /// The fire burning in [firepitId] at [at], or null when it is cold. A
  /// non-fire zone buff owned by the same entity is not a fire and reads as
  /// null.
  ///
  /// [at] defaults to now. An offline settle replays the gap segment by
  /// segment and asks at the instant of the segment, not at the wall clock,
  /// which by then is hours past the stretch being settled.
  FireItem? activeFire(
    EntityId firepitId,
    ZoneId zoneId,
    BuffData buffState, {
    DateTime? at,
  }) {
    final buff = _buffService.getZoneBuff(buffState, zoneId, firepitId);
    if (buff is! FireItem) return null;
    // the sweep runs on a 1s tick, so a fire can be a moment past its end
    // while still in the map. treat it as out.
    if (buff.expirationTime.isBefore(at ?? DateTime.now())) return null;
    return buff;
  }

  /// The fire slots burning in [zoneId] at [at], in slot order.
  List<EntityId> litSlots(ZoneId zoneId, BuffData buffState, {DateTime? at}) =>
      [
        for (final slot in FireSlots.slots)
          if (activeFire(slot, zoneId, buffState, at: at) != null) slot,
      ];

  /// Whether a fire may be laid in [firepitId]: one already burns there, or
  /// the zone has fewer than [cap] fires going (see [FireSlots.capFor]).
  bool canLight(
    EntityId firepitId,
    ZoneId zoneId,
    BuffData buffState,
    int cap, {
    DateTime? at,
  }) {
    if (activeFire(firepitId, zoneId, buffState, at: at) != null) return true;
    return litSlots(zoneId, buffState, at: at).length < cap;
  }

  /// The slot a new fire in [zoneId] goes in: the first cold one, or null
  /// when [cap] fires are already burning.
  EntityId? freeSlot(
    ZoneId zoneId,
    BuffData buffState,
    int cap, {
    DateTime? at,
  }) {
    final lit = litSlots(zoneId, buffState, at: at);
    if (lit.length >= cap) return null;
    for (final slot in FireSlots.slots) {
      if (!lit.contains(slot)) return slot;
    }
    return null;
  }

  /// Whether cooking recipes are available at [firepitId] at [at],
  /// defaulting to now.
  bool canCookAt(
    EntityId firepitId,
    ZoneId zoneId,
    BuffData buffState, {
    DateTime? at,
  }) {
    return activeFire(firepitId, zoneId, buffState, at: at)?.canCook ?? false;
  }

  /// Lights [fireId] in [firepitId]: adds to the fire already burning when it
  /// is the same kind, and replaces it outright when it is not. This is the
  /// whole "add more logs, or start a different fire" rule.
  ///
  /// [count] is how many lays go on at once, which is how an offline stretch
  /// of firemaking settles: n crafts are n lays however they are applied.
  /// Each lay adds its burn time (see [FireItem.addLays]). There is no cap.
  ///
  /// [burnScale] is how much longer it burns for the firemaker's level (see
  /// [FireItem.burnScale]).
  ///
  /// [at] is the instant the fire is lit at, defaulting to now. A cook loop
  /// settling time away relights at the segment it is replaying, and a fire
  /// stamped from the wall clock instead would read as burning until long
  /// after the gap, cooking the whole of it for free.
  void lightOrExtend(
    ItemId fireId,
    EntityId firepitId,
    ZoneId zoneId,
    BuffData buffState, {
    int count = 1,
    DateTime? at,
    double burnScale = 1,
  }) {
    if (count <= 0) return;
    final now = at ?? DateTime.now();

    // the same fire, still burning: the lays go on it, reagents and all
    final existing = _buffService.getZoneBuff(buffState, zoneId, firepitId);
    if (existing is FireItem &&
        existing.id == fireId &&
        existing.expirationTime.isAfter(now)) {
      existing.addLays(count, now, scale: burnScale);
      return;
    }

    final fire = fireId.build();
    if (fire is! FireItem) return;
    fire.lightAt(now, lays: count, scale: burnScale);
    // a different fire, or one that has gone out, is replaced outright:
    // cleared first, since the buff service would otherwise extend a spent
    // fire of the same kind rather than light this one
    _buffService.removeZoneBuff(buffState, zoneId, firepitId);
    _buffService.setZoneBuff(fire, buffState, zoneId, firepitId, at: now);
  }

  /// Puts the fire out, ending its buff immediately.
  void extinguish(EntityId firepitId, ZoneId zoneId, BuffData buffState) {
    _buffService.removeZoneBuff(buffState, zoneId, firepitId);
  }
}
