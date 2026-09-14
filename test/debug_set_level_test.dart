import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/skill_service.dart';

/// The skill screen's debug box sets a level, not an xp figure — nobody
/// knows what 737,627 xp is, and everybody knows what 80 is.
void main() {
  final skillService = SkillService();

  SkillData skill() => SkillData(name: 'Attack', xp: 0);

  test('the level asked for is the level that reads back', () {
    for (final level in [1, 2, 37, 80, 99]) {
      final data = skill();
      skillService.setLevel(level, data);
      expect(skillService.getLevel(data), level);
    }
  });

  test('it lands on the start of the level, not part way through it', () {
    final data = skill();
    skillService.setLevel(50, data);

    expect(data.xp, data.xpTable[50]);
    // no progress banked toward 51
    expect(skillService.percentProgressToLevelUp(data), 0.0);
  });

  test('a level off the end of the table clamps instead of writing junk', () {
    final top = skill().xpTable.length - 1;

    final high = skill();
    skillService.setLevel(top + 40, high);
    expect(skillService.getLevel(high), top);

    final low = skill();
    skillService.setLevel(-5, low);
    expect(skillService.getLevel(low), 1);
    expect(low.xp, 0);
  });

  test('setting a level down from a high one takes the xp back', () {
    final data = skill();
    skillService.setLevel(90, data);
    final high = data.xp;

    skillService.setLevel(10, data);
    expect(data.xp, lessThan(high));
    expect(skillService.getLevel(data), 10);
  });
}
