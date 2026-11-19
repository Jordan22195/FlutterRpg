import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// Fishing pays for going further out: at every level, the deepest water the
/// player reaches — with the best rod that level wears — is worth the most
/// xp an hour. A low spot's small pool lets a strong cast overkill it into
/// several catches, so the fish further out carry far more xp each to stay
/// ahead.
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

  // the main ladder; the Murky Marsh is the River's reagent-heavy twin and
  // is held to its own check below
  const ladder = [
    EntityId.TRANQUIL_POND,
    EntityId.CREEK,
    EntityId.RIVER,
    EntityId.DEEP_POND,
    EntityId.LAKE,
    EntityId.OCEAN,
  ];
  const rods = [
    (1, ItemId.COPPER_FISHING_ROD),
    (20, ItemId.IRON_FISHING_ROD),
    (40, ItemId.STEEL_FISHING_ROD),
    (60, ItemId.MITHRIL_FISHING_ROD),
    (70, ItemId.ADAMANT_FISHING_ROD),
    (80, ItemId.RUNE_FISHING_ROD),
    (90, ItemId.DRAGON_FISHING_ROD),
  ];

  int requiredLevel(EntityId id) =>
      (id.definition as FishingEntityDefinition).requiredLevel;

  double xpPerHourAt(int level, EntityId spot) {
    final data = save.playerData.skillData[SkillId.FISHING]!;
    data.xp = data.xpTable[level];
    final rod = rods.lastWhere((r) => r.$1 <= level).$2;
    save.playerData.equipmentData.equipedTools[SkillId.FISHING] = EquipmentItem(
      id: rod,
    );
    return session.worldController
        .entityDetails(spot.build() as EncounterEntity)
        .playerXpPerHour;
  }

  test('the deepest water reached pays the most xp an hour', () {
    for (var level = 1; level <= 99; level++) {
      final reached = ladder.where((s) => requiredLevel(s) <= level).toList();
      final top = reached.last;
      final topXp = xpPerHourAt(level, top);
      for (final lower in reached.take(reached.length - 1)) {
        expect(
          topXp,
          greaterThan(xpPerHourAt(level, lower)),
          reason: 'at fishing $level, ${lower.name} out-earns ${top.name}',
        );
      }
    }
  });

  test('the marsh trades some xp for its reagents, and beats the creek', () {
    for (
      var level = requiredLevel(EntityId.MURKY_MARSH);
      level < requiredLevel(EntityId.DEEP_POND);
      level++
    ) {
      final marsh = xpPerHourAt(level, EntityId.MURKY_MARSH);
      expect(marsh, lessThan(xpPerHourAt(level, EntityId.RIVER)));
      expect(marsh, greaterThan(xpPerHourAt(level, EntityId.CREEK)));
    }
  });
}
