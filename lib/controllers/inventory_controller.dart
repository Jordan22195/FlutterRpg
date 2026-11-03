import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/scouting_result.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/systems/exploration_system.dart';
import 'package:rpg/systems/potion_system.dart';

class InventoryController extends ChangeNotifier {
  final InventoryData _inventoryData;
  final BuffData _buffState;

  final InventoryService _inventoryService;
  final PotionSystem _potionSystem;
  final ExplorationSystem _explorationSystem;
  final PlayerData _playerState;
  final WorldData _worldState;

  /// Called after a scouting map has added entities to a zone, so whatever
  /// shows the world follows. Wired in GameSessionFactory, since the world
  /// controller is built after this one.
  VoidCallback? onZoneScouted;

  InventoryController({
    required InventoryData inventoryData,
    required BuffData buffState,
    required InventoryService inventoryService,
    required PotionSystem potionSystem,
    required ExplorationSystem explorationSystem,
    required PlayerData playerState,
    required WorldData worldState,
  }) : _inventoryData = inventoryData,
       _buffState = buffState,
       _inventoryService = inventoryService,
       _potionSystem = potionSystem,
       _explorationSystem = explorationSystem,
       _playerState = playerState,
       _worldState = worldState;

  // inventory data is mutated by other domains (encounter drops, crafting,
  // equipment). those controllers are wired to call this in GameSessionFactory
  void refresh() {
    notifyListeners();
  }

  List<ObjectStack> getObjectStackList() {
    return _inventoryService.getObjectStackList(_inventoryData);
  }

  int getItemCount(ItemId id) {
    return _inventoryService.getItemCount(_inventoryData, id);
  }

  // dev/testing helper: force a stack to a specific count
  void devSetItemCount(ItemId id, int count) {
    _inventoryService.setItemCount(_inventoryData, id, count);
    notifyListeners();
  }

  int getEquipmentCount(EquipmentItem item) {
    return _inventoryService.getEquipmentCount(_inventoryData, item);
  }

  // dev/testing helper: force the equipment stack matching this item's
  // identity to a specific count
  void devSetEquipmentCount(EquipmentItem item, int count) {
    _inventoryService.setEquipmentCount(_inventoryData, item, count);
    notifyListeners();
  }

  // dev/testing helper: force the quality of the whole equipment stack
  // matching this item's identity. returns the stack it landed on, which is
  // a different instance when the new quality merged it into an existing one
  EquipmentItem? devSetEquipmentQuality(EquipmentItem item, Rarity quality) {
    final stack = _inventoryService.setEquipmentQuality(
      _inventoryData,
      item,
      quality,
    );
    if (stack != null) notifyListeners();
    return stack;
  }

  ItemDefinition? getItemDefinition(ItemId id) {
    return id.definition;
  }

  /// Whether [id] is a potion at all — true for something drinkable in
  /// principle, whether or not the player is holding one.
  bool isDrinkable(ItemId id) => _potionSystem.isDrinkable(id);

  /// Drinks one [id] out of the inventory, putting its buff up. False when
  /// [id] is not a potion or there is none left to drink.
  bool drinkPotion(ItemId id) {
    final drank = _potionSystem.drink(id, _inventoryData, _buffState);
    if (drank) notifyListeners();
    return drank;
  }

  /// Whether [id] is something the player can use from the bag: a scouting
  /// map, in principle, whether or not they are holding one.
  bool isUsable(ItemId id) => ScoutingMaps.isMap(id);

  /// Uses one [id] from the bag. For a scouting map that discovers its
  /// zone's entities and returns what turned up; null when [id] is not a map,
  /// there is none left, or its zone has nothing to find (the map is kept).
  ScoutingResult? useItem(ItemId id) {
    final result = _explorationSystem.useScoutingMap(
      id: id,
      playerState: _playerState,
      worldState: _worldState,
      inventory: _inventoryData,
    );
    if (result == null) return null;
    notifyListeners();
    onZoneScouted?.call();
    return result;
  }

  List<ItemId> getFoodItems() {
    return _inventoryService.getFoodItemsSortedByHealing(_inventoryData);
  }

  // unique equipment instances in the inventory (unequipped)
  List<EquipmentItem> getEquipmentList() {
    return List.unmodifiable(_inventoryData.equipment);
  }

  List<EquipmentItem> getSlotItemList(ArmorSlots slot) {
    return _inventoryService.getEquipmentForSlot(slot, _inventoryData);
  }

  List<EquipmentItem> getSlotItemListForSkill(
    ArmorSlots slot,
    SkillId skillId,
  ) {
    return _inventoryService.getEquipmentForSlotAndSkill(
      slot,
      _inventoryData,
      skillId,
    );
  }
}
