import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/skill_unlocks.dart';
import 'package:rpg/game_session.dart';

// the skill detail screen's unlocks card
void main() {
  final catalogs = GameSessionFactory().catalog1();
  List<SkillUnlock> rows(SkillId s) => unlocksForSkill(s, catalogs);

  test('every mining and woodcutting node is listed, gated or not', () {
    final mining = rows(SkillId.MINING).where((r) => r.category == 'Gathering');
    expect(
      mining.expand((r) => r.icons),
      containsAll([EntityId.COPPER, EntityId.MITHRIL_VEIN]),
    );
    expect(mining.every((r) => r.levelRequirement >= 1), isTrue);

    final wood = rows(
      SkillId.WOODCUTTING,
    ).where((r) => r.category == 'Gathering');
    expect(
      wood.expand((r) => r.icons),
      containsAll([EntityId.TREE, EntityId.MAPLE_TREE]),
    );
  });

  test('a tree or vein is gated by its own defence', () {
    for (final id in EntityId.values) {
      final def = id.definition;
      if (def is! EncounterEntityDefinition) continue;
      if (def.entityType != SkillId.MINING &&
          def.entityType != SkillId.WOODCUTTING) {
        continue;
      }
      expect(def.requiredLevel, def.defence, reason: def.name);
    }
    final rows = unlocksForSkill(SkillId.MINING, catalogs);
    expect(
      rows
          .firstWhere((r) => r.icons.contains(EntityId.ADAMANTITE_VEIN))
          .levelRequirement,
      55,
    );
  });

  test('gear sets are listed at the level that gates them', () {
    final fishing = rows(SkillId.FISHING).where((r) => r.category == 'Gear');
    final novice = fishing.firstWhere((r) => r.name == 'Novice set');
    expect(novice.levelRequirement, 20);
    expect(novice.icons.length, greaterThan(1));
    expect(novice.icons.every((i) => i is ItemId), isTrue);
  });

  test('rows are sorted by level and gear rows carry icons', () {
    for (final skill in SkillId.values) {
      final r = rows(skill);
      for (var i = 1; i < r.length; i++) {
        expect(
          r[i].levelRequirement,
          greaterThanOrEqualTo(r[i - 1].levelRequirement),
        );
      }
      for (final row in r.where((x) => x.category == 'Gear')) {
        expect(row.icons, isNotEmpty);
      }
    }
  });

  test('only the zone and gear unlocks remain for attack and exploration', () {
    expect(
      rows(SkillId.ATTACK).map((r) => r.category).toSet(),
      everyElement(equals('Gear')),
    );
    expect(rows(SkillId.EXPLORATION).map((r) => r.category).toSet(), {
      'Zone',
      'Gear',
    });
  });

  test('fishing lists fish and gear, not spots', () {
    final fishing = rows(SkillId.FISHING);
    expect(fishing.map((r) => r.category).toSet(), {'Fish', 'Gear'});
    final carp = fishing.firstWhere((r) => r.name == 'Carp');
    expect(carp.levelRequirement, 5);
    expect(carp.icons, [ItemId.CARP]);
  });

  test('cooked food shows its icon and what it heals', () {
    final chicken = rows(
      SkillId.COOKING,
    ).firstWhere((r) => r.name == 'Cooked Chicken');
    expect(chicken.icons, [ItemId.COOKED_CHICKEN]);
    expect(chicken.detail, startsWith('Heals '));
  });

  test('crafting recipes carry the icon of what they make', () {
    for (final skill in [
      SkillId.BLACKSMITHING,
      SkillId.JEWELCRAFTING,
      SkillId.ALCHEMY,
    ]) {
      final recipes = rows(skill).where((r) => r.category == 'Recipe');
      expect(recipes, isNotEmpty);
      expect(
        recipes.every((r) => r.icons.length == 1),
        isTrue,
        reason: '$skill',
      );
    }
  });
}
