import 'dart:math';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import '../services/inventory_service.dart';
import '../data/combat_segment_outcome.dart';
import '../data/encounter_data.dart';
import '../data/action_result.dart';

class EncounterService {
  /// Bonus yield rolls a single herb pick makes on top of its guaranteed
  /// herb, so a pick yields 1..1+[herbBonusRolls].
  static const int herbBonusRolls = 4;

  // set respawn flag for ui for 200ms then reset entity hp. the dying
  // entity is captured at call time: the active encounter can switch
  // during the delay, and the reset must land on the entity that died
  //
  // [instant] skips the pause entirely. the flash sells a resource node
  // repopulating; the next member of a queue is a different enemy stepping
  // up, which shouldn't stall — and a deferred reset would land 200ms later
  // on an enemy the player has already started hitting
  Future<void> respawn(
    EncounterData encounterState,
    EncounterEntity entity, {
    bool instant = false,
  }) async {
    if (instant) {
      entity.hitpoints = entity.maxHitPoints;
      return;
    }

    encounterState.respawning = true;

    await Future.delayed(const Duration(milliseconds: 200));
    entity.hitpoints = entity.maxHitPoints;

    encounterState.respawning = false;
  }

  /// Expected damage per action: the to-hit roll times the uniform
  /// 1..maxHit damage roll.
  double playerAverageDamage(
    Map<SkillId, int> playerStatTotals,
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    if (encounterState.isActive == false) {
      return 0;
    }
    final entity =
        encounterState.entity ??
        EncounterEntity(
          id: EntityId.NULL,
          name: "",
          count: 0,
          entityType: SkillId.NULL,
          defence: 0,
          hitpoints: 0,
        );

    final skillId = entity.entityType;

    int playerOffenseSkillStat = playerStatTotals[skillId] ?? 0;

    int encounterDefence = encounterState.entity!.defence;
    double avgDamage =
        chanceToHit(playerOffenseSkillStat, encounterDefence) *
        (1 +
            computeMaxHit(
              attack: playerOffenseSkillStat,
              defense: encounterDefence,
            )) /
        2.0;
    return avgDamage;
  }

  /// Actions needed to take one count down from full hitpoints. Infinite
  /// when the player can't damage it at all.
  double actionsToKill(int maxHitPoints, double averageDamage) {
    if (maxHitPoints <= 0 || averageDamage <= 0) {
      return double.infinity;
    }
    return maxHitPoints / averageDamage;
  }

  EncounterActionResult resolvePlayerDamage(
    Map<SkillId, int> playerStatTotals,
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    EncounterActionResult res = EncounterActionResult();

    if (encounterState.isActive == false) {
      return res;
    }
    final entity =
        encounterState.entity ??
        EncounterEntity(
          id: EntityId.NULL,
          name: "",
          count: 0,
          entityType: SkillId.NULL,
          defence: 0,
          hitpoints: 0,
        );

    final skillId = entity.entityType;

    int playerOffenseSkillStat = playerStatTotals[skillId] ?? 0;

    int encounterDefence = encounterState.entity!.defence;
    int dmg = calculateAttackDamage(
      attackerAttack: playerOffenseSkillStat,
      defenderDefense: encounterDefence,
      defenderHp: entity.hitpoints,
    );
    encounterState.lastPlayerDamage = dmg;
    entity.hitpoints -= dmg;

    // todo : xp calculations
    res.damageDone = dmg;
    res.enemyDied = entity.hitpoints <= 0;

    return res;
  }

  // return damage roll for given attack and defence stats
  // damage does not exceed the hp parameter
  int calculateAttackDamage({
    required int attackerAttack,
    required int defenderDefense,
    required int defenderHp,
  }) {
    final rng = Random();

    // 1) Roll to hit
    final hitChance = chanceToHit(attackerAttack, defenderDefense);
    final hitRoll = rng.nextDouble();

    if (hitRoll > hitChance) {
      return 0;
    }

    // 2) Roll damage
    int damage = rollDamageUniform(
      attack: attackerAttack,
      defense: defenderDefense,
      rng: rng,
    );

    if (damage > defenderHp) {
      damage = defenderHp;
    }

    return damage;
  }

  // check the unique id of the enity and see if it matches the unique
  // id of the entity in the encounter state
  bool isNewEntity(EncounterData encounterState, Entity entity) {
    if (encounterState.entity == null) {
      return true;
    }
    return encounterState.entity!.instanceId != entity.instanceId;
  }

