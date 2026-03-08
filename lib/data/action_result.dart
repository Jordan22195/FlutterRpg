import 'ObjectStack.dart';
import 'skill.dart';

class ActionResult {
  Map<SkillId, double> xp = {};
  List<ObjectStack> items = [];
  bool enemyDied = false;
  int damageDone = 0;
}
