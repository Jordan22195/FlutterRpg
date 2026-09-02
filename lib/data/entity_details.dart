import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import 'skill_data.dart';

/// One row of an entity's drop table: how likely the item is to land on a
/// single kill/gather, and how big the stack runs when it does.
class EntityDropChance {
  final ItemId itemId;
  final String name;

  /// The quality this line drops at. A table may list the same item more
  /// than once at different qualities, which is otherwise two identical
  /// looking rows.
  final Rarity rarity;

  /// Probability this drop lands on one kill (0..1).
  final double chance;

  final int minCount;
  final int maxCount;

  /// Rolled by a layered bonus roll rather than the main drop table.
  final bool bonus;

  const EntityDropChance({
    required this.itemId,
    required this.name,
    this.rarity = Rarity.COMMON,
    required this.chance,
    required this.minCount,
    required this.maxCount,
    required this.bonus,
  });

  /// True when the stack size varies (count..highCount).
  bool get hasCountRange => maxCount > minCount;
}

/// Snapshot of everything the entity details popup shows: the entity's own
/// stats, its drop table odds, and both sides of the combat roll resolved
/// against the player's current stats. Built by
/// [EncounterSystem.buildEntityDetails].
class EntityDetails {
  final EncounterEntity entity;

  /// Level gate for gathering the entity (herbs); 0 when ungated.
  final int requiredLevel;

  /// Estimated xp for consuming one count, matching the explore card.
  final double xpPerUnit;

  /// The player skill rolled against this entity (its [entityType]).
  final int playerSkillLevel;
  final int playerDefence;
  final int playerMaxHp;

  /// The player's chance for one action to land, and its damage ceiling.
  final double playerHitChance;
  final int playerMaxHit;

  /// Combat entities only: the entity's chance to land a hit on the player
  /// and how hard it hits. Both zero for everything else.
  final double entityHitChance;
  final int entityMaxHit;

  /// Herbs only: expected herbs per pick, since a pick always succeeds and
  /// the roll against the herb's difficulty only sets the yield. 0 for
  /// every other entity, which yields one stack per successful action.
  final double expectedYield;

  final List<EntityDropChance> drops;

  const EntityDetails({
    required this.entity,
    required this.requiredLevel,
    required this.xpPerUnit,
    required this.playerSkillLevel,
    required this.playerDefence,
    required this.playerMaxHp,
    required this.playerHitChance,
    required this.playerMaxHit,
    required this.entityHitChance,
    required this.entityMaxHit,
    required this.expectedYield,
    required this.drops,
  });

  SkillId get skill => entity.entityType;

  /// Whether the entity fights back, i.e. whether the incoming-damage
  /// section applies.
  bool get isCombat => entity is CombatEntity;

  /// Whether actions against this entity roll damage against its
  /// hitpoints. Fishing spots replenish and herbs are picked in one
  /// action, so neither has a damage/kill cycle.
  bool get usesDamage => skill != SkillId.FISHING && skill != SkillId.HERBALISM;

  double get playerMissChance => 1.0 - playerHitChance;

  /// Expected damage per action: the to-hit roll times the uniform
  /// 1..maxHit damage roll.
  double get playerAverageDamage => playerHitChance * (1 + playerMaxHit) / 2.0;

  /// Actions needed to take one count down from full hitpoints. Infinite
  /// when the player can't damage it at all.
  double get actionsToKill {
    if (entity.maxHitPoints <= 0 || playerAverageDamage <= 0) {
      return double.infinity;
    }
    return entity.maxHitPoints / playerAverageDamage;
  }

  /// The player's chance to turn aside an incoming swing. A blocked hit
  /// deals no damage and awards defence xp instead.
  double get blockChance => 1.0 - entityHitChance;

  double get entityAverageDamage => entityHitChance * (1 + entityMaxHit) / 2.0;

  /// Seconds between the entity's swings; 0 for non-combat entities.
  double get entityAttackInterval {
    final e = entity;
    return e is CombatEntity ? e.attackInterval : 0;
  }

  /// Incoming damage per second at the entity's swing rate.
  double get entityDamagePerSecond {
    final interval = entityAttackInterval;
    return interval <= 0 ? 0 : entityAverageDamage / interval;
  }
}
