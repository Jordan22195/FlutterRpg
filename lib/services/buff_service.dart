import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';
import '../data/active_buff.dart';
import '../data/buff_data.dart';
import '../catalogs/items/items.dart';

class BuffService {
  final nullBuff = ItemId.NULL_BUFF.build() as BuffItem;

  List<BuffItem> getGlobalBuffs(BuffData buffState) {
    return buffState.globalBuffs.values.toList();
  }

  /// The global buff [id] is currently putting up, or null when none is. A
  /// buff that has run out but not been swept yet reads as null, the way
  /// [FiremakingSystem.activeFire] treats a fire a moment past its end.
  BuffItem? getGlobalBuff(BuffData buffState, ItemId id, {DateTime? at}) {
    final buff = buffState.globalBuffs[id];
    if (buff == null) return null;
    if (!buff.expirationTime.isAfter(at ?? DateTime.now())) return null;
    return buff;
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

  // stat bonuses from all buffs affecting the player at [at], defaulting to
  // now: global buffs plus the zone buffs of the zone the player is in.
  // expired buffs are skipped even if the expiry sweep hasn't removed them
  // yet.
  //
  // [at] is what an offline settle asks with. It replays the gap segment by
  // segment, and a fire that burnt out an hour into the gap was buffing the
  // player for the segments before that - reading the wall clock instead
  // would settle the whole gap as if nothing had been lit.
  Map<SkillId, int> getBuffedStatTotal(
    BuffData buffState,
    ZoneId currentZoneId, {
    DateTime? at,
  }) {
    Map<SkillId, int> total = {};
    final now = at ?? DateTime.now();
    // fires don't stack: of every fire in the zone buffing a stat, only the
    // strongest counts, so a second fire is for a second stat
    final bestFire = <SkillId, int>{};
    final activeBuffs = <BuffItem>[...buffState.globalBuffs.values];
    for (final buff in [...?buffState.zoneBuffs[currentZoneId]?.values]) {
      if (buff is! FireItem) {
        activeBuffs.add(buff);
        continue;
      }
      for (final entry in buff.bonusAt(now).entries) {
        final best = bestFire[entry.key];
        if (best == null || entry.value > best) {
          bestFire[entry.key] = entry.value;
        }
      }
    }
    for (final buff in activeBuffs) {
      total = Util.addMap(total, buff.bonusAt(now));
    }

    return Util.addMap(total, bestFire);
  }

  /// Every buff on the player at [at] (defaulting to now), the global ones
  /// first and then [currentZoneId]'s, each with what it is lending. Reads
  /// the same rule [getBuffedStatTotal] adds up by: a fire beaten on a stat
  /// by another fire in the zone has that effect marked uncounted, the
  /// first of two equal fires being the one that counts. Fires giving
  /// nothing at all go to the back. Expired but unswept buffs are left out.
  List<ActiveBuff> activeBuffs(
    BuffData buffState,
    ZoneId currentZoneId, {
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final global = [
      for (final buff in buffState.globalBuffs.values)
        if (buff.expirationTime.isAfter(now)) buff,
    ];
    final zone = [
      for (final buff in [...?buffState.zoneBuffs[currentZoneId]?.values])
        if (buff.expirationTime.isAfter(now)) buff,
    ];

    // which fire is the one counting on each stat
    final bestFire = <SkillId, FireItem>{};
    for (final buff in zone.whereType<FireItem>()) {
      for (final entry in buff.bonusAt(now).entries) {
        final best = bestFire[entry.key];
        if (best == null || entry.value > (best.bonusAt(now)[entry.key] ?? 0)) {
          bestFire[entry.key] = buff;
        }
      }
    }

    ActiveBuff view(BuffItem buff, {required bool zoneBuff}) {
      final effects = [
        for (final entry in buff.bonusAt(now).entries)
          BuffEffect(
            stat: entry.key,
            amount: entry.value,
            counted: buff is! FireItem || identical(bestFire[entry.key], buff),
          ),
      ]..sort((a, b) => b.amount.compareTo(a.amount));
      return ActiveBuff(
        id: buff.id,
        zoneBuff: zoneBuff,
        endsAt: buff.expirationTime,
        duration: buff.duration,
        effects: effects,
      );
    }

    final views = [
      for (final buff in global) view(buff, zoneBuff: false),
      for (final buff in zone) view(buff, zoneBuff: true),
    ];
    return [
      ...views.where((v) => !v.outranked),
      ...views.where((v) => v.outranked),
    ];
  }

  /// Set/refresh the buff owned by [ownerEntityId] in [zoneId].
  ///
  /// An owner holds one buff at a time. Applying the same buff again extends
  /// it (adding logs to a burning fire); applying a different one replaces it
  /// outright (lighting a new kind of fire in the same firepit).
  ///
  /// [at] is the instant the buff is applied at, defaulting to now. An
  /// offline settle relights a fire at the segment it is replaying, and an
  /// extension has to be measured from there rather than from the wall
  /// clock hours later.
  void setZoneBuff(
    ZoneBuffItem buffItem,
    BuffData buffState,
    ZoneId zoneId,
    EntityId ownerEntityId, {
    DateTime? at,
  }) {
    final buffs = buffState.zoneBuffs.putIfAbsent(zoneId, () => {});

    final existing = buffs[ownerEntityId];
    if (existing != null && existing.id == buffItem.id) {
      existing.expirationTime = _extendedExpiration(
        existing,
        buffItem.duration,
        at: at,
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
  DateTime _extendedExpiration(
    BuffItem buff,
    Duration duration, {
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final base = buff.expirationTime.isAfter(now) ? buff.expirationTime : now;
    return base.add(duration);
  }

  /// Add/refresh a buff.
  /// If it already exists, extends its duration - measured from [at], which
  /// defaults to now and is the replayed instant for an offline settle.
  void addBuff(BuffItem buff, BuffData buffState, {DateTime? at}) {
    if (buffState.globalBuffs.containsKey(buff.id)) {
      final existing = buffState.globalBuffs[buff.id];
      if (existing != null) {
        existing.expirationTime = _extendedExpiration(
          existing,
          buff.duration,
          at: at,
        );
      }
      return;
    }
    buffState.globalBuffs[buff.id] = buff;
  }

  /// Optionally remove a buff early.
  void removeGlobalBuff(ItemId id, BuffData buffState) {
    if (buffState.globalBuffs.remove(id) != null) {}
  }

  void checkBuffExpriations(BuffData buffState, {DateTime? at}) {
    checkGlobalBuffExpiration(buffState, at: at);
  }

  /// When the next buff runs out, counting the global buffs and [zoneId]'s —
  /// the same set [getBuffedStatTotal] reads, because those are the ones
  /// whose expiry can change what an action produces.
  ///
  /// Null when nothing is burning. Strictly [after], so a settle asking from
  /// the instant it just swept never gets the same answer twice and stalls.
  DateTime? nextExpiration(
    BuffData buffState,
    ZoneId zoneId, {
    required DateTime after,
  }) {
    DateTime? next;
    final buffs = [
      ...buffState.globalBuffs.values,
      ...?buffState.zoneBuffs[zoneId]?.values,
    ];
    // a fire's reagents run out on their own clocks, and each of them
    // moves the stats as much as the fire going out does
    for (final buff in buffs) {
      for (final time in buff.changeTimes) {
        if (!time.isAfter(after)) continue;
        if (next == null || time.isBefore(next)) next = time;
      }
    }
    return next;
  }

  // Sweep burnt-out zone buffs. Returns the removed buffs so the caller can
  // react (a fire going out changes what its firepit offers).
  //
  // [at] defaults to now. An offline settle sweeps at the end of every
  // segment with that segment's own instant, so a fire that burnt out an
  // hour into the gap is gone for the rest of the replay and nothing after
  // it cooks. A buff expiring exactly at [at] goes with it: a segment ends
  // on the expiry it was cut at, and leaving that buff behind would hand
  // the next segment a whole fire's worth of free cooking.
  List<ZoneBuffItem> removeExpiredZoneBuffs(
    BuffData buffState, {
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final list = <ZoneBuffItem>[];
    for (final z in buffState.zoneBuffs.values) {
      final ids = z.keys.toList(growable: false);
      for (final id in ids) {
        final buff = z[id];
        if (buff != null && !buff.expirationTime.isAfter(now)) {
          list.add(buff);
          z.remove(id);
        }
      }
    }
    return list;
  }

  // Decrement and purge active buffs. [at] carries the same meaning it does
  // in [removeExpiredZoneBuffs].
  void checkGlobalBuffExpiration(BuffData buffState, {DateTime? at}) {
    if (buffState.globalBuffs.isEmpty) {
      return;
    }
    final now = at ?? DateTime.now();
    final ids = buffState.globalBuffs.keys.toList(growable: false);
    for (final id in ids) {
      final buff = buffState.globalBuffs[id];
      if (buff == null) continue;

      if (!buff.expirationTime.isAfter(now)) {
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
tick does the sweeping while the game is live; an offline settle takes the
sweep over for the stretch it is replaying, so that a buff which burnt out
mid-gap is still readable for the segment it was burning in.
*/
