import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/services/world_service.dart';
import '../data/encounter_data.dart';
import '../services/encounter_service.dart';
import '../systems/encounter_system.dart';
import '../services/inventory_service.dart';
import '../data/ObjectStack.dart';

// controllers coordinate between ui and systems or services
// systems coordinate multiple services

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
  final InventoryService _inventoryService;

  //systems
  final EncounterSystem _encounterSystem;

  ActionResult latestActionResult = ActionResult();

  EncounterController({
    required PlayerData playerData,
    required EncounterData encounterState,

    required EncounterService encounterService,
    required WorldData worldState,
    required WorldService worldService,
    required ActionTimingController actionTimingController,
    required EntityCatalog entityCatalog,
    required WeightedDropTableService dropTableService,
    required PlayerDataService playerDataService,
    required InventoryData inventoryState,
    required InventoryService inventoryService,
    required ItemCatalog itemCatalog,
    required EncounterSystem encounterSystem,
  }) : _playerState = playerData,
       _encounterState = encounterState,
       _encounterService = encounterService,
       _worldState = worldState,
       _worldService = worldService,
       _actionTimingController = actionTimingController,
       _playerDataService = playerDataService,
       _inventoryState = inventoryState,
       _encounterSystem = encounterSystem,
       _inventoryService = inventoryService;

  void doFishingEncounterAction() {
    latestActionResult = _encounterSystem.executeFishingAction(
      playerState: _playerState,
      encounter: _encounterState,
      world: _worldState,
      playerInventory: _inventoryState,
    );

    // check action conditions are met before the action fires again
    if (!_encounterService.fishingConditionsMet(
      _playerState,
      _encounterState,
    )) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  // function bound to action button in startEncounterAction.
  // This executes periodically.
  // 
  void doEncounterAction() {
    latestActionResult = _encounterSystem.executePlayerAction(
      playerState: _playerState,
      encounter: _encounterState,
      worldState: _worldState,
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
  // fires a single time when action button is pressed
  // binds the entity's encounter action to the periodic loop
  void startEncounterAction() {
    // get the player view entity
    final entity = _worldService.getSelectedEntity(_playerState, _worldState);
    if (entity is! EncounterEntity) {
      return;
    }

    // fishing spots don't deplete or fight back, so they run their own
    // action with looser start conditions than combat/gathering encounters
    final isFishing = entity.entityType == SkillId.FISHING;
    final action = isFishing ? doFishingEncounterAction : doEncounterAction;

    // same entity with its action already running: let it continue.
    // (a stopped action on the same entity falls through and restarts)
    if (!_encounterService.isNewEntity(_encounterState, entity) &&
        _actionTimingController.isRunningAction(action)) {
      return;
    }

    // stop action timing
    _actionTimingController.stop();

    // set as active entity in encounter state.
    _encounterService.setEncounterEntity(_encounterState, entity);

    // check action conditions are met
    final conditionsMet = isFishing
        ? _encounterService.fishingConditionsMet(_playerState, _encounterState)
        : _encounterService.encounterConditionsMet(
            _playerState,
            _encounterState,
          );
    if (!conditionsMet) {
      return;
    }

    // bind the encounter action to the action timing controller.
    // same icon + count the entity's card shows on the explore screen.
    _actionTimingController.bindOnFireFunction(
      action,
      activityIconId: entity.id,
      activityCount: () => _encounterState.entity?.count ?? 0,
    );

    // start action timing
    _actionTimingController.start();
  }

  // function bound to eat button
  void eatSingleEquipedFood() {
    _playerDataService.eatEquipedFood(_playerState);
  }

  // resolves the entity the player is viewing. prefers the live encounter
  // entity so in-progress state is shown; before the first action starts
  // (or after viewing a different entity) falls back to the selected world entity
  EncounterEntity? _resolveViewedEntity() {
    final active = _encounterState.entity;
    if (active != null && active.id == _playerState.currentEntityViewId) {
      return active;
    }
    final selected = _worldService.getSelectedEntity(_playerState, _worldState);
    return selected is EncounterEntity ? selected : null;
  }

  // populates encounter hp bar percentage - needs to move to entity view controller
  double getHealthPercent() {
    final e = _resolveViewedEntity();
    if (e == null || e.maxHitPoints <= 0) return 0.0;
    return (e.hitpoints / e.maxHitPoints).clamp(0.0, 1.0);
  }

  // todo make this not return the mutable entity state. instead return
  // a snapshot or copy of the entity
  EncounterEntity getActiveEntity() {
    return _resolveViewedEntity() ??
        EncounterEntity(
          id: EntityId.NULL,
          name: "null",
          count: 0,
          entityType: SkillId.NULL,
          defence: 0,
          hitpoints: 0,
        );
  }

  bool respawning() {
    return _encounterState.respawning;
  }

  bool isCombatEntity() {
    return (_resolveViewedEntity() is CombatEntity);
  }

  List<ObjectStack> itemDrops() {
    return _inventoryService.getObjectStackList(_encounterState.itemDrops);
  }

  ItemId getEquipedFoodItemId() {
    return _playerState.equipmentData.equipedFood;
  }

  int getEquipedFoodItemCount() {
    final id = _playerState.equipmentData.equipedFood;
    return _inventoryService.getItemCount(_inventoryState, id);
  }

  void setEquipedFood(ItemId id) {}

  ItemId getEquipedTool() {
    return ItemId.NULL;
  }

  void equipTool(ItemId id) {}

  Map<SkillId, int> getPlayerStats() {
    return _playerDataService.getStatTotals(_playerState);
  }

  int getPlayerHp() {
    return _playerState.hitpoints;
  }
}
