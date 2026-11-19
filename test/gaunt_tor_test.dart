import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

// Gaunt Tor (design/DUNGEON_LOOT_GUIDE.md): Ironroot Hills' dungeon and the
// third tier-6 one. Three level-233 bosses with five pieces between them,
// and a Strength cuirass and Recovery mantle of the chest's own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tor = DungeonId.GAUNT_TOR.definition;

  EquipmentItemDefinition eq(ItemId id) =>
      id.definition as EquipmentItemDefinition;
  int tierOf(ItemId id) => eq(id).fibLevel - eq(id).fibOffset;
  SkillId lead(ItemId id) => eq(id).catalogSecondaries!.first;
  CombatEntityDefinition combat(EntityId id) =>
      id.definition as CombatEntityDefinition;

  Map<ItemId, Set<Rarity>> gearIn(Iterable<DropRoll> rolls) {
    final out = <ItemId, Set<Rarity>>{};
    for (final roll in rolls) {
      for (final line in roll.entries.flattened) {
        if (line.id.definition is! EquipmentItemDefinition) continue;
        (out[line.id] ??= {}).add(line.rarity);
      }
    }
    return out;
  }

  const owned = {
    EntityId.THUNDERHORN: {ItemId.THUNDERHORN_HELM},
    EntityId.THE_CAIRNWARDEN: {
      ItemId.CAIRNSTONE_GREAVES,
      ItemId.CAIRNWARDENS_SIGNET,
    },
    EntityId.THE_HILL_KING: {ItemId.HILL_KINGS_CUDGEL, ItemId.GIANTBONE_GIRDLE},
  };
  const chestOnly = {ItemId.IRONROOT_CUIRASS, ItemId.RAMHIDE_MANTLE};
  const pair = {Rarity.RARE, Rarity.EPIC};

  test('the hills hold the entrance, free and repeatable', () {
    expect(
      ZoneId.IRONROOT_HILLS.definition.permanentEntities,
      contains(EntityId.GAUNT_TOR_ENTRANCE),
    );
    expect(tor.type, DungeonType.ZONE);
  });

  test('three floors, each ending on its own level-233 boss', () {
    expect(tor.entries.map((c) => c.entities.last.entityId), [
      EntityId.THUNDERHORN,
      EntityId.THE_CAIRNWARDEN,
      EntityId.THE_HILL_KING,
    ]);
    for (final card in tor.entries) {
      final boss = combat(card.entities.last.entityId);
      expect(boss.level, 233);
      expect(boss.isDungeonBoss, isTrue);
    }
  });

  test('the hills\' own monsters fill the floors', () {
    final trash = {
      for (final card in tor.entries)
        for (final ref in card.entities.take(card.entities.length - 1))
          ref.entityId,
    };
    expect(trash, {
      EntityId.ROCK_RAM,
      EntityId.TROLL,
      EntityId.EARTH_ELEMENTAL_UNCOMMON,
      EntityId.HILL_GIANT,
    });
    for (final id in trash) {
      expect(
        ZoneId.IRONROOT_HILLS.definition.discoverableEntities.any(
          (e) => e.id == id,
        ),
        isTrue,
        reason: '${id.name} lives in the hills',
      );
    }
  });

  test('each boss drops its own uniques at rare and epic', () {
    for (final MapEntry(key: boss, value: items) in owned.entries) {
      final uniques = gearIn(combat(boss).bonusDrops);
      expect(uniques.keys.toSet(), items, reason: boss.name);
      for (final rarities in uniques.values) {
        expect(rarities, pair, reason: boss.name);
      }
    }
  });

  test('every piece is tier 6 and carries four secondaries', () {
    for (final id in [...owned.values.expand((e) => e), ...chestOnly]) {
      expect(tierOf(id), 6, reason: id.name);
      expect(eq(id).catalogSecondaries, hasLength(4), reason: id.name);
    }
  });

  test('the pieces and their leads are the ones designed', () {
    expect(eq(ItemId.THUNDERHORN_HELM).armorSlot, ArmorSlots.HEAD);
    expect(eq(ItemId.CAIRNSTONE_GREAVES).armorSlot, ArmorSlots.LEGS);
    expect(eq(ItemId.CAIRNWARDENS_SIGNET).armorSlot, ArmorSlots.FINGER);
    expect(
      (ItemId.HILL_KINGS_CUDGEL.definition as WeaponItemDefinition).weaponType,
      WeaponTypeId.SWORD,
    );
    expect(eq(ItemId.GIANTBONE_GIRDLE).armorSlot, ArmorSlots.WAIST);
    expect(eq(ItemId.IRONROOT_CUIRASS).armorSlot, ArmorSlots.CHEST);
    expect(eq(ItemId.RAMHIDE_MANTLE).armorSlot, ArmorSlots.BACK);

    expect(lead(ItemId.THUNDERHORN_HELM), SkillId.SPEED);
    expect(lead(ItemId.CAIRNSTONE_GREAVES), SkillId.STRENGTH);
    expect(lead(ItemId.CAIRNWARDENS_SIGNET), SkillId.SPEED);
    expect(lead(ItemId.HILL_KINGS_CUDGEL), SkillId.STRENGTH);
    expect(lead(ItemId.GIANTBONE_GIRDLE), SkillId.STRENGTH);
    expect(lead(ItemId.IRONROOT_CUIRASS), SkillId.STRENGTH);
    expect(lead(ItemId.RAMHIDE_MANTLE), SkillId.RECOVERY);
  });

  test('the chest has its two exclusives and three boss pieces at epic', () {
    final gear = gearIn(tor.chestRolls);
    for (final id in chestOnly) {
      expect(gear[id], pair, reason: id.name);
    }
    final bossPieces = gear.keys.toSet()..removeAll(chestOnly);
    expect(bossPieces, {
      ItemId.THUNDERHORN_HELM,
      ItemId.CAIRNSTONE_GREAVES,
      ItemId.GIANTBONE_GIRDLE,
    });
    for (final id in bossPieces) {
      expect(gear[id], {Rarity.EPIC}, reason: id.name);
    }
  });

  test('no piece repeats the slot and lead of another unique at its tier', () {
    String key(ItemId id) {
      final def = id.definition;
      final slot = def is WeaponItemDefinition
          ? def.weaponType.name
          : eq(id).armorSlot.name;
      return '$slot/${tierOf(id)}/${lead(id).name}';
    }

    final mine = {...owned.values.expand((e) => e), ...chestOnly};

    final others = <String, ItemId>{
      for (final id in ItemId.values)
        if (!mine.contains(id) &&
            id.definition is EquipmentItemDefinition &&
            (id.definition as EquipmentItemDefinition).catalogSecondaries !=
                null &&
            (id.definition as EquipmentItemDefinition)
                .catalogSecondaries!
                .isNotEmpty)
          key(id): id,
    };
    for (final id in mine) {
      expect(
        others[key(id)],
        isNull,
        reason: '${id.name} collides with ${others[key(id)]?.name}',
      );
    }
  });
}
