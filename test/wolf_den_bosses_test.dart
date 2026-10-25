import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';

// The Wolf Den's three bosses: each is its family's ordinary monster, drops
// and all, with a tenth-of-kills roll for one slot of basic skilling gear.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final floors = {
    for (final card in DungeonId.WOLF_DEN.definition.entries) card.name: card,
  };

  /// Every basic skilling piece worn in [slot].
  Set<ItemId> basicPieces(ArmorSlots slot) => {
    for (final id in ItemId.values)
      if (id.definition case final SkillingGearDefinition def
          when def.tier == SkillingGearTier.BASIC && def.armorSlot == slot)
        id,
  };

  final bosses = [
    (
      floor: 'Cave Entrance',
      boss: EntityId.CAVE_BEAR,
      base: EntityId.BEAR,
      rarity: Rarity.RARE,
      slot: ArmorSlots.HEAD,
    ),
    (
      floor: 'Deep Lair',
      boss: EntityId.DEN_ALPHA_WOLF,
      base: EntityId.FOREST_WOLF,
      rarity: Rarity.RARE,
      slot: ArmorSlots.CHEST,
    ),
    (
      floor: 'Sunken Grotto',
      boss: EntityId.GROTTO_FUNGAL_MONSTER,
      base: EntityId.FUNGAL_MONSTER,
      rarity: Rarity.COMMON,
      slot: ArmorSlots.LEGS,
    ),
  ];

  for (final b in bosses) {
    group(b.boss.name, () {
      final def = b.boss.definition as CombatEntityDefinition;
      final base = b.base.definition as CombatEntityDefinition;

      test('is the last monster on the ${b.floor}, alone', () {
        final last = floors[b.floor]!.entities.last;
        expect(last.entityId, b.boss);
        expect(last.count, 1);
      });

      test('is its family at ${b.rarity.name}', () {
        expect(def.archetype, same(base.archetype));
        expect(def.rarity, b.rarity);
      });

      test('drops what its family does', () {
        expect(
          def.itemDrops.map((d) => (d.id, d.count, d.highCount, d.weight)),
          base.itemDrops.map((d) => (d.id, d.count, d.highCount, d.weight)),
        );
        // and keeps any roll the family makes on top
        for (final roll in base.bonusDrops) {
          expect(
            def.bonusDrops.any(
              (r) => r.chance == roll.chance && r.entries == roll.entries,
            ),
            isTrue,
          );
        }
      });

      test('a tenth of kills, one of every skill\'s basic ${b.slot.name}', () {
        final gear = def.bonusDrops
            .where((r) => !base.bonusDrops.any((o) => o.entries == r.entries))
            .toList();
        expect(gear, hasLength(1));
        expect(gear.single.chance, 0.1);
        final ids = gear.single.entries.map((e) => e.id).toSet();
        expect(ids, basicPieces(b.slot));
        expect(ids, hasLength(11));
        // evenly
        expect(gear.single.entries.map((e) => e.weight).toSet(), {1});
      });
    });
  }

  test('the tables are the shared ones', () {
    expect(
      (EntityId.CAVE_BEAR.definition as CombatEntityDefinition).bonusDrops.any(
        (r) => r.entries == basicSkillingHeadDropTable,
      ),
      isTrue,
    );
  });
}
