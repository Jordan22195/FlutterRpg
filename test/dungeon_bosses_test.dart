import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';

// Every dungeon floor builds to one boss: its last monster, and nothing but
// a boss stands there. A boss is its own entity, so it is never also a
// regular somewhere — on another floor or out in a zone.
void main() {
  // dev floors reuse whatever is to hand
  final dungeons = DungeonId.values.where(
    (d) => d.isReal && !d.name.startsWith('DEV_'),
  );

  bool isBoss(EntityId id) =>
      id.definition is CombatEntityDefinition &&
      (id.definition as CombatEntityDefinition).isDungeonBoss;

  // floors that end on a pack of regulars rather than one monster, and are
  // meant to: the lair builds to the Queen alone
  const knownBossless = {
    'GOBLIN_QUEEN_LAIR · Warren Entrance',
    'GOBLIN_QUEEN_LAIR · Deep Warren',
  };

  test('every floor ends on a boss, alone', () {
    for (final dungeon in dungeons) {
      for (final floor in dungeon.definition.entries) {
        final last = floor.entities.last;
        final where = '${dungeon.name} · ${floor.name}';
        if (knownBossless.contains(where)) {
          expect(isBoss(last.entityId), isFalse, reason: '$where has one now');
          continue;
        }
        expect(isBoss(last.entityId), isTrue, reason: where);
        expect(last.count, 1, reason: where);
      }
    }
  });

  test('a boss stands only at the end of its one floor', () {
    final ends = <EntityId, String>{};
    for (final dungeon in DungeonId.values.where((d) => d.isReal)) {
      for (final floor in dungeon.definition.entries) {
        final where = '${dungeon.name} · ${floor.name}';
        for (final (i, ref) in floor.entities.indexed) {
          if (!isBoss(ref.entityId)) continue;
          expect(
            i,
            floor.entities.length - 1,
            reason: '${ref.entityId.name} is mid-floor in $where',
          );
          if (dungeon.name.startsWith('DEV_')) continue;
          expect(
            ends.containsKey(ref.entityId),
            isFalse,
            reason:
                '${ref.entityId.name} ends both ${ends[ref.entityId]} '
                'and $where',
          );
          ends[ref.entityId] = where;
        }
      }
    }
    for (final zone in ZoneId.values) {
      final placed = [
        ...zone.definition.permanentEntities,
        ...zone.definition.discoverableEntities.map((e) => e.id),
      ];
      for (final id in placed) {
        expect(
          isBoss(id),
          isFalse,
          reason: '${id.name} is a boss, out in ${zone.name}',
        );
      }
    }
  });

  test('every boss has a floor to end', () {
    final placed = {
      for (final dungeon in dungeons)
        for (final floor in dungeon.definition.entries)
          floor.entities.last.entityId,
    };
    for (final id in EntityId.values.where(isBoss)) {
      expect(placed, contains(id), reason: id.name);
    }
  });

  test('the Webbed Thicket\'s boss is its own zombie', () {
    final thicket = DungeonId.SPIDER_DEN.definition.entries.first;
    expect(thicket.entities.last.entityId, EntityId.THICKET_ZOMBIE);
    final boss = EntityId.THICKET_ZOMBIE.definition as CombatEntityDefinition;
    final regular =
        EntityId.ZOMBIE_UNCOMMON.definition as CombatEntityDefinition;
    expect(regular.isDungeonBoss, isFalse);
    expect(boss.archetype, same(regular.archetype));
    expect(boss.rarity, regular.rarity);
    expect(boss.itemDrops, regular.itemDrops);
  });
}
