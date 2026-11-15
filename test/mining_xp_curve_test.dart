import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// Mining pays for the harder vein: at every level, the hardest vein on the
/// ore ladder the player can mine — with the best pickaxe that level wears —
/// is worth the most xp an hour. A harder vein is mined slower, so each point
/// of damage against it pays more ([EncounterEntityDefinition.xpPerDamage]).
void main() {
  late GameSession session;
  late SaveGameData save;

  setUp(() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    save = factory.newGame(catalogs);
    session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  });

  tearDown(() => session.dispose());

  // the gold and gem veins sit beside a ladder rung and are held to it below
  const ladder = [
    EntityId.COPPER,
    EntityId.IRON,
    EntityId.COAL_VEIN,
    EntityId.MITHRIL_VEIN,
    EntityId.ADAMANTITE_VEIN,
    EntityId.RUNITE_VEIN,
    EntityId.DRAGONITE_VEIN,
  ];
  const picks = [
    (1, ItemId.COPPER_PICKAXE),
    (20, ItemId.IRON_PICKAXE),
    (40, ItemId.STEEL_PICKAXE),
    (60, ItemId.MITHRIL_PICKAXE),
    (70, ItemId.ADAMANT_PICKAXE),
    (80, ItemId.RUNE_PICKAXE),
    (90, ItemId.DRAGON_PICKAXE),
  ];

  EncounterEntityDefinition def(EntityId id) =>
      id.definition as EncounterEntityDefinition;

  double xpPerHourAt(int level, EntityId vein) {
    final data = save.playerData.skillData[SkillId.MINING]!;
    data.xp = data.xpTable[level];
    final pick = picks.lastWhere((p) => p.$1 <= level).$2;
    save.playerData.equipmentData.equipedTools[SkillId.MINING] =
        EquipmentItem(id: pick);
    final details = session.worldController.entityDetails(
      vein.build() as EncounterEntity,
    );
    return details.playerDamagePerSecond * 3600 * def(vein).xpPerDamage;
  }

  test('the hardest vein reached pays the most xp an hour', () {
    for (var level = 1; level <= 99; level++) {
      final reached = ladder
          .where((v) => def(v).requiredLevel <= level)
          .toList();
      final top = reached.last;
      final topXp = xpPerHourAt(level, top);
      for (final lower in reached.take(reached.length - 1)) {
        expect(
          topXp,
          greaterThan(xpPerHourAt(level, lower)),
          reason: 'at mining $level, ${lower.name} out-earns ${top.name}',
        );
      }
    }
  });

  test('a side vein pays what its rung does', () {
    expect(
      def(EntityId.GOLD_VEIN).xpPerDamage,
      def(EntityId.COAL_VEIN).xpPerDamage,
    );
    expect(
      def(EntityId.GEM_VEIN).xpPerDamage,
      def(EntityId.MITHRIL_VEIN).xpPerDamage,
    );
  });
}
