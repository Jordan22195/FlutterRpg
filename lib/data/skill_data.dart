import 'dart:math';
import 'package:flutter/widgets.dart';

enum SkillId {
  STAMINA, // each point increaes stamina bar by 10.
  // each point of stam spent is 1xp
  SPEED, // the fast stance's stat: shortens the action interval and raises
  // the boost ceiling, both on a root curve - see boostStatBonus.
  // actions done at near top speed give xp
  STRENGTH, // every other stance's stat: raises the stat the stance is spent
  // on, a little standing still and a lot at full boost - see
  // PlayerDataService.getStatTotals
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

  /// What one action of this skill last paid, for the detail screen's level
  /// goal ("N more of these to get there"). For the combat skills it is a
  /// running average over recent hits instead, since a single hit says little.
  /// Null until the skill has paid out once.
  double? lastActionXp;

  /// The level the player set the goal slider to on the detail screen. Null
  /// until they move it, which reads as the next level.
  int? goalLevel;

  final List<double> xpTable = SkillData._buildXpTable(99);

  SkillData({
    required this.name,
    required this.xp,
    this.lastActionXp,
    this.goalLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'xp': xp,
      if (lastActionXp != null) 'lastActionXp': lastActionXp,
      if (goalLevel != null) 'goalLevel': goalLevel,
    };
  }

  factory SkillData.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final rawXp = json['xp'];
    final rawLastActionXp = json['lastActionXp'];
    final rawGoalLevel = json['goalLevel'];

    if (rawName is! String) {
      throw FormatException('Missing or invalid "name". Expected String.');
    }

    if (rawXp is! num) {
      throw FormatException('Missing or invalid "xp". Expected number.');
    }

    // the old xp tracker's keys are simply ignored
    if (rawLastActionXp != null && rawLastActionXp is! num) {
      throw FormatException('Invalid "lastActionXp". Expected number.');
    }

    if (rawGoalLevel != null && rawGoalLevel is! num) {
      throw FormatException('Invalid "goalLevel". Expected number.');
    }

    return SkillData(
      name: rawName,
      xp: rawXp.toDouble(),
      lastActionXp: (rawLastActionXp as num?)?.toDouble(),
      goalLevel: (rawGoalLevel as num?)?.toInt(),
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
          return AssetImage('assets/icons/skills/recovery.png');
        case SkillId.SPEED:
          return AssetImage('assets/icons/skills/speed.png');
        case SkillId.STRENGTH:
          return AssetImage('assets/icons/skills/strength.png');
        case SkillId.STAMINA:
          return AssetImage('assets/icons/skills/stamina.png');
        case SkillId.EXPLORATION:
          return AssetImage('assets/icons/skills/exploration.png');
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
        case SkillId.ALCHEMY:
          return AssetImage('assets/icons/skills/alchemy.png');
        case SkillId.NULL:
          return null;
        default:
          return null;
      }
    }
  }
}
