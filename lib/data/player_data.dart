import 'dart:math';
import 'package:rpg/catalogs/entities/entities.dart';
import 'auto_eat_rule.dart';
import 'skill_data.dart';
import 'equipment_data.dart';
import '../catalogs/zones/zones.dart';
import '../data/buff_data.dart';

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
const double kBoostIdleShare = 0.15;

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
  ZoneId currentZoneId;

  EntityId currentEntityViewId;

  // skill stats
  BuffData buffData;
  Map<SkillId, SkillData> skillData;
  EquipmentData equipmentData;
  SkillId skillBoost = SkillId.SPEED;
  Stance stance = Stance.fast;

  /// When automated combat eats. Read by the live frame loop and by an
  /// offline settle alike.
  AutoEatRule autoEatRule = AutoEatRule.standard;

  DateTime lastActionTime = DateTime.now();

  // mutable stats
  int hitpoints = 10;
  double stamina = 0;
  double boostMultiplier = 1.0;

  PlayerData({
    required this.currentZoneId,
    required this.currentEntityViewId,
    required this.buffData,
    required this.skillData,
    required this.equipmentData,
    required this.hitpoints,
    required this.stamina,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentZoneId': currentZoneId.name,
      'currentEntityViewId': currentEntityViewId.name,
      'buffData': buffData.toJson(),
      'skillData': skillData.map(
        (key, value) => MapEntry(key.name, value.toJson()),
      ),
      'equipmentData': equipmentData.toJson(),
      'hitpoints': hitpoints,
      'stamina': stamina,
      'autoEatRule': autoEatRule.toJson(),
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

    return PlayerData(
        currentZoneId: ZoneId.values.firstWhere(
          (z) => z.name == rawZoneId,
          orElse: () => throw FormatException('Invalid ZoneId "\$rawZoneId".'),
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
          ? AutoEatRule.fromJson(json['autoEatRule'] as Map<String, dynamic>)
          : AutoEatRule.standard;
  }
}
