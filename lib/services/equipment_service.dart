import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import '../catalogs/item_catalog.dart';
import '../utilities/util.dart';

class EquipmentService {
  Map<SkillId, int> getStatTotals(EquipmentData equipmentState) {
    Map<SkillId, int> stats = {};
    for (final item in equipmentState.armorEquipment.values) {
      if (item == null) continue;
      stats = Util.addMap(stats, item.effectiveSkillBonus);
    }

    // each per-skill tool contributes only the bonus for the skill it
    // is equipped under (an axe's attack bonus doesn't leak into combat)
    for (final entry in equipmentState.equipedTools.entries) {
      final item = entry.value;
      if (item == null) continue;
      final bonus = item.effectiveSkillBonus[entry.key];
      if (bonus != null) {
        stats = Util.addMap(stats, {entry.key: bonus});
      }
    }
    return stats;
  }

  /// Equips [item] into its slot, applying weapon exclusivity rules.
  /// Returns the instances displaced by the swap (so they can be put
  /// back in the inventory), or null when the item can't be equipped
  /// this way (tools go through [equipTool]).
  List<EquipmentItem>? equipItem(EquipmentItem item, EquipmentData eq) {
    final displaced = <EquipmentItem>[];

    void displace(ArmorSlots slot) {
      final old = eq.armorEquipment[slot];
      if (old != null) displaced.add(old);
      eq.armorEquipment[slot] = null;
    }

    switch (item.armorSlot) {
      case ArmorSlots.WEAPON_2H:
        displace(ArmorSlots.WEAPON_2H);
        displace(ArmorSlots.WEAPON_1H);
        displace(ArmorSlots.OFFHAND);
        eq.armorEquipment[ArmorSlots.WEAPON_2H] = item;
        return displaced;
      case ArmorSlots.WEAPON_1H:
        displace(ArmorSlots.WEAPON_1H);
        displace(ArmorSlots.WEAPON_2H);
        eq.armorEquipment[ArmorSlots.WEAPON_1H] = item;
        return displaced;
      case ArmorSlots.OFFHAND:
        displace(ArmorSlots.OFFHAND);
        displace(ArmorSlots.WEAPON_2H);
        eq.armorEquipment[ArmorSlots.OFFHAND] = item;
        return displaced;
      case ArmorSlots.TOOL:
        // tools are equipped per skill via equipTool
        return null;
      default:
        if (!eq.armorEquipment.containsKey(item.armorSlot)) return null;
        displace(item.armorSlot);
        eq.armorEquipment[item.armorSlot] = item;
        return displaced;
    }
  }

  /// The skills whose action is performed with the equipped weapon rather
  /// than with a per-skill tool.
  static const Set<SkillId> weaponSkills = {
    SkillId.ATTACK,
    SkillId.RANGED,
    SkillId.MAGIC,
  };

  /// Whatever the player performs [skill]'s action with: the equipped weapon
  /// in combat, that skill's own tool when gathering. Null when the player
  /// has nothing equipped for it — including every skill that isn't
  /// performed with an item at all, like crafting at a bench.
  EquipmentItem? actionItemFor(SkillId skill, EquipmentData equipmentState) {
    if (weaponSkills.contains(skill)) {
      return equipmentState.armorEquipment[ArmorSlots.WEAPON_1H] ??
          equipmentState.armorEquipment[ArmorSlots.WEAPON_2H];
    }
    return equipmentState.equipedTools[skill];
  }

  /// How long one swing of [skill]'s equipped item takes. Null when nothing
  /// is equipped for it, or when what is equipped carries no speed of its
  /// own (only weapons and tools do).
  Duration? actionIntervalFor(SkillId skill, EquipmentData equipmentState) {
    final item = actionItemFor(skill, equipmentState);
    return item is WeaponItem ? item.actionInterval : null;
  }

  /// Every instance the player is currently wearing or carrying as a tool.
  /// Equipping takes an item out of the inventory, so this is the only
  /// place worn gear can be found.
  List<EquipmentItem> equippedItems(EquipmentData equipmentState) {
    return [
      for (final item in equipmentState.armorEquipment.values)
        if (item != null) item,
      for (final item in equipmentState.equipedTools.values)
        if (item != null) item,
    ];
  }

  /// The equipped instance with [instanceId], or null when it isn't worn.
  EquipmentItem? findEquippedInstance(
    String instanceId,
    EquipmentData equipmentState,
  ) {
    for (final item in equippedItems(equipmentState)) {
      if (item.instanceId == instanceId) return item;
    }
    return null;
  }

  /// Clears whichever slot holds [instanceId], for when the instance stops
  /// existing entirely (disenchanting worn gear consumes it). Returns what
  /// was removed, or null when nothing was wearing it.
  EquipmentItem? removeEquippedInstance(
    String instanceId,
    EquipmentData equipmentState,
  ) {
    for (final entry in equipmentState.armorEquipment.entries) {
      if (entry.value?.instanceId == instanceId) {
        final old = entry.value;
        equipmentState.armorEquipment[entry.key] = null;
        return old;
      }
    }
    for (final entry in equipmentState.equipedTools.entries) {
      if (entry.value?.instanceId == instanceId) {
        final old = entry.value;
        equipmentState.equipedTools[entry.key] = null;
        return old;
      }
    }
    return null;
  }

  EquipmentItem? unequipSlot(ArmorSlots slot, EquipmentData equipmentState) {
    final old = equipmentState.armorEquipment[slot];
    equipmentState.armorEquipment[slot] = null;
    return old;
  }

  EquipmentItem? getItemInSlot(ArmorSlots slot, EquipmentData equipmentState) {
    return equipmentState.armorEquipment[slot];
  }

  void setEquipedFood(ItemId itemId, EquipmentData equipmentState) {
    equipmentState.equipedFood = itemId;
  }

  // the tool equipped for a gathering skill (axe for woodcutting, ...)
  EquipmentItem? getToolForSkill(SkillId skill, EquipmentData equipmentState) {
    return equipmentState.equipedTools[skill];
  }

  /// Equips [item] as the tool for [skill]; returns the displaced tool.
  EquipmentItem? equipTool(
    SkillId skill,
    EquipmentItem item,
    EquipmentData equipmentState,
  ) {
    final old = equipmentState.equipedTools[skill];
    equipmentState.equipedTools[skill] = item;
    return old;
  }

  EquipmentItem? unequipTool(SkillId skill, EquipmentData equipmentState) {
    final old = equipmentState.equipedTools[skill];
    equipmentState.equipedTools[skill] = null;
    return old;
  }
}
