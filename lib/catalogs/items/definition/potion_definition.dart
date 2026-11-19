import 'package:rpg/catalogs/items/definition/buff_item_definition.dart';
import 'package:rpg/catalogs/items/definition/item_definition.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/skill_data.dart';

// ignore_for_file: constant_identifier_names

/// Alchemy's potion ladder. See design/ALCHEMY_POTIONS.md.
///
/// Every potion is one herb and one reagent. The tier names the herbs (a
/// core herb and a combat herb, each one zone's own) and the grade of
/// reagent it takes; the potion's skill names which herb and which reagent
/// family ([potionSlots]). So the 60 recipes are derived, not written.
enum PotionTier {
  MINOR(prefix: 'Minor', bonus: 5, levels: (1, 10), xp: (15, 50)),
  REGULAR(prefix: '', bonus: 8, levels: (15, 24), xp: (70, 100)),
  SUPER(prefix: 'Super', bonus: 13, levels: (25, 34), xp: (125, 165)),
  GREATER(prefix: 'Greater', bonus: 21, levels: (35, 50), xp: (200, 250)),
  GRAND(prefix: 'Grand', bonus: 34, levels: (55, 80), xp: (320, 400)),
  SUPREME(prefix: 'Supreme', bonus: 55, levels: (89, 99), xp: (520, 640));

  /// The word in front of the potion's name; empty for the plain tier.
  final String prefix;

  /// What a potion of this tier adds to its skill.
  final int bonus;

  /// The Alchemy level the tier's first and last potion ask for. The ten
  /// potions are spread evenly between them, one level each (or near it),
  /// in [PotionSlot.order].
  final (int, int) levels;

  /// The xp the tier's first and last potion pay, spread the same way.
  final (int, int) xp;

  static int _spread((int, int) range, int order) =>
      range.$1 +
      ((range.$2 - range.$1) * order / (potionSlots.length - 1)).round();

  /// The Alchemy level the potion at [order] in the tier asks for.
  int levelAt(int order) => _spread(levels, order);

  /// The xp one brew of the potion at [order] pays.
  int xpAt(int order) => _spread(xp, order);

  const PotionTier({
    required this.prefix,
    required this.bonus,
    required this.levels,
    required this.xp,
  });

  /// The herb the core-stat potions (and Exploration) brew from.
  ItemId get coreHerb => switch (this) {
    MINOR => ItemId.MEADOWSWEET,
    REGULAR => ItemId.REEDMINT,
    SUPER => ItemId.SILT_LILY,
    GREATER => ItemId.SALTWORT,
    GRAND => ItemId.GLIMMERCAP,
    SUPREME => ItemId.FROSTBLOOM,
  };

  /// The herb the combat and gathering potions brew from.
  ItemId get combatHerb => switch (this) {
    MINOR => ItemId.BRAMBLEWORT,
    REGULAR => ItemId.DUSKTHORN,
    SUPER => ItemId.MIRECAP,
    GREATER => ItemId.BLUESTEM,
    GRAND => ItemId.BLOODROOT,
    SUPREME => ItemId.EMBERROOT,
  };

  /// The reagent grade the tier takes: tier n, grade n.
  ReagentGrade get grade => ReagentGrade.values[index];
}

/// A kind of creature, and so the kind of part it leaves behind. A monster's
/// archetype names its family; every monster on it drops that family's part
/// at the grade its level reaches (`CombatEntityDefinition.reagentDrop`).
enum ReagentFamily { FEATHER, FANG, HORN, SHELL, VENOM, ICHOR }

/// How big a part is: one per potion tier, read off the level of whatever
/// dropped it.
enum ReagentGrade {
  SMALL,
  STURDY,
  THICK,
  HEAVY,
  ANCIENT,
  PRIMAL;

  /// The grade a monster on Fibonacci [rung] drops: rungs 0–5 (levels up
  /// to 13) are Small, then one grade a rung up to Primal at 10 (144+).
  static ReagentGrade forRung(int rung) =>
      values[(rung - 5).clamp(0, values.length - 1)];

