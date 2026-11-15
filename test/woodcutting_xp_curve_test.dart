import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// Woodcutting pays for the harder tree: at every level, the hardest tree
/// the player can cut — with the best axe that level wears — is worth the
/// most xp an hour. A harder tree is chopped slower, so each point of damage
/// against it pays more ([EncounterEntityDefinition.xpPerDamage]).
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

  // the Bog Tree is the Willow's swamp twin and is held to it below
  const ladder = [
    EntityId.TREE,
    EntityId.OAK_TREE,
    EntityId.WILLOW_TREE,
    EntityId.MAPLE_TREE,
    EntityId.YEW_TREE,
    EntityId.MAGIC_TREE,
  ];
  const axes = [
    (1, ItemId.COPPER_AXE),
    (20, ItemId.IRON_AXE),
    (40, ItemId.STEEL_AXE),
    (60, ItemId.MITHRIL_AXE),
    (70, ItemId.ADAMANT_AXE),
    (80, ItemId.RUNE_AXE),
    (90, ItemId.DRAGON_AXE),
  ];

  int requiredLevel(EntityId id) =>
      (id.definition as EncounterEntityDefinition).requiredLevel;

  double xpPerHourAt(int level, EntityId tree) {
    final data = save.playerData.skillData[SkillId.WOODCUTTING]!;
    data.xp = data.xpTable[level];
    final axe = axes.lastWhere((a) => a.$1 <= level).$2;
    save.playerData.equipmentData.equipedTools[SkillId.WOODCUTTING] =
        EquipmentItem(id: axe);
    final details = session.worldController.entityDetails(
      tree.build() as EncounterEntity,
    );
    final def = tree.definition as EncounterEntityDefinition;
    return details.playerDamagePerSecond * 3600 * def.xpPerDamage;
  }

  test('the hardest tree reached pays the most xp an hour', () {
    for (var level = 1; level <= 99; level++) {
      final reached = ladder.where((t) => requiredLevel(t) <= level).toList();
      final top = reached.last;
      final topXp = xpPerHourAt(level, top);
      for (final lower in reached.take(reached.length - 1)) {
        expect(
          topXp,
          greaterThan(xpPerHourAt(level, lower)),
          reason: 'at woodcutting $level, ${lower.name} out-earns ${top.name}',
        );
      }
    }
  });

  test('a fell pays its scaled xp', () {
    final oak = EntityId.OAK_TREE.build() as EncounterEntity;
    final def = EntityId.OAK_TREE.definition as EncounterEntityDefinition;
    expect(
      session.worldController.entityDetails(oak).xpPerUnit,
      def.hitpoints * def.xpPerDamage,
    );
  });

  test('the bog tree pays what the willow does', () {
    final bog = EntityId.BOG_TREE.definition as EncounterEntityDefinition;
    final willow = EntityId.WILLOW_TREE.definition as EncounterEntityDefinition;
    expect(bog.xpPerDamage, willow.xpPerDamage);
  });
}
