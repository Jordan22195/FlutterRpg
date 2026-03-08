import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/momentum_loop_controller.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/services/world_service.dart';
import '../data/encounter_data.dart';
import '../services/encounter_service.dart';
import '../systems/encounter_system.dart';

// controllers coordinate between ui and systems or services
// services coordinate multiple services

class EncounterController extends ChangeNotifier {
  // nonserialized data
  final EncounterData _encounterState;

  // controllers
  final ActionTimingController _actionTimingController;

  // data
  final PlayerData _playerState;
  final WorldData _worldState;
  final InventoryData _inventoryState;

  // services
  final EncounterService _encounterService;
  final WorldService _worldService;
  final PlayerDataService _playerDataService;

  //systems
  final EncounterSystem _encounterSystem;
  final PlayerStatSystem _playerStatSystem;

  ActionResult latestActionResult = ActionResult();

  EncounterController({
    required PlayerData playerData,
    required EncounterData encounterState,

    required EncounterService encounterService,
    required WorldData worldState,
    required WorldService worldService,
    required EquipmentData equpmentState,
    required ActionTimingController actionTimingController,
    required EntityCatalog entityCatalog,
    required WeightedDropTableService dropTableService,
    required PlayerDataService playerDataService,
    required InventoryData inventoryState,
    required InventoryService inventoryService,
    required ItemCatalog itemCatalog,
    required EncounterSystem encounterSystem,
    required PlayerStatSystem playerStatSystem,
  }) : _playerState = playerData,
       _encounterState = encounterState,
       _encounterService = encounterService,
       _worldState = worldState,
       _worldService = worldService,
       _actionTimingController = actionTimingController,
       _playerDataService = playerDataService,
       _inventoryState = inventoryState,
       _encounterSystem = encounterSystem,
       _playerStatSystem = playerStatSystem;

  void doFishingEncounterAction() {
    final stats = _playerStatSystem.getStatTotals(_playerState);

    latestActionResult = _encounterSystem.executeFishingAction(
      stats: stats,
      player: _playerState,
      encounter: _encounterState,
      world: _worldState,
      playerInventory: _inventoryState,
    );
    notifyListeners();
  }

  // function bound to action button. executes periodically.
  void doEncounterAction() {
    final stats = _playerStatSystem.getStatTotals(_playerState);

    latestActionResult = _encounterSystem.executePlayerAction(
      stats: stats,
      player: _playerState,
      encounter: _encounterState,
      world: _worldState,
      playerInventory: _inventoryState,
    );

    // check action conditions are met before the action fires again
    if (!_encounterService.encounterConditionsMet(
      _playerState,
      _encounterState,
    )) {
      // stop action timing
      _actionTimingController.stop();
      // todo reset encouter state
    }
    notifyListeners();
  }

  // todo move this logic to the enoucnter system
  // fire a single time when action button is pressed
  void startEncounterAction() {
    // get the player view entity
    final entity = _worldService.getSelectedEntity(_playerState, _worldState);

    // check if this is a new entity
    final isNew = _encounterService.isNewEntity(_encounterState, entity);

    // if the entity is not new
    if (!isNew) {
      // return, and continue action with current entity.
      return;
    }

    // stop action timing
    _actionTimingController.stop();

    // set as active entity in encounter state.
    _encounterService.setEncounterEntity(
      _encounterState,
      entity as EncounterEntity,
    );

    // check action conditions are met
    if (!_encounterService.encounterConditionsMet(
      _playerState,
      _encounterState,
    )) {
      return;
    }
    // bind Encounter action to action timing controller
    _actionTimingController.bindOnFireFunction(doEncounterAction);

    // start action timing
    _actionTimingController.start();
  }

  // function bound to eat button
  void eatSingleEquipedFood() {
    _playerDataService.eatEquipedFood(_playerState);
  }

  // populates encounter hp bar percentage - needs to move to entity view controller
  double getHealthPercent() {
    final e = _encounterState.entity;
    if (e!.maxHitPoints <= 0) return 0.0;
    return (e.hitpoints / e.maxHitPoints).clamp(0.0, 1.0);
  }
}
