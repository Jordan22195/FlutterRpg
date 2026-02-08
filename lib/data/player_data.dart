import 'skill.dart';
import 'zone.dart';
import 'inventory.dart';
import 'armor_equipment.dart';
import 'exploration_state.dart';

import 'package:flutter/material.dart';

class PlayerData {
  final Zones currentZoneId;
  final Map<Skills, Skill> skills;
  final Inventory inventory;
  final ArmorEquipment gear;
  final ZoneState zones;
  int hitpoints = 10;

  PlayerData({
    required this.currentZoneId,
    required this.skills,
    required this.inventory,
    required this.gear,
    required this.zones,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentZoneId': currentZoneId.name, // enum → string
      'hitpoints': hitpoints,

      'skills': skills.map(
        (key, value) => MapEntry(
          key.name, // Skills enum → string
          value.toJson(), // Skill → json
        ),
      ),

      'inventory': inventory.toJson(),
      'gear': gear.toJson(),
      'explorationStatus': zones.toJson(),
    };
  }

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    // --- Helpers ---
    T _enumFromName<T extends Enum>(
      List<T> values,
      Object? raw, {
      required T fallback,
    }) {
      if (raw is String) {
        for (final v in values) {
          if (v.name == raw) return v;
        }
      }
      return fallback;
    }

    Map<String, dynamic> _asMap(Object? raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.cast<String, dynamic>();
      return <String, dynamic>{};
    }

    int _asInt(Object? raw, {required int fallback}) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? fallback;
      return fallback;
    }

    // --- Defaults (manual object creation) ---
    // Choose a sensible fallback zone. If you have Zones.NULL, use it instead.
    final Zones defaultZone = Zones.STARTING_FOREST;

    // Build a default skill set so you always have every skill.
    Map<Skills, Skill> defaultSkills() {
      final map = <Skills, Skill>{};
      for (final s in Skills.values) {
        map[s] = Skill(name: s.name, xp: 1);
      }
      return map;
    }

    final Inventory defaultInventory = Inventory(itemMap: {});
    final ArmorEquipment defaultGear = ArmorEquipment();
    final ZoneState defaultExploration = ZoneState(discoveredEntities: {});

    // --- Parse fields safely ---
    Zones zoneId;
    try {
      zoneId = _enumFromName(
        Zones.values,
        json['currentZoneId'],
        fallback: defaultZone,
      );
    } catch (e) {
      debugPrint('PlayerData.fromJson: bad currentZoneId: $e');
      zoneId = defaultZone;
    }

    // Skills: load what exists, fill the rest with defaults
    final skillsOut = defaultSkills();
    try {
      final rawSkills = _asMap(json['skills']);
      for (final entry in rawSkills.entries) {
        final skillEnum = _enumFromName(
          Skills.values,
          entry.key,
          fallback: Skills.HITPOINTS,
        );

        // Each value should be a Map for Skill.fromJson
        final skillJson = _asMap(entry.value);
        try {
          skillsOut[skillEnum] = Skill.fromJson(skillJson);
        } catch (e) {
          debugPrint('PlayerData.fromJson: bad skill ${entry.key}: $e');
          // keep default for that skill
        }
      }
    } catch (e) {
      debugPrint('PlayerData.fromJson: skills parse failed: $e');
    }

    Inventory inv;
    try {
      final invJson = _asMap(json['inventory']);
      inv = invJson.isEmpty ? defaultInventory : Inventory.fromJson(invJson);
    } catch (e) {
      debugPrint('PlayerData.fromJson: inventory parse failed: $e');
      inv = defaultInventory;
    }

    ArmorEquipment gear;
    try {
      final gearJson = _asMap(json['gear']);
      gear = gearJson.isEmpty ? defaultGear : ArmorEquipment.fromJson(gearJson);
    } catch (e) {
      debugPrint('PlayerData.fromJson: gear parse failed: $e');
      gear = defaultGear;
    }

    ZoneState exploration;
    try {
      final expJson = _asMap(json['explorationStatus']);
      exploration = expJson.isEmpty
          ? defaultExploration
          : ZoneState.fromJson(expJson);
    } catch (e) {
      debugPrint('PlayerData.fromJson: explorationStatus parse failed: $e');
      exploration = defaultExploration;
    }

    // Build the object
    final player = PlayerData(
      currentZoneId: zoneId,
      skills: skillsOut,
      inventory: inv,
      gear: gear,
      zones: exploration,
    );

    // hitpoints (not in constructor)
    try {
      player.hitpoints = _asInt(json['hitpoints'], fallback: 10);
    } catch (e) {
      debugPrint('PlayerData.fromJson: hitpoints parse failed: $e');
      player.hitpoints = 10;
    }

    return player;
  }
}
