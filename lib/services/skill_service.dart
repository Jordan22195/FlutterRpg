import '../data/skill_data.dart';

class SkillService {
  double percentProgressToLevelUp(SkillData skillState) {
    final curLevel = getLevel(skillState);

    // Maxed (level 99 if table is 99)
    if (curLevel >= skillState.xpTable.length - 1) return 1.0;

    final curLvlXp = skillState.xpTable[curLevel];
    final nextLvlXp = nextLevelXp(skillState);
    final span = nextLvlXp - curLvlXp;

    if (span <= 0) return 0.0;

    final intoLevel = (skillState.xp - curLvlXp);

    return (intoLevel / span).clamp(0.0, 1.0);
  }

  double nextLevelXp(SkillData skillState) {
    final curLevel = getLevel(skillState);

    // Maxed (level 99 if table is 99)
    if (curLevel >= skillState.xpTable.length - 1) return 0;

    return skillState.xpTable[curLevel + 1];
  }

  double xpToLevelUp(SkillData skillState) {
    final level = getLevel(skillState);
    final nextLevel = (level + 1).clamp(1, skillState.xpTable.length - 1);

    // Already at max level
    if (level >= skillState.xpTable.length - 1) return 0;

    final nextXp = skillState.xpTable[nextLevel];
    final remaining = nextXp - skillState.xp;
    return remaining <= 0 ? 0 : remaining;
  }

  int getLevel(SkillData skillState) {
    return getLevelFromXp(skillState.xp, skillState);
  }

  void addXp(double xp, SkillData skillState) {
    skillState.xp += xp;
  }

  int getLevelFromXp(double xp, SkillData skillState) {
    for (int level = 1; level < skillState.xpTable.length; level++) {
      if (xp < skillState.xpTable[level]) {
        return level - 1;
      }
    }
    return skillState.xpTable.length - 1;
  }
}
