import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/bound_action.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/widgets/stance_button.dart';

/// A chest opened from the bag is spent, so the gathering loot window that
/// listed it stops listing it.
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

  const nest = ItemId.SMALL_BIRDS_NEST;

  test('opening a chest takes it off the session loot', () {
    save.inventoryData.itemMap[nest] = 3;
    save.encounterData.itemDrops.itemMap[nest] = 3;

    session.inventoryController.openNests(nest, max: 1);
    expect(save.encounterData.itemDrops.itemMap[nest], 2);

    session.inventoryController.openNests(nest);
    expect(save.encounterData.itemDrops.itemMap.containsKey(nest), isFalse);
  });

  test('chests held from before the session leave its loot at zero', () {
    // five in the bag, only two of them found this session
    save.inventoryData.itemMap[nest] = 5;
    save.encounterData.itemDrops.itemMap[nest] = 2;

    session.inventoryController.openNests(nest);
    expect(save.encounterData.itemDrops.itemMap.containsKey(nest), isFalse);
    expect(save.inventoryData.itemMap[nest] ?? 0, 0);
  });

  group('the stance picker', () {
    test('shows while idle and while working something with stances', () {
      expect(runningActionOffersStances(null), isTrue);
      expect(
        runningActionOffersStances(
          const BoundAction.encounter(
            zoneId: ZoneId.TUTORIAL_FARM,
            entityId: EntityId.GOBLIN,
          ),
        ),
        isTrue,
      );
      expect(
        runningActionOffersStances(
          const BoundAction.encounter(
            zoneId: ZoneId.TUTORIAL_FARM,
            entityId: EntityId.TREE,
          ),
        ),
        isTrue,
      );
    });

    test('hides while the loop runs something that has none', () {
      expect(
        runningActionOffersStances(
          const BoundAction.explore(zoneId: ZoneId.TUTORIAL_FARM),
        ),
        isFalse,
      );
      expect(
        runningActionOffersStances(
          const BoundAction.encounter(
            zoneId: ZoneId.TUTORIAL_FARM,
            entityId: EntityId.GUAM,
          ),
        ),
        isFalse,
      );
    });
  });
}
