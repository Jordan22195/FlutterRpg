import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/data/firemaking_recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';

/// The top of the woodcutting ladder: maple, yew and magic, their logs,
/// fires and bird's nests, and the two skilling groves the yew and magic
/// trees grow in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EncounterEntityDefinition tree(EntityId id) =>
      id.definition as EncounterEntityDefinition;

  const ladder = [
    (EntityId.MAPLE_TREE, ItemId.MAPLE_LOGS, ItemId.STURDY_BIRDS_NEST),
    (EntityId.YEW_TREE, ItemId.YEW_LOGS, ItemId.GILDED_BIRDS_NEST),
    (EntityId.MAGIC_TREE, ItemId.MAGIC_LOGS, ItemId.ENCHANTED_BIRDS_NEST),
  ];

  test('each tree gives its own logs and nest, and climbs past the last', () {
    var lastDefence = 0;
    var lastValue = 0;
    for (final (id, logs, nest) in ladder) {
      final def = tree(id);
      expect(def.entityType, SkillId.WOODCUTTING);
      expect(def.itemDrops.single.id, logs, reason: id.name);
      expect(
        def.bonusDrops.expand((r) => r.entries).map((e) => e.id),
        contains(nest),
        reason: id.name,
      );
      expect(def.defence, greaterThan(lastDefence), reason: id.name);
      expect(logs.definition.value, greaterThan(lastValue), reason: id.name);
      lastDefence = def.defence;
      lastValue = logs.definition.value;
    }
  });

  test('every log tier from maple up lays a cookfire and every bonfire', () {
    final reagents = [
      for (final id in ItemId.values)
        if (id.definition is FireReagentDefinition) id,
    ];
    for (final (_, logs, _) in ladder) {
      final fires = firemakingRecipes
          .where((r) => r.inputs.containsKey(logs))
          .map((r) => r.output.single.id.definition)
          .whereType<FireItemDefinition>()
          .toList();
      expect(fires.where((f) => f.canCook), hasLength(1), reason: logs.name);
      expect(
        fires.where((f) => f.isBonfire).map((f) => f.reagent).toSet(),
        reagents.toSet(),
        reason: logs.name,
      );
    }
  });

  test('firemaking levels climb with the wood, and stay under 99', () {
    final woods = [ItemId.MAPLE_LOGS, ItemId.YEW_LOGS, ItemId.MAGIC_LOGS];
    var lastCook = 0;
    var lastBonfire = 0;
    for (final logs in woods) {
      final cook = firemakingRecipes.singleWhere(
        (r) =>
            r.inputs.containsKey(logs) &&
            (r.output.single.id.definition as FireItemDefinition).canCook,
      );
      expect(cook.levelRequirement, greaterThan(lastCook), reason: logs.name);
      lastCook = cook.levelRequirement;
      final bonfire = bonfireWoods[logs]!.level;
      expect(bonfire, greaterThan(lastBonfire), reason: logs.name);
      lastBonfire = bonfire;
      for (final r in firemakingRecipes.where(
        (r) => r.inputs.containsKey(logs),
      )) {
        expect(r.levelRequirement, lessThan(99), reason: r.id);
      }
    }
  });

  test('every nest tier opens, one gear tier each', () {
    for (final nest in [
      ItemId.SMALL_BIRDS_NEST,
      ItemId.WOVEN_BIRDS_NEST,
      ItemId.STURDY_BIRDS_NEST,
      ItemId.GILDED_BIRDS_NEST,
      ItemId.ENCHANTED_BIRDS_NEST,
    ]) {
      expect(birdsNestRolls.containsKey(nest), isTrue, reason: nest.name);
    }
    final gearTiers = {
      for (final rolls in birdsNestRolls.values)
        for (final roll in rolls)
          for (final e in roll.entries)
            if (e.id.definition case SkillingGearDefinition(:final tier)) tier,
    };
    expect(gearTiers, hasLength(5));
  });

  group('the groves', () {
    test('Old Yew Grove is one road up from Maplewater Lake', () {
      expect(
        ZoneTravelGraph.travelHops(ZoneId.MAPLEWATER_LAKE, ZoneId.YEW_GROVE),
        1,
      );
      expect(zoneNodeCenter(ZoneId.YEW_GROVE), isNotNull);
    });

    test('Witchlight Grove lies past the yews', () {
      expect(
        ZoneTravelGraph.travelPath(ZoneId.MAPLEWATER_LAKE, ZoneId.MAGIC_GROVE),
        [ZoneId.MAPLEWATER_LAKE, ZoneId.YEW_GROVE, ZoneId.MAGIC_GROVE],
      );
      expect(zoneNodeCenter(ZoneId.MAGIC_GROVE), isNotNull);
      expect(
        ZoneId.MAGIC_GROVE.definition.explorationLevel,
        greaterThan(ZoneId.YEW_GROVE.definition.explorationLevel),
      );
    });

    test('each grove is woodcutting only, mostly its own tree', () {
      for (final (zone, main) in [
        (ZoneId.YEW_GROVE, EntityId.YEW_TREE),
        (ZoneId.MAGIC_GROVE, EntityId.MAGIC_TREE),
      ]) {
        final def = zone.definition;
        expect(def.requiredSkill, SkillId.WOODCUTTING, reason: zone.name);
        expect(def.permanentEntities, contains(EntityId.FIREPIT));
        final finds = def.discoverableEntities;
        for (final e in finds) {
          expect(tree(e.id).entityType, SkillId.WOODCUTTING, reason: zone.name);
        }
        final top = finds.reduce((a, b) => a.weight >= b.weight ? a : b);
        expect(top.id, main, reason: zone.name);
      }
    });
  });
}
