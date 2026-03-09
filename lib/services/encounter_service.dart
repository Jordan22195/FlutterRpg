import 'dart:math';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import '../services/inventory_service.dart';
import '../data/encounter_data.dart';
import '../data/action_result.dart';

class EncounterService {
  // set respawn flag for ui for 200ms then reset entity hp
  Future<void> respawn(EncounterData encounterState) async {
    encounterState.respawning = true;

    await Future.delayed(const Duration(milliseconds: 200));
    final e = encounterState.entity!;
    e.hitpoints = e.maxHitPoints;

    encounterState.respawning = false;
  }

  ActionResult resolvePlayerDamage(
    Map<SkillId, int> playerStatTotals,
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    ActionResult res = ActionResult();

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
      print(
        'Miss! (rolled ${hitRoll.toStringAsFixed(2)} '
        'vs chance ${hitChance.toStringAsFixed(2)})',
      );
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

    encounterState.entity = entity;

    encounterState.isActive = true;
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

  // calculate enemy attack roll against player
  int entityAttack(
    EncounterData encounterState,
    Map<SkillId, int> playerStatTotals,
  ) {
    if (encounterState.entity is! CombatEntity) {
      return 0;
    }
    final e = encounterState.entity as CombatEntity;

    int damageDone = calculateAttackDamage(
      attackerAttack: e.attack,
      defenderDefense: playerStatTotals[SkillId.DEFENCE] ?? 1,
      defenderHp: playerStatTotals[SkillId.HITPOINTS] ?? 0,
    );
    return damageDone;
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

  ActionResult doFishingAction(
    Map<SkillId, int> playerStatTotals,
    PlayerData playerState,
    EncounterData encounterState,
  ) {
    int playerSkillStatTotal = playerStatTotals[SkillId.FISHING] ?? 1;
    final e = encounterState.entity;
    ActionResult r = ActionResult();
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
