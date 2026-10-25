import '../data/combat_tuning.dart';
import '../data/equipment_data.dart';
import '../data/gear_set.dart';
import '../data/skill_data.dart';
import '../catalogs/items/items.dart';
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

  /// What [item] demands of the player before it can be worn, or null when
  /// nothing does — a piece with no material behind it (jewellery, a boss
  /// drop, a stone axe) asks for level 0, which is not a requirement.
  ///
  /// The skill comes from what the piece *is* and the level from what it is
  /// *made of*: a mithril sword asks for attack at mithril's level where a
  /// mithril helmet asks for defence at the same one.
  ({SkillId skill, int level})? requirementFor(EquipmentItem item) {
    final level = item.skillLevelRequirement;
    if (level <= 0) return null;
    return (skill: item.skillRequirement, level: level);
  }

  /// Whether [item] can be worn by a player at [skillLevels].
  ///
  /// [skillLevels] is levels earned from xp, never [getStatTotals] — gear
  /// that counted its own bonus toward its own requirement would let a
  /// player bootstrap up the ladder one piece at a time.
  bool meetsRequirement(EquipmentItem item, Map<SkillId, int> skillLevels) {
    final needed = requirementFor(item);
    if (needed == null) return true;
    return (skillLevels[needed.skill] ?? 0) >= needed.level;
  }

  /// What [item] would be measured against: the piece wearing it would
  /// take off. Its own slot for armour; whatever weapon is in hand for a
  /// weapon, one- or two-handed; the tool for its skill for a tool; and the
  /// weaker of the two rings for a ring, since that is the one to replace.
  /// Null when that place is empty.
  EquipmentItem? counterpartFor(
    EquipmentItem item,
    EquipmentData equipmentState,
  ) {
    final slots = equipmentState.armorEquipment;
    switch (item.armorSlot) {
      case ArmorSlots.TOOL:
        return equipmentState.equipedTools[item.skillRequirement];
      case ArmorSlots.WEAPON_1H || ArmorSlots.WEAPON_2H:
        return slots[ArmorSlots.WEAPON_1H] ?? slots[ArmorSlots.WEAPON_2H];
      case ArmorSlots.FINGER || ArmorSlots.FINGER_2:
        final a = slots[ArmorSlots.FINGER];
        final b = slots[ArmorSlots.FINGER_2];
        if (a == null || b == null) return null;
        return statTotal(a) <= statTotal(b) ? a : b;
      default:
        return slots[item.armorSlot];
    }
  }

  /// Whether this very piece is the one being worn.
  bool isEquipped(EquipmentItem item, EquipmentData equipmentState) =>
      equippedItems(
        equipmentState,
      ).any((worn) => worn.instanceId == item.instanceId);

  /// Everything [item] adds, summed across its stats; 0 for nothing. A
  /// weapon or tool that swings counts its damage per second of swing too —
  /// its damage is most of what it is worth, and per second so a dagger and
  /// a greatsword of the same metal weigh the same.
  int statTotal(EquipmentItem? item) {
    if (item == null) return 0;
    final stats = item.effectiveSkillBonus.values.fold<int>(
      0,
      (sum, v) => sum + v,
    );
    return stats + damagePerSecondOf(item).round();
  }

  /// [item]'s damage per second of swing, before the attack multiplier; 0
  /// for anything that does not swing.
  double damagePerSecondOf(EquipmentItem item) {
    final def = item.definition;
    if (def is! WeaponItemDefinition || !def.usesDamage) return 0;
    final seconds = def.actionInterval.inMicroseconds / 1e6;
    return seconds <= 0 ? 0 : def.damageAt(item.quality) / seconds;
  }

  /// The skills whose action is a swing that deals damage to a pool: a
  /// fight, a tree, a vein and a cast into a fishing spot. Herbs roll their
  /// skill instead.
  static const Set<SkillId> damageSkills = {
    ...weaponSkills,
    SkillId.MINING,
    SkillId.WOODCUTTING,
    SkillId.FISHING,
  };

  /// What one swing of [skill]'s action deals before the attack multiplier:
  /// the equipped weapon's or tool's damage, or a bare hand's when nothing
  /// that swings is equipped for it. Null for an action that is not a
  /// swing at a pool at all, which then rolls the way it always has.
  double? swingDamageFor(SkillId skill, EquipmentData equipmentState) {
    if (!damageSkills.contains(skill)) return null;
    // read off the definition rather than the instance's class: what makes
    // a piece a weapon is what it is defined as
    final item = actionItemFor(skill, equipmentState);
    final def = item?.definition;
    if (item != null && def is WeaponItemDefinition && def.usesDamage) {
      return def.damageAt(item.quality);
    }
    return unarmedDamage;
  }

  /// How much of each stance boost [skill]'s action takes, from the shape of
  /// what is equipped to perform it — see [WeaponEquipmentParameters].
  ///
  /// With nothing that swings equipped, speed is taken whole: exploring and
  /// bench work have no shape to trade it against, and keep the boost they
  /// always had. A bare-handed swing's strength takes the middle share.
  ({double speed, double strength}) affinityFor(
    SkillId? skill,
    EquipmentData equipmentState,
  ) {
    final item = skill == null ? null : actionItemFor(skill, equipmentState);
    final def = item?.definition;
    if (def is! WeaponItemDefinition || !def.usesDamage) {
      return (speed: 1.0, strength: unarmedAffinity);
    }
    return (speed: def.speedAffinity, strength: def.strengthAffinity);
  }

  /// Whether any of [candidates] would be an upgrade on [equipped]: one the
  /// player can wear right now whose stats add up to more. An empty slot
  /// counts as nothing, so anything wearable is an upgrade on it.
  bool hasUpgrade(
    EquipmentItem? equipped,
    Iterable<EquipmentItem> candidates,
    Map<SkillId, int> skillLevels,
  ) {
    final current = statTotal(equipped);
    return candidates.any(
      (c) => meetsRequirement(c, skillLevels) && statTotal(c) > current,
    );
  }

  /// Equips [item] into its slot, applying weapon exclusivity rules.
  /// [toSlot] picks between the slots an item accepts (which ring finger
  /// it goes on); without it the first empty one wins. Returns the
  /// instances displaced by the swap (so they can be put back in the
  /// inventory), or null when the item can't be equipped this way (tools
  /// go through [equipTool]).
  List<EquipmentItem>? equipItem(
    EquipmentItem item,
    EquipmentData eq, {
    ArmorSlots? toSlot,
  }) {
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
        final target = _armorTargetFor(item, eq, toSlot);
        if (target == null) return null;
        displace(target);
        eq.armorEquipment[target] = item;
        return displaced;
    }
  }

  /// Where a piece of armor goes: the caller's pick when the item fits it,
  /// otherwise the first slot the item accepts that is empty, otherwise the
  /// first one — whose occupant gets displaced.
  ArmorSlots? _armorTargetFor(
    EquipmentItem item,
    EquipmentData eq,
    ArmorSlots? toSlot,
  ) {
    final targets = item.armorSlot.equipTargets
        .where(eq.armorEquipment.containsKey)
        .toList();
    if (targets.isEmpty) return null;
    if (toSlot != null && targets.contains(toSlot)) return toSlot;
    return targets.firstWhere(
      (slot) => eq.armorEquipment[slot] == null,
      orElse: () => targets.first,
    );
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

  /// How many outfits a player can keep saved at once.
  static const int maxGearSets = 6;

  /// "Set N" for the lowest N no saved set is already called.
  String defaultGearSetName(EquipmentData equipmentState) {
    final taken = {for (final set in equipmentState.gearSets) set.name};
    var n = 1;
    while (taken.contains('Set $n')) {
      n++;
    }
    return 'Set $n';
  }

  /// [name] trimmed to what a set may be called, or the default name when
  /// nothing is left of it.
  String _gearSetName(String? name, EquipmentData equipmentState) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return defaultGearSetName(equipmentState);
    return trimmed.length > GearSet.maxNameLength
        ? trimmed.substring(0, GearSet.maxNameLength)
        : trimmed;
  }

  static GearSetPiece _pieceOf(EquipmentItem item) => GearSetPiece(
    instanceId: item.instanceId,
    stackKey: item.stackKey,
    label: item.displayName,
  );

  /// What the player is wearing right now as a set — every armour and
  /// weapon slot, and the tools only when [includeTools].
  GearSet captureGearSet(
    String name,
    EquipmentData equipmentState, {
    required bool includeTools,
  }) {
    return GearSet(
      name: name,
      armor: {
        for (final entry in equipmentState.armorEquipment.entries)
          if (entry.value != null) entry.key: _pieceOf(entry.value!),
      },
      includesTools: includeTools,
      tools: includeTools
          ? {
              for (final entry in equipmentState.equipedTools.entries)
                if (entry.value != null) entry.key: _pieceOf(entry.value!),
            }
          : null,
    );
  }

  /// Saves what is worn as a new set at the end of the list. Null when the
  /// list is already full.
  GearSet? saveGearSet(
    EquipmentData equipmentState, {
    String? name,
    required bool includeTools,
  }) {
    if (equipmentState.gearSets.length >= maxGearSets) return null;
    final set = captureGearSet(
      _gearSetName(name, equipmentState),
      equipmentState,
      includeTools: includeTools,
    );
    equipmentState.gearSets.add(set);
    return set;
  }

  /// Replaces the set at [index] with what is worn now, keeping its name.
  GearSet? overwriteGearSet(
    int index,
    EquipmentData equipmentState, {
    required bool includeTools,
  }) {
    if (index < 0 || index >= equipmentState.gearSets.length) return null;
    final set = captureGearSet(
      equipmentState.gearSets[index].name,
      equipmentState,
      includeTools: includeTools,
    );
    equipmentState.gearSets[index] = set;
    return set;
  }

  void renameGearSet(int index, String name, EquipmentData equipmentState) {
    if (index < 0 || index >= equipmentState.gearSets.length) return;
    final set = equipmentState.gearSets[index];
    // an empty rename keeps the old name rather than inventing a new one
    if (name.trim().isEmpty) return;
    set.name = _gearSetName(name, equipmentState);
  }

  void deleteGearSet(int index, EquipmentData equipmentState) {
    if (index < 0 || index >= equipmentState.gearSets.length) return;
    equipmentState.gearSets.removeAt(index);
  }

  /// Whether what is worn is exactly [set]: every slot it fills holds its
  /// piece (or an identical one) and every slot it leaves empty is empty.
  bool isWearingGearSet(GearSet set, EquipmentData equipmentState) {
    bool same(EquipmentItem? worn, GearSetPiece? piece) {
      if (worn == null || piece == null) return worn == null && piece == null;
      return worn.instanceId == piece.instanceId ||
          worn.stackKey == piece.stackKey;
    }

    for (final entry in equipmentState.armorEquipment.entries) {
      if (!same(entry.value, set.armor[entry.key])) return false;
    }
    if (!set.includesTools) return true;
    for (final skill in {
      ...set.tools.keys,
      ...equipmentState.equipedTools.keys,
    }) {
      if (!same(equipmentState.equipedTools[skill], set.tools[skill])) {
        return false;
      }
    }
    return true;
  }
}
