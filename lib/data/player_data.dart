import 'dart:math';
import 'package:rpg/catalogs/entities/entities.dart';
import 'auto_eat_rule.dart';
import 'skill_data.dart';
import 'equipment_data.dart';
import '../catalogs/zones/zones.dart';
import '../data/buff_data.dart';
import '../catalogs/items/items.dart';

/// Stance: which skill the action loop boosts during an encounter.
/// Picked on the combat screen; sets [PlayerData.skillBoost].
enum Stance { offensive, defensive, strong, fast }

const Map<Stance, SkillId> kStanceBoostSkill = {
  Stance.offensive: SkillId.ATTACK,
  Stance.defensive: SkillId.DEFENCE,
  Stance.strong: SkillId.STRENGTH,
  Stance.fast: SkillId.SPEED,
};

/// The skill the action loop's boost trains, and whose stat sets the boost
/// ceiling.
///
/// Only the fast stance runs on speed. Every other stance spends strength -
/// offensive and defensive included, where strength is what decides how far
/// attack or defence can be pushed. So the pair toggles with the stance: fast
/// trains speed, everything else trains strength.
SkillId boostTrainedSkill(SkillId skillBoost) {
  return skillBoost == SkillId.SPEED ? SkillId.SPEED : SkillId.STRENGTH;
}

/// What a boost stat is worth at full tilt, as a fraction of what it acts
/// on: strength on the stat it is spent on, speed on the action rate.
///
/// Square root rather than linear. A linear ceiling made a hundred points
/// worth eleven times, which is not a bonus so much as a different game;
/// the root keeps every point paying while landing a hundred of them at
/// about double. Nothing caps it - past the useful range it simply climbs
/// slowly rather than hitting a wall.
double boostStatBonus(int stat) => 0.1 * sqrt(stat < 0 ? 0 : stat);

/// Speed's half of that curve. Speed pays twice - once by shortening the
/// interval and again through the boost ceiling - so each half carries
/// half the exponent, and the two multiply back to [boostStatBonus]'s
/// shape at the top end.
double speedStatBonus(int stat) => 0.1 * sqrt(stat < 0 ? 0 : stat);

/// How much of the interval speed takes off standing still, before any of
/// the boost bar is filled. The interval is divided by `1 + this`, so it
/// approaches zero without ever arriving - which is what lets the old hard
/// floor go.
double speedIdleBonus(int stat) => 0.05 * sqrt(stat < 0 ? 0 : stat);

/// The share of [boostStatBonus] a strength stance is worth standing
/// still. Small but always on; the boost bar buys the rest.
///
/// DISABLED with the multiplicative application it belonged to - see
/// [PlayerDataService.getStatTotals]. Kept so the old curve can be switched
/// back on; nothing reads it while strength is additive.
const double kBoostIdleShare = 0.15;

/// Strength's additive curve, tuned by two exponents: what a stance pays
/// standing still, and what a full boost bar pays. The bar runs straight
/// between them.
///
/// Additive rather than multiplicative, which is what stops a stance being
/// worth more the higher the skill it lands on already is - the points are
/// the same whether they are added to mining 20 or mining 60. The old
/// multiplier is kept, disabled, in [PlayerDataService.getStatTotals].
const double kStrengthIdleExponent = 0.75;
const double kStrengthMaxExponent = 1.0;

/// Added on top of the max curve, so a full bar is worth a point even at
/// no strength at all.
const double kStrengthMaxOffset = 1.0;

/// Flat stat points a strength stance adds with the boost bar empty.
double strengthIdleBonus(int stat) =>
    pow(stat < 0 ? 0 : stat, kStrengthIdleExponent).toDouble();

/// Flat stat points a strength stance adds with the boost bar full.
double strengthMaxBonus(int stat) =>
    pow(stat < 0 ? 0 : stat, kStrengthMaxExponent).toDouble() +
    kStrengthMaxOffset;

/// Which stat totals a boosted skill scales - see
/// [PlayerDataService.getStatTotals].
///
/// Attack and defence scale themselves: the rolls read those stats directly.
/// Strength is different - no roll reads it, it is the stat the boost
/// ceiling is derived from - so it scales the gathering skill the boost is
/// being spent on instead. Boosting strength itself would feed the ceiling
/// back into its own multiplier and run away.
///
/// Speed is absent: it shortens the action interval rather than scaling any
/// stat.
const Map<SkillId, List<SkillId>> kBoostedStats = {
  SkillId.ATTACK: [SkillId.ATTACK],
  SkillId.DEFENCE: [SkillId.DEFENCE],
  SkillId.STRENGTH: [SkillId.MINING, SkillId.WOODCUTTING],
};

