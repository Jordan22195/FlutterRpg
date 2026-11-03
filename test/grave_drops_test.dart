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
  test('skeleton and zombie both leave rotten flesh and grave moss', () {
    for (final id in [EntityId.SKELETON, EntityId.ZOMBIE]) {
      final ids = idsIn(combat(id).itemDrops);
      expect(ids, containsAll([ItemId.ROTTEN_FLESH, ItemId.GRAVE_MOSS]));
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

  test('tattered cloth is pure attack on the second rung', () {
    for (final id in [
      ItemId.TATTERED_HOOD,
      ItemId.TATTERED_CLOAK,
      ItemId.TATTERED_WRAPS,
      ItemId.TATTERED_SHOES,
    ]) {
      final def = id.definition as EquipmentItemDefinition;
      expect(def.fibLevel, 2, reason: id.name);
      expect(def.statWeights.keys, [SkillId.ATTACK], reason: id.name);
    }
  });

  test('the wraith haunts the darkwood and sheds grave moss and rags', () {
    expect(
      idsIn(combat(EntityId.WRAITH).itemDrops),
      contains(ItemId.GRAVE_MOSS),
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
      (
        EntityId.GIANT_BAT,
        [
          EntityId.GIANT_BAT_UNCOMMON,
          EntityId.GIANT_BAT_RARE,
          EntityId.GIANT_BAT_EPIC,
          EntityId.GIANT_BAT_LEGENDARY,
        ],
      ),
      (
        EntityId.ZOMBIE,
        [
          EntityId.ZOMBIE_UNCOMMON,
          EntityId.THICKET_ZOMBIE,
          EntityId.ZOMBIE_RARE,
          EntityId.ZOMBIE_EPIC,
          EntityId.ZOMBIE_LEGENDARY,
        ],
      ),
    ]) {
      final ids = idsIn(combat(base).itemDrops);
      for (final v in variants) {
        expect(idsIn(combat(v).itemDrops), ids, reason: v.name);
      }
    }
    expect(
      combat(
        EntityId.THICKET_ZOMBIE,
      ).bonusDrops.expand((r) => r.entries).map((e) => e.id),
      containsAll(tatteredClothDropTable.map((e) => e.id)),
    );
  });

  test(
    'the spider den bosses drop the cloak and ring; the chest holds rare',
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
      final rare = DungeonId.SPIDER_DEN.definition.chestRolls
          .expand((r) => r.entries)
          .where((e) => e.rarity == Rarity.RARE);
      expect(rare.map((e) => e.id), {
        ItemId.WEBBED_CLOAK,
        ItemId.VENOMFANG_RING,
      });
    },
  );

  test(
    'the spider den chest hauls the darkwood in bulk, and an epic necklace',
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
          ItemId.HARRALANDER,
          ItemId.SILK,
          ItemId.VENOM,
          ItemId.BAT_WING,
          ItemId.ROTTEN_FLESH,
        ]),
      );
      for (final e in bulk) {
        expect((e.lowCount, e.highCount), (20, 80), reason: e.id.name);
      }
      expect(
        rolls
            .expand((r) => r.entries)
            .any(
              (e) =>
                  e.id == ItemId.SPIDER_SILK_NECKLACE &&
                  e.rarity == Rarity.EPIC,
            ),
        isTrue,
      );
    },
  );
}
