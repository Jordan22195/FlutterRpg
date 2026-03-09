import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/services/world_service.dart';
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

  Map<SkillId, int> getBuffedStatTotal(BuffData buffState) {
    Map<SkillId, int> total = {};
    for (final buff in buffState.globalBuffs.values) {
      total = Util.addMap(total, buff.skillBonus) as Map<SkillId, int>;
    }

    return total;
  }

  /// Set/refresh the campfire buff.
  /// If the same buff is already active, extends its duration.
  void setZoneBuff(BuffItem buffItem, BuffData buffState, ZoneId zoneId) {
    if (!buffState.zoneBuffs.containsKey(zoneId)) {
      buffState.zoneBuffs[zoneId] = {};
    }
    final buffs = buffState.zoneBuffs[zoneId] ?? {};
    if (buffs.containsKey(buffItem.id)) {
      final buff = buffs[buffItem.id] ?? nullBuff;
      buff.expirationTime = buff.expirationTime.add(buffItem.duration);
      return;
    }
    buffs[buffItem.id] = buffItem as ZoneBuffItem;
  }

  /// Add/refresh a buff.
  /// If it already exists, extends its duration.
  void addBuff(BuffItem buff, BuffData buffState) {
    if (buffState.globalBuffs.containsKey(buff.id)) {
      final existing = buffState.globalBuffs[buff.id];
      if (existing != null) {
        existing.expirationTime = existing.expirationTime.add(buff.duration);
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

  // Decrement campfire buff.
  // If it just expired, normalize the ID to NULL (keeps the name).
  // return list of removed buffs so zone buff system can remove
  // associated enitities from world state
  List<ZoneBuffItem> removeExpiredZoneBuffs(BuffData buffState) {
    final list = [] as List<ZoneBuffItem>;
    for (final z in buffState.zoneBuffs.values) {
      for (final b in z.entries) {
        if (b.value.expirationTime.isBefore(DateTime.now())) {
          list.add(b.value);
          z.remove(b.key);
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
how do zone buffs work with entites

a)
buff data  controls life time of entity
entity buff item definition has a reference to the associated 
entity id
a new system called zone buff system would control it. 
on creation of buff create a new entity and add it to the zone.
the buff item has a reference to zone id and entity id. when the buff expires
the system removes the entity from the zone and removes the buff.

scenarios
-buffs createdvon exploartion like animals
you need the reverse mapping, an entity to a buff.
explore drops buff entity with buff item id. need to trigger 
creation of new buff item. would need a system to tie it togeather.
loke explore system. 
then zone buff system manages the lifetime of it.
-buff created on crafting like campfire
crafting creates the buff and entity follows. how to pass from crafting system to zone buff system?
- a new system? special firemaking system to create the buffs.

zone buff system manages the lifespan - runs on tick from the controller

can the new campfire system extend the existing crafting system?
its not that much code. i can just put in the crafting system

*/

class ZoneBuffSystem {
  final WorldService _worldService;
  final BuffService _buffService;

  ZoneBuffSystem({
    required WorldService worldService,
    required BuffService buffService,
  }) : _worldService = worldService,
       _buffService = buffService;

  void updateZoneBuffs(BuffData buffState, WorldData worldState) {
    //check the duration of the zone buffs
    final expiredBuffs = _buffService.removeExpiredZoneBuffs(buffState);

    //if buffs are expired, remove associated entity from the world
    for (final b in expiredBuffs) {
      _worldService.removeEntityFromZone(b.entityId, b.zoneId, worldState);
    }
  }
}
