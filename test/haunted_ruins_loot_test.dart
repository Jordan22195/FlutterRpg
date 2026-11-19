import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';

// The Haunted Ruins' loot (design/DUNGEON_LOOT_GUIDE.md): the third
// dungeon at Tempest Reach's tier. Tier-4 pieces off the first two bosses,
// tier-5 off the Abbot, and gauntlets of its own in the chest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ruins = DungeonId.HAUNTED_RUINS.definition;

  EquipmentItemDefinition eq(ItemId id) =>
      id.definition as EquipmentItemDefinition;
  int tierOf(ItemId id) => eq(id).fibLevel - eq(id).fibOffset;
  SkillId lead(ItemId id) => eq(id).catalogSecondaries!.first;

  Map<ItemId, Set<Rarity>> uniquesOf(EntityId boss) {
    final def = boss.definition as CombatEntityDefinition;
    final out = <ItemId, Set<Rarity>>{};
    for (final roll in [...def.bonusDrops, ...def.extraBonusDrops]) {
      for (final line in roll.entries.flattened) {
        if (line.id.definition is! EquipmentItemDefinition) continue;
        (out[line.id] ??= {}).add(line.rarity);
      }
    }
    return out;
  }

  Map<ItemId, Set<Rarity>> chestGear() {
    final out = <ItemId, Set<Rarity>>{};
    for (final roll in ruins.chestRolls) {
      for (final line in roll.entries.flattened) {
        if (line.id.definition is! EquipmentItemDefinition) continue;
        (out[line.id] ??= {}).add(line.rarity);
      }
    }
    return out;
  }

  const owned = {
    EntityId.THE_GRAVEKEEPER: {
      ItemId.GRAVEKEEPERS_GREATCOAT,
      ItemId.GRAVEKEEPERS_KEYRING,
    },
    EntityId.THE_SHROUDED_WRAITH: {ItemId.SHROUDREAVER, ItemId.WEEPING_ROSARY},
    EntityId.THE_UNDYING_ABBOT: {
      ItemId.ABBOTS_GRIMOIRE,
      ItemId.OSSUARY_PAULDRONS,
    },
  };
  const pair = {Rarity.RARE, Rarity.EPIC};

  test('the Silent Nave ends on the Shrouded Wraith', () {
    final nave = ruins.entries.firstWhere((c) => c.name == 'The Silent Nave');
    expect(nave.entities.last.entityId, EntityId.THE_SHROUDED_WRAITH);
    // the Abbess is retired: no card fights her any more
    for (final card in ruins.entries) {
      expect(
        card.entities.map((e) => e.entityId),
        isNot(contains(EntityId.THE_WEEPING_ABBESS)),
      );
    }
  });

  test('each boss drops its own two uniques at rare and epic', () {
    for (final MapEntry(key: boss, value: items) in owned.entries) {
      final uniques = uniquesOf(boss);
      expect(uniques.keys.toSet(), items, reason: boss.name);
      for (final rarities in uniques.values) {
        expect(rarities, pair, reason: boss.name);
      }
    }
  });

  test('the first two bosses drop tier 4, the Abbot tier 5', () {
    for (final id in [
      ...owned[EntityId.THE_GRAVEKEEPER]!,
      ...owned[EntityId.THE_SHROUDED_WRAITH]!,
    ]) {
      expect(tierOf(id), 4, reason: id.name);
    }
    for (final id in owned[EntityId.THE_UNDYING_ABBOT]!) {
      expect(tierOf(id), 5, reason: id.name);
    }
  });

  test('the pieces are the ones asked for', () {
    expect(eq(ItemId.GRAVEKEEPERS_GREATCOAT).armorSlot, ArmorSlots.CHEST);
    expect(
      (ItemId.SHROUDREAVER.definition as WeaponItemDefinition).weaponType,
      WeaponTypeId.GREATSWORD,
    );
    final grimoire = eq(ItemId.ABBOTS_GRIMOIRE);
    expect(grimoire.armorSlot, ArmorSlots.OFFHAND);
    final leadWeight = grimoire.statWeights.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    expect(leadWeight, SkillId.ATTACK);
  });

  test(
    'the chest has the Reliquary Gauntlets and three boss trims at epic',
    () {
      final gear = chestGear();
      expect(gear[ItemId.RELIQUARY_GAUNTLETS], pair);
      expect(tierOf(ItemId.RELIQUARY_GAUNTLETS), 4);
      // on a slot none of the ruins' bosses cover
      final bossSlots = {
        for (final id in owned.values.expand((e) => e))
          if (id.definition is! WeaponItemDefinition) eq(id).armorSlot,
      };
      expect(
        bossSlots,
        isNot(contains(eq(ItemId.RELIQUARY_GAUNTLETS).armorSlot)),
      );
      final bossPieces = gear.keys.toSet()..remove(ItemId.RELIQUARY_GAUNTLETS);
      expect(bossPieces, {
        ItemId.GRAVEKEEPERS_KEYRING,
        ItemId.WEEPING_ROSARY,
        ItemId.OSSUARY_PAULDRONS,
      });
      // never above the boss's own top rarity
      for (final id in bossPieces) {
        expect(gear[id], {Rarity.EPIC}, reason: id.name);
      }
    },
  );

  test('every unique sets four secondaries, and tier 5 gains Attack leads', () {
    for (final id in [
      ...owned.values.expand((e) => e),
      ItemId.RELIQUARY_GAUNTLETS,
    ]) {
      expect(eq(id).catalogSecondaries, hasLength(4), reason: id.name);
    }
    for (final id in owned[EntityId.THE_UNDYING_ABBOT]!) {
      final weights = eq(id).statWeights;
      expect(
        weights.entries.reduce((a, b) => a.value >= b.value ? a : b).key,
        SkillId.ATTACK,
        reason: id.name,
      );
    }
    expect(lead(ItemId.OSSUARY_PAULDRONS), SkillId.SPEED);
    expect(lead(ItemId.ABBOTS_GRIMOIRE), SkillId.STRENGTH);
  });
}
