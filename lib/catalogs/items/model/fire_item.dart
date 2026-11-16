import 'dart:math' as math;

import 'package:rpg/catalogs/items/definition/fire_item_definition.dart';
import 'package:rpg/catalogs/items/model/zone_buff_item.dart';
import 'package:rpg/data/skill_data.dart';

/// One stretch of a fire's burn still to come: the bonus it gives and how
/// long it lasts.
typedef BurnStep = ({int bonus, Duration left});

/// A fire burning in a firepit. [canCook] is what opens the cooking half of
/// the firepit screen; a cookfire's own COOKING bonus is what makes a better
/// fire burn less food, via the buffed stat totals.
///
/// A campfire or bonfire has no bonus of its own. It holds the reagent buffs
/// thrown on it instead, one per stat, each running out on its own clock and
/// all of them ending with the fire.
///
/// Fires burn one of two ways:
///
/// - a campfire or cookfire is a steady slow burn: every lay adds the fire's
///   own burn time at its full bonus, with no cap. Lay it and walk away.
/// - a bonfire is stoked ([FireItemDefinition.stokes]): it burns on heat,
///   not a timer. Each lay raises the heat, by less the hotter it already
///   is, and the heat cools on its own - halving every [halfLife], so the
///   hotter it is the faster it falls. Heat stoked over the ceiling cools
///   slower ([peakHalfLife]), so the peak holds a few minutes once the
///   logs stop. Its bonus is the highest rung of the
///   [ladder] the heat has reached, up to the wood's [ceiling]. Stoke it to
///   the top, then carry the long cool-down into a fight; it goes out once
///   the heat falls below 1.
class FireItem extends ZoneBuffItem {
  FireItem({
    required super.id,
    super.fuelUnits,
    super.zoneId,
    super.ownerEntityId,
  }) {
    _heatAt = DateTime.now();
  }

  /// The bonus ladder a bonfire's heat climbs: Fibonacci, without the 2.
  static const List<int> ladder = [1, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233];

  /// How long a bonfire's heat takes to halve.
  static const Duration halfLife = Duration(minutes: 2);

  /// How long heat stoked above the [ceiling] takes to halve: slower than
  /// [halfLife], so a bonfire stoked to its peak holds it for a few minutes
  /// after the logs stop before it starts cooling down the rungs.
  static const Duration peakHalfLife = Duration(minutes: 5);

  /// The share of the gap to [heatCap] each lay closes.
  static const double heatPerLay = 0.25;

  /// How far past its [ceiling] a bonfire's heat can be pushed, as a
  /// multiple of the ceiling. Above 1, so steady stoking settles over the
  /// top rung and the fire holds it for a while after the logs stop.
  static const double heatCapFactor = 1.6;

  /// How many rungs above its wood's campfire a bonfire tops out.
  static const int ceilingRungs = 2;

  /// [value] stepped [by] rungs along the [ladder] from the rung it stands
  /// on.
  static int stepped(int value, int by) {
    if (value <= 0) return 0;
    if (by == 0) return value;
    final to = _rungOf(value) + by;
    if (to < 0) return 1;
    if (to >= ladder.length) return ladder.last;
    return ladder[to];
  }

  // the highest rung [value] reaches
  static int _rungOf(num value) {
    var rung = 0;
    for (var i = 0; i < ladder.length; i++) {
      if (ladder[i] <= value) rung = i;
    }
    return rung;
  }

  /// How much longer than the base this fire burns, from the firemaker's
  /// level when its last lay went on: 1 at the fire's level requirement,
  /// and [burnScalePerLevel] more for every level over it. It stretches a
  /// campfire's burn per lay, how slowly a bonfire cools, and how long each
  /// reagent lasts on it.
  double burnScale = 1;

  /// The extra burn per firemaking level over the fire's requirement.
  static const double burnScalePerLevel = 0.01;

  /// The burn scale a firemaker at [level] gets on a fire whose recipe asks
  /// for [requirement].
  static double burnScaleFor(int level, int requirement) {
    final over = level - requirement;
    return over <= 0 ? 1 : 1 + over * burnScalePerLevel;
  }

  // the half-lives, stretched by the burn scale
  double get _halfMicros => halfLife.inMicroseconds * burnScale;
  double get _peakHalfMicros => peakHalfLife.inMicroseconds * burnScale;

  /// The heat at [_heatAt]. Only a bonfire has any.
  double _heat = 0;
  late DateTime _heatAt;

  @override
  FireItemDefinition get definition => id.definition as FireItemDefinition;

  bool get canCook => definition.canCook;

  /// What one reagent's buff is worth on this fire: a campfire's wood, or
  /// the rung a bonfire's heat starts from.
  int get power => definition.power;

  bool get tendable => definition.tendable;

  /// Whether this fire burns on heat rather than a timer.
  bool get stokes => definition.stokes;

