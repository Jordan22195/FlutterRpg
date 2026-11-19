import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

// Spinehold Caverns (design/DUNGEON_LOOT_GUIDE.md): the first tier-6
// dungeon. Three level-377 bosses, two tier-6 pieces off each, and an
// Attack helm of its own in the chest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final caverns = DungeonId.SPINEHOLD_CAVERNS.definition;

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
    EntityId.BRIDGE_TROLL: {ItemId.TROLLHIDE_TREADS, ItemId.TOLLKEEPERS_BELT},
    EntityId.STEEL_SENTINEL: {
      ItemId.SENTINELS_BULWARK,
      ItemId.SENTINELS_GORGET,
    },
    EntityId.GREYSPINE_DRAKE: {
      ItemId.DRAKEFANG_GREATSWORD,
      ItemId.WYRMCREST_RING,
    },
  };
  const helm = ItemId.ARCHWARDENS_HELM;
  const pair = {Rarity.RARE, Rarity.EPIC};

  test('three floors, each ending on its own level-377 boss', () {
    expect(caverns.entries.map((c) => c.name), [
      'The Hollow Arch',
      'The High Gallery',
      "The Drake's Roost",
    ]);
    expect(caverns.entries.map((c) => c.entities.last.entityId), [
      EntityId.BRIDGE_TROLL,
      EntityId.STEEL_SENTINEL,
      EntityId.GREYSPINE_DRAKE,
    ]);
    for (final card in caverns.entries) {
      expect(combat(card.entities.last.entityId).level, 377);
      expect(combat(card.entities.last.entityId).isDungeonBoss, isTrue);
    }
  });

  test('each boss drops its own two uniques at rare and epic', () {
    for (final MapEntry(key: boss, value: items) in owned.entries) {
      final uniques = gearIn(combat(boss).bonusDrops);
      expect(uniques.keys.toSet(), items, reason: boss.name);
      for (final rarities in uniques.values) {
        expect(rarities, pair, reason: boss.name);
      }
    }
  });

  test('every piece is tier 6 and carries four secondaries', () {
    for (final id in [...owned.values.expand((e) => e), helm]) {
      expect(tierOf(id), 6, reason: id.name);
      expect(eq(id).catalogSecondaries, hasLength(4), reason: id.name);
    }
  });

  test('the pieces and their leads are the ones asked for', () {
    expect(eq(ItemId.TROLLHIDE_TREADS).armorSlot, ArmorSlots.FEET);
    expect(eq(ItemId.TOLLKEEPERS_BELT).armorSlot, ArmorSlots.WAIST);
    expect(eq(ItemId.SENTINELS_BULWARK).armorSlot, ArmorSlots.OFFHAND);
    expect(eq(ItemId.SENTINELS_GORGET).armorSlot, ArmorSlots.NECK);
    expect(
      (ItemId.DRAKEFANG_GREATSWORD.definition as WeaponItemDefinition)
          .weaponType,
      WeaponTypeId.GREATSWORD,
    );
    expect(eq(ItemId.WYRMCREST_RING).armorSlot, ArmorSlots.FINGER);
    expect(eq(helm).armorSlot, ArmorSlots.HEAD);
    expect(eq(helm).statWeights.keys.first, SkillId.ATTACK);

    expect(lead(ItemId.TROLLHIDE_TREADS), SkillId.SPEED);
    expect(lead(ItemId.TOLLKEEPERS_BELT), SkillId.RECOVERY);
    expect(lead(ItemId.SENTINELS_BULWARK), SkillId.STAMINA);
    expect(lead(ItemId.SENTINELS_GORGET), SkillId.STRENGTH);
    expect(lead(ItemId.DRAKEFANG_GREATSWORD), SkillId.STRENGTH);
    expect(lead(ItemId.WYRMCREST_RING), SkillId.STRENGTH);
    expect(lead(helm), SkillId.STRENGTH);
  });

  test('the chest has the helm and two boss pieces at epic', () {
    final gear = gearIn(caverns.chestRolls);
    expect(gear[helm], pair);
    final bossSlots = {
      for (final id in owned.values.expand((e) => e))
        if (id.definition is! WeaponItemDefinition) eq(id).armorSlot,
    };
    expect(bossSlots, isNot(contains(eq(helm).armorSlot)));
    final bossPieces = gear.keys.toSet()..remove(helm);
    expect(bossPieces, {ItemId.TROLLHIDE_TREADS, ItemId.SENTINELS_BULWARK});
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

    final mine = {...owned.values.expand((e) => e), helm};
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
