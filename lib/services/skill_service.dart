import '../data/debug_settings.dart';
import '../data/skill_data.dart';

class SkillService {
  /// Where the debug skill-level cap is read from; null means uncapped.
  final DebugSettings? _debugSettings;

  SkillService({DebugSettings? debugSettings}) : _debugSettings = debugSettings;

  /// The highest level [skillState] can read at: the top of its table, or
  /// the debug cap when that is lower.
  int maxLevel(SkillData skillState) {
    final top = skillState.xpTable.length - 1;
    final cap = _debugSettings?.maxSkillLevel;
    return cap == null ? top : cap.clamp(1, top);
  }

  double percentProgressToLevelUp(SkillData skillState) {
    return progressAtXp(skillState.xp, skillState);
  }

  /// The share of the way from its level to the next that [xp] sits, on
  /// [skillState]'s table — for showing an xp the skill no longer has, like
  /// where it stood before an offline settle. Maxed reads as 1.
  double progressAtXp(double xp, SkillData skillState) {
    final curLevel = getLevelFromXp(xp, skillState);

    // Maxed (level 99 if table is 99, or at the debug cap)
    if (curLevel >= maxLevel(skillState)) return 1.0;

    final curLvlXp = skillState.xpTable[curLevel];
    final nextLvlXp = skillState.xpTable[curLevel + 1];
    final span = nextLvlXp - curLvlXp;

    if (span <= 0) return 0.0;

    return ((xp - curLvlXp) / span).clamp(0.0, 1.0);
  }

  double nextLevelXp(SkillData skillState) {
    final curLevel = getLevel(skillState);

    // Maxed (level 99 if table is 99, or at the debug cap)
    if (curLevel >= maxLevel(skillState)) return 0;

    return skillState.xpTable[curLevel + 1];
  }

  double xpToLevelUp(SkillData skillState) {
    final level = getLevel(skillState);
    final nextLevel = (level + 1).clamp(1, skillState.xpTable.length - 1);

    // Already at max level
    if (level >= maxLevel(skillState)) return 0;

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

  void setXp(double xp, SkillData skillState) {
    skillState.xp = xp < 0 ? 0 : xp;
  }

  /// Puts the skill at exactly [level], on the least xp that level starts
  /// at — so the level reads back as asked, with no progress into the next.
  ///
  /// Levels run 1 to the top of the table; anything outside that clamps,
  /// which keeps a typo from writing an xp the curve never produces.
  void setLevel(int level, SkillData skillState) {
    final maxLevel = skillState.xpTable.length - 1;
    setXp(skillState.xpTable[level.clamp(1, maxLevel)], skillState);
  }

  /// The level [xp] reads at, held to [maxLevel].
  int getLevelFromXp(double xp, SkillData skillState) {
    final cap = maxLevel(skillState);
    for (int level = 1; level <= cap; level++) {
      if (xp < skillState.xpTable[level]) {
        return level - 1;
      }
    }
    return cap;
  }

  /// The xp [skillState] needs in total to stand at [level], clamped to the
  /// table. The goal tracker subtracts the xp held from this.
  double xpAtLevel(int level, SkillData skillState) {
    final clamped = level.clamp(1, skillState.xpTable.length - 1);
    return skillState.xpTable[clamped];
  }

  /// Notes that one action of [skillState] just paid [xp]. With [average]
  /// (combat, where one hit is noise) it folds into a running average that
  /// weights the last ~20 hits; otherwise it is simply the last action's pay.
  void recordActionXp(
    double xp,
    SkillData skillState, {
    required bool average,
  }) {
    if (xp <= 0) return;
    final prior = skillState.lastActionXp;
    skillState.lastActionXp = (!average || prior == null)
        ? xp
        : prior + (xp - prior) * 0.05;
  }
}
