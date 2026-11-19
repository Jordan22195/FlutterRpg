import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

// The Ashen Vaults (design/DUNGEON_LOOT_GUIDE.md): the second tier-6
// dungeon. Three level-377 bosses with five pieces between them, and a
// Speed chest piece and pendant of the chest's own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final vaults = DungeonId.ASHEN_VAULTS.definition;

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
    EntityId.ASH_WYVERN: {ItemId.CINDERFANG, ItemId.WYVERNWING_CLOAK},
    EntityId.SLAG_WARDEN: {
      ItemId.SLAGPLATE_BRACERS,
      ItemId.SLAGPLATE_PAULDRONS,
    },
    EntityId.HEART_OF_THE_RIDGE: {ItemId.RIDGEHEART_GAUNTLETS},
  };
  const chestOnly = {ItemId.ASHWEAVE_HAUBERK, ItemId.EMBERGLASS_PENDANT};
  const pair = {Rarity.RARE, Rarity.EPIC};

  test('three floors, each ending on its own level-377 boss', () {
    expect(vaults.entries.map((c) => c.entities.last.entityId), [
      EntityId.ASH_WYVERN,
      EntityId.SLAG_WARDEN,
      EntityId.HEART_OF_THE_RIDGE,
    ]);
    for (final card in vaults.entries) {
      expect(combat(card.entities.last.entityId).level, 377);
      expect(combat(card.entities.last.entityId).isDungeonBoss, isTrue);
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
    expect(
      (ItemId.CINDERFANG.definition as WeaponItemDefinition).weaponType,
      WeaponTypeId.DAGGER,
    );
    expect(eq(ItemId.WYVERNWING_CLOAK).armorSlot, ArmorSlots.BACK);
    expect(eq(ItemId.SLAGPLATE_BRACERS).armorSlot, ArmorSlots.WRIST);
    expect(eq(ItemId.SLAGPLATE_PAULDRONS).armorSlot, ArmorSlots.SHOULDER);
    expect(eq(ItemId.RIDGEHEART_GAUNTLETS).armorSlot, ArmorSlots.HANDS);
    expect(eq(ItemId.ASHWEAVE_HAUBERK).armorSlot, ArmorSlots.CHEST);
    expect(eq(ItemId.EMBERGLASS_PENDANT).armorSlot, ArmorSlots.NECK);

    expect(lead(ItemId.CINDERFANG), SkillId.SPEED);
    expect(lead(ItemId.WYVERNWING_CLOAK), SkillId.SPEED);
    expect(lead(ItemId.SLAGPLATE_BRACERS), SkillId.STRENGTH);
    expect(lead(ItemId.SLAGPLATE_PAULDRONS), SkillId.STAMINA);
    expect(lead(ItemId.RIDGEHEART_GAUNTLETS), SkillId.STRENGTH);
    expect(lead(ItemId.ASHWEAVE_HAUBERK), SkillId.SPEED);
    expect(lead(ItemId.EMBERGLASS_PENDANT), SkillId.SPEED);

    // the bosses' focuses: Attack, Defence, a Strength piece
    expect(eq(ItemId.WYVERNWING_CLOAK).statWeights.keys.first, SkillId.ATTACK);
    expect(
      eq(ItemId.SLAGPLATE_BRACERS).statWeights.keys.first,
      SkillId.DEFENCE,
    );
  });

  test('the chest has its two exclusives and two boss pieces at epic', () {
    final gear = gearIn(vaults.chestRolls);
    for (final id in chestOnly) {
      expect(gear[id], pair, reason: id.name);
    }
    final bossPieces = gear.keys.toSet()..removeAll(chestOnly);
    expect(bossPieces, {ItemId.WYVERNWING_CLOAK, ItemId.SLAGPLATE_PAULDRONS});
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