String stanceLabel(Stance stance) {
  switch (stance) {
    case Stance.offensive:
      return 'Offensive';
    case Stance.defensive:
      return 'Defensive';
    case Stance.strong:
      return 'Strong';
    case Stance.fast:
      return 'Fast';
  }
}

/// The stances an encounter offers, in display order. Combat picks an attack
/// style; mining and woodcutting trade power for pace. Everything else runs
/// fast with nothing to choose - see [PlayerDataService.coerceStanceFor].
List<Stance> stancesForEntity(EncounterEntity entity) {
  if (entity is CombatEntity) {
    return const [Stance.offensive, Stance.defensive, Stance.fast];
  }
  if (entity.entityType == SkillId.MINING ||
      entity.entityType == SkillId.WOODCUTTING) {
    return const [Stance.strong, Stance.fast];
  }
  return const [Stance.fast];
}

class PlayerData {
  // location info
  ZoneId _currentZoneId;

  /// Where the player is standing. Everything an action *does* keys off
  /// this.
  ZoneId get currentZoneId => _currentZoneId;

  /// Moving the player also points them at where they now are: arriving
  /// somewhere is looking at it. The invariant lives here rather than in the
  /// one service that moves them, so no path can move the player and leave
  /// the screens reading the place they left.
  set currentZoneId(ZoneId id) {
    _currentZoneId = id;
    currentZoneViewId = id;
  }

  EntityId currentEntityViewId;

  /// The zone the screens are showing, which is not always the one the
  /// player is standing in: the map's Enter walks you into a place to look
  /// at it before you decide to make the trip.
  ///
  /// The zone half of the same view/active split [currentEntityViewId]
  /// makes for entities. Everything a screen *reads* keys off this;
  /// everything an action *does* keys off [currentZoneId], which is why
  /// the action button becomes a travel button whenever the two differ.
  /// Arriving somewhere sets both, so they are equal in the ordinary case.
  late ZoneId currentZoneViewId;

  // skill stats
  BuffData buffData;
  Map<SkillId, SkillData> skillData;
  EquipmentData equipmentData;
  SkillId skillBoost = SkillId.SPEED;
  Stance stance = Stance.fast;

  /// When automated combat eats. Read by the live frame loop and by an
  /// offline settle alike.
  AutoEatRule autoEatRule = AutoEatRule.standard;

  /// Potions re-drunk whenever their buff lapses while an action runs. On
  /// PlayerData rather than UiState for the same reason as [autoEatRule]:
  /// the live tick and an offline settle read the same set.
  Set<ItemId> autoDrinkPotions = {};

  DateTime lastActionTime = DateTime.now();

  // mutable stats
  int hitpoints = 10;
  double stamina = 0;

  /// How full the boost bar is, 0..1. Written by the action loop each
  /// frame; read only by [PlayerDataService.getStatTotals], which runs the
  /// strength curve off it. Held here rather than a multiplier because the
  /// strength bonus is additive now - see [strengthIdleBonus].
  double boostFill = 0.0;

  PlayerData({
    required ZoneId currentZoneId,
    required this.currentEntityViewId,
    required this.buffData,
    required this.skillData,
    required this.equipmentData,
    required this.hitpoints,
    required this.stamina,
  }) : _currentZoneId = currentZoneId {
    // a new game opens looking at where it starts you
    currentZoneViewId = currentZoneId;
  }

  Map<String, dynamic> toJson() {
    return {
      'currentZoneId': currentZoneId.name,
      'currentZoneViewId': currentZoneViewId.name,
      'currentEntityViewId': currentEntityViewId.name,
      'buffData': buffData.toJson(),
      'skillData': skillData.map(
        (key, value) => MapEntry(key.name, value.toJson()),
      ),
      'equipmentData': equipmentData.toJson(),
      'hitpoints': hitpoints,
      'stamina': stamina,
      'autoEatRule': autoEatRule.toJson(),
      'autoDrinkPotions': [for (final id in autoDrinkPotions) id.name],
      'lastActionTime': lastActionTime.toIso8601String(),
    };
  }

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    final rawZoneId = json['currentZoneId'];
    final rawEntityId = json['currentEntityViewId'];
    final rawBuffData = json['buffData'];
    final rawSkillData = json['skillData'];
    final rawEquipmentData = json['equipmentData'];
    final rawHitpoints = json['hitpoints'];
    final rawStamina = json['stamina'];

