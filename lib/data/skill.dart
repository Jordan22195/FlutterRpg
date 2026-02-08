import 'dart:ffi';
import 'dart:math' as Math;

enum Skills {
  HITPOINTS, // health
  ATTACK, // melee attack
  RANGED, // ranged attack
  MAGIC, // magic attack
  DEFENCE, // damage reduction
  WOODCUTTING, // cut down trees for logs
  FIREMAKING, // build fires for buffs and cooking
  MINING, // mine for ore and gems
  LEATHERWORKING, // make leather armor for ranging
  BLACKSMITHING, // make metal armor and weapons for melee
  TAILORING, // make cloth armor for magic
  ENCHANTING, // enhance gear
  JEWELCRAFTING, // make jeweley items
  FLETCHING, // make ranged weapons and staves?
  FISHING,
  COOKING,
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

    final nextLevel = (curLevel + 1);

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
      points += ((level + 300 * Math.pow(2, level / 7)) / 4).floor();
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
    return Skill(name: json['name'] as String, xp: json['xp'] as int);
  }
}
