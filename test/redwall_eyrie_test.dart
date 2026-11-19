import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';

// The Redwall Eyrie (design/DUNGEON_LOOT_GUIDE.md): Redwall Bluffs'
// dungeon. Levels 144 to 233, a level-233 boss on every floor, tier-5 pieces
// off the first three bosses, tier 6 off Redwing, and a cloak and a cuirass
// of its own in the chest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mine = DungeonId.REDWALL_EYRIE.definition;

  EquipmentItemDefinition eq(ItemId id) =>
      id.definition as EquipmentItemDefinition;
  int tierOf(ItemId id) => eq(id).fibLevel - eq(id).fibOffset;
  SkillId lead(ItemId id) => eq(id).catalogSecondaries!.first;
  CombatEntityDefinition combat(EntityId id) =>
      id.definition as CombatEntityDefinition;

  Map<ItemId, Set<Rarity>> uniquesOf(EntityId boss) {
    final out = <ItemId, Set<Rarity>>{};
    for (final roll in combat(boss).bonusDrops) {
      for (final line in roll.entries.flattened) {
        if (line.id.definition is! EquipmentItemDefinition) continue;
        (out[line.id] ??= {}).add(line.rarity);
      }
    }
    return out;
  }

  Map<ItemId, Set<Rarity>> chestGear() {
    final out = <ItemId, Set<Rarity>>{};
    for (final roll in mine.chestRolls) {
      for (final line in roll.entries.flattened) {
        if (line.id.definition is! EquipmentItemDefinition) continue;
        (out[line.id] ??= {}).add(line.rarity);
      }
    }
    return out;
  }

  const owned = {
    EntityId.OLD_STONEGAZE: {ItemId.BASILISK_FANG, ItemId.GAZEGLASS_RING},
    EntityId.LEDGE_WARDEN: {ItemId.LEDGEWALKER_GREAVES},
    EntityId.ARCH_CHIMERA: {ItemId.CHIMERAS_HORN},
    EntityId.REDWING_MATRIARCH: {ItemId.REDWINGS_TALON, ItemId.REDWINGS_CREST},
  };
  const exclusives = {ItemId.EYRIE_WINDCLOAK, ItemId.REDWALL_CUIRASS};
  const pair = {Rarity.RARE, Rarity.EPIC};

  test('the eyrie stands in Redwall Bluffs', () {
    expect(
      ZoneId.REDWALL_BLUFFS.definition.permanentEntities,
      contains(EntityId.REDWALL_EYRIE_ENTRANCE),
    );
    final entrance =
        EntityId.REDWALL_EYRIE_ENTRANCE.definition as DungeonEntityDefinition;
    expect(entrance.dungeonId, DungeonId.REDWALL_EYRIE);
    expect(mine.type, DungeonType.ZONE);
  });

  test('four floors, each ending on its own boss, none of them human', () {
    expect(mine.entries.map((c) => c.name), [
      'The Gorge Floor',
      'The Hanging Ledges',
      'The Wind-Cut Arches',
      'The Eyrie',
    ]);
    expect(mine.entries.map((c) => c.entities.last.entityId), [
      EntityId.OLD_STONEGAZE,
      EntityId.LEDGE_WARDEN,
      EntityId.ARCH_CHIMERA,
      EntityId.REDWING_MATRIARCH,
    ]);
    for (final card in mine.entries) {
      final bosses = card.entities.where(
        (e) => combat(e.entityId).isDungeonBoss,
      );
      expect(bosses, hasLength(1), reason: card.name);
      expect(card.entities.last.count, 1, reason: card.name);
    }
  });

  test('levels run from 144 up, every boss at 233 and nothing above it', () {
    final levels = [
      for (final card in mine.entries)
        for (final ref in card.entities) combat(ref.entityId).level,
    ];
    expect(levels.reduce((a, b) => a > b ? a : b), 233);
    for (final card in mine.entries) {
      expect(combat(card.entities.last.entityId).level, 233, reason: card.name);
      for (final ref in card.entities) {
        expect(combat(ref.entityId).level, lessThanOrEqualTo(233));
      }
    }
    // the first two floors are trash at 144 (bar the scorpions, a step up)
    for (final card in mine.entries.take(2)) {
      for (final ref in card.entities.take(card.entities.length - 1)) {
        expect(combat(ref.entityId).level, lessThanOrEqualTo(144));
      }
    }
  });

  test('no gargoyle stands in the eyrie', () {
    for (final card in mine.entries) {
      for (final ref in card.entities) {
        expect(ref.entityId, isNot(EntityId.GARGOYLE), reason: card.name);
      }
    }
  });

  test('each boss drops its own uniques at rare and epic', () {
    for (final MapEntry(key: boss, value: items) in owned.entries) {
      final uniques = uniquesOf(boss);
      expect(uniques.keys.toSet(), items, reason: boss.name);
      for (final rarities in uniques.values) {
        expect(rarities, pair, reason: boss.name);
      }
    }
  });

  test('the first three bosses drop tier 5, Redwing tier 6', () {
    for (final boss in [
      EntityId.OLD_STONEGAZE,
      EntityId.LEDGE_WARDEN,
      EntityId.ARCH_CHIMERA,
    ]) {
      for (final id in owned[boss]!) {
        expect(tierOf(id), 5, reason: id.name);
      }
    }
    for (final id in owned[EntityId.REDWING_MATRIARCH]!) {
      expect(tierOf(id), 6, reason: id.name);
    }
    for (final id in exclusives) {
      expect(tierOf(id), 5, reason: id.name);
    }
  });

  test('the pieces are the ones asked for', () {
    WeaponTypeId weapon(ItemId id) =>
        (id.definition as WeaponItemDefinition).weaponType;
    expect(weapon(ItemId.BASILISK_FANG), WeaponTypeId.DAGGER);
    expect(eq(ItemId.GAZEGLASS_RING).armorSlot, ArmorSlots.FINGER);
    expect(eq(ItemId.LEDGEWALKER_GREAVES).armorSlot, ArmorSlots.LEGS);
    expect(weapon(ItemId.CHIMERAS_HORN), WeaponTypeId.SCEPTER);
    expect(weapon(ItemId.REDWINGS_TALON), WeaponTypeId.GREATSWORD);
    expect(eq(ItemId.REDWINGS_CREST).armorSlot, ArmorSlots.HEAD);
    expect(eq(ItemId.EYRIE_WINDCLOAK).armorSlot, ArmorSlots.BACK);
    expect(eq(ItemId.REDWALL_CUIRASS).armorSlot, ArmorSlots.CHEST);

    expect(lead(ItemId.BASILISK_FANG), SkillId.SPEED);
    expect(lead(ItemId.GAZEGLASS_RING), SkillId.STRENGTH);
    expect(lead(ItemId.LEDGEWALKER_GREAVES), SkillId.STAMINA);
    expect(lead(ItemId.CHIMERAS_HORN), SkillId.RECOVERY);
    expect(lead(ItemId.REDWINGS_TALON), SkillId.SPEED);
    expect(lead(ItemId.REDWINGS_CREST), SkillId.STAMINA);
    expect(lead(ItemId.EYRIE_WINDCLOAK), SkillId.STRENGTH);
    expect(lead(ItemId.REDWALL_CUIRASS), SkillId.SPEED);
    for (final id in [...owned.values.expand((e) => e), ...exclusives]) {
      expect(eq(id).catalogSecondaries, hasLength(4), reason: id.name);
    }
  });

  test('the chest has its two exclusives and three boss trims at epic', () {
    final gear = chestGear();
    for (final id in exclusives) {
      expect(gear[id], pair, reason: id.name);
    }
    final bossSlots = {
      for (final id in owned.values.expand((e) => e))
        if (id.definition is! WeaponItemDefinition) eq(id).armorSlot,
    };
    for (final id in exclusives) {
      expect(bossSlots, isNot(contains(eq(id).armorSlot)), reason: id.name);
    }
    final bossPieces = gear.keys.toSet()..removeAll(exclusives);
    expect(bossPieces, {
      ItemId.GAZEGLASS_RING,
      ItemId.LEDGEWALKER_GREAVES,
      ItemId.REDWINGS_CREST,
    });
    for (final id in bossPieces) {
      expect(gear[id], {Rarity.EPIC}, reason: id.name);
    }
  });

  test('no piece repeats the slot and lead of another unique at its tier', () {
    // the guide's slot-collision rule: a new piece on the same slot and
    // lead stat as a same-tier unique makes one of them dead loot
    String key(ItemId id) {
      final def = id.definition;
      final slot = def is WeaponItemDefinition
          ? def.weaponType.name
          : eq(id).armorSlot.name;
      return '$slot/${tierOf(id)}/${lead(id).name}';
    }

    final eyrieItems = {...owned.values.expand((e) => e), ...exclusives};
    final others = <String, ItemId>{
      for (final id in ItemId.values)
        if (!eyrieItems.contains(id) &&
            id.definition is EquipmentItemDefinition &&
            (id.definition as EquipmentItemDefinition).catalogSecondaries !=
                null &&
            (id.definition as EquipmentItemDefinition)
                .catalogSecondaries!
                .isNotEmpty)
          key(id): id,
    };
    for (final id in eyrieItems) {
      expect(
        others[key(id)],
        isNull,
        reason: '${id.name} collides with ${others[key(id)]?.name}',
      );
    }
  });
}
