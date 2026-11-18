import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';
import 'package:rpg/data/skill_data.dart';

// The three west-coast dungeons, one per zone off Southwood Forest. Each
// runs its zone's monsters, ends every card on a boss above them, and drops
// gear at the tier the boss rung allows (design/DUNGEON_LOOT_GUIDE.md).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int levelOf(EntityId id) => (id.definition as CombatEntityDefinition).level;
  EquipmentItemDefinition eq(ItemId id) =>
      id.definition as EquipmentItemDefinition;
  int tierOf(ItemId id) => eq(id).fibLevel - eq(id).fibOffset;
  // what a unique leans toward: the first of its catalog secondaries
  SkillId lead(ItemId id) => eq(id).catalogSecondaries!.first;

  // every boss's uniques, read off its bonus rolls, with their rarities
  Map<ItemId, Set<Rarity>> uniquesOf(EntityId boss) {
    final out = <ItemId, Set<Rarity>>{};
    for (final roll in (boss.definition as CombatEntityDefinition).bonusDrops) {
      for (final line in roll.entries.flattened) {
        if (line.id.definition is! EquipmentItemDefinition) continue;
        (out[line.id] ??= {}).add(line.rarity);
      }
    }
    return out;
  }

  final cases = [
    (
      zone: ZoneId.REEDWATER_VALE,
      entrance: EntityId.REEDMAZE_ENTRANCE,
      dungeon: DungeonId.REEDMAZE,
      cards: ['The Reedbeds', "Snapper's Pool"],
      bosses: [EntityId.OLD_CROAKER, EntityId.OLD_SNAPJAW],
      bossLevels: [34, 34],
      mobs: (13, 34),
      tiers: {2},
      rarities: {Rarity.UNCOMMON, Rarity.RARE},
    ),
    (
      zone: ZoneId.MUDMOUTH_DELTA,
      entrance: EntityId.SILT_WARRENS_ENTRANCE,
      dungeon: DungeonId.SILT_WARRENS,
      cards: ['The Mudflats', 'The Wallows', 'Deathroll Channel'],
      bosses: [EntityId.OLD_MUDCLAW, EntityId.WALLOW_BULL, EntityId.MUDMAW],
      bossLevels: [55, 55, 89],
      mobs: (21, 55),
      tiers: {3},
      rarities: {Rarity.UNCOMMON, Rarity.RARE},
    ),
    (
      zone: ZoneId.SALTWIND_COAST,
      entrance: EntityId.BRINEDEEP_CAVES_ENTRANCE,
      dungeon: DungeonId.BRINEDEEP_CAVES,
      cards: ['The Tidepools', 'The Drowned Shrine', "The Leviathan's Deep"],
      bosses: [
        EntityId.BRINECRUSHER,
        EntityId.NAGA_TIDECALLER,
        EntityId.LEVIATHAN,
      ],
      bossLevels: [144, 144, 144],
      mobs: (34, 89),
      tiers: {4, 5},
      rarities: {Rarity.RARE, Rarity.EPIC},
    ),
  ];

  for (final c in cases) {
    final def = c.dungeon.definition;
    group(def.name, () {
      test('is a free zone dungeon entered from ${c.zone.definition.name}', () {
        final entrance = c.entrance.definition as DungeonEntityDefinition;
        expect(entrance.dungeonId, c.dungeon);
        expect(def.type, DungeonType.ZONE);
        expect(def.isKeyed, isFalse);
        expect(c.zone.definition.permanentEntities, contains(c.entrance));
      });

      test('runs its cards at twenty-five fights each', () {
        expect(def.entries.map((e) => e.name), c.cards);
        for (final card in def.entries) {
          final fights = card.entities.fold(0, (sum, e) => sum + e.count);
          expect(fights, 25, reason: card.name);
        }
      });

      test('its mobs are the zone\'s, and each card ends on its boss', () {
        final bosses = [for (final card in def.entries) card.entities.last];
        expect(bosses.map((b) => b.entityId), c.bosses);
        expect(bosses.map((b) => levelOf(b.entityId)), c.bossLevels);
        for (final b in bosses) {
          expect(b.count, 1);
          expect(
            (b.entityId.definition as CombatEntityDefinition).isDungeonBoss,
            isTrue,
          );
        }

        final zoneMobs = c.zone.definition.discoverableEntities
            .map((e) => e.id)
            .toSet();
        for (final card in def.entries) {
          for (final mob in card.entities.take(card.entities.length - 1)) {
            expect(zoneMobs, contains(mob.entityId), reason: card.name);
            expect(
              levelOf(mob.entityId),
              inInclusiveRange(c.mobs.$1, c.mobs.$2),
              reason: '${card.name}: ${mob.entityId.name}',
            );
          }
        }
      });

      test('every boss drops its own gear at the band\'s pair', () {
        for (final boss in c.bosses) {
          final uniques = uniquesOf(boss);
          expect(uniques, isNotEmpty, reason: boss.name);
          for (final MapEntry(key: item, value: rarities) in uniques.entries) {
            expect(rarities, c.rarities, reason: item.name);
            expect(c.tiers, contains(tierOf(item)), reason: item.name);
          }
        }
      });

      test('the chest has an exclusive of its own at the dungeon\'s tier', () {
        final bossItems = {for (final b in c.bosses) ...uniquesOf(b).keys};
        final chestGear = {
          for (final roll in def.chestRolls)
            for (final line in roll.entries.flattened)
              if (line.id.definition is EquipmentItemDefinition) line.id,
        };
        final exclusives = chestGear.difference(bossItems);
        expect(exclusives, hasLength(1));
        expect(c.tiers, contains(tierOf(exclusives.single)));
      });
    });
  }

  test('the Brinedeep Caves match Tempest Reach piece for piece', () {
    // same tiers and four catalog secondaries each, on slots and stats
    // Tempest leaves open
    const pairs = {
      ItemId.WARLORDS_CLEAVER: ItemId.BRINECRUSHER_CLAW,
      ItemId.WARLORDS_WARHELM: ItemId.BRINECLAW_BRACERS,
      ItemId.ALPHAS_FANG: ItemId.TIDECALLERS_SCEPTER,
      ItemId.ALPHAS_MANTLE: ItemId.SALTSCALE_SANDALS,
      ItemId.STORMCALLERS_SCEPTER: ItemId.LEVIATHANS_FANG,
      ItemId.GALEWRAP_GAUNTLETS: ItemId.LEVIATHAN_GIRDLE,
      ItemId.STORMHIDE_LEGS: ItemId.PEARLSCALE_CUIRASS,
    };
    final tempestSlots = {
      for (final id in pairs.keys)
        if (id.definition is! WeaponItemDefinition) eq(id).armorSlot,
    };
    for (final MapEntry(key: tempest, value: coast) in pairs.entries) {
      expect(tierOf(coast), tierOf(tempest), reason: coast.name);
      expect(eq(coast).catalogSecondaries, hasLength(4), reason: coast.name);
      if (coast.definition is WeaponItemDefinition) continue;
      expect(tempestSlots, isNot(contains(eq(coast).armorSlot)));
    }

    // speed leads at tier 4 and strength at tier 5, where the ladder had
    // neither
    expect(lead(ItemId.SALTSCALE_SANDALS), SkillId.SPEED);
    expect(lead(ItemId.LEVIATHAN_GIRDLE), SkillId.STRENGTH);
  });

  test('the Silt Warrens\' trims match the Drowned Fen\'s', () {
    const pairs = {
      ItemId.CROWQUILL_BRACERS: ItemId.MUDCLAW_GRIPS,
      ItemId.OOZE_SLICK_BELT: ItemId.WALLOWHIDE_TREADS,
    };
    for (final MapEntry(key: fen, value: delta) in pairs.entries) {
      expect(eq(delta).fibLevel, eq(fen).fibLevel, reason: delta.name);
      expect(lead(delta), lead(fen), reason: delta.name);
    }
  });
}
