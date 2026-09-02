import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// The Ashen Foothills are the rung above the swamp, and the only place
/// mithril is mined.
///
/// The mithril ore, the bar and all ten pieces of mithril gear shipped as
/// items with no way to obtain any of them — no node dropped the ore and no
/// recipe smelted the bar. This zone is what closes that chain.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WeightedDropTableEntry<EntityId>? entryFor(ZoneId zone, EntityId entity) {
    for (final e in zone.definition.discoverableEntities) {
      if (e.id == entity) return e;
    }
    return null;
  }

  group('Ashen Foothills', () {
    test('sits beyond the swamp, which is how you get there', () {
      final graph = ZoneTravelGraph();

      expect(ZoneTravelGraph.travelHops(ZoneId.SWAMP, ZoneId.FOOTHILLS), 1);
      expect(
        ZoneTravelGraph.travelPath(ZoneId.TUTORIAL_FARM, ZoneId.FOOTHILLS),
        [
          ZoneId.TUTORIAL_FARM,
          ZoneId.SOUTHWOOD_FOREST,
          ZoneId.SOUTH_HAVEN,
          ZoneId.SWAMP,
          ZoneId.FOOTHILLS,
        ],
      );
      expect(ZoneTravelGraph.isFreeZone(ZoneId.FOOTHILLS), isFalse);
      expect(graph.travelCost(ZoneId.SWAMP, ZoneId.FOOTHILLS), greaterThan(0));
    });

    test('is drawn on the world map, inside the canvas', () {
      final centre = zoneNodeCenter(ZoneId.FOOTHILLS);
      expect(centre, isNotNull, reason: 'the zone needs a map node');
      expect(centre!.dx, inInclusiveRange(0, kWorldMapSize.width));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
    });

    test('outranks the swamp the road reaches it through', () {
      final foothills = ZoneId.FOOTHILLS.definition;
      expect(
        foothills.explorationLevel,
        greaterThan(ZoneId.SWAMP.definition.explorationLevel),
      );
      expect(foothills.xpPerExplore, greaterThan(0));
    });

    test('has a firepit, the way every wilderness zone does', () {
      expect(
        ZoneId.FOOTHILLS.definition.permanentEntities,
        contains(EntityId.FIREPIT),
      );
    });

    test('holds the roster the archetypes were written for', () {
      for (final id in [
        EntityId.HARPY,
        EntityId.IMP,
        EntityId.ORC,
        EntityId.TROLL,
        EntityId.HILL_GIANT,
      ]) {
        expect(
          entryFor(ZoneId.FOOTHILLS, id),
          isNotNull,
          reason: '${id.name} should live in the foothills',
        );
      }
    });

    test('the two heaviest are gated behind the zone door', () {
      for (final id in [EntityId.TROLL, EntityId.HILL_GIANT]) {
        expect(
          entryFor(ZoneId.FOOTHILLS, id)!.unlockLevel,
          greaterThan(ZoneId.FOOTHILLS.definition.explorationLevel),
          reason: '${id.name} should not greet you at the door',
        );
      }
    });
  });

  group('mithril is reachable', () {
    test('the vein is here, and it is tier 4 mining', () {
      expect(entryFor(ZoneId.FOOTHILLS, EntityId.MITHRIL_VEIN), isNotNull);

      final coal = EntityId.COAL_VEIN.definition as EncounterEntityDefinition;
      final mithril =
          EntityId.MITHRIL_VEIN.definition as EncounterEntityDefinition;

      expect(mithril.entityType, SkillId.MINING);
      expect(
        mithril.defence,
        greaterThan(coal.defence),
        reason: 'mithril is the rung above the darkwood coal',
      );
    });

    test('the vein drops the ore it is named for', () {
      final def = EntityId.MITHRIL_VEIN.definition as EncounterEntityDefinition;
      expect(def.itemDrops.map((d) => d.id), contains(ItemId.MITHRIL_ORE));
    });

    test('and nothing else in the game yields mithril ore', () {
      // the point of the node: before it, the ore and the whole gear tier
      // behind it were unobtainable
      final sources = <String>[];
      for (final id in EntityId.values) {
        final def = id.definition;
        if (def is! EncounterEntityDefinition) continue;
        final drops = {
          ...def.itemDrops.map((d) => d.id),
          for (final roll in def.bonusDrops) ...roll.entries.map((d) => d.id),
        };
        if (drops.contains(ItemId.MITHRIL_ORE)) sources.add(id.name);
      }
      expect(sources, ['MITHRIL_VEIN']);
    });

    test('the ore smelts, and the bar forges every mithril piece', () {
      final recipes = RecipeCatalog();
      CraftingRecipe? making(ItemId item) {
        for (final r in recipes.recipes) {
          if (r.output.any((o) => o.id == item)) return r;
        }
        return null;
      }

      final bar = making(ItemId.MITHRIL_BAR);
      expect(bar, isNotNull, reason: 'nothing smelts a mithril bar');
      expect(bar!.inputs.keys, contains(ItemId.MITHRIL_ORE));

      final gear = ItemId.values.where(
        (i) =>
            i.name.startsWith('MITHRIL_') &&
            i != ItemId.MITHRIL_BAR &&
            i != ItemId.MITHRIL_ORE,
      );
      expect(gear, isNotEmpty);
      for (final item in gear) {
        expect(making(item), isNotNull, reason: 'nothing forges ${item.name}');
      }
    });
  });
}