  // set the entity instance in the encounter state
  void setEncounterEntity(
    EncounterData encounterState,
    EncounterEntity entity,
  ) {
    if (entity.count <= 0) {
      encounterState.isActive = false;
    }

    // revive entities stuck at 0 hp (a missed respawn or a save written
    // mid-respawn); at 0 hp all damage rolls cap at 0 and the entity can
    // never die again
    if (entity.hitpoints <= 0 && entity.count > 0 && entity.maxHitPoints > 0) {
      entity.hitpoints = entity.maxHitPoints;
    }

    encounterState.entity = entity;

    encounterState.isActive = true;
  }

  /// Resolves the enemy's swings over [seconds], one at a time.
  ///
  /// Sampled per swing rather than averaged, because what ends a fight is
  /// variance and not the mean: an enemy averaging 6 against a 10hp player
  /// looks survivable forever, while the same enemy rolling its max of 12
  /// ends it outright. Averaging the player's own damage is fine - killing
  /// an enemy faster or slower than the mean does not change how the fight
  /// ends - but averaging the enemy's is what made offline combat free.
  ///
  /// The order mirrors the live frame exactly (damage, death, then the eat,
  /// see [EncounterController.onActionTimingFrame]), so a replayed fight and
  /// one watched on screen are the same fight.
  ///
  /// Cost is a couple of integer operations and an inline xorshift step per
  /// swing, with nothing allocated: ten million swings - about seven months
  /// away at a two second attack interval - resolve in well under a second.
  /// [rng] seeds it; tests pass a seeded one to pin a sequence.
  CombatSegmentOutcome resolveIncomingDamage({
    required int hitpoints,
    required int maxHp,
    required double eatThreshold,
    required int foodCount,
    required int restoreAmount,
    required int enemyAttack,
    required int playerDefence,
    required double attackInterval,
    required double seconds,
    Random? rng,
  }) {
    CombatSegmentOutcome none(double elapsed) => CombatSegmentOutcome(
      swings: 0,
      elapsed: elapsed,
      hitpoints: hitpoints,
      foodEaten: 0,
      blocks: 0,
      died: false,
    );

    if (seconds <= 0 || attackInterval <= 0 || maxHp <= 0) {
      return none(seconds <= 0 ? 0 : seconds);
    }

    final swingCount = (seconds / attackInterval).floor();
    if (swingCount <= 0) return none(seconds);

    // the two numbers the whole fight runs on: how often a swing lands, and
    // how hard it can land. both are the live formulas.
    final hitChance = chanceToHit(enemyAttack, playerDefence);
    final maxHit = computeMaxHit(attack: enemyAttack, defense: playerDefence);
    // entityAttack caps a roll at the player's max hp, so a max hit above
    // the pool is not worth more than the pool
    final damageCap = maxHit < maxHp ? maxHit : maxHp;
    // the hit roll as a 16 bit fraction, so a swing costs integer compares
    // rather than a double divide
    final hitCutoff = (hitChance * 0x10000).round();
    final eatAt = maxHp * eatThreshold;

    var state = ((rng ?? Random()).nextInt(0x7FFFFFFF) | 1) & 0xFFFFFFFF;
    var hp = hitpoints;
    var food = foodCount;
    var eaten = 0;
    var blocks = 0;
    var resolved = 0;
    var died = false;

    for (var i = 0; i < swingCount; i++) {
      resolved = i + 1;

      // xorshift32: a fresh Random.nextInt a swing would cost more than the
      // rest of the loop put together
      state ^= (state << 13) & 0xFFFFFFFF;
      state ^= state >> 17;
      state ^= (state << 5) & 0xFFFFFFFF;

      if ((state & 0xFFFF) >= hitCutoff) {
        // a miss. live pays defence xp for the damage it avoided
        blocks++;
        continue;
      }

      state ^= (state << 13) & 0xFFFFFFFF;
      state ^= state >> 17;
      state ^= (state << 5) & 0xFFFFFFFF;

      var damage = 1 + (state % maxHit);
      if (damage > damageCap) damage = damageCap;

      hp -= damage;
      if (hp <= 0) {
        hp = 0;
        died = true;
        break;
      }

      if (food > 0 && hp <= eatAt && restoreAmount > 0) {
        food--;
        eaten++;
        hp += restoreAmount;
        if (hp > maxHp) hp = maxHp;
      }
    }

    return CombatSegmentOutcome(
      swings: resolved,
      elapsed: died ? resolved * attackInterval : seconds,
      hitpoints: hp,
      foodEaten: eaten,
      blocks: blocks,
      died: died,
    );
  }

