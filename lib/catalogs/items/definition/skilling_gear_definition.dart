import 'package:rpg/catalogs/items/definition/equipment_item_definition.dart';
import 'package:rpg/catalogs/items/definition/equipment_material.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';

// ignore_for_file: constant_identifier_names

/// The five rungs of skilling gear. Each one is a rung of the stat ladder —
/// a budget of 2, 3, 5, 8 and 13 before the tier's rarity scales it and
/// adds its secondary rolls — and the level in that skill it takes to wear.
enum SkillingGearTier {
  BASIC(fibLevel: 1, skillLevelRequirement: 1, rarity: Rarity.COMMON),
  NOVICE(fibLevel: 2, skillLevelRequirement: 20, rarity: Rarity.UNCOMMON),
  APPRENTICE(fibLevel: 3, skillLevelRequirement: 40, rarity: Rarity.RARE),
  ADVANCED(fibLevel: 4, skillLevelRequirement: 60, rarity: Rarity.EPIC),
  MASTER(fibLevel: 5, skillLevelRequirement: 80, rarity: Rarity.LEGENDARY);

  final int fibLevel;
  final int skillLevelRequirement;

  /// The tier's rarity: it frames the piece, scales its skill stat and
  /// sets how many core-stat secondaries it rolls, as for any gear.
  final Rarity rarity;

  const SkillingGearTier({
    required this.fibLevel,
    required this.skillLevelRequirement,
    required this.rarity,
  });
}

/// A piece of a gathering or crafting skill's set: worn for that one skill,
/// and gated by it. It is made of nothing, so where a plate piece takes its
/// rung, split and requirement from its metal, this takes all three from
/// its [skill] and [tier].
class SkillingGearDefinition extends EquipmentItemDefinition {
  final SkillId skill;
  final SkillingGearTier tier;

  const SkillingGearDefinition({
    required super.name,
    required super.value,
    required ArmorSlots super.armorSlot,
    required this.skill,
    required this.tier,
    super.description,
    super.iconAsset,
    super.quality,
  });

  /// The tier's rung whatever the slot: a hat is worth what a tunic is.
  @override
  int get fibLevel => tier.fibLevel;

  /// The tier's rarity is the piece's, and it pays out like any other
  /// gear's: it scales the skill stat and rolls the core-stat secondaries.
  @override
  Rarity? get fixedRarity => tier.rarity;

  @override
  Map<SkillId, int> get statWeights => {skill: 1};

  @override
  SkillId get skillRequirement => skill;

  @override
  int get skillLevelRequirement => tier.skillLevelRequirement;

  @override
  SkillingGearDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    ArmorSlots? armorSlot,
    EquipmentMaterialId? materialId,
    int? fibLevel,
    Map<SkillId, int>? statWeights,
    SkillId? skill,
    SkillingGearTier? tier,
  }) {
    return SkillingGearDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      armorSlot: armorSlot ?? this.armorSlot,
      skill: skill ?? this.skill,
      tier: tier ?? this.tier,
    );
  }
}
