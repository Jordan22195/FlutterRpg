import 'package:rpg/catalogs/items/definition/fire_item_definition.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/items/model/zone_buff_item.dart';
import 'package:rpg/data/skill_data.dart';

/// A fire burning in a firepit. [canCook] is what opens the cooking half of
/// the firepit screen; a cookfire's own COOKING bonus is what makes a better
/// fire burn less food, via the buffed stat totals.
///
/// Every fire is a steady slow burn giving its definition's bonus: each lay
/// adds the fire's own burn time, with no cap. Lay it and walk away.
class FireItem extends ZoneBuffItem {
  FireItem({
    required super.id,
    super.fuelUnits,
    super.zoneId,
    super.ownerEntityId,
  });

  /// How much longer than the base this fire burns, from the firemaker's
  /// level when its last lay went on: 1 at the fire's level requirement,
  /// and [burnScalePerLevel] more for every level over it.
  double burnScale = 1;

  /// The extra burn per firemaking level over the fire's requirement.
  static const double burnScalePerLevel = 0.01;

  /// The burn scale a firemaker at [level] gets on a fire whose recipe asks
  /// for [requirement].
  static double burnScaleFor(int level, int requirement) {
    final over = level - requirement;
    return over <= 0 ? 1 : 1 + over * burnScalePerLevel;
  }

  @override
  FireItemDefinition get definition => id.definition as FireItemDefinition;

  bool get canCook => definition.canCook;

  /// Whether this is a bonfire, laid with a reagent for its stat.
  bool get isBonfire => definition.isBonfire;

  /// Lights a fresh fire of [lays] at [at], burning at [scale] (see
  /// [burnScale]).
  void lightAt(DateTime at, {int lays = 1, double scale = 1}) {
    expirationTime = at;
    burnScale = scale;
    addLays(lays, at, scale: scale);
  }

  /// Lays [lays] more on at [at]: [lays] more of its burn time, stretched by
  /// the [scale] the firemaker's level gives (the fire's own when not
  /// given), from now if it had gone out.
  void addLays(int lays, DateTime at, {double? scale}) {
    if (lays <= 0) return;
    if (scale != null) burnScale = scale;
    final base = expirationTime.isAfter(at) ? expirationTime : at;
    final burn = definition.duration * lays;
    expirationTime = base.add(
      Duration(microseconds: (burn.inMicroseconds * burnScale).round()),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['burnScale'] = burnScale;
    return json;
  }

  void readFireStateFromJson(Map<String, dynamic> json) {
    // missing from a save before firemaking level stretched the burn
    final rawScale = json['burnScale'];
    burnScale = rawScale is num && rawScale > 0 ? rawScale.toDouble() : 1;
  }

  /// The fires that were retired when bonfires became one recipe per
  /// reagent, keyed by their old name, each to the prefix its wood's
  /// bonfires now carry ('OAK_BONFIRE' + '_STAMINA').
  static const Map<String, String> _retiredFires = {
    'BASIC_CAMPFIRE': 'BONFIRE',
    'BONFIRE': 'BONFIRE',
    'OAK_CAMPFIRE': 'OAK_BONFIRE',
    'OAK_BONFIRE': 'OAK_BONFIRE',
    'WILLOW_CAMPFIRE': 'WILLOW_BONFIRE',
    'WILLOW_BONFIRE': 'WILLOW_BONFIRE',
    'BOG_CAMPFIRE': 'BOG_BONFIRE',
    'BOG_BONFIRE': 'BOG_BONFIRE',
    'MAPLE_CAMPFIRE': 'MAPLE_BONFIRE',
    'MAPLE_BONFIRE': 'MAPLE_BONFIRE',
    'YEW_CAMPFIRE': 'YEW_BONFIRE',
    'YEW_BONFIRE': 'YEW_BONFIRE',
    'MAGIC_CAMPFIRE': 'MAGIC_BONFIRE',
    'MAGIC_BONFIRE': 'MAGIC_BONFIRE',
  };

  /// A saved fire from before bonfires were one recipe per reagent, brought
  /// up to date: a campfire or bonfire still burning a reagent buff at [now]
  /// becomes its wood's bonfire for that stat, burning as long as that buff
  /// had left. Returns null for one carrying no buff, which is simply
  /// dropped, and [json] unchanged for anything that is not a retired fire.
  static Map<String, dynamic>? migrateRetiredJson(
    Map<String, dynamic> json,
    DateTime now,
  ) {
    final prefix = _retiredFires[json['id']];
    if (prefix == null) return json;
    final reagents = json['reagents'];
    if (reagents is! Map) return null;
    for (final stat in SkillId.values) {
      final raw = reagents[stat.name];
      final until = raw is String ? DateTime.tryParse(raw) : null;
      if (until == null || !until.isAfter(now)) continue;
      final id = ItemId.byName('${prefix}_${stat.name}');
      if (id == null) continue;
      final rawEnd = json['expirationTime'];
      final fireEnd = rawEnd is String ? DateTime.tryParse(rawEnd) : null;
      final end = fireEnd != null && fireEnd.isBefore(until) ? fireEnd : until;
      return {...json, 'id': id.name, 'expirationTime': end.toIso8601String()};
    }
    return null;
  }
}
