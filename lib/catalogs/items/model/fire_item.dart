import 'package:rpg/catalogs/items/definition/fire_item_definition.dart';
import 'package:rpg/catalogs/items/model/zone_buff_item.dart';
import 'package:rpg/data/skill_data.dart';

/// A fire burning in a firepit. [canCook] is what opens the cooking half of
/// the firepit screen; a cookfire's own COOKING bonus is what makes a better
/// fire burn less food, via the buffed stat totals.
///
/// A campfire or bonfire has no bonus of its own. It holds the reagent buffs
/// thrown on it instead, one per stat, each running out on its own clock and
/// all of them ending with the fire.
class FireItem extends ZoneBuffItem {
  FireItem({
    required super.id,
    super.fuelUnits,
    super.zoneId,
    super.ownerEntityId,
  });

  @override
  FireItemDefinition get definition => id.definition as FireItemDefinition;

  bool get canCook => definition.canCook;

  /// What one reagent's buff is worth on this fire.
  int get power => definition.power;

  bool get tendable => definition.tendable;

  /// When each tended stat's buff runs out. A stat past its time is simply
  /// down; it stays in the map until tended again or the fire goes out,
  /// since nothing reads it once it is past.
  final Map<SkillId, DateTime> reagentExpirations = {};

  /// Whether [stat]'s reagent buff is up at [at].
  bool reagentActive(SkillId stat, DateTime at) {
    if (!expirationTime.isAfter(at)) return false;
    final until = reagentExpirations[stat];
    return until != null && until.isAfter(at);
  }

  /// When [stat]'s reagent buff stops counting: its own end, or the fire's
  /// if the fire goes out first. Null when it is not up at [at].
  DateTime? reagentEndsAt(SkillId stat, DateTime at) {
    if (!reagentActive(stat, at)) return null;
    final until = reagentExpirations[stat]!;
    return until.isBefore(expirationTime) ? until : expirationTime;
  }

  /// The stats being tended at [at], in [SkillId] order.
  List<SkillId> activeReagentStats(DateTime at) => [
    for (final stat in SkillId.values)
      if (reagentActive(stat, at)) stat,
  ];

  /// Throws [count] reagents' worth of [stat] on: the buff extends from its
  /// current end when it is still up, and starts at [at] when it is not.
  void tend(SkillId stat, DateTime at, {int count = 1}) {
    if (count <= 0) return;
    final current = reagentExpirations[stat];
    final base = current != null && current.isAfter(at) ? current : at;
    reagentExpirations[stat] = base.add(definition.reagentBurn * count);
  }

  @override
  Map<SkillId, int> bonusAt(DateTime at) {
    if (!expirationTime.isAfter(at)) return const {};
    return {
      ...definition.skillBonus,
      for (final stat in activeReagentStats(at)) stat: power,
    };
  }

  @override
  Iterable<DateTime> get changeTimes => [
    expirationTime,
    ...reagentExpirations.values,
  ];

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['reagents'] = {
      for (final entry in reagentExpirations.entries)
        entry.key.name: entry.value.toIso8601String(),
    };
    return json;
  }

  /// Restores the reagent buffs, tolerating a save from before fires were
  /// tended - it simply has none.
  void readFireStateFromJson(Map<String, dynamic> json) {
    reagentExpirations.clear();
    final raw = json['reagents'];
    if (raw is! Map) return;
    final stats = SkillId.values.asNameMap();
    for (final entry in raw.entries) {
      final stat = stats[entry.key];
      final value = entry.value;
      if (stat == null || value is! String) continue;
      final until = DateTime.tryParse(value);
      if (until != null) reagentExpirations[stat] = until;
    }
  }
}
