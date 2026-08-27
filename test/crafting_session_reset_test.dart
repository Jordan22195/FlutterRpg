import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// Starting a craft clears the station's crafted-items session in more cases
// than "moved to a different station": switching to a different recipe at
// the same station is also a new session, even though the earlier crafts
// stay valid inventory-wise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  test('switching to a different recipe at the same station clears the '
      'previous recipe\'s crafted items', () {
    final session = buildSession();
    final save = session.saveGameData;
    save.playerData.currentEntityViewId = EntityId.ANVIL;
    save.inventoryData.itemMap[ItemId.COPPER_ORE] = 200;
    setLevel(session, SkillId.BLACKSMITHING, 16);

    expect(
      session.craftingController.startCraftingActionFor(
        'smelt_copper_bar',
        EntityId.ANVIL,
      ),
      isTrue,
    );

    // simulate output already produced this session, as the craft loop
    // would have via craftActiveRecipe
    save.craftingState.craftedItems.itemMap[ItemId.COPPER_BAR] = 5;
    expect(session.craftingController.craftedItems(), isNotEmpty);

    save.inventoryData.itemMap[ItemId.COPPER_BAR] = 200;
    expect(
      session.craftingController.startCraftingActionFor(
        'forge_copper_dagger',
        EntityId.ANVIL,
      ),
      isTrue,
    );

    expect(session.craftingController.craftedItems(), isEmpty);
    expect(session.craftingController.craftedEquipment(), isEmpty);

    session.actionTimingController.stop();
    session.dispose();
  });

  test('the clear on a new recipe notifies listeners synchronously, not '
      'only once a craft fires', () {
    final session = buildSession();
    final save = session.saveGameData;
    save.playerData.currentEntityViewId = EntityId.ANVIL;
    save.inventoryData.itemMap[ItemId.COPPER_ORE] = 200;
    setLevel(session, SkillId.BLACKSMITHING, 16);

    expect(
      session.craftingController.startCraftingActionFor(
        'smelt_copper_bar',
        EntityId.ANVIL,
      ),
      isTrue,
    );
    save.craftingState.craftedItems.itemMap[ItemId.COPPER_BAR] = 5;
    save.inventoryData.itemMap[ItemId.COPPER_BAR] = 200;

    var notified = false;
    session.craftingController.addListener(() => notified = true);

    session.craftingController.startCraftingActionFor(
      'forge_copper_dagger',
      EntityId.ANVIL,
    );

    // the screen must repaint as soon as startCraftingAction runs, not
    // wait on the first tick of the new recipe to notice the items cleared
    expect(notified, isTrue);

    session.actionTimingController.stop();
    session.dispose();
  });

  test('resuming the same stopped recipe at the same station keeps its '
      'crafted items', () {
    final session = buildSession();
    final save = session.saveGameData;
    save.playerData.currentEntityViewId = EntityId.ANVIL;
    save.inventoryData.itemMap[ItemId.COPPER_ORE] = 200;

    expect(
      session.craftingController.startCraftingActionFor(
        'smelt_copper_bar',
        EntityId.ANVIL,
      ),
      isTrue,
    );

    save.craftingState.craftedItems.itemMap[ItemId.COPPER_BAR] = 5;
    session.actionTimingController.stop();

    expect(
      session.craftingController.startCraftingActionFor(
        'smelt_copper_bar',
        EntityId.ANVIL,
      ),
      isTrue,
    );

    expect(
      session.craftingController.craftedItems().fold<int>(
        0,
        (sum, stack) => sum + stack.count,
      ),
      5,
    );

    session.actionTimingController.stop();
    session.dispose();
  });
}
