import '../catalogs/item_catalog.dart';
import 'ObjectStack.dart';
import 'skill_data.dart';

class ActionResult {
  Map<SkillId, double> xp = {};
  List<ObjectStack> items = [];

  /// Equipment produced by the action. Kept apart from [items] because an
  /// instance carries its own quality and never stacks.
  List<EquipmentItem> equipment = [];

  bool enemyDied = false;
  int damageDone = 0;
}
