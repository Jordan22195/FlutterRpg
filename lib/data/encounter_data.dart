import 'inventory_data.dart';
import '../catalogs/entity_catalog.dart';

class EncounterData {
  InventoryData itemDrops = InventoryData(itemMap: {});
  int lastPlayerDamage = 0;
  bool isActive = false;
  bool respawning = false;
  EncounterEntity? entity;
}
