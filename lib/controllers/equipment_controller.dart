import 'package:flutter/foundation.dart';
import '../catalogs/items/items.dart';
import '../data/equipment_data.dart';
import '../data/inventory_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/equipment_service.dart';
import '../services/player_data_service.dart';
import '../services/skill_service.dart';
import '../systems/equipment_system.dart';

class EquipmentController extends ChangeNotifier {
  // data
  final PlayerData _playerState;
  final InventoryData _inventoryState;

  // services
  final EquipmentService _equipmentService;
  final PlayerDataService _playerDataService;
  final SkillService _skillService;

  // systems
  final EquipmentSystem _equipmentSystem;

  EquipmentController({
    required PlayerData playerState,
    required InventoryData inventoryState,
    required EquipmentService equipmentService,
    required PlayerDataService playerDataService,
    required SkillService skillService,
    required EquipmentSystem equipmentSystem,
  }) : _playerState = playerState,
       _inventoryState = inventoryState,
       _equipmentService = equipmentService,
       _playerDataService = playerDataService,
       _skillService = skillService,
       _equipmentSystem = equipmentSystem;

  /// The levels the player has earned, which is what a piece's requirement
  /// is measured against — deliberately not [getStatTotals], so gear cannot
  /// count its own bonus toward its own requirement.
  Map<SkillId, int> get _skillLevels => {
    for (final entry in _playerState.skillData.entries)
      entry.key: _skillService.getLevel(entry.value),
  };

  /// What [item] asks of the player before it can be worn, or null when it
  /// asks nothing. For showing the gate in the UI; [canEquip] applies it.
  ({SkillId skill, int level})? requirementFor(EquipmentItem item) =>
      _equipmentService.requirementFor(item);

  /// Whether the player is skilled enough to wear [item] right now.
  bool canEquip(EquipmentItem item) =>
      _equipmentService.meetsRequirement(item, _skillLevels);

  EquipmentItem? getItemInSlot(ArmorSlots slot) {
    return _equipmentService.getItemInSlot(slot, _playerState.equipmentData);
  }

  /// Combined effective bonuses from all equipped armor, weapons, and tools.
  Map<SkillId, int> getStatTotals() {
    return _equipmentService.getStatTotals(_playerState.equipmentData);
  }

  /// Every stat the player has, split by where it comes from: levels earned,
  /// gear worn, potions drunk, and the stance. The total is the number the
  /// game itself plays by, not a re-added sum, so the readout cannot drift
  /// from the stats being used.
  ({
    Map<SkillId, int> skills,
    Map<SkillId, int> gear,
    Map<SkillId, int> buffs,
    Map<SkillId, int> stance,
    Map<SkillId, int> total,
  })
  getStatBreakdown() => _playerDataService.getStatBreakdown(_playerState);

  /// [toSlot] picks between the slots the item accepts, for gear with more
  /// than one home (rings); without it the first empty one wins. False when
  /// the piece asks for a level the player has not earned.
  bool equipItem(EquipmentItem item, {ArmorSlots? toSlot}) {
    final equipped = _equipmentSystem.equipItem(
      item,
      _playerState.equipmentData,
      _inventoryState,
      skillLevels: _skillLevels,
      toSlot: toSlot,
    );
    notifyListeners();
    return equipped;
  }

  // the tool equipped for a gathering skill
  EquipmentItem? getToolForSkill(SkillId skill) {
    return _equipmentService.getToolForSkill(skill, _playerState.equipmentData);
  }

  /// False when the tool asks for a level the player has not earned.
  bool equipToolForSkill(SkillId skill, EquipmentItem item) {
    final equipped = _equipmentSystem.equipTool(
      skill,
      item,
      _playerState.equipmentData,
      _inventoryState,
      skillLevels: _skillLevels,
    );
    notifyListeners();
    return equipped;
  }

  // the equipped weapon; combat entities use this as their 'tool'
  EquipmentItem? getEquipedWeapon() {
    return getItemInSlot(ArmorSlots.WEAPON_2H) ??
        getItemInSlot(ArmorSlots.WEAPON_1H);
  }

  void setEquipedFood(ItemId itemId) {
    _equipmentService.setEquipedFood(itemId, _playerState.equipmentData);
    notifyListeners();
  }

  void unequipSlot(ArmorSlots slot) {
    _equipmentSystem.unequipSlot(
      slot,
      _playerState.equipmentData,
      _inventoryState,
    );
    notifyListeners();
  }

  void unequipToolForSkill(SkillId skill) {
    _equipmentSystem.unequipTool(
      skill,
      _playerState.equipmentData,
      _inventoryState,
    );
    notifyListeners();
  }
}
