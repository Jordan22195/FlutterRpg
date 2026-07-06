import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/game_session.dart';

void main() {
  test('SaveGameData survives a JSON round trip', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);

    final encoded = jsonEncode(save.toJson());
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final restored = SaveGameData.fromJson(decoded);

    expect(restored.slotId, save.slotId);
    expect(restored.contentPackId, save.contentPackId);
    expect(
      restored.playerData.currentZoneId,
      save.playerData.currentZoneId,
    );
    expect(
      restored.worldData.zones.keys,
      save.worldData.zones.keys,
    );
    expect(
      restored.worldData.zones.values.map((z) => z.permanentEntities.length),
      save.worldData.zones.values.map((z) => z.permanentEntities.length),
    );
  });
}
