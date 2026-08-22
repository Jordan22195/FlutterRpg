import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/game_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explore finds hit both inventories and clear on activity swap', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final world = session.worldController;
    final inventory = save.inventoryData;

    expect(save.playerData.currentZoneId, ZoneId.TUTORIAL_FARM);

    world.startExplore();
    for (var i = 0; i < 300; i++) {
      world.doExplore(1);
    }

    final finds = world.getCurrentZoneItems();
    expect(finds, isNotEmpty, reason: 'coins should drop within 300 rolls');
    for (final stack in finds) {
      expect(
        inventory.itemMap[stack.id],
        stack.count,
        reason: 'player inventory mirrors the explore find list',
      );
    }

    // another activity takes over the action loop
    session.actionTimingController.stop();
    session.actionTimingController.bindOnFireFunction((_, {offline = false, at, span}) {});
    session.actionTimingController.start();
    expect(world.getCurrentZoneItems(), isEmpty);

    // the next explore session starts from an empty find list, but the
    // player keeps everything they already picked up
    world.startExplore();
    expect(world.getCurrentZoneItems(), isEmpty);
    expect(inventory.itemMap, isNotEmpty);

    // pausing and resuming the same session keeps the finds on screen
    world.doExplore(1);
    final resumed = world.getCurrentZoneItems();
    world.stopExplore();
    world.startExplore();
    expect(world.getCurrentZoneItems().length, resumed.length);
  });
}
