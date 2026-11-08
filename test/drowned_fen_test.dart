import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/data/alchemy_recipes.dart';
import 'package:rpg/data/skill_data.dart';

// Blackmire Swamp's dungeon and the super potions it feeds. The Drowned Fen
// is a step past the Spider Den on the level ladder, but its gear is the
// Spider Den's at the same strength, on slots the den leaves empty.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fen = DungeonId.DROWNED_FEN.definition;
  int levelOf(EntityId id) => (id.definition as CombatEntityDefinition).level;

  group('Drowned Fen', () {
    test('is entered from Blackmire Swamp', () {
      final entrance =
          EntityId.DROWNED_FEN_ENTRANCE.definition as DungeonEntityDefinition;
      expect(entrance.dungeonId, DungeonId.DROWNED_FEN);
      expect(fen.type, DungeonType.ZONE);
    });

    test('runs three cards of twenty-five fights', () {
      expect(fen.entries.map((c) => c.name), [
        'Reedbank',
        'Ooze Pits',
        'Murkjaw Nest',
      ]);
      for (final card in fen.entries) {
        final fights = card.entities.fold(0, (sum, e) => sum + e.count);
        expect(fights, 25, reason: card.name);
      }
    });

    test('its mobs run L34-55 and its bosses 55, 55, 89', () {
      final bosses = [for (final card in fen.entries) card.entities.last];
      expect(bosses.map((b) => b.entityId), [
        EntityId.MURDER_KING,
        EntityId.PRIMORDIAL_OOZE,
        EntityId.MURKJAW_MATRIARCH,
      ]);
      expect(bosses.map((b) => levelOf(b.entityId)), [55, 55, 89]);
      for (final b in bosses) {
        expect(
          (b.entityId.definition as CombatEntityDefinition).isDungeonBoss,
          isTrue,
        );
      }

      for (final card in fen.entries) {
        for (final mob in card.entities.take(card.entities.length - 1)) {
          expect(
            levelOf(mob.entityId),
            inInclusiveRange(34, 55),
            reason: '${card.name}: ${mob.entityId.name}',
          );
        }
      }
    });

    test('its gear matches the Spider Den piece for piece', () {
      EquipmentItemDefinition eq(ItemId id) =>
          id.definition as EquipmentItemDefinition;
      int weight(ItemId id) =>
          eq(id).statWeights.values.fold(0, (sum, w) => sum + w);

      const pairs = {
        ItemId.WEBBED_CLOAK: ItemId.OOZE_SLICK_BELT,
        ItemId.VENOMFANG_RING: ItemId.CROWQUILL_BRACERS,
        ItemId.SPIDER_SILK_NECKLACE: ItemId.MURKJAW_PAULDRONS,
      };
      final spiderSlots = pairs.keys.map((id) => eq(id).armorSlot).toSet();
      for (final MapEntry(key: spider, value: swamp) in pairs.entries) {
        expect(eq(swamp).fibLevel, eq(spider).fibLevel, reason: swamp.name);
        expect(weight(swamp), weight(spider), reason: swamp.name);
        expect(spiderSlots, isNot(contains(eq(swamp).armorSlot)));
      }

      // the two trim pieces both carry strength
      for (final id in [ItemId.CROWQUILL_BRACERS, ItemId.OOZE_SLICK_BELT]) {
        expect(eq(id).statWeights, contains(SkillId.STRENGTH), reason: id.name);
      }
    });
  });

  group('super potions', () {
    const supers = {
      ItemId.SUPER_RECOVERY_POTION: SkillId.RECOVERY,
      ItemId.SUPER_FISHING_POTION: SkillId.FISHING,
      ItemId.SUPER_STAMINA_POTION: SkillId.STAMINA,
      ItemId.SUPER_DEFENCE_POTION: SkillId.DEFENCE,
      ItemId.SUPER_SPEED_POTION: SkillId.SPEED,
      ItemId.SUPER_STRENGTH_POTION: SkillId.STRENGTH,
      ItemId.SUPER_ATTACK_POTION: SkillId.ATTACK,
    };

    test('give +13, the Fibonacci rung past the standard tier', () {
      for (final MapEntry(key: id, value: skill) in supers.entries) {
        final def = id.definition as BuffItemDefinition;
        expect(def.skillBonus, {skill: 13}, reason: id.name);
      }
    });

    test('are brewed from mirecap and a swamp reagent', () {
      for (final id in supers.keys) {
        final recipe = alchemyRecipes.singleWhere(
          (r) => r.output.any((o) => o.id == id),
        );
        expect(recipe.inputs.keys, contains(ItemId.MIRECAP), reason: id.name);
        expect(recipe.inputs, hasLength(2), reason: id.name);
      }
    });
  });
}
