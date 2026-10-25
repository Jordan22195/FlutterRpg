import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/game_session.dart';
import 'support/gathering_tools.dart';

// A relaunch picks the running action back up, and the session it was in
// with it: what the encounter screen says was gathered this session
// survives the app being closed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a relaunch keeps what the session had gathered', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final first = factory.create(
      save: withGatheringTools(factory.newGame(catalogs)),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final save = first.saveGameData;
    final zone = save.worldData.zones[save.playerData.currentZoneId]!;
    final pond =
        zone.permanentEntities.firstWhere((e) => e.id == EntityId.TRANQUIL_POND)
            as EncounterEntity;

    // on the pond's screen, as the player is when they close the app
    save.playerData.currentEntityViewId = EntityId.TRANQUIL_POND;
    expect(first.encounterController.startEncounterActionFor(pond), isTrue);
    for (var i = 0; i < 20; i++) {
      first.encounterController.doFishingEncounterAction(1);
    }
    final gathered = Map.of(save.encounterData.itemDrops.itemMap);
    expect(gathered.values.fold<int>(0, (a, b) => a + b), greaterThan(0));

    // closed with the cast still running, and opened again
    final json = jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
    first.actionTimingController.stop();
    first.dispose();

    final second = factory.create(
      save: SaveGameData.fromJson(json),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final reloaded = second.saveGameData;
    final reloadedPond = reloaded
        .worldData
        .zones[reloaded.playerData.currentZoneId]!
        .permanentEntities
        .firstWhere((e) => e.id == EntityId.TRANQUIL_POND);
    // the encounter is on the zone's own pond again, not a copy of it
    expect(identical(reloaded.encounterData.entity, reloadedPond), isTrue);

    second.resumeBoundAction();
    expect(second.actionTimingController.isTicking, isTrue);
    expect(reloaded.encounterData.itemDrops.itemMap, gathered);
    expect(
      second.encounterController.itemDrops().map((s) => s.id).toSet(),
      gathered.keys.toSet(),
    );

    second.actionTimingController.stop();
    second.dispose();
  });
}
