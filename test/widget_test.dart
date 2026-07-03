import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/game_session.dart';

void main() {
  test('new game save data builds from catalogs', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);

    expect(save.playerData.skillData, isNotEmpty);
    expect(save.worldData.zones, isNotEmpty);

    // round-trips through json
    final restored = SaveGameData.fromJson(save.toJson());
    expect(restored.slotId, save.slotId);
    expect(restored.worldData.zones.length, save.worldData.zones.length);
  });
}
