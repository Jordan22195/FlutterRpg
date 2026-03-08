import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/catalogs/location_catalog.dart';

import 'data/inventory_data.dart';

class GameSession {
  // game state data
  PlayerData playerState;
  InventoryData playerInventory;
  Map<SkillId, SkillData> playerSkills;
  WorldData worldState;
  BuffData buffState;
  EncounterData encounterStates;

  // catalogs
  ItemCatalog itemCatalog;
  EntityCatalog entityCatalog;
  ZoneCatalog zoneCatalog;
  LocationCatalog locationCatalog;

  // controllers
  PlayerDataController playerDataController;
  EncounterController encounterController;
  Z
  // services

  GameSession({
    required this.playerState,
    required this.playerInventory,
    required this.playerSkills,
    required this.worldState,
    required this.buffState,
    required this.encounterStates,
    required this.itemCatalog,
    required this.entityCatalog,
    required this.zoneCatalog,
    required this.locationCatalog,
    //
    required this.playerDataController,
    required this.encounterController,
  });
}