  /// The highest bonus a bonfire can be stoked to.
  int get ceiling => stepped(power, ceilingRungs);

  double get heatCap => ceiling * heatCapFactor;

  /// The longest a bonfire can burn: from a full [heatCap] down to out, at
  /// its [burnScale]. Zero for a fire that does not stoke.
  Duration get maxBurn => stokes ? _coolTime(heatCap, 1) : Duration.zero;

  /// The bonus that names what this fire gives: a reagent's power on a
  /// campfire, a cookfire's own bonus, a bonfire's [ceiling].
  int get headlineBonus {
    if (stokes) return ceiling;
    if (tendable) return power;
    var best = 0;
    for (final v in definition.skillBonus.values) {
      if (v > best) best = v;
    }
    return best;
  }

  /// A bonfire's heat at [at]: what it was at the last lay, halved for every
  /// [halfLife] since.
  double heatAt(DateTime at) {
    if (!stokes) return 0;
    final dt = at.difference(_heatAt).inMicroseconds;
    if (dt <= 0) return _heat;
    // over the ceiling it cools at the slow peak rate, then at the normal
    // one from the ceiling down
    final c = ceiling.toDouble();
    if (_heat > c) {
      final toCeiling = _halves(_heat / c) * _peakHalfMicros;
      if (dt <= toCeiling) {
        return _heat * math.pow(0.5, dt / _peakHalfMicros);
      }
      return c * math.pow(0.5, (dt - toCeiling) / _halfMicros);
    }
    return _heat * math.pow(0.5, dt / _halfMicros);
  }

  static double _halves(double ratio) => math.log(ratio) / math.ln2;

  /// The bonus this fire gives each reagent at [at], 0 once it is out: a
  /// campfire's wood all the way, a bonfire the rung its heat has reached.
  int powerAt(DateTime at) {
    if (!expirationTime.isAfter(at)) return 0;
    if (!stokes) return power;
    return _rungBonus(heatAt(at));
  }

  // the rung [heat] has reached, capped at the ceiling
  int _rungBonus(double heat) {
    if (heat < 1) return 0;
    final v = ladder[_rungOf(heat)];
    return v > ceiling ? ceiling : v;
  }

  // how long [from] heat takes to cool to [to]
  Duration _coolTime(double from, double to) {
    if (from <= to || to <= 0) return Duration.zero;
    final c = ceiling.toDouble();
    var micros = 0.0;
    var h = from;
    // the stretch over the ceiling cools at the slow peak rate
    if (h > c) {
      final stop = to > c ? to : c;
      micros += _halves(h / stop) * _peakHalfMicros;
      h = stop;
    }
    if (h > to) micros += _halves(h / to) * _halfMicros;
    return Duration(microseconds: micros.round());
  }

  /// Every stretch still to come at [at], bonus by bonus, highest first: a
  /// campfire's one steady burn, or each rung a bonfire will cool through.
  List<BurnStep> stepsAt(DateTime at) {
    if (!expirationTime.isAfter(at)) return const [];
    if (!stokes) {
      return [(bonus: headlineBonus, left: expirationTime.difference(at))];
    }
    return _stepsFrom(heatAt(at));
  }

  // the rungs [heat] will cool through, highest first, each with how long
  // it lasts: the top until the heat falls under its floor, each lower one
  // from the floor above it down to its own, the last until the heat is
  // under 1
  List<BurnStep> _stepsFrom(double heat) {
    final steps = <BurnStep>[];
    var h = heat;
    var bonus = _rungBonus(h);
    while (bonus > 0) {
      final floor = bonus.toDouble();
      steps.add((bonus: bonus, left: _coolTime(h, floor)));
      if (floor <= 1) break;
      h = floor;
      bonus = ladder[_rungOf(floor) - 1];
    }
    return steps;
  }

  /// Lights a fresh fire of [lays] at [at], burning at [scale] (see
  /// [burnScale]).
  void lightAt(DateTime at, {int lays = 1, double scale = 1}) {
    _heat = 0;
    _heatAt = at;
    expirationTime = at;
    burnScale = scale;
    addLays(lays, at, scale: scale);
  }

  /// Lays [lays] more on at [at], at the [scale] the firemaker's level gives
  /// (see [burnScale]); it carries on at the fire's own when not given. A
  /// campfire burns [lays] more of its burn time, stretched by the scale,
  /// from now if it had gone out. A bonfire's heat rises by a [heatPerLay]
  /// share of the gap to [heatCap] for each, and cools at the new scale from
  /// here on.
  void addLays(int lays, DateTime at, {double? scale}) {
    if (lays <= 0) return;
    if (!stokes) {
      if (scale != null) burnScale = scale;
      final base = expirationTime.isAfter(at) ? expirationTime : at;
      final burn = definition.duration * lays;
      expirationTime = base.add(
        Duration(microseconds: (burn.inMicroseconds * burnScale).round()),
      );
      return;
    }
    // the heat so far cooled at the old scale; from this lay on, the new one
    final heat = heatAt(at);
    if (scale != null) burnScale = scale;
    _heat = _heatAfter(heat, lays);
    _heatAt = at;
    expirationTime = at.add(_coolTime(_heat, 1));
  }

