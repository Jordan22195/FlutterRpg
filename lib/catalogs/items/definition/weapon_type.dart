// ignore_for_file: constant_identifier_names

import 'package:rpg/catalogs/items/attack_speed.dart';
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
  // combat. The spread is the trade the player is making: a dagger swings
  // three times in the time a greatsword swings once, so it is worth two
  // rungs less to land on the same damage over a fight.
  DAGGER(
    WeaponEquipmentParameters(
      slot: ArmorSlots.WEAPON_1H,
      fibOffset: 0,
      actionInterval: FastAttackSpeed,
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
    ),
  ),

  // gathering tools. A tool pours its rung into the skill it is for rather
  // than into attack, which is the whole of what makes it a tool.
  AXE(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.WOODCUTTING,
      statWeight: {SkillId.WOODCUTTING: 1},
    ),
  ),
  PICKAXE(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.MINING,
      statWeight: {SkillId.MINING: 1},
    ),
  ),
  SICKLE(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 1,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.HERBALISM,
      statWeight: {SkillId.HERBALISM: 1},
    ),
  ),
  FISHING_ROD(
    WeaponEquipmentParameters(
      slot: ArmorSlots.TOOL,
      fibOffset: 0,
      actionInterval: MediumAttackSpeed,
      skillRequirement: SkillId.FISHING,
      statWeight: {SkillId.FISHING: 1},
    ),
  ),

  // one-offs. A boss unique is the only thing of its shape in the game, so
  // its type carries what would otherwise be written on the item.
  PITCHFORK(
    WeaponEquipmentParameters(
      slot: ArmorSlots.WEAPON_2H,
      fibOffset: 2,
      actionInterval: SlowAttackSpeed,
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

  /// What the weapon pours its budget into. Attack for anything that fights;
  /// a tool names the skill it speeds up instead.
  final Map<SkillId, int> statWeight;

  const WeaponEquipmentParameters({
    required this.slot,
    required this.fibOffset,
    required this.actionInterval,
    this.skillRequirement = SkillId.ATTACK,
    this.statWeight = const {SkillId.ATTACK: 1},
  });
}
