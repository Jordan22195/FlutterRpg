import 'package:flutter/widgets.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';

import '../catalogs/zone_catalog.dart';
import '../services/world_service.dart';
import '../catalogs/entity_catalog.dart';
import '../services/weighted_drop_table_service.dart';
import '../data/ObjectStack.dart';

class WorldController extends ChangeNotifier {
  // data
  final PlayerData _playerState;
  final WorldData _worldState;

  // catalogs
  final ZoneCatalog _zoneCatalog;
  final EntityCatalog _entityCatalog;

  // services
  final WorldService _worldService;
  final WeightedDropTableService _dropTableService;

  WorldController({
    required WorldData worldState,
    required WorldService worldService,
    required PlayerData playerState,
    required ZoneCatalog zoneCatalog,
    required WeightedDropTableService dropTableService,
    required EntityCatalog entityCatalog,
  }) : _dropTableService = dropTableService,
       _worldService = worldService,
       _zoneCatalog = zoneCatalog,
       _worldState = worldState,
       _entityCatalog = entityCatalog,
       _playerState = playerState;

  List<Entity> getCurrentZoneEntities() {
    final list = _worldService.getCurrentZoneEntities(
      _playerState,
      _worldState,
    );
    return list;
  }

  ZoneDefinition getCurrentZoneDefinition() {
    return _zoneCatalog.getDefinitionFor(_playerState.currentZoneId);
  }

  void discoverEntity() {
    final entries = _worldService.getZoneDropTableEntries(
      _playerState,
      _zoneCatalog,
    );
    final newEntity = _dropTableService.roll(entries);
    _worldService.addEntityToCurrentZone(
      newEntity as ObjectStack<EntityId>,
      _entityCatalog,
      _playerState,
      _worldState,
    );
    notifyListeners();
  }
}
