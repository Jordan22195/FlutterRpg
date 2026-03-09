import 'dart:math';
import 'package:flutter/widgets.dart';

enum SkillId {
  STAMINA, // each point increaes stamina bar by 10.
  // each point of stam spent is 1xp
  SPEED, // each point increases max speed (reduces min action interval) by a percent
  // actions done at near top speed give xp
  ECONOMY, //increases speed threasold where stamina drain starts
  //actions done near threshold give xp
  // COMBAT
  EXPLORATION,
  HITPOINTS, // health - entity
  ATTACK, // melee attack - entity accuracy and damage
  RANGED, // ranged attack - not sure how this will be used yet
  MAGIC, // magic attack - not sure how this will be used yet
  DEFENCE, // damage reduction - entity
  // GATHERING
  WOODCUTTING, // cut down trees for logs - entity encounter
  MINING, // mine for ore and gems - entity encounter
  FISHING, // catch fish for cooking - entity encounter
  FORAGING, // gather herbs for alchemy - entity encounter - higher level let you find more stuff while exploring
  // Crafting
  FIREMAKING, // build fires for buffs and cooking - crafting without location
  LEATHERWORKING, // make leather armor for ranging - crafting at leatherworking station
  BLACKSMITHING, // make metal armor and weapons for melee - crafting at blacksmith station
  TAILORING, // make cloth armor for magic - crafting at loom
  ENCHANTING, // enhance gear - crafting at enchanting station with gear and enchantment materials
  JEWELCRAFTING, // make jeweley items - crafting at jeweling station with gems and metal bars
  FLETCHING, // make ranged weapons and staves - crafting at fletching station with logs
  COOKING, // cook food for healing and buffs - crafting at fire
  ALCHEMY, // make potions for buffs and healing - crafting at alchemy station with herbs and water
  NULL,
}

class SkillData {
  final String name;
  double xp;

  final List<double> xpTable = SkillData._buildXpTable(99);

  SkillData({required this.name, required this.xp});

  static List<double> _buildXpTable(int maxLevel) {
    final table = List<double>.filled(maxLevel + 1, 0);
    double points = 0;

    for (int level = 1; level <= maxLevel; level++) {
      table[level] = points;
      points += ((level + 300 * pow(2, level / 7)) / 4).floor();
    }

    return table;
  }
}

class SkillController extends ChangeNotifier {
  static ImageProvider? imageProviderFor(dynamic objectId) {
    {
      if (objectId is! SkillId) {
        throw ArgumentError('Expected Skills, got ${objectId.runtimeType}');
      }
      switch (objectId) {
        case SkillId.ECONOMY:
          return AssetImage('assets/icons/skills/economy.png');
        case SkillId.SPEED:
          return AssetImage('assets/icons/skills/speed.png');
        case SkillId.STAMINA:
          return AssetImage('assets/icons/skills/stamina.png');
        case SkillId.ATTACK:
          return AssetImage('assets/icons/skills/attack.png');
        case SkillId.DEFENCE:
          return AssetImage('assets/icons/skills/defence.png');
        case SkillId.HITPOINTS:
          return AssetImage('assets/icons/skills/hp.png');
        case SkillId.RANGED:
          return AssetImage('assets/icons/skills/ranged.png');
        case SkillId.MAGIC:
          return AssetImage('assets/icons/skills/magic.png');
        case SkillId.WOODCUTTING:
          return AssetImage('assets/icons/skills/woodcutting.png');
        case SkillId.FIREMAKING:
          return AssetImage('assets/icons/skills/firemaking.png');
        case SkillId.MINING:
          return AssetImage('assets/icons/skills/mining.png');
        case SkillId.LEATHERWORKING:
          return AssetImage('assets/icons/skills/leatherworking.png');
        case SkillId.BLACKSMITHING:
          return AssetImage('assets/icons/skills/blacksmithing.png');
        case SkillId.TAILORING:
          return AssetImage('assets/icons/skills/tailoring.png');
        case SkillId.ENCHANTING:
          return AssetImage('assets/icons/skills/enchanting.png');
        case SkillId.JEWELCRAFTING:
          return AssetImage('assets/icons/skills/jewelcrafting.png');
        case SkillId.FLETCHING:
          return AssetImage('assets/icons/skills/fletching.png');
        case SkillId.FISHING:
          return AssetImage('assets/icons/skills/fishing.png');
        case SkillId.COOKING:
          return AssetImage('assets/icons/skills/cooking.png');
        case SkillId.NULL:
          return null;
        default:
          return null;
      }
    }
  }
}
