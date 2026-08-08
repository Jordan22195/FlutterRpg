import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';
import '../data/buff_data.dart';
import '../catalogs/item_catalog.dart';

class BuffService {
  final nullBuff = BuffItem(
    id: ItemId.NULL,
    name: "",
    value: 0,
    skillBonus: {},
    duration: Duration(seconds: 0),
  );

  List<BuffItem> getGlobalBuffs(BuffData buffState) {
    return buffState.globalBuffs.values.toList();
  }

  List<ZoneBuffItem> getZoneBuffs(BuffData buffState, ZoneId zoneId) {
    return buffState.zoneBuffs[zoneId]?.values.toList() ?? [];
  }

  /// The buff owned by [ownerEntityId] in [zoneId] — for a firepit, the fire
  /// currently burning in it.
  ZoneBuffItem? getZoneBuff(
    BuffData buffState,
    ZoneId zoneId,
    EntityId ownerEntityId,
  ) {
    return buffState.zoneBuffs[zoneId]?[ownerEntityId];
  }

  // stat bonuses from all buffs affecting the player right now: global
  // buffs plus the zone buffs of the zone the player is in. expired
  // buffs are skipped even if the expiry sweep hasn't removed them yet
  Map<SkillId, int> getBuffedStatTotal(
    BuffData buffState,
    ZoneId currentZoneId,
  ) {
    Map<SkillId, int> total = {};
    final now = DateTime.now();
    final activeBuffs = [
      ...buffState.globalBuffs.values,
      ...?buffState.zoneBuffs[currentZoneId]?.values,
    ];
    for (final buff in activeBuffs) {
      if (buff.expirationTime.isBefore(now)) continue;
      total = Util.addMap(total, buff.skillBonus);
    }

    return total;
  }

  /// Set/refresh the buff owned by [ownerEntityId] in [zoneId].
  ///
  /// An owner holds one buff at a time. Applying the same buff again extends
  /// it (adding logs to a burning fire); applying a different one replaces it
  /// outright (lighting a new kind of fire in the same firepit).
  void setZoneBuff(
    ZoneBuffItem buffItem,
    BuffData buffState,
    ZoneId zoneId,
    EntityId ownerEntityId,
  ) {
    final buffs = buffState.zoneBuffs.putIfAbsent(zoneId, () => {});

    final existing = buffs[ownerEntityId];
    if (existing != null && existing.id == buffItem.id) {
      existing.expirationTime = _extendedExpiration(
        existing,
        buffItem.duration,
      );
      return;
    }

    buffItem.zoneId = zoneId;
    buffItem.ownerEntityId = ownerEntityId;
    buffs[ownerEntityId] = buffItem;
  }

  /// Removes an owner's buff early — putting out a fire.
  void removeZoneBuff(
    BuffData buffState,
    ZoneId zoneId,
    EntityId ownerEntityId,
  ) {
    buffState.zoneBuffs[zoneId]?.remove(ownerEntityId);
  }

  // extend from the current expiration, or from now if the buff already
  // ran out but hasn't been swept yet (never extend from the past)
  DateTime _extendedExpiration(BuffItem buff, Duration duration) {
    final now = DateTime.now();
    final base = buff.expirationTime.isAfter(now) ? buff.expirationTime : now;
    return base.add(duration);
  }

  /// Add/refresh a buff.
  /// If it already exists, extends its duration.
  void addBuff(BuffItem buff, BuffData buffState) {
    if (buffState.globalBuffs.containsKey(buff.id)) {
      final existing = buffState.globalBuffs[buff.id];
      if (existing != null) {
        existing.expirationTime = _extendedExpiration(existing, buff.duration);
      }
      return;
    }
    buffState.globalBuffs[buff.id] = buff;
  }

  /// Optionally remove a buff early.
  void removeGlobalBuff(ItemId id, BuffData buffState) {
    if (buffState.globalBuffs.remove(id) != null) {}
  }

  void checkBuffExpriations(BuffData buffState) {
    checkGlobalBuffExpiration(buffState);
  }

  // Sweep burnt-out zone buffs. Returns the removed buffs so the caller can
  // react (a fire going out changes what its firepit offers).
  List<ZoneBuffItem> removeExpiredZoneBuffs(BuffData buffState) {
    final list = <ZoneBuffItem>[];
    for (final z in buffState.zoneBuffs.values) {
      final ids = z.keys.toList(growable: false);
      for (final id in ids) {
        final buff = z[id];
        if (buff != null && buff.expirationTime.isBefore(DateTime.now())) {
          list.add(buff);
          z.remove(id);
        }
      }
    }
    return list;
  }

  // Decrement and purge active buffs.
  void checkGlobalBuffExpiration(BuffData buffState) {
    if (buffState.globalBuffs.isEmpty) {
      return;
    }
    final ids = buffState.globalBuffs.keys.toList(growable: false);
    for (final id in ids) {
      final buff = buffState.globalBuffs[id];
      if (buff == null) continue;

      if (buff.expirationTime.isBefore(DateTime.now())) {
        buffState.globalBuffs.remove(id);
        continue;
      }
    }
  }
}

/*
how do zone buffs work with entities

a zone buff is owned by the entity that produced it, and is keyed by that
entity id. a fire is a buff owned by the firepit it burns in — there is no
separate fire entity to keep in sync, and no entity state to lose when
permanent entities are rebuilt from the catalog on load. the firepit renders
whatever its buff says is burning, and reverts to a bare firepit when the
buff is swept.

FiremakingSystem is what creates and extends those buffs. BuffController's
tick does the sweeping, so nothing else has to watch the clock.
*/
