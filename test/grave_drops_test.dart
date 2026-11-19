import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';

/// Every item a drop list can land on, nested tables flattened.
Set<ItemId> idsIn(List<ItemDropType> drops) => {
  for (final d in drops)
    if (d is NestedDrop) ...idsIn(d.table) else d.id,
};

EncounterEntityDefinition combat(EntityId id) =>
    id.definition as EncounterEntityDefinition;

void main() {
  test('skeleton and zombie both leave rotten flesh and an ichor part', () {
    for (final id in [EntityId.SKELETON, EntityId.ZOMBIE]) {
      final ids = idsIn(combat(id).itemDrops);
      expect(ids, contains(ItemId.ROTTEN_FLESH));
      expect(
        (combat(id) as CombatEntityDefinition).archetype.reagentFamily,
        ReagentFamily.ICHOR,
      );
    }
  });

  test('the skeleton drops common steel and an uncommon steel shield', () {
    final drops = combat(EntityId.SKELETON).itemDrops;
    expect(
      drops.whereType<NestedDrop>().map((d) => d.rarityOverride).toSet(),
      {null},
      reason: 'no rare steel',
    );
    expect(
      drops.any(
        (d) => d.id == ItemId.STEEL_SHIELD && d.rarity == Rarity.UNCOMMON,
      ),
      isTrue,
    );
  });

  test('the zombie alone rolls tattered cloth, as a rare bonus', () {
    final rolled = {
      for (final roll in combat(EntityId.ZOMBIE).bonusDrops)
        ...idsIn(roll.entries),
    };
    expect(rolled, {
      ItemId.TATTERED_HOOD,
      ItemId.TATTERED_CLOAK,
      ItemId.TATTERED_WRAPS,
      ItemId.TATTERED_SHOES,
    });
    expect(combat(EntityId.SKELETON).bonusDrops, isEmpty);
  });

  test('tattered cloth sits on the second rung, one focus a piece', () {
    for (final id in [
      ItemId.TATTERED_HOOD,
      ItemId.TATTERED_CLOAK,
      ItemId.TATTERED_WRAPS,
      ItemId.TATTERED_SHOES,
    ]) {
      final def = id.definition as EquipmentItemDefinition;
      expect(def.fibLevel, 2, reason: id.name);
      expect(def.catalogSecondaries, hasLength(4), reason: id.name);
    }
    // the four rags lean four different ways
    expect({
      for (final id in [
        ItemId.TATTERED_HOOD,
        ItemId.TATTERED_CLOAK,
        ItemId.TATTERED_WRAPS,
        ItemId.TATTERED_SHOES,
      ])
        (id.definition as EquipmentItemDefinition).catalogSecondaries!.first,
    }, hasLength(4));
  });

  test('the wraith haunts the darkwood and sheds ichor and rags', () {
    expect(
      (combat(EntityId.WRAITH) as CombatEntityDefinition)
          .archetype
          .reagentFamily,
      ReagentFamily.ICHOR,
    );
    expect(
      combat(EntityId.WRAITH).bonusDrops.single.chance,
      greaterThan(combat(EntityId.ZOMBIE).bonusDrops.single.chance),
    );
    expect(
      combat(EntityId.WRAITH).bonusDrops.single.entries.map((e) => e.rarity),
      everyElement(Rarity.UNCOMMON),
    );
    final found = ZoneId.DARKWOOD_FOREST.definition.discoverableEntities.any(
      (e) => e.id == EntityId.WRAITH,
    );
    expect(found, isTrue);
  });

  test('the uncommon bear drops what a bear does, and more of it', () {
    final base = combat(EntityId.BEAR).itemDrops;
    final uncommon = combat(EntityId.BEAR_UNCOMMON).itemDrops;
    expect(idsIn(uncommon), idsIn(base));
    for (final drop in uncommon) {
      final plain = base.firstWhere((d) => d.id == drop.id);
      expect(drop.lowCount, greaterThan(plain.lowCount), reason: '${drop.id}');
    }
  });

  test('the spider den runs three floors, each ending on its own boss', () {
    final floors = DungeonId.SPIDER_DEN.definition.entries;
    expect(floors.map((f) => f.name), [
      'Webbed Thicket',
      'Cocoon Hollow',
      "Broodmother's Lair",
    ]);
    expect(floors.map((f) => f.entities.last.entityId), [
      EntityId.THICKET_WEAVER,
      EntityId.THICKET_ZOMBIE,
      EntityId.SPIDER_BROODMOTHER,
    ]);
    expect(
      floors.first.entities.map((e) => (e.entityId, e.count)),
      containsAll([
        (EntityId.GIANT_SPIDER_UNCOMMON, 12),
        (EntityId.GIANT_BAT_UNCOMMON, 6),
      ]),
    );
  });

  test('black weapons match mithril, and a wraith can drop the greatsword', () {
    const pairs = {
      ItemId.BLACK_DAGGER: ItemId.MITHRIL_DAGGER,
      ItemId.BLACK_SWORD: ItemId.MITHRIL_SWORD,
      ItemId.BLACK_GREATSWORD: ItemId.MITHRIL_GREATSWORD,
    };
    pairs.forEach((black, mithril) {
      final b = black.definition as WeaponItemDefinition;
      final m = mithril.definition as WeaponItemDefinition;
      expect(b.materialRung, m.materialRung, reason: black.name);
      expect(b.weaponType, m.weaponType, reason: black.name);
      for (final r in Rarity.values) {
        expect(b.damageAt(r), m.damageAt(r), reason: '${black.name} $r');
      }
    });
    expect(
      idsIn(combat(EntityId.WRAITH).itemDrops),
      contains(ItemId.BLACK_GREATSWORD),
    );
  });

  test('cocoon hollow fields uncommon skeletons, and they drop something', () {
    final hollow = DungeonId.SPIDER_DEN.definition.entries[1];
    expect(
      hollow.entities.map((e) => e.entityId),
      contains(EntityId.SKELETON_UNCOMMON),
    );
    expect(combat(EntityId.SKELETON_UNCOMMON).itemDrops, isNotEmpty);
  });

  test('every giant bat and zombie variant drops what its common does', () {
    for (final (base, variants) in [
      (EntityId.GIANT_BAT, [EntityId.GIANT_BAT_UNCOMMON]),
      (EntityId.ZOMBIE, [EntityId.ZOMBIE_UNCOMMON, EntityId.THICKET_ZOMBIE]),
    ]) {
      final ids = idsIn(combat(base).itemDrops);
      for (final v in variants) {
        expect(idsIn(combat(v).itemDrops), ids, reason: v.name);
      }
    }
    // the rags are the overworld zombies' — a boss owns its own pieces
    // only (design/DUNGEON_LOOT_GUIDE.md)
    expect(
      combat(
        EntityId.THICKET_ZOMBIE,
      ).bonusDrops.expand((r) => r.entries).map((e) => e.id),
      isNot(contains(anyOf(tatteredClothDropTable.map((e) => e.id).toList()))),
    );
    expect(
      combat(
        EntityId.ZOMBIE,
      ).bonusDrops.expand((r) => r.entries).map((e) => e.id),
      containsAll(tatteredClothDropTable.map((e) => e.id)),
    );
  });

  test(
    'the spider den bosses drop the cloak and ring; the chest gives some at rare',
    () {
      ids(List<DropRoll> rolls) =>
          rolls.expand((r) => r.entries).map((e) => e.id);
      expect(
        ids(combat(EntityId.THICKET_WEAVER).bonusDrops),
        contains(ItemId.WEBBED_CLOAK),
      );
      expect(
        ids(combat(EntityId.THICKET_ZOMBIE).bonusDrops),
        contains(ItemId.VENOMFANG_RING),
      );
      // the bosses' pieces in the chest come at rare, their top; the chest's
      // own leggings at both of the band's
      final rare = DungeonId.SPIDER_DEN.definition.chestRolls
          .expand((r) => r.entries)
          .where((e) => e.rarity == Rarity.RARE)
          .map((e) => e.id)
          .toSet();
      expect(rare, {
        ItemId.WEBBED_CLOAK,
        ItemId.SPIDER_SILK_NECKLACE,
        ItemId.BROODSILK_LEGGINGS,
      });
    },
  );

  test(
    'the spider den chest hauls the darkwood in bulk, and its own leggings',
    () {
      final rolls = DungeonId.SPIDER_DEN.definition.chestRolls;
      final bulk = [
        for (final r in rolls)
          for (final e in r.entries)
            if (e.rarity == Rarity.COMMON) e,
      ];
      expect(
        bulk.map((e) => e.id),
        containsAll([
          ItemId.WILLOW_LOGS,
          ItemId.COAL,
          ItemId.PIKE,
          ItemId.SALMON,
          ItemId.DUSKTHORN,
          ItemId.THICK_VENOM,
          ItemId.THICK_FEATHER,
          ItemId.ROTTEN_FLESH,
        ]),
      );
      for (final e in bulk) {
        expect((e.lowCount, e.highCount), (20, 80), reason: e.id.name);
      }
      // nothing above the band: no epic necklace any more
      expect(
        rolls.expand((r) => r.entries).where((e) => e.rarity == Rarity.EPIC),
        isEmpty,
      );
      expect(
        rolls.expand((r) => r.entries).map((e) => e.id),
        contains(ItemId.BROODSILK_LEGGINGS),
      );
    },
  );
}
