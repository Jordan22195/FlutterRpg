import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/game_session.dart';

void main() {
  test('loading repairs entities duplicated as permanent and discovered', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);

    final farm = save.worldData.zones[ZoneId.TUTORIAL_FARM]!;

    // corrupt the save the way older versions did: the pond (permanent)
    // also sits in the discovered list with a non-zero count
    final duplicate =
        catalogs.entityCatalog.buildEntity(EntityId.TRANQUIL_POND)
            as EncounterEntity;
    duplicate.count = 3;
    farm.discoveredEntities.add(duplicate);

    // and a doubled permanent entry
    farm.permanentEntities.add(
      catalogs.entityCatalog.buildEntity(EntityId.TRANQUIL_POND),
    );

    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    // exactly one pond remains, in the permanent list only
    expect(
      farm.permanentEntities.where((e) => e.id == EntityId.TRANQUIL_POND),
      hasLength(1),
    );
    expect(
      farm.discoveredEntities.where((e) => e.id == EntityId.TRANQUIL_POND),
      isEmpty,
    );

    // legitimately discovered entities are untouched
    final tree = catalogs.entityCatalog.buildEntity(EntityId.TREE);
    farm.discoveredEntities.add(tree);
    expect(farm.discoveredEntities, contains(tree));

    session.dispose();
  });
}
