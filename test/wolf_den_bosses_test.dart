import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';

// The Wolf Den's three bosses: each is its family's ordinary monster, drops
// and all, and none of the skilling gear sets in its drops.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final floors = {
    for (final card in DungeonId.WOLF_DEN.definition.entries) card.name: card,
  };

  final bosses = [
    (
      floor: 'Cave Entrance',
      boss: EntityId.CAVE_BEAR,
      base: EntityId.BEAR,
      rarity: Rarity.RARE,
    ),
    (
      floor: 'Deep Lair',
      boss: EntityId.DEN_ALPHA_WOLF,
      base: EntityId.FOREST_WOLF,
      rarity: Rarity.RARE,
    ),
    (
      floor: 'Sunken Grotto',
      boss: EntityId.GROTTO_FUNGAL_MONSTER,
      base: EntityId.FUNGAL_MONSTER,
      rarity: Rarity.COMMON,
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

      // the grotto boss has a haul of its own, covered in wolf_den_set_test
      if (b.boss != EntityId.GROTTO_FUNGAL_MONSTER)
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

      test('rolls no skilling gear', () {
        final dropped = [
          ...def.itemDrops.map((d) => d.id),
          for (final roll in def.bonusDrops) ...roll.entries.map((e) => e.id),
        ];
        expect(
          dropped.where((id) => id.definition is SkillingGearDefinition),
          isEmpty,
        );
      });
    });
  }
}
