// ignore_for_file: constant_identifier_names

import 'package:rpg/catalogs/items/attack_speed.dart';
import 'package:rpg/data/combat_tuning.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';

/// What a weapon *is*, as opposed to what it is made of.
///
/// A material says which rung of the ladder a piece starts from; the type
/// says how far above that rung this shape of weapon sits, what it swings
/// at, and how fast. The two are independent — every metal comes as a
/// dagger, a sword and a greatsword — so they are named separately and a
/// weapon is the pair of them.
enum WeaponTypeId {
  // combat. A swing's damage scales with how long it takes, so every shape
  // of the same metal lands the same damage per second at rest. What sets
  // them apart is which stance boost they take best: a dagger turns speed
  // into the most extra swings, a greatsword turns strength into the most
  // extra damage, and a sword — with a shield beside it — sits between.
  DAGGER(
    WeaponEquipmentParameters(
      slot: ArmorSlots.WEAPON_1H,
      fibOffset: 0,
      actionInterval: FastAttackSpeed,
      speedAffinity: 1.0,
      strengthAffinity: 0.5,
    ),
  ),
  SWORD(
    WeaponEquipmentParameters(
      slot: ArmorSlots.WEAPON_1H,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
    ),
  ),
  GREATSWORD(
    WeaponEquipmentParameters(
      slot: ArmorSlots.WEAPON_2H,
      fibOffset: 2,
      actionInterval: SlowAttackSpeed,
      speedAffinity: 0.5,
      strengthAffinity: 1.0,
    ),
  ),

  // gathering tools. An axe and a pickaxe swing at a node the way a weapon
  // swings at a monster, so they carry damage (a share of a weapon's — see
  // toolDamageScale) and the skill they are for is the multiplier. A sickle
  // and a rod do not hit anything: they still pour their rung into the
  // skill, which is what the herb and fishing rolls read.
  AXE(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.WOODCUTTING,
      damageScale: toolDamageScale,
    ),
  ),
  PICKAXE(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.MINING,
      damageScale: toolDamageScale,
    ),
  ),
  SICKLE(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.HERBALISM,
      statWeight: {SkillId.HERBALISM: 1},
      usesDamage: false,
    ),
  ),
  FISHING_ROD(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 0,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.FISHING,
      statWeight: {SkillId.FISHING: 1},
      usesDamage: false,
    ),
  ),

  // one-offs. A boss unique is the only thing of its shape in the game, so
  // its type carries what would otherwise be written on the item.
  PITCHFORK(
    WeaponEquipmentParameters(
      slot: ArmorSlots.WEAPON_2H,
      fibOffset: 2,
      actionInterval: SlowAttackSpeed,
      speedAffinity: 0.5,
      strengthAffinity: 1.0,
    ),
  ),
  SCEPTER(
    WeaponEquipmentParameters(
      slot: ArmorSlots.WEAPON_1H,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
      statWeight: {SkillId.ATTACK: 12, SkillId.DEFENCE: 4},
    ),
  );

  final WeaponEquipmentParameters parameters;

  const WeaponTypeId(this.parameters);
}

/// The half of a weapon that comes from its shape rather than its material.
///
/// It carries the same [SkillId] and split an [EquipmentParameters] does,
/// but deliberately is not one: a material states the rung a piece starts on
/// and the level it demands, where a type states how far *over* that rung its
/// shape sits — so the two are added rather than chosen between, and the
/// level stays the metal's business.
class WeaponEquipmentParameters {
  /// Where the weapon is held. A dagger and a sword share [
  /// ArmorSlots.WEAPON_1H] and differ in everything else, which is why the
  /// slot cannot be what sets a weapon's rung.
  final ArmorSlots slot;

  /// Rungs over the material, the same currency [ArmorSlots.fibOffset] is
  /// in — a slower, heavier shape of the same metal is worth more.
  final int fibOffset;

  /// How long one swing takes.
  final Duration actionInterval;

  /// The skill the shape is wielded with, which is the shape's business
  /// rather than the metal's: a copper sword asks for attack where a copper
  /// helmet asks for defence, and an axe asks for the skill it chops with.
  /// The *level* it asks for stays the material's.
  final SkillId skillRequirement;

  /// Stats the weapon adds on top of its damage. Nothing, for anything that
  /// swings — its damage is the whole of what it is, and Attack is the
  /// multiplier on it. A sickle or a rod, which do not hit, pour their rung
  /// into their skill instead; a unique may carry a rider.
  final Map<SkillId, int> statWeight;

  /// Whether a swing of this shape deals [WeaponItemDefinition.damage]. Off
  /// for the tools whose rolls read a skill rather than hit a pool.
  final bool usesDamage;

  /// The share of a weapon's damage on the same rung this shape carries:
  /// 1 for anything that fights, [toolDamageScale] for a gathering tool.
  final double damageScale;

  /// How much of the fast stance's boost this shape turns into extra swings,
  /// 0..1. A dagger takes it all; a greatsword half.
  final double speedAffinity;

  /// How much of a strength stance's boost this shape turns into extra
  /// damage, 0..1. A greatsword takes it all; a dagger half.
  final double strengthAffinity;

  const WeaponEquipmentParameters({
    required this.slot,
    required this.fibOffset,
    required this.actionInterval,
    this.skillRequirement = SkillId.ATTACK,
    this.statWeight = const {},
    this.usesDamage = true,
    this.damageScale = 1.0,
    this.speedAffinity = 0.75,
    this.strengthAffinity = 0.75,
  });
}
