import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'support/gathering_tools.dart';

// Fishing trains at about the rate blacksmithing does. At each spot's own
// level, what casting pays a second - catch chance, the rod's overkill
// catches and the fish table all in - sits close to what smelting the best
// bar at that level pays.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a cast at each spot pays about what a smelt does at its level', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final session = factory.create(
      save: withGatheringTools(factory.newGame(catalogs)),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final player = session.saveGameData.playerData;
    final encounters = session.encounterService;
    void setLevel(SkillId skill, int level) {
      final data = player.skillData[skill]!;
      data.xp = data.xpTable[level];
    }

    final smelts = RecipeCatalog()
        .recipesForSkill(SkillId.BLACKSMITHING)
        .where((r) => r.id.startsWith('smelt_'))
        .toList();

    for (final id in [
      EntityId.TRANQUIL_POND,
      EntityId.CREEK,
      EntityId.RIVER,
      EntityId.DEEP_POND,
      EntityId.LAKE,
      EntityId.OCEAN,
    ]) {
      final def = id.definition as EncounterEntityDefinition;
      final level = def.requiredLevel;
      setLevel(SkillId.FISHING, level);
      setLevel(SkillId.BLACKSMITHING, level);

      final fishing = session.playerDataService.getStatTotals(
        player,
      )[SkillId.FISHING]!;
      // the rod's swing at the spot, as a live cast rolls it
      final maxHit = session.encounterSystem.playerSwingMaxHit(
        player,
        id.build() as EncounterEntity,
      )!;
      final table = def.dropTableAt(fishing);
      var weight = 0.0;
      var xp = 0.0;
      for (final entry in table) {
        weight += entry.weight;
        xp += entry.weight * entry.id.id.definition.xpValue * entry.count;
      }
      final perCast =
          encounters.chanceToHit(fishing, def.defence) *
          encounters.meanCatchesPerHit(maxHit, def.hitpoints) *
          xp /
          weight;

      final perSmelt = smelts
          .where((r) => r.levelRequirement <= level)
          .map((r) => r.xp)
          .reduce((a, b) => a > b ? a : b);

      // per second, not per action: a rod swings at a tool's pace, a hair
      // off the bench's in the fast stance
      double seconds(SkillId skill) =>
          session.actionTimingSystem.intervalFor(skill, player).inMicroseconds /
          1e6;
      final castRate = perCast / seconds(SkillId.FISHING);
      final smeltRate = perSmelt / seconds(SkillId.BLACKSMITHING);
      expect(
        castRate / smeltRate,
        inInclusiveRange(0.8, 1.2),
        reason:
            '${id.name} at $level: casting pays '
            '${castRate.toStringAsFixed(2)}/s, smelting '
            '${smeltRate.toStringAsFixed(2)}/s',
      );
    }
    session.dispose();
  });
}
