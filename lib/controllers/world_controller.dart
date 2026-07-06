import 'package:flutter/widgets.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import '../catalogs/zone_catalog.dart';
import '../services/world_service.dart';
import '../catalogs/entity_catalog.dart';
import '../services/weighted_drop_table_service.dart';
import '../services/entity_screen_router_service.dart';

class WorldController extends ChangeNotifier {
  // controllers
  final ActionTimingController _actionTimingController;
  final EncounterController _encounterController;
  final CraftingController _craftingController;

  // data
  final PlayerData _playerState;
  final WorldData _worldState;

  // catalogs
  final ZoneCatalog _zoneCatalog;
  final EntityCatalog _entityCatalog;

  // services
  final WorldService _worldService;
  final WeightedDropTableService _dropTableService;
  final EntityScreenRouterService _entityScreenRouterService;

  WorldController({
    required WorldData worldState,
    required WorldService worldService,
    required PlayerData playerState,
    required ZoneCatalog zoneCatalog,
    required WeightedDropTableService dropTableService,
    required EntityCatalog entityCatalog,
    required EntityScreenRouterService entityScreenRouterService,
    required ActionTimingController actionTimingController,
    required EncounterController encounterController,
    required CraftingController craftingController,
  }) : _dropTableService = dropTableService,
       _worldService = worldService,
       _zoneCatalog = zoneCatalog,
       _worldState = worldState,
       _entityCatalog = entityCatalog,
       _playerState = playerState,
       _entityScreenRouterService = entityScreenRouterService,
       _actionTimingController = actionTimingController,
       _encounterController = encounterController,
       _craftingController = craftingController;

  // world data (entity counts, removals) is mutated by other domains
  // (encounter kills/catches). those controllers are wired to call this
  // in GameSessionFactory
  void refresh() {
    notifyListeners();
  }

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

  // fires a single time when the explore button is pressed
  // binds doExplore to the periodic loop
  void startExplore() {
    // if already exploring, continue the current explore action
    if (_actionTimingController.isRunningAction(doExplore)) {
      return;
    }

    // stop action timing
    _actionTimingController.stop();

    // bind explore action to action timing controller
    _actionTimingController.bindOnFireFunction(
      doExplore,
      activityIconId: SkillId.EXPLORATION,
    );

    // start action timing
    _actionTimingController.start();
  }

  // function bound to action button in startExplore.
  // This executes periodically.
  void doExplore() {
    final entries = _worldService.getZoneDropTableEntries(
      _playerState,
      _zoneCatalog,
    );
    final newEntity = _dropTableService.roll(entries);
    _worldService.addEntityToCurrentZone(
      newEntity.id,
      newEntity.count,
      _entityCatalog,
      _playerState,
      _worldState,
    );
    notifyListeners();
  }

  void stopExplore() {
    // stop action timing
    _actionTimingController.stop();
    notifyListeners();
  }

  void navigateToEntity(EntityId entityId, BuildContext context) {
    _entityScreenRouterService.navigateToEntity(entityId, context);

    // todo: move this. break paradigm of only mutating data in services.
    _playerState.currentEntityViewId = entityId;

    // finished encounter/crafting sessions clear their drops on navigation
    _encounterController.onEntityViewChanged();
    _craftingController.onEntityViewChanged();
  }
}
