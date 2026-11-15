import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';

/// The skilling mines: Forest Mine and the two mines off it and Ironroot
/// Hills. Each one's veins are ordered by rarity, and the two new mines are
/// one road off the zone they hang from.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The drop weight of [entity] in [zone]'s discovery table.
  double weight(ZoneId zone, EntityId entity) => zone
      .definition
      .discoverableEntities
      .firstWhere((e) => e.id == entity)
      .weight
      .toDouble();

  /// That [order] runs from most to least common in [zone].
  void expectDescending(ZoneId zone, List<EntityId> order) {
    for (var i = 1; i < order.length; i++) {
      expect(
        weight(zone, order[i - 1]),
        greaterThan(weight(zone, order[i])),
        reason: '${order[i - 1].name} before ${order[i].name} in ${zone.name}',
      );
    }
  }

  Set<EntityId> veins(ZoneId zone) => {
    for (final e in zone.definition.discoverableEntities)
      if (e.id.definition case EncounterEntityDefinition(
        entityType: SkillId.MINING,
      ))
        e.id,
  };

  test('Forest Mine: copper, then iron, coal uncommon, gold rare', () {
    expectDescending(ZoneId.FOREST_MINE, [
      EntityId.COPPER,
      EntityId.IRON,
      EntityId.COAL_VEIN,
      EntityId.GOLD_VEIN,
    ]);
  });

  group('Forest Mine Depths', () {
    const zone = ZoneId.FOREST_MINE_DEPTHS;

    test('is one road down from the Forest Mine, and only from there', () {
      expect(ZoneTravelGraph.travelHops(ZoneId.FOREST_MINE, zone), 1);
      expect(ZoneTravelGraph.travelPath(ZoneId.SOUTH_HAVEN, zone), [
        ZoneId.SOUTH_HAVEN,
        ZoneId.FOREST_MINE,
        zone,
      ]);
      expect(zoneNodeCenter(zone), isNotNull);
    });

    test('holds coal, iron, gold, mithril and gems, in that order', () {
      final order = [
        EntityId.COAL_VEIN,
        EntityId.IRON,
        EntityId.GOLD_VEIN,
        EntityId.MITHRIL_VEIN,
        EntityId.GEM_VEIN,
      ];
      expect(veins(zone), order.toSet());
      expectDescending(zone, order);
    });

    test('is harder to enter than the first level', () {
      final first = ZoneId.FOREST_MINE.definition;
      expect(zone.definition.requiredSkill, SkillId.MINING);
      expect(zone.definition.requiredLevel, greaterThan(first.requiredLevel));
      expect(
        zone.definition.explorationLevel,
        greaterThan(first.explorationLevel),
      );
    });
  });

  group('Ironroot Mine', () {
    const zone = ZoneId.IRONROOT_MINE;

    test('is one road off Ironroot Hills, and only from there', () {
      expect(ZoneTravelGraph.travelHops(ZoneId.IRONROOT_HILLS, zone), 1);
      expect(ZoneTravelGraph.travelPath(ZoneId.IRON_GATE_CITY, zone), [
        ZoneId.IRON_GATE_CITY,
        ZoneId.IRONROOT_HILLS,
        zone,
      ]);
      expect(zoneNodeCenter(zone), isNotNull);
    });

    test('holds coal, mithril, adamantite, and runite as the rare find', () {
      final order = [
        EntityId.COAL_VEIN,
        EntityId.MITHRIL_VEIN,
        EntityId.ADAMANTITE_VEIN,
        EntityId.RUNITE_VEIN,
      ];
      expect(veins(zone), order.toSet());
      expectDescending(zone, order);
    });
  });

  test('both new mines are pure skilling: no monsters to find', () {
    for (final zone in [ZoneId.FOREST_MINE_DEPTHS, ZoneId.IRONROOT_MINE]) {
      expect(
        zone.definition.discoverableEntities.map((e) => e.id).toSet(),
        veins(zone),
        reason: zone.name,
      );
    }
  });
}
