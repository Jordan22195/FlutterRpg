import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/entities/combat_archetype.dart';
import 'package:rpg/catalogs/entities/combat_type.dart';
import 'package:rpg/catalogs/entities/model/combat_entity.dart';
import 'package:rpg/catalogs/entities/definition/encounter_entity_definition.dart';
import 'package:rpg/utilities/util.dart';
import 'package:rpg/catalogs/items/items.dart';

/// A thing that fights back. Its stats are never written by hand: [level]
/// sets the size of its stat budget and [combatType] splits that budget
/// across attack, defence and hitpoints, so every enemy sits on the same
/// curve and a level reads the same everywhere.
///
/// One definition is one monster. What every monster of its kind shares —
/// art, how it fights, the common loot — lives on its [CombatArchetype];
/// what makes this one its own (name, rung, loot of its own, the rarity
/// border it is drawn with) is written here.
///
/// [rarity] is cosmetic: it colors the border around the portrait and
/// nothing else. The level is [fibLevel] alone.
///
/// Drops default to the archetype's, scaled to how far above its
/// [CombatArchetype.lootFibLevel] this monster sits (see [itemDrops]), so a
/// monster only writes the loot that sets it apart.
class CombatEntityDefinition extends EncounterEntityDefinition {
  /// The kind of monster this is.
  final CombatArchetype archetype;

  /// Index into [Util.fibonacciCache]: the rung of the ladder this monster
  /// stands on. A level is always a rung — there is no way to write one
  /// between them, so every monster lines up with a gear tier.
  final int fibLevel;

  /// Seconds between swings, or null to swing at the archetype's pace.
  final double? ownAttackInterval;

  /// Set on the one monster that ends a dungeon floor, and on nothing else:
  /// a boss is its own entity, so a monster that is a boss in one place is
  /// never also a regular somewhere. The dungeon screen draws its tile apart.
  final bool isDungeonBoss;

  /// The main table as written here, or null to inherit the archetype's.
  /// Written, it replaces the inherited table outright.
  final List<ItemDropType>? ownItemDrops;

  /// Lines added to the main table, on top of whichever [itemDrops]
  /// resolves to — inherited or written. Never scaled: they are written at
  /// the counts and qualities this monster drops them at.
  final List<ItemDropType> extraItemDrops;

  /// The bonus rolls as written here, or null to inherit the archetype's.
  /// `const []` turns the inherited ones off.
  final List<DropRoll>? ownBonusDrops;

  /// Bonus rolls added to whichever [bonusDrops] resolves to.
  final List<DropRoll> extraBonusDrops;

  const CombatEntityDefinition(
    this.archetype, {
    required this.fibLevel,
    required super.name,
    super.rarity,
    double? attackInterval,
    List<ItemDropType>? itemDrops,
    this.extraItemDrops = const [],
    List<DropRoll>? bonusDrops,
    this.extraBonusDrops = const [],
    this.isDungeonBoss = false,
    // art comes from the archetype, and the combat stats are derived from
    // level and type by the getters below; the fields the parent stores
    // for all of them are never read. Nor are the drop lists it stores:
    // the getters below resolve them against the archetype.
  }) : assert(fibLevel >= 0, 'a level is a rung of the Fibonacci ladder'),
       ownAttackInterval = attackInterval,
       ownItemDrops = itemDrops,
       ownBonusDrops = bonusDrops,
       super(
         iconAsset: '',
         entityType: SkillId.ATTACK,
         defence: 0,
         hitpoints: 0,
         itemDrops: const [],
       );

  /// How many rungs above the archetype's loot this monster stands: what
  /// its inherited drops are scaled by. A monster may stand below the rung
  /// its archetype's loot was written for — a level-89 banshee on an
  /// archetype whose loot is written at 144 — but then it cannot inherit,
  /// since that would mean dropping less than one of something: it writes
  /// its own tables, and the catalog test holds it to that.
  int get lootSteps => fibLevel - archetype.lootFibLevel;

  /// Resolved tables, built once per definition: rolled on every kill, and
  /// scaling a table flattens it.
  static final Expando<List<ItemDropType>> _itemDropsCache = Expando();
  static final Expando<List<DropRoll>> _bonusDropsCache = Expando();

  /// The main table: [ownItemDrops] if written, otherwise the archetype's
  /// scaled by [lootSteps] ([WeightedDrops.scaledBy] — more of each stack,
  /// equipment a rung up per step), then [extraItemDrops] on top.
  @override
  List<ItemDropType> get itemDrops => _itemDropsCache[this] ??= [
    ...ownItemDrops ?? archetype.itemDrops.scaledBy(lootSteps),
    ...extraItemDrops,
  ];

