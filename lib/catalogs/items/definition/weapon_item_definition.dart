import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/combat_tuning.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/weapon_item.dart';
import 'package:rpg/catalogs/items/definition/equipment_item_definition.dart';
import 'package:rpg/catalogs/items/definition/equipment_material.dart';
import 'package:rpg/catalogs/items/definition/weapon_type.dart';

/// A weapon or a tool: the one piece of gear defined by two things at once.
/// [materialId] sets the rung it starts from and [weaponType] sets what the
/// shape is worth over that rung, what it swings at, and how fast — so a
/// copper sword is the pair, and neither half is written out by hand.
class WeaponItemDefinition extends EquipmentItemDefinition {
  final WeaponTypeId weaponType;

  /// Set only by a weapon that swings at a speed its type does not, and read
  /// through [actionInterval].
  final Duration? _actionInterval;

  /// How long one swing takes. Its type's, unless the definition overrode it.
  Duration get actionInterval =>
      _actionInterval ?? weaponType.parameters.actionInterval;

  /// A weapon is held where its shape is held — there is no such thing as a
  /// greatsword worn on the head.
  @override
  ArmorSlots get defaultSlot => weaponType.parameters.slot;

  /// A weapon splits by what it is, not what it is made of: copper is a
  /// defensive metal, and a copper sword is still an attacking weapon.
  @override
  Map<SkillId, int> get defaultStatWeights => weaponType.parameters.statWeight;

  /// Wielded with the skill its shape is wielded with — the level it asks
  /// for is still the metal's, which is why only the skill moves here.
  @override
  SkillId get skillRequirement => weaponType.parameters.skillRequirement;

  @override
  int get fibOffset => super.fibOffset + weaponType.parameters.fibOffset;

  /// Whether a swing of this weapon deals [damageAt]. Off for the sickle and
  /// the rod, which roll a skill rather than hit a pool.
  bool get usesDamage => weaponType.parameters.usesDamage;

  /// The rung this weapon is made from: its own rung less what its shape
  /// adds over the metal. A copper greatsword is copper, whatever its shape
  /// is worth on the stat ladder.
  int get materialRung => fibLevel - weaponType.parameters.fibOffset;

  /// What one swing deals before the attack multiplier, at [rarity]: the
  /// rung's damage per second times how long the swing takes, so a slower
  /// shape hits harder by exactly what it gives up in speed. A tool carries
  /// its type's share of it; a better roll scales it the way it scales any
  /// piece's stats.
  double damageAt(Rarity rarity) {
    if (!usesDamage) return 0;
    final seconds = actionInterval.inMicroseconds / 1e6;
    return weaponDamageForRung(materialRung) *
        seconds *
        weaponType.parameters.damageScale *
        rarity.statMultiplier;
  }

  /// See [WeaponEquipmentParameters.speedAffinity].
  double get speedAffinity => weaponType.parameters.speedAffinity;

  /// See [WeaponEquipmentParameters.strengthAffinity].
  double get strengthAffinity => weaponType.parameters.strengthAffinity;

  const WeaponItemDefinition({
    required super.name,
    required super.value,
    required this.weaponType,
    Duration? actionInterval,
    super.armorSlot,
    super.materialId,
    super.fibLevel,
    super.statWeights,
    super.description,
    super.iconAsset,
    super.quality,
  }) : _actionInterval = actionInterval;

  @override
  WeaponItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    ArmorSlots? armorSlot,
    EquipmentMaterialId? materialId,
    WeaponTypeId? weaponType,
    int? fibLevel,
    Map<SkillId, int>? statWeights,
    Duration? actionInterval,
  }) {
    return WeaponItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      armorSlot: armorSlot ?? this.armorSlot,
      materialId: materialId ?? this.materialId,
      weaponType: weaponType ?? this.weaponType,
      fibLevel: fibLevel ?? this.fibLevel,
      statWeights: statWeights ?? this.statWeights,
      actionInterval: actionInterval ?? _actionInterval,
    );
  }

  @override
  WeaponItem toItem(ItemId id) => WeaponItem(id: id);
}
