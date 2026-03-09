import 'package:rpg/catalogs/recipe_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/equipment_controller.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/crafting_state.dart';
import 'package:rpg/data/encounter_data.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/crafting_service.dart';
import 'package:rpg/services/encounter_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/services/world_service.dart';
import 'package:rpg/systems/crafting_system.dart';
import 'package:rpg/systems/encounter_system.dart';
import 'package:rpg/systems/equipment_system.dart';

import 'data/inventory_data.dart';

class GameSession {
  // game state data
  PlayerData playerState;
  InventoryData playerInventory;
  WorldData worldState;
  BuffData buffData;
  CraftingState craftingState;
  EncounterData encounterData;
  EquipmentData equipmentData;
  Map<SkillId, SkillData> skillData;

  // catalogs
  ItemCatalog itemCatalog;
  EntityCatalog entityCatalog;
  RecipeCatalog recipeCatalog;
  ZoneCatalog zoneCatalog;

  // controllers
  PlayerDataController playerDataController;
  EncounterController encounterController;
  BuffController buffController;
  CraftingController craftingController;
  EquipmentController equipmentController;
  WorldController worldController;

  // services
  BuffService buffService;
  CraftingService craftingService;
  EncounterService encounterService;
  EquipmentService equipmentService;
  InventoryService inventoryService;
  PlayerDataService playerDataService;
  SkillService skillService;
  WeightedDropTableService weightedDropTableService;
  WorldService worldService;

  // systems
  CraftingSystem craftingSystem;
  EncounterSystem encounterSystem;
  EquipmentSystem equipmentSystem;

  GameSession({
    // data
    required this.playerState,
    required this.playerInventory,
    required this.worldState,
    required this.buffData,
    required this.craftingState,
    required this.encounterData,
    required this.equipmentData,
    required this.skillData,

    // catalogs
    required this.itemCatalog,
    required this.entityCatalog,
    required this.recipeCatalog,
    required this.zoneCatalog,

    // controllers
    required this.playerDataController,
    required this.encounterController,
    required this.buffController,
    required this.craftingController,
    required this.equipmentController,
    required this.worldController,

    // services
    required this.buffService,
    required this.craftingService,
    required this.encounterService,
    required this.equipmentService,
    required this.inventoryService,
    required this.playerDataService,
    required this.skillService,
    required this.weightedDropTableService,
    required this.worldService,

    // systems
    required this.craftingSystem,
    required this.encounterSystem,
    required this.equipmentSystem,
  });
}
