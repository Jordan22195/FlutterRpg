import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/inventory.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/skill.dart';
import '../data/zone.dart';

class EncounterController extends ChangeNotifier {
  EncounterController._internal();
  static final EncounterController instance = EncounterController._internal();
  EncounterController() {}
  late PlayerDataController playerDataController;
  int lastPlayerDamage = 0;
  bool isActive = false;
  Entities activeEntityId = Entities.NULL;
  Inventory encounterItemDrops = Inventory(itemMap: {});
  Entity _entity = Entity(
    id: Entities.NULL,
    name: "null",
    entityType: Skills.ATTACK,
    defence: 0,
    hitpoints: 1,
  );

  Entity getEntity() {
    return _entity;
  }

  double getHealtPercent() {
    if (getEntity().maxHitPoints <= 0) return 0.0;
    return (getEntity().hitpoints / getEntity().maxHitPoints).clamp(0.0, 1.0);
  }

  Skills getEncounterSkillType() {
    return _entity.entityType;
  }

  void endEcnounter() {
    isActive = false;
    playerDataController.actionTimingController.stopNow();
  }

  void initEncounter(Entities id) {
    activeEntityId = id;
    _entity = EntityController.buildEntity(id);

    encounterItemDrops.clear();
    isActive = false;
    print("init encounter with ${_entity.name}");
    notifyListeners();
  }

  int getEntityCount() {
    if (getEncounterSkillType() == Skills.FISHING) {
      return 1;
    }
    return playerDataController.getEntityCount(
      playerDataController.data?.currentZoneId ?? Zones.NULL,
      activeEntityId,
    );
  }

  void startEncounter(Entities id) {
    if (getEntityCount() <= 0) {
      print("error - no entities of this type to encounter");
      return;
    }
    isActive = true;
  }

  void endEncounter() {
    isActive = false;
    activeEntityId = Entities.NULL;
    encounterItemDrops.clear();
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

  // For reporting / tooltips:
  double averageDamageFromMaxHit(int maxHit) => (maxHit + 1) / 2.0;

  int resolveAttack({
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
      print('Overkill! Damage: $damage | HP: $defenderHp → 0');
    }

    final newHp = max(0, defenderHp - damage);

    print('Hit! Damage: $damage | HP: $defenderHp → $newHp');
    return damage;
  }

  void doFishingAction() {
    int playerSkillStatTotal = playerDataController.getPlayerSkillStatTotal(
      Skills.FISHING,
    );

    int encounterDefence = _entity.defence;
    int dmg = resolveAttack(
      attackerAttack: playerSkillStatTotal,
      defenderDefense: encounterDefence,
      defenderHp: _entity.hitpoints,
    );
    lastPlayerDamage = dmg;

    if (dmg == 0) {
      print("no fish caught");
      return;
    }

    final fishDrop = rollLoot();
    print(fishDrop.id);
    final def = ItemController.definitionFor(fishDrop.id);
    print("caught ${def?.name} x${fishDrop.count} worth ${def?.xpValue} xp");
    applyExp(def?.xpValue ?? 0);
    playerDataController.refresh();
  }

  void doPlayerEncounterAction() {
    if (isActive == false) {
      startEncounter(activeEntityId);
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

    int playerSkillStatTotal = playerDataController.getPlayerSkillStatTotal(
      skillType,
    );

    int encounterDefence = _entity.defence;
    int dmg = resolveAttack(
      attackerAttack: playerSkillStatTotal,
      defenderDefense: encounterDefence,
      defenderHp: _entity.hitpoints,
    );
    lastPlayerDamage = dmg;
    _entity.hitpoints -= dmg;

    applyExp(dmg);
    if (isDead()) {
      print("entity died");
      rollLoot();

      playerDataController.decrimentEntity(
        playerDataController.data?.currentZoneId ?? Zones.NULL,
        activeEntityId,
      );
      if (getEntityCount() > 0) {
        _entity.hitpoints = _entity.maxHitPoints;
      } else {
        endEcnounter();
      }
    }
    notifyListeners();
    playerDataController.saveAppData();
  }

  bool isCombatEntity() {
    final e = _entity;
    print("${e.id} is combt entity : ${e is CombatEntity}");

    return (e is CombatEntity); // non-combat entities don't attack
  }

  void applyExp(int damage) {
    final skillType = getEncounterSkillType();
    int xp = damage * 2;
    print("xp $skillType $xp");
    SkillController.instance.getSkill(skillType).addXp(xp);
    if (skillType == Skills.ATTACK) {
      SkillController.instance.getSkill(Skills.HITPOINTS).addXp(xp);
    }
  }

  void entityAttack() {
    int attack = 0;
    if (isCombatEntity()) {
      attack = (_entity as CombatEntity).attack;
    }
    int damageDone = resolveAttack(
      attackerAttack: attack,
      defenderDefense: playerDataController.getPlayerSkillStatTotal(
        Skills.DEFENCE,
      ),
      defenderHp: playerDataController.data?.hitpoints ?? 0,
    );
  }

  bool isDead() {
    return _entity.hitpoints <= 0;
  }

  ObjectStack<dynamic> rollLoot() {
    final items = EntityController.entityDropTableRoll(activeEntityId);
    print(items);
    encounterItemDrops.addItems(items.id, items.count);
    print(encounterItemDrops.getObjectStackList()[0].count);
    return items;
  }
}
