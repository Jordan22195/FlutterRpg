import 'package:flutter/widgets.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/enchanting_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import '../catalogs/zone_catalog.dart';
import '../services/player_data_service.dart';
import '../services/world_service.dart';
import '../catalogs/entity_catalog.dart';
import '../services/weighted_drop_table_service.dart';
import '../services/entity_screen_router_service.dart';

class WorldController extends ChangeNotifier {
  // controllers
  final ActionTimingController _actionTimingController;
  final EncounterController _encounterController;
  final CraftingController _craftingController;
  final EnchantingController _enchantingController;

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
  final PlayerDataService _playerDataService;

  WorldController({
    required WorldData worldState,
    required WorldService worldService,
    required PlayerData playerState,
    required ZoneCatalog zoneCatalog,
    required WeightedDropTableService dropTableService,
    required EntityCatalog entityCatalog,
    required EntityScreenRouterService entityScreenRouterService,
    required PlayerDataService playerDataService,
    required ActionTimingController actionTimingController,
    required EncounterController encounterController,
    required CraftingController craftingController,
    required EnchantingController enchantingController,
  }) : _dropTableService = dropTableService,
       _playerDataService = playerDataService,
       _worldService = worldService,
       _zoneCatalog = zoneCatalog,
       _worldState = worldState,
       _entityCatalog = entityCatalog,
       _playerState = playerState,
       _entityScreenRouterService = entityScreenRouterService,
       _actionTimingController = actionTimingController,
       _encounterController = encounterController,
       _craftingController = craftingController,
       _enchantingController = enchantingController;

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

  // ---- zone travel ----

  ZoneId get currentZoneId => _playerState.currentZoneId;

  ZoneDefinition zoneDefinition(ZoneId zoneId) {
    return _zoneCatalog.getDefinitionFor(zoneId);
  }

  /// The zone graph's edges, for drawing the travel paths on the map.
  List<(ZoneId, ZoneId, double)> travelEdges() {
    return ZoneCatalog.travelEdges();
  }

  /// Stamina cost to travel from the player's zone to [target], summed
  /// along the path through the zone tree.
  double travelCostTo(ZoneId target) {
    return _zoneCatalog.travelCost(_playerState.currentZoneId, target);
  }

  bool canAffordTravelTo(ZoneId target) {
    return _playerState.stamina >= travelCostTo(target);
  }

  bool meetsZoneRequirement(ZoneId target) {
    final def = _zoneCatalog.getDefinitionFor(target);
    if (def.requiredSkill == SkillId.NULL || def.requiredLevel <= 0) {
      return true;
    }
    final level =
        _playerDataService.getStatTotals(_playerState)[def.requiredSkill] ?? 0;
    return level >= def.requiredLevel;
  }

  /// Moves the player to [target], paying the path's stamina cost.
  /// Returns false when the level requirement isn't met or stamina can't
  /// cover the cost. Re-entering the current zone is free.
  bool travelToZone(ZoneId target) {
    if (target == _playerState.currentZoneId) return true;
    if (!meetsZoneRequirement(target)) return false;

    final cost = travelCostTo(target);
    if (cost.isInfinite || _playerState.stamina < cost) return false;

    _playerDataService.changeStamina(-cost, _playerState);
    _playerDataService.setCurrentZone(target, _playerState);
    notifyListeners();
    return true;
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

    // finished encounter/crafting/enchanting sessions clear their
    // drops on navigation
    _encounterController.onEntityViewChanged();
    _craftingController.onEntityViewChanged();
    _enchantingController.onEntityViewChanged();
  }
}
