import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';

// Old Sorrow Mine (design/DUNGEON_LOOT_GUIDE.md): Copperdust Flats'
// dungeon, the fourth at Tempest Reach's tier. Levels 55 to 144, a boss on
// every floor, tier-4 pieces off the first three bosses, tier 5 off the
// Lode Golem, and a duster and a nugget of its own in the chest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mine = DungeonId.OLD_SORROW_MINE.definition;

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
    EntityId.PACKRAT_KING: {ItemId.PACKRATS_TRINKET},
    EntityId.DUSKWING_MATRIARCH: {ItemId.DUSKWING_CUFFS},
    EntityId.THE_BORER: {
      ItemId.BORERS_MANDIBLE,
      ItemId.BORERS_SHELL_PAULDRONS,
    },
    EntityId.LODE_GOLEM: {ItemId.LODESTONE_MAUL, ItemId.HEART_OF_THE_LODE},
  };
  const exclusives = {ItemId.PROSPECTORS_DUSTER, ItemId.MOTHER_LODE_NUGGET};
  const pair = {Rarity.RARE, Rarity.EPIC};

  test('the mine stands in Copperdust Flats', () {
    expect(
      ZoneId.COPPERDUST_FLATS.definition.permanentEntities,
      contains(EntityId.OLD_SORROW_MINE_ENTRANCE),
    );
    final entrance =
        EntityId.OLD_SORROW_MINE_ENTRANCE.definition as DungeonEntityDefinition;
    expect(entrance.dungeonId, DungeonId.OLD_SORROW_MINE);
    expect(mine.type, DungeonType.ZONE);
  });

  test('four floors, each ending on its own boss', () {
    expect(mine.entries.map((c) => c.name), [
      'The Headframe',
      'The Collapsed Drift',
      'The Stamp Mill',
      'The Mother Lode',
    ]);
    expect(mine.entries.map((c) => c.entities.last.entityId), [
      EntityId.PACKRAT_KING,
      EntityId.DUSKWING_MATRIARCH,
      EntityId.THE_BORER,
      EntityId.LODE_GOLEM,
    ]);
    for (final card in mine.entries) {
      final bosses = card.entities.where(
        (e) => combat(e.entityId).isDungeonBoss,
      );
      expect(bosses, hasLength(1), reason: card.name);
      expect(card.entities.last.count, 1, reason: card.name);
    }
  });

  test('levels run from 55 to 144, the Lode Golem alone at the top', () {
    final levels = [
      for (final card in mine.entries)
        for (final ref in card.entities) combat(ref.entityId).level,
    ];
    expect(levels.reduce((a, b) => a < b ? a : b), 55);
    expect(levels.reduce((a, b) => a > b ? a : b), 144);
    expect(
      [
        for (final card in mine.entries)
          combat(card.entities.last.entityId).level,
      ],
      [89, 89, 89, 144],
    );
    // the trash never outclimbs the floor's boss
    for (final card in mine.entries) {
      final boss = combat(card.entities.last.entityId).level;
      for (final ref in card.entities) {
        expect(combat(ref.entityId).level, lessThanOrEqualTo(boss));
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

  test('the first three bosses drop tier 4, the Lode Golem tier 5', () {
    for (final boss in [
      EntityId.PACKRAT_KING,
      EntityId.DUSKWING_MATRIARCH,
      EntityId.THE_BORER,
    ]) {
      for (final id in owned[boss]!) {
        expect(tierOf(id), 4, reason: id.name);
      }
    }
    for (final id in owned[EntityId.LODE_GOLEM]!) {
      expect(tierOf(id), 5, reason: id.name);
    }
    for (final id in exclusives) {
      expect(tierOf(id), 4, reason: id.name);
    }
  });

  test('the pieces are the ones asked for', () {
    expect(eq(ItemId.PACKRATS_TRINKET).armorSlot, ArmorSlots.FINGER);
    expect(eq(ItemId.DUSKWING_CUFFS).armorSlot, ArmorSlots.WRIST);
    expect(
      (ItemId.BORERS_MANDIBLE.definition as WeaponItemDefinition).weaponType,
      WeaponTypeId.DAGGER,
    );
    expect(eq(ItemId.BORERS_SHELL_PAULDRONS).armorSlot, ArmorSlots.SHOULDER);
    expect(
      (ItemId.LODESTONE_MAUL.definition as WeaponItemDefinition).weaponType,
      WeaponTypeId.GREATSWORD,
    );
    expect(eq(ItemId.HEART_OF_THE_LODE).armorSlot, ArmorSlots.OFFHAND);
    expect(eq(ItemId.PROSPECTORS_DUSTER).armorSlot, ArmorSlots.BACK);
    expect(eq(ItemId.MOTHER_LODE_NUGGET).armorSlot, ArmorSlots.NECK);

    expect(lead(ItemId.PACKRATS_TRINKET), SkillId.SPEED);
    expect(lead(ItemId.DUSKWING_CUFFS), SkillId.RECOVERY);
    expect(lead(ItemId.BORERS_MANDIBLE), SkillId.STRENGTH);
    expect(lead(ItemId.BORERS_SHELL_PAULDRONS), SkillId.STRENGTH);
    expect(lead(ItemId.LODESTONE_MAUL), SkillId.STRENGTH);
    expect(lead(ItemId.HEART_OF_THE_LODE), SkillId.STAMINA);
    expect(lead(ItemId.PROSPECTORS_DUSTER), SkillId.STAMINA);
    expect(lead(ItemId.MOTHER_LODE_NUGGET), SkillId.STRENGTH);
    for (final id in [...owned.values.expand((e) => e), ...exclusives]) {
      expect(eq(id).catalogSecondaries, hasLength(4), reason: id.name);
    }
  });

  test('the chest has its two exclusives and three boss trims at epic', () {
    final gear = chestGear();
    for (final id in exclusives) {
      expect(gear[id], pair, reason: id.name);
    }
    // on slots none of the mine's bosses cover
    final bossSlots = {
      for (final id in owned.values.expand((e) => e))
        if (id.definition is! WeaponItemDefinition) eq(id).armorSlot,
    };
    for (final id in exclusives) {
      expect(bossSlots, isNot(contains(eq(id).armorSlot)), reason: id.name);
    }
    final bossPieces = gear.keys.toSet()..removeAll(exclusives);
    expect(bossPieces, {
      ItemId.PACKRATS_TRINKET,
      ItemId.DUSKWING_CUFFS,
      ItemId.BORERS_SHELL_PAULDRONS,
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

    final mineItems = {...owned.values.expand((e) => e), ...exclusives};
    final others = <String, ItemId>{
      for (final id in ItemId.values)
        if (!mineItems.contains(id) &&
            id.definition is EquipmentItemDefinition &&
            (id.definition as EquipmentItemDefinition).catalogSecondaries !=
                null &&
            (id.definition as EquipmentItemDefinition)
                .catalogSecondaries!
                .isNotEmpty)
          key(id): id,
    };
    for (final id in mineItems) {
      expect(
        others[key(id)],
        isNull,
        reason: '${id.name} collides with ${others[key(id)]?.name}',
      );
    }
  });
}