  // calculate hit chance for a given attack and defense.
  double chanceToHit(
    int attack,
    int defense, {
    double minChance = 0.05, // 5% floor / 95% ceiling
    double slope = 0.045, // tuned for 1–200 stat range
    double bias = 0.0, // positive favors attacker, negative favors defender
  }) {
    // Clamp inputs defensively
    attack = attack.clamp(0, 100000);
    defense = defense.clamp(0, 100000);

    final diff = (attack - defense) + bias;

    // Logistic curve
    final core = 1.0 / (1.0 + exp(-slope * diff));

    // Apply floor/ceiling so it's never guaranteed
    return minChance + (1.0 - 2.0 * minChance) * core;
  }

  // calculated max git for a given attack and defense
  int computeMaxHit({
    required int attack,
    required int defense,
    double attackScaling = 1.0, // attack=100 => unmitigated max 100
    int baseMax = 0,
    int minMaxHit = 1,
  }) {
    attack = attack.clamp(0, 100000);
    defense = defense.clamp(0, 100000);

    final unmitigated = baseMax + (attack * attackScaling);

    final denom = attack + defense;
    final multiplier = denom > 0 ? (attack / denom) : 0.5;

    final maxHit = (unmitigated * multiplier).floor();
    return max(minMaxHit, maxHit);
  }

  // roll for damange (1 - max hit)
  int rollDamageUniform({
    required int attack,
    required int defense,
    Random? rng,
  }) {
    final r = rng ?? Random();
    final maxHit = computeMaxHit(attack: attack, defense: defense);

    // Uniform integer in [1, maxHit]
    return 1 + r.nextInt(maxHit);
  }

  // calculate enemy attack roll against player. a blocked hit deals 0
  // damage; when that happens the player earns defence xp equal to the
  // damage the blow would have dealt had it landed.
  EncounterActionResult entityAttack(
    EncounterData encounterState,
    Map<SkillId, int> playerStatTotals,
  ) {
    final result = EncounterActionResult();
    if (encounterState.entity is! CombatEntity) {
      return result;
    }
    final e = encounterState.entity as CombatEntity;

    final defence = playerStatTotals[SkillId.DEFENCE] ?? 1;

    int damageDone = calculateAttackDamage(
      attackerAttack: e.attack,
      defenderDefense: defence,
      defenderHp: playerStatTotals[SkillId.HITPOINTS] ?? 0,
    );
    result.damageDone = damageDone;

    // blocked hit: reward defence xp for the damage that was avoided
    if (damageDone <= 0) {
      final wouldHaveDone = rollDamageUniform(
        attack: e.attack,
        defense: defence,
      );
      result.xp[SkillId.DEFENCE] = wouldHaveDone.toDouble();
    }

    return result;
  }

  void resetEncounterState(
    EncounterData encounterState,
    InventoryService inventoryService,
  ) {
    encounterState.isActive = false;
    inventoryService.clearItems(encounterState.itemDrops);
    encounterState.lastPlayerDamage = 0;
    encounterState.respawning = false;
  }

  EncounterActionResult doFishingAction(
    Map<SkillId, int> playerStatTotals,
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    int playerSkillStatTotal = playerStatTotals[SkillId.FISHING] ?? 1;
    final e = encounterState.entity;
    EncounterActionResult r = EncounterActionResult();
    if (e == null) {
      return r;
    }

    r.damageDone = calculateAttackDamage(
      attackerAttack: playerSkillStatTotal,
      defenderDefense: e.defence,
      defenderHp: e.hitpoints,
    );

    return r;
  }

  bool fishingConditionsMet(
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    if (encounterState.entity == null) return false;
    if (!encounterState.isActive) return false;

    return true;
  }

  // herbs don't fight back, so no hp check; unlike fishing spots they
  // deplete, so the count matters. the herbalism level gate needs the
  // entity catalog and lives in EncounterSystem.meetsHerbRequirement
  bool herbalismConditionsMet(
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    if (encounterState.entity == null) return false;
    if (encounterState.entity!.count <= 0) return false;
    if (!encounterState.isActive) return false;

    return true;
  }

  // picking an herb always succeeds; the roll against its difficulty only
  // sets the yield. base 1 herb plus one bonus herb per successful to-hit
  // roll, so yield runs 1-5 and approaches 5 as herbalism outgrows the
  // herb's defence
  int rollHerbYield({
    required int herbalismStat,
    required int defence,
    int bonusRolls = herbBonusRolls,
    Random? rng,
  }) {
    final r = rng ?? Random();
    final bonusChance = chanceToHit(herbalismStat, defence);

    int gathered = 1;
    for (int i = 0; i < bonusRolls; i++) {
      if (r.nextDouble() <= bonusChance) gathered++;
    }
    return gathered;
  }

  bool encounterConditionsMet(
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    if (playerState.hitpoints <= 0) return false;
    if (encounterState.entity == null) return false;
    if (encounterState.entity!.count <= 0) return false;
    if (!encounterState.isActive) return false;

    return true;
  }
}
