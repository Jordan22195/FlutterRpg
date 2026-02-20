import 'dart:math';
import 'package:flutter/widgets.dart';
import '../utilities/image_resolver.dart';

enum Skills {
  // COMBAT
  HITPOINTS, // health - entity
  ATTACK, // melee attack - entity accuracy and damage
  RANGED, // ranged attack - not sure how this will be used yet
  MAGIC, // magic attack - not sure how this will be used yet
  DEFENCE, // damage reduction - entity
  // GATHERING
  WOODCUTTING, // cut down trees for logs - entity encounter
  MINING, // mine for ore and gems - entity encounter
  FISHING, // catch fish for cooking - entity encounter
  FORAGING, // gather herbs for alchemy - entity encounter - higher level let you find more stuff while exploring
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

class Skill {
  final String name;
  int xp;

  final List<int> xpTable = Skill._buildXpTable(99);

  Skill({required this.name, required this.xp});

  double percentProgressToLevelUp() {
    final curLevel = getLevel();

    // Maxed (level 99 if table is 99)
    if (curLevel >= xpTable.length - 1) return 1.0;

    final curLvlXp = xpTable[curLevel];
    final nextLvlXp = nextLevelXp();
    final span = nextLvlXp - curLvlXp;

    if (span <= 0) return 0.0;

    final intoLevel = (this.xp - curLvlXp);

    return (intoLevel / span).clamp(0.0, 1.0);
  }

  int nextLevelXp() {
    final curLevel = getLevel();

    // Maxed (level 99 if table is 99)
    if (curLevel >= xpTable.length - 1) return 0;

    return xpTable[curLevel + 1];
  }

  int xpToLevelUp() {
    final level = getLevel();
    final nextLevel = (level + 1).clamp(1, xpTable.length - 1);

    // Already at max level
    if (level >= xpTable.length - 1) return 0;

    final nextXp = xpTable[nextLevel];
    final remaining = nextXp - xp;
    return remaining <= 0 ? 0 : remaining;
  }

  int getLevel() {
    return getLevelFromXp(xp);
  }

  void addXp(int xp) {
    print("addxp $name $xp");
    this.xp += xp;
  }

  static List<int> _buildXpTable(int maxLevel) {
    final table = List<int>.filled(maxLevel + 1, 0);
    int points = 0;

    for (int level = 1; level <= maxLevel; level++) {
      table[level] = points;
      points += ((level + 300 * pow(2, level / 7)) / 4).floor();
    }

    return table;
  }

  int getLevelFromXp(int xp) {
    for (int level = 1; level < xpTable.length; level++) {
      if (xp < xpTable[level]) {
        return level - 1;
      }
    }
    return xpTable.length - 1;
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'xp': xp};
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    print("fromjson ${json['name']} ${json['xp']}");
    return Skill(name: json['name'] as String, xp: json['xp'] as int);
  }
}

class SkillController extends ChangeNotifier {
  SkillController._internal();
  static final SkillController instance = SkillController._internal();

  static final Map<Skills, Skill> _skills = {};

  Map<String, dynamic> toJson() {
    print("skillcontroller tojson");
    final map = <String, dynamic>{};
    _skills.forEach((key, value) {
      map[key.name] = value.toJson();
    });
    return map;
  }

  void fromJson(Map<String, dynamic> json) {
    print("skillcontroller fromjson with keys ${json.keys}");
    // Start from a known-good default set so missing keys don't leave holes.
    _skills..clear();

    for (final skill in Skills.values) {
      if (skill != Skills.NULL) {
        _skills[skill] = Skill(name: skill.name, xp: 0);
      }
    }

    // Overlay any persisted values.
    json.forEach((key, value) {
      print("processing skill key $key with value $value");
      final skillEnum = Skills.values.firstWhere(
        (e) => e.name == key,
        orElse: () => Skills.NULL,
      );

      if (skillEnum == Skills.NULL) return;

      // jsonDecode often produces Map<dynamic, dynamic>; normalize before parsing.
      print("parsing skill $key with value $value");
      if (value is Map) {
        final map = Map<String, dynamic>.from(value as Map);
        _skills[skillEnum] = Skill.fromJson(map);
      }
    });

    notifyListeners();
  }

  static void init() {
    for (var skill in Skills.values) {
      if (skill != Skills.NULL) {
        _skills[skill] = Skill(name: skill.name, xp: 0);
      }
    }
    EnumImageProviderLookup.register<Skills>(SkillController.imageProviderFor);
  }

  Skill getSkill(Skills id) {
    return _skills[id] ?? Skill(name: "Error", xp: 1);
  }

  void addXp(Skills skill, int xp) {
    _skills[skill]?.addXp(xp);
  }

  static ImageProvider? imageProviderFor(dynamic objectId) {
    {
      if (objectId is! Skills) {
        throw ArgumentError('Expected Skills, got ${objectId.runtimeType}');
      }
      switch (objectId) {
        case Skills.ATTACK:
          return AssetImage('assets/icons/skills/attack.png');
        case Skills.DEFENCE:
          return AssetImage('assets/icons/skills/defence.png');
        case Skills.HITPOINTS:
          return AssetImage('assets/icons/skills/hp.png');
        case Skills.RANGED:
          return AssetImage('assets/icons/skills/ranged.png');
        case Skills.MAGIC:
          return AssetImage('assets/icons/skills/magic.png');
        case Skills.WOODCUTTING:
          return AssetImage('assets/icons/skills/woodcutting.png');
        case Skills.FIREMAKING:
          return AssetImage('assets/icons/skills/firemaking.png');
        case Skills.MINING:
          return AssetImage('assets/icons/skills/mining.png');
        case Skills.LEATHERWORKING:
          return AssetImage('assets/icons/skills/leatherworking.png');
        case Skills.BLACKSMITHING:
          return AssetImage('assets/icons/skills/blacksmithing.png');
        case Skills.TAILORING:
          return AssetImage('assets/icons/skills/tailoring.png');
        case Skills.ENCHANTING:
          return AssetImage('assets/icons/skills/enchanting.png');
        case Skills.JEWELCRAFTING:
          return AssetImage('assets/icons/skills/jewelcrafting.png');
        case Skills.FLETCHING:
          return AssetImage('assets/icons/skills/fletching.png');
        case Skills.FISHING:
          return AssetImage('assets/icons/skills/fishing.png');
        case Skills.COOKING:
          return AssetImage('assets/icons/skills/cooking.png');
        case Skills.NULL:
          return null;
        default:
          return null;
      }
    }
  }
}
