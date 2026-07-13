import 'dart:math';
import 'package:flutter/widgets.dart';

enum SkillId {
  STAMINA, // each point increaes stamina bar by 10.
  // each point of stam spent is 1xp
  SPEED, // each point increases max speed (reduces min action interval) by a percent
  // actions done at near top speed give xp
  RECOVERY, // stamina recovers over time at a rate set by this stat
  // trains while stamina is actively being restored
  // COMBAT
  EXPLORATION,
  HITPOINTS, // health - entity
  ATTACK, // melee attack - entity accuracy and damage
  RANGED, // ranged attack - not sure how this will be used yet
  MAGIC, // magic attack - not sure how this will be used yet
  DEFENCE, // damage reduction - entity
  // GATHERING
  WOODCUTTING, // cut down trees for logs - entity encounter
  MINING, // mine for ore and gems - entity encounter
  FISHING, // catch fish for cooking - entity encounter
  HERBALISM, // gather herbs for alchemy - entity encounter - one pick per action, roll vs difficulty sets yield
  // Crafting
  FIREMAKING, // build fires for buffs and cooking - crafting without location
  LEATHERWORKING, // make leather armor for ranging - crafting at leatherworking station
  BLACKSMITHING, // make metal armor and weapons for melee - crafting at blacksmith station
  TAILORING, // make cloth armor for magic - crafting at loom
  ENCHANTING, // enhance gear - crafting at enchanting station with gear and enchantment materials
  JEWELCRAFTING, // make jeweley items - crafting at jeweling station with gems and metal bars
  FLETCHING, // make ranged weapons and staves - crafting at fletching station with logs
  COOKING, // cook food for healing and buffs - crafting at fire
  ALCHEMY, // make potions for buffs and healing - crafting at alchemy station with herbs and water
  NULL,
}

class SkillData {
  final String name;
  double xp;

  // Xp-rate tracker: set when the player presses Start/Reset on the skill's
  // detail screen. Null means no tracker is running for this skill.
  DateTime? trackerStartTime;
  double? trackerStartXp;

  final List<double> xpTable = SkillData._buildXpTable(99);

  SkillData({
    required this.name,
    required this.xp,
    this.trackerStartTime,
    this.trackerStartXp,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'xp': xp,
      if (trackerStartTime != null)
        'trackerStartTime': trackerStartTime!.toIso8601String(),
      if (trackerStartXp != null) 'trackerStartXp': trackerStartXp,
    };
  }

  factory SkillData.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final rawXp = json['xp'];
    final rawTrackerStartTime = json['trackerStartTime'];
    final rawTrackerStartXp = json['trackerStartXp'];

    if (rawName is! String) {
      throw FormatException('Missing or invalid "name". Expected String.');
    }

    if (rawXp is! num) {
      throw FormatException('Missing or invalid "xp". Expected number.');
    }

    if (rawTrackerStartTime != null && rawTrackerStartTime is! String) {
      throw FormatException('Invalid "trackerStartTime". Expected String.');
    }

    if (rawTrackerStartXp != null && rawTrackerStartXp is! num) {
      throw FormatException('Invalid "trackerStartXp". Expected number.');
    }

    return SkillData(
      name: rawName,
      xp: rawXp.toDouble(),
      trackerStartTime: rawTrackerStartTime == null
          ? null
          : DateTime.tryParse(rawTrackerStartTime as String),
      trackerStartXp: (rawTrackerStartXp as num?)?.toDouble(),
    );
  }

  static List<double> _buildXpTable(int maxLevel) {
    final table = List<double>.filled(maxLevel + 1, 0);
    double points = 0;

    for (int level = 1; level <= maxLevel; level++) {
      table[level] = points;
      points += ((level + 300 * pow(2, level / 7)) / 4).floor();
    }

    return table;
  }
}

class SkillController extends ChangeNotifier {
  static ImageProvider? imageProviderFor(dynamic objectId) {
    {
      if (objectId is! SkillId) {
        throw ArgumentError('Expected Skills, got ${objectId.runtimeType}');
      }
      switch (objectId) {
        case SkillId.RECOVERY:
          // reuses the old economy art until recovery art exists
          return AssetImage('assets/icons/skills/economy.png');
        case SkillId.SPEED:
          return AssetImage('assets/icons/skills/speed.png');
        case SkillId.STAMINA:
          return AssetImage('assets/icons/skills/stamina.png');
        case SkillId.ATTACK:
          return AssetImage('assets/icons/skills/attack.png');
        case SkillId.DEFENCE:
          return AssetImage('assets/icons/skills/defence.png');
        case SkillId.HITPOINTS:
          return AssetImage('assets/icons/skills/hp.png');
        case SkillId.RANGED:
          return AssetImage('assets/icons/skills/ranged.png');
        case SkillId.MAGIC:
          return AssetImage('assets/icons/skills/magic.png');
        case SkillId.WOODCUTTING:
          return AssetImage('assets/icons/skills/woodcutting.png');
        case SkillId.FIREMAKING:
          return AssetImage('assets/icons/skills/firemaking.png');
        case SkillId.MINING:
          return AssetImage('assets/icons/skills/mining.png');
        case SkillId.LEATHERWORKING:
          return AssetImage('assets/icons/skills/leatherworking.png');
        case SkillId.BLACKSMITHING:
          return AssetImage('assets/icons/skills/blacksmithing.png');
        case SkillId.TAILORING:
          return AssetImage('assets/icons/skills/tailoring.png');
        case SkillId.ENCHANTING:
          return AssetImage('assets/icons/skills/enchanting.png');
        case SkillId.JEWELCRAFTING:
          return AssetImage('assets/icons/skills/jewelcrafting.png');
        case SkillId.FLETCHING:
          return AssetImage('assets/icons/skills/fletching.png');
        case SkillId.FISHING:
          return AssetImage('assets/icons/skills/fishing.png');
        case SkillId.HERBALISM:
          return AssetImage('assets/icons/skills/herbalism.png');
        case SkillId.COOKING:
          return AssetImage('assets/icons/skills/cooking.png');
        case SkillId.NULL:
          return null;
        default:
          return null;
      }
    }
  }
}