  double _heatAfter(double heat, int lays) {
    var h = heat;
    for (var i = 0; i < lays; i++) {
      h += heatPerLay * (heatCap - h);
    }
    return h;
  }

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

  /// Whether kindling for [stat] can go on at [at]. A fire carries one
  /// kindling: it takes more of the one burning on it, or any once nothing
  /// is, but never a second stat beside the first.
  bool takesKindling(SkillId stat, DateTime at) {
    for (final active in activeReagentStats(at)) {
      if (active != stat) return false;
    }
    return true;
  }

  /// The kindling stat burning on this fire at [at], or null when none is.
  SkillId? kindlingAt(DateTime at) {
    final active = activeReagentStats(at);
    return active.isEmpty ? null : active.first;
  }

  /// How full [stat]'s reagent buff is at [at]: its time left out of the
  /// fire's, 0 to 1. A buff can burn no longer than its fire, so a full ring
  /// is one that lasts as long as the fire does; laying more logs on lowers
  /// every ring until more reagents go on. 0 when it is down.
  double reagentFullness(SkillId stat, DateTime at) {
    final end = reagentEndsAt(stat, at);
    if (end == null) return 0;
    final fireLeft = expirationTime.difference(at).inMilliseconds;
    if (fireLeft <= 0) return 0;
    return (end.difference(at).inMilliseconds / fireLeft).clamp(0.0, 1.0);
  }

  /// Throws [count] reagents' worth of [stat] on: the buff extends from its
  /// current end when it is still up, and starts at [at] when it is not. It
  /// stacks to at most the fire's own end: past that it would be burning on
  /// a fire that is out.
  void tend(SkillId stat, DateTime at, {int count = 1}) {
    if (count <= 0) return;
    final current = reagentExpirations[stat];
    final base = current != null && current.isAfter(at) ? current : at;
    // a reagent lasts longer on a fire a better firemaker laid
    final burn = definition.reagentBurn * count;
    final extended = base.add(
      Duration(microseconds: (burn.inMicroseconds * burnScale).round()),
    );
    reagentExpirations[stat] = extended.isAfter(expirationTime)
        ? expirationTime
        : extended;
  }

  /// Everything the fire gives at [at]: a cookfire's own bonus, and every
  /// reagent burning on it at the fire's [powerAt].
  @override
  Map<SkillId, int> bonusAt(DateTime at) {
    if (!expirationTime.isAfter(at)) return const {};
    final reagentBonus = powerAt(at);
    return {
      ...definition.skillBonus,
      for (final stat in activeReagentStats(at)) stat: reagentBonus,
    };
  }

  /// A bonfire's bonus changes each time its heat cools under a rung.
  Iterable<DateTime> get _rungDrops sync* {
    if (!stokes || _heat < 1) return;
    var t = _heatAt;
    for (final step in _stepsFrom(_heat)) {
      t = t.add(step.left);
      yield t;
    }
  }

  @override
  Iterable<DateTime> get changeTimes => [
    ..._rungDrops,
    expirationTime,
    ...reagentExpirations.values,
  ];

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['burnScale'] = burnScale;
    if (stokes) {
      json['heat'] = _heat;
      json['heatAt'] = _heatAt.toIso8601String();
    }
    json['reagents'] = {
      for (final entry in reagentExpirations.entries)
        entry.key.name: entry.value.toIso8601String(),
    };
    return json;
  }

  /// Restores a bonfire's heat and the reagent buffs. A campfire is its
  /// expiration alone. A bonfire saved before it burnt on heat is relit at
  /// the heat that lasts as long as it had left; one from before fires were
  /// tended simply has no reagents.
  void readFireStateFromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    // missing from a save before firemaking level stretched the burn
    final rawScale = json['burnScale'];
    burnScale = rawScale is num && rawScale > 0 ? rawScale.toDouble() : 1;
    if (stokes) {
      final rawHeat = json['heat'];
      final rawAt = json['heatAt'];
      final at = rawAt is String ? DateTime.tryParse(rawAt) : null;
      if (rawHeat is num && at != null) {
        _heat = rawHeat.toDouble();
        _heatAt = at;
      } else {
        // the heat that cools to 1 just when the old fire would have gone
        // out
        final left = expirationTime.difference(now);
        _heatAt = now;
        _heat = left.isNegative
            ? 0
            : math
                  .pow(2, left.inMicroseconds / _halfMicros)
                  .toDouble()
                  .clamp(0.0, heatCap);
      }
      expirationTime = _heat < 1 ? _heatAt : _heatAt.add(_coolTime(_heat, 1));
    }

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
