// ignore_for_file: constant_identifier_names

import 'package:rpg/data/skill_data.dart';

enum EquipmentMaterialId {
  NULL(MetalEquipmentParameters(fibLevel: 0, skillLevelRequirement: 0)),
  COPPER(MetalEquipmentParameters(fibLevel: 0, skillLevelRequirement: 1)),
  IRON(MetalEquipmentParameters(fibLevel: 1, skillLevelRequirement: 20)),
  STEEL(MetalEquipmentParameters(fibLevel: 2, skillLevelRequirement: 40)),
  MITHRIL(MetalEquipmentParameters(fibLevel: 3, skillLevelRequirement: 60)),
  ADAMANT(MetalEquipmentParameters(fibLevel: 4, skillLevelRequirement: 70)),
  RUNE(MetalEquipmentParameters(fibLevel: 5, skillLevelRequirement: 80)),
  DRAGON(MetalEquipmentParameters(fibLevel: 6, skillLevelRequirement: 90)),

  // The hides. A hide splits its rung between attack and defence, so it has
  // to sit a rung above the plate it wants to match on defence — which is
  // why the ladder starts at 1 where copper starts at 0, and why the level
  // each tier asks for is the one the plate a rung below it asks for. The
  // top two run past the end of the metal ladder, so they run up to the cap.
  LIGHT_LEATHER(
    LeatherEquipmentParameters(fibLevel: 1, skillLevelRequirement: 1),
  ),
  MEDIUM_LEATHER(
    LeatherEquipmentParameters(fibLevel: 2, skillLevelRequirement: 20),
  ),
  HEAVY_LEATHER(
    LeatherEquipmentParameters(fibLevel: 3, skillLevelRequirement: 40),
  ),
  LIGHT_DRAGONHIDE(
    LeatherEquipmentParameters(fibLevel: 4, skillLevelRequirement: 60),
  ),
  MEDIUM_DRAGONHIDE(
    LeatherEquipmentParameters(fibLevel: 5, skillLevelRequirement: 70),
  ),
  HEAVY_DRAGONHIDE(
    LeatherEquipmentParameters(fibLevel: 6, skillLevelRequirement: 80),
  ),
  LIGHT_DEMONHIDE(
    LeatherEquipmentParameters(fibLevel: 7, skillLevelRequirement: 90),
  ),
  MEDIUM_DEMONHIDE(
    LeatherEquipmentParameters(fibLevel: 8, skillLevelRequirement: 95),
  ),
  HEAVY_DEMONHIDE(
    LeatherEquipmentParameters(fibLevel: 9, skillLevelRequirement: 99),
  );

  // Added example values for iron

  // 1. The enum must declare a final variable to hold the data
  final EquipmentParameters parameters;

  // 2. The enum must have a const constructor to receive the data
  const EquipmentMaterialId(this.parameters);
}

class EquipmentParameters {
  final int fibLevel;
  final int skillLevelRequirement;
  final SkillId skillRequirement;
  final Map<SkillId, int> statWeight;

  const EquipmentParameters({
    required this.fibLevel,
    required this.skillRequirement,
    required this.skillLevelRequirement,
    required this.statWeight,
  });
}

class MetalEquipmentParameters extends EquipmentParameters {
  const MetalEquipmentParameters({
    required super.fibLevel,
    super.skillRequirement = SkillId.DEFENCE,

    required super.skillLevelRequirement,
    super.statWeight = const {SkillId.DEFENCE: 1},
  });
}

class LeatherEquipmentParameters extends EquipmentParameters {
  const LeatherEquipmentParameters({
    required super.fibLevel,
    super.skillRequirement = SkillId.DEFENCE,
    required super.skillLevelRequirement,
    super.statWeight = const {SkillId.ATTACK: 1, SkillId.DEFENCE: 1},
  });
}
