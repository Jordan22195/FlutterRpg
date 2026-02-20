import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/inventory.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/skill.dart';
import '../data/zone.dart';

class EntityEncounter {
  EntityEncounter({required this.entityId})
    : entity = EntityController.buildEntity(entityId) {
    init();
  }

  final Entities entityId;
  Inventory itemDrops = Inventory(itemMap: {});
  int lastPlayerDamage = 0;
  bool isActive = false;
  bool respawning = false;
  Entity entity;
  late PlayerDataController playerController;
  late EncounterController encounterController;

  void init() {
    playerController = PlayerDataController.instance;
    encounterController = EncounterController.instance;
  }

  double getHealthPercent() {
    if (entity.maxHitPoints <= 0) return 0.0;
    return (entity.hitpoints / entity.maxHitPoints).clamp(0.0, 1.0);
  }

  Skills getEncounterSkillType() {
    return entity.entityType;
  }

  void endEcnounter() {
    isActive = false;
    playerController.actionTimingController.stopNow();
    playerController.refresh();
  }

  int getEntityCount() {
    if (getEncounterSkillType() == Skills.FISHING) {
      return 1;
    }
    return playerController.getEntityCount(
      playerController.data?.currentZoneId ?? Zones.NULL,
      entityId,
    );
  }

  void startEncounter(Entities id) {
    if (getEntityCount() <= 0) {
      print("error - no entities of this type to encounter");
      return;
    }
    isActive = true;
  }

  bool isDead() {
    return entity.hitpoints <= 0;
  }

  void endEncounter() {
    isActive = false;
    itemDrops.clear();
  }

  void doFishingAction() {
    int playerSkillStatTotal = playerController.getStatTotal(Skills.FISHING);

    int encounterDefence = entity.defence;
    int dmg = encounterController.calculateAttackDamage(
      attackerAttack: playerSkillStatTotal,
      defenderDefense: encounterDefence,
      defenderHp: entity.hitpoints,
    );

    if (dmg == 0) {
      print("no fish caught");
      return;
    }

    final fishDrop = rollLoot();
    final def = ItemController.definitionFor(fishDrop.id);
    applyExp(def?.xpValue ?? 0);
    playerController.refresh();
  }

  Future<void> _handleRespawn() async {
    respawning = true;
    playerController.refresh();

    await Future.delayed(const Duration(milliseconds: 200));

    entity.hitpoints = entity.maxHitPoints;

    respawning = false;
    playerController.refresh();
  }

  void doPlayerEncounterAction() {
    if (isActive == false) {
      startEncounter(entityId);
    }
    if (isActive == false) {
      print(
        "error - tried to do encounter action while encounter is not active",
      );
      return;
    }

    final skillType = getEncounterSkillType();

    if (skillType == Skills.FISHING) {
      doFishingAction();
      return;
    }

    int playerSkillStatTotal = playerController.getStatTotal(skillType);

    int encounterDefence = entity.defence;
    int dmg = encounterController.calculateAttackDamage(
      attackerAttack: playerSkillStatTotal,
      defenderDefense: encounterDefence,
      defenderHp: entity.hitpoints,
    );
    lastPlayerDamage = dmg;
    entity.hitpoints -= dmg;

    applyExp(dmg);
    if (isDead()) {
      rollLoot();

      playerController.decrimentEntity(
        playerController.data?.currentZoneId ?? Zones.NULL,
        entityId,
      );
      //respawn with full hp if there are more of this entity to encounter, otherwise end encounter
      if (getEntityCount() > 0) {
        _handleRespawn();
      } else {
        endEcnounter();
      }
    }
    playerController.refresh();
  }

  bool isCombatEntity() {
    return (entity is CombatEntity);
  } // non-combat entities don't attack

  void applyExp(int damage) {
    final skillType = getEncounterSkillType();
    int xp = damage * 2;
    SkillController.instance.getSkill(skillType).addXp(xp);
    if (skillType == Skills.ATTACK) {
      SkillController.instance.getSkill(Skills.HITPOINTS).addXp(xp);
    }
  }

  ObjectStack<dynamic> rollLoot() {
    final items = EntityController.entityDropTableRoll(entityId);
    print(items);
    itemDrops.addItems(items.id, items.count);
    PlayerDataController.instance.addItemToInventory(items);
    print(itemDrops.getObjectStackList()[0].count);
    return items;
  }

  void entityAttack() {
    int attack = 0;
    if (isCombatEntity()) {
      attack = (entity as CombatEntity).attack;
    }
    int damageDone = encounterController.calculateAttackDamage(
      attackerAttack: attack,
      defenderDefense: playerController.getStatTotal(Skills.DEFENCE),
      defenderHp: playerController.data?.hitpoints ?? 0,
    );
    playerController.data?.hitpoints = max(
      0,
      (playerController.data?.hitpoints ?? 0) - damageDone,
    );
  }
}

class EncounterController {
  EncounterController._internal();
  static final EncounterController instance = EncounterController._internal();
  EncounterController() {}
  Items equipedPickaxe = Items.NULL;
  Items equipedAxe = Items.NULL;
  Items equipedFood = Items.NULL;
  late PlayerDataController playerController;

  void init() {
    playerController = PlayerDataController.instance;
  }

  int getEquipedPickaxeBonus() {
    if (equipedPickaxe == Items.NULL) return 0;
    return (ItemController.definitionFor(equipedPickaxe) as WeaponItemDefition)
            .skillBonus[Skills.MINING] ??
        0;
  }

  int getEquipedAxeBonus() {
    if (equipedAxe == Items.NULL) return 0;
    return (ItemController.definitionFor(equipedAxe) as WeaponItemDefition)
            .skillBonus[Skills.WOODCUTTING] ??
        0;
  }

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

  void eatSingleEquipedFood() {
    if (equipedFood == Items.NULL ||
        playerController.data?.inventory.countOf(equipedFood) == 0) {
      print("no food equiped");
      return;
    }
    final def = ItemController.definitionFor(equipedFood) as FoodItemDefinition;
    final healAmount = def.restoreAmount;
    playerController.data?.hitpoints = min(
      playerController.getStatTotal(Skills.HITPOINTS),
      (playerController.data?.hitpoints ?? 0) + healAmount,
    );
    PlayerDataController.instance.data?.inventory.removeItems(equipedFood, 1);
    if (PlayerDataController.instance.data?.inventory.countOf(equipedFood) ==
        0) {
      equipedFood = Items.NULL;
    }
    playerController.refresh();
  }
}