    if (rawZoneId is! String) {
      throw FormatException('Missing or invalid "currentZoneId".');
    }

    if (rawEntityId is! String) {
      throw FormatException('Missing or invalid "currentEntityViewId".');
    }

    if (rawBuffData is! Map) {
      throw FormatException('Missing or invalid "buffData".');
    }

    if (rawSkillData is! Map) {
      throw FormatException('Missing or invalid "skillData".');
    }

    if (rawEquipmentData is! Map) {
      throw FormatException('Missing or invalid "equipmentData".');
    }

    if (rawHitpoints is! int) {
      throw FormatException('Missing or invalid "hitpoints".');
    }

    if (rawStamina is! num) {
      throw FormatException('Missing or invalid "stamina".');
    }

    final rawLastActionTime = json['lastActionTime'];
    final lastActionTime = rawLastActionTime is String
        ? DateTime.parse(rawLastActionTime)
        : DateTime.now();

    final skillData = <SkillId, SkillData>{};

    for (final entry in rawSkillData.entries) {
      final rawSkillId = entry.key;
      final rawSkill = entry.value;

      if (rawSkillId is! String) {
        throw FormatException('Invalid skill id key.');
      }

      if (rawSkill is! Map<String, dynamic>) {
        throw FormatException('Invalid skill data for "\$rawSkillId".');
      }

      // migration: renamed skills map onto their new ids
      const legacySkillNames = {
        'ECONOMY': SkillId.RECOVERY,
        'FORAGING': SkillId.HERBALISM,
      };

      final skillId =
          legacySkillNames[rawSkillId] ??
          SkillId.values.firstWhere(
            (s) => s.name == rawSkillId,
            orElse: () =>
                throw FormatException('Invalid SkillId "\$rawSkillId".'),
          );

      skillData[skillId] = SkillData.fromJson(rawSkill);
    }

    final data =
        PlayerData(
            currentZoneId: ZoneId.values.firstWhere(
              (z) => z.name == rawZoneId,
              orElse: () =>
                  throw FormatException('Invalid ZoneId "\$rawZoneId".'),
            ),
            currentEntityViewId: EntityId.values.firstWhere(
              (e) => e.name == rawEntityId,
              orElse: () =>
                  throw FormatException('Invalid EntityId "\$rawEntityId".'),
            ),
            buffData: BuffData.fromJson(Map<String, dynamic>.from(rawBuffData)),
            skillData: skillData,
            equipmentData: EquipmentData.fromJson(
              Map<String, dynamic>.from(rawEquipmentData),
            ),
            hitpoints: rawHitpoints,
            stamina: rawStamina.toDouble(),
          )
          ..lastActionTime = lastActionTime
          ..autoEatRule = json['autoEatRule'] is Map<String, dynamic>
              ? AutoEatRule.fromJson(
                  json['autoEatRule'] as Map<String, dynamic>,
                )
              : AutoEatRule.standard
          ..autoDrinkPotions = _readAutoDrinkPotions(json['autoDrinkPotions']);

    // a save from before the map could show you a place you aren't standing
    // in, or one naming a zone the catalog has since retired, comes back
    // looking at wherever the player is. being put back on the wrong screen
    // is not worth failing a load over.
    final rawViewZoneId = json['currentZoneViewId'];
    data.currentZoneViewId = rawViewZoneId is String
        ? (ZoneId.values.asNameMap()[rawViewZoneId] ?? data.currentZoneId)
        : data.currentZoneId;

    return data;
  }
}

/// A preference rather than a position, so anything malformed reads as
/// nothing toggled rather than failing the load. An id the catalog has
/// since retired is skipped, the way InventoryData skips one.
Set<ItemId> _readAutoDrinkPotions(Object? raw) {
  if (raw is! List) return {};
  final ids = <ItemId>{};
  for (final entry in raw) {
    if (entry is! String) continue;
    final id = ItemId.values.asNameMap()[entry];
    if (id != null) ids.add(id);
  }
  return ids;
}