  /// The grade a non-combat source at [level] gives (a fishing water by its
  /// level requirement), on the same bands as [forRung]: below 21 Small,
  /// then 21 / 34 / 55 / 89 / 144.
  static ReagentGrade forLevel(int level) {
    const floors = [21, 34, 55, 89, 144];
    var grade = 0;
    for (final floor in floors) {
      if (level >= floor) grade++;
    }
    return values[grade];
  }
}

/// Which herb and which reagent family a potion of [SkillId] brews from, and
/// where it falls in the tier's staggered unlock order (0 first, 9 last).
typedef PotionSlot = ({bool coreHerb, ReagentFamily family, int order});

/// Every skill alchemy has a potion for: five on each herb. Each skill has
/// its own place in the unlock order, so a tier opens one potion at a time.
/// Each family
/// feeds two potions (Feather and Ichor one), so one monster's drop keeps
/// two buffs going.
const Map<SkillId, PotionSlot> potionSlots = {
  SkillId.SPEED: (coreHerb: true, family: ReagentFamily.FEATHER, order: 1),
  SkillId.STAMINA: (coreHerb: true, family: ReagentFamily.HORN, order: 4),
  SkillId.STRENGTH: (coreHerb: true, family: ReagentFamily.FANG, order: 6),
  SkillId.RECOVERY: (coreHerb: true, family: ReagentFamily.VENOM, order: 8),
  SkillId.EXPLORATION: (coreHerb: true, family: ReagentFamily.ICHOR, order: 9),
  SkillId.DEFENCE: (coreHerb: false, family: ReagentFamily.SHELL, order: 2),
  SkillId.WOODCUTTING: (coreHerb: false, family: ReagentFamily.FANG, order: 3),
  SkillId.FISHING: (coreHerb: false, family: ReagentFamily.SHELL, order: 0),
  SkillId.MINING: (coreHerb: false, family: ReagentFamily.HORN, order: 5),
  SkillId.HERBALISM: (coreHerb: false, family: ReagentFamily.VENOM, order: 7),
};

/// A potion on the ladder: +[PotionTier.bonus] to [skill] for three
/// minutes. The bonus is derived from the tier rather than written, so the
/// two cannot drift.
class PotionDefinition extends BuffItemDefinition {
  final PotionTier tier;
  final SkillId skill;

  const PotionDefinition({
    required super.name,
    required super.value,
    required this.tier,
    required this.skill,
    super.description,
    super.iconAsset,
    super.quality,
    super.duration = const Duration(minutes: 3),
  }) : super(skillBonus: const {});

  @override
  Map<SkillId, int> get skillBonus => {skill: tier.bonus};

  PotionSlot get slot => potionSlots[skill]!;

  /// The herb this potion brews from.
  ItemId get herb => slot.coreHerb ? tier.coreHerb : tier.combatHerb;

  /// The reagent this potion brews from.
  ItemId get reagent => reagentPart(slot.family, tier.grade);

  /// The Alchemy level the recipe asks for.
  int get levelRequirement => tier.levelAt(slot.order);

  /// The xp one brew pays.
  int get brewXp => tier.xpAt(slot.order);

  @override
  PotionDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    Map<SkillId, int>? skillBonus,
    Duration? duration,
  }) {
    return PotionDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      tier: tier,
      skill: skill,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      duration: duration ?? this.duration,
    );
  }
}

/// A creature-family part at a grade: what every potion's second half is.
class ReagentPartDefinition extends ItemDefinition {
  final ReagentFamily family;
  final ReagentGrade grade;

  const ReagentPartDefinition({
    required super.name,
    required super.value,
    required this.family,
    required this.grade,
    super.description,
    super.iconAsset,
  });

  @override
  ReagentPartDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
  }) {
    return ReagentPartDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      family: family,
      grade: grade,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
    );
  }
}

final Map<(ReagentFamily, ReagentGrade), ItemId> _parts = {
  for (final id in ItemId.values)
    if (id.definition case final ReagentPartDefinition def)
      (def.family, def.grade): id,
};

/// The item for [family]'s part at [grade].
ItemId reagentPart(ReagentFamily family, ReagentGrade grade) =>
    _parts[(family, grade)]!;