  /// The bonus rolls, resolved the way [itemDrops] is: each inherited roll
  /// keeps its chance and has its entries scaled.
  @override
  List<DropRoll> get bonusDrops => _bonusDropsCache[this] ??= [
    ...ownBonusDrops ??
        [
          for (final roll in archetype.bonusDrops)
            DropRoll(
              chance: roll.chance,
              entries: roll.entries.scaledBy(lootSteps),
            ),
        ],
    ...extraBonusDrops,
  ];

  /// The chance a regular monster drops its reagent part on a kill. A
  /// dungeon boss always does, [bossReagentLow]–[bossReagentHigh] of them.
  /// design/ALCHEMY_POTIONS.md, "Drop rate".
  static const double reagentChance = 0.5;
  static const int bossReagentLow = 2;
  static const int bossReagentHigh = 4;

  static final Expando<List<DropRoll>> _rolledBonusCache = Expando();

  /// This monster's alchemy reagent: its archetype's family, at the grade
  /// its rung reaches. Derived, so a new monster on a tagged archetype
  /// drops the right part without writing one. Null for an untagged one.
  DropRoll? get reagentDrop {
    final family = archetype.reagentFamily;
    if (family == null) return null;
    return DropRoll(
      chance: isDungeonBoss ? 1.0 : reagentChance,
      entries: [
        ItemDropType(
          id: reagentPart(family, ReagentGrade.forRung(fibLevel)),
          lowCount: isDungeonBoss ? bossReagentLow : 1,
          highCount: isDungeonBoss ? bossReagentHigh : 1,
        ),
      ],
    );
  }

  @override
  List<DropRoll> get rolledBonusDrops =>
      _rolledBonusCache[this] ??= [...bonusDrops, ?reagentDrop];

  @override
  String get iconAsset => archetype.iconAsset;

  CombatType get combatType => archetype.combatType;

  double get attackInterval => ownAttackInterval ?? archetype.attackInterval;

  /// The stat budget: the rung [fibLevel] names.
  ///
  /// Recoverable from the three stats via [CombatType.levelOf] — for a
  /// regular; a boss's hitpoints are multiplied past what its level gives.
  int get level => Util.fib(fibLevel);

  int get attack => combatType.attackAt(level);

  @override
  int get defence => combatType.defenceAt(level);

  /// How many times a regular's hitpoints a dungeon boss stands on: the
  /// fight that ends a floor is meant to be one, not one more swing.
  static const int bossHitpointsMultiplier = 10;

  /// A boss has [bossHitpointsMultiplier] times what its level gives. Its
  /// attack and defence stay its level's, so the fight is longer, not
  /// harder to land a hit in.
  @override
  int get hitpoints =>
      combatType.hitpointsAt(level) *
      (isDungeonBoss ? bossHitpointsMultiplier : 1);

  @override
  CombatEntity toEntity(EntityId id) => CombatEntity(id: id);

  /// [iconAsset], [defence] and [hitpoints] are inherited from the base
  /// signature but have no meaning here — art comes from the archetype and
  /// the stats come from [level] and [combatType], so vary the archetype
  /// (or the fibLevel) instead.
  @override
  CombatEntityDefinition copyWith({
    CombatArchetype? archetype,
    int? fibLevel,
    double? attackInterval,
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    List<ItemDropType>? itemDrops,
    List<ItemDropType>? extraItemDrops,
    List<DropRoll>? bonusDrops,
    List<DropRoll>? extraBonusDrops,
    bool? isDungeonBoss,
  }) {
    assert(
      iconAsset == null && defence == null && hitpoints == null,
      'art and combat stats are derived: pass an archetype or a fibLevel, '
      'not iconAsset/defence/hitpoints',
    );
    return CombatEntityDefinition(
      archetype ?? this.archetype,
      fibLevel: fibLevel ?? this.fibLevel,
      attackInterval: attackInterval ?? ownAttackInterval,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      // the written tables, not the resolved ones, so a copy on another
      // rung re-scales what it inherits rather than freezing this one's
      itemDrops: itemDrops ?? ownItemDrops,
      extraItemDrops: extraItemDrops ?? this.extraItemDrops,
      bonusDrops: bonusDrops ?? ownBonusDrops,
      extraBonusDrops: extraBonusDrops ?? this.extraBonusDrops,
      isDungeonBoss: isDungeonBoss ?? this.isDungeonBoss,
    );
  }
}
