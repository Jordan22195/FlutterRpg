import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../catalogs/zones/zones.dart';
import '../data/buff_data.dart';
import '../services/buff_service.dart';

/// Fires, and the firepits they burn in.
///
/// A fire is not an entity — it is a [FireItem] zone buff keyed to the firepit
/// that owns it. That means a firepit holds exactly one fire at a time, two
/// firepits in a zone burn independently, and a fire's remaining time survives
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
  /// [count] lights the same fire that many times at once, which is how an
  /// offline stretch of firemaking settles: burn time is what a fire craft
  /// pays out, so n crafts are worth n durations however they are applied.
  void lightOrExtend(
    ItemId fireId,
    EntityId firepitId,
    ZoneId zoneId,
    BuffData buffState, {
    int count = 1,
  }) {
    if (count <= 0) return;
    final fire = fireId.build();
    if (fire is! FireItem) return;

    // this instance is one application of the fire, so a batched one is
    // worth the whole batch's burn time - both when it extends the fire
    // already burning and when it replaces a different one
    if (count > 1) {
      fire.duration = fire.duration * count;
      fire.expirationTime = DateTime.now().add(fire.duration);
    }

    _buffService.setZoneBuff(fire, buffState, zoneId, firepitId);
  }

  /// Puts the fire out, ending its buff immediately.
  void extinguish(EntityId firepitId, ZoneId zoneId, BuffData buffState) {
    _buffService.removeZoneBuff(buffState, zoneId, firepitId);
  }
}
