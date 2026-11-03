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

/// A thing that fights back. Its stats are never written by hand: [level]
/// sets the size of its stat budget and [combatType] splits that budget
/// across attack, defence and hitpoints, so every enemy sits on the same
/// curve and a level reads the same everywhere.
///
/// One definition is a single *rarity variant* of a monster. What the
/// variants share — art, tier, how it fights — lives on the shared
/// [CombatArchetype]; what makes a variant its own thing (name, rarity,
/// drops) is written here.
///
/// Drops default to the common variant's, scaled to this one's rarity (see
/// [itemDrops]), so a variant only writes the loot that sets it apart.
class CombatEntityDefinition extends EncounterEntityDefinition {
  /// The monster this is a variant of.
  final CombatArchetype archetype;

  /// Set on the one monster that ends a dungeon floor, and on nothing else:
  /// a boss is its own entity, so a monster that is a boss in one place is
  /// never also a regular somewhere. The dungeon screen draws its tile apart.
  final bool isDungeonBoss;

  /// The main table as written here, or null to inherit the common
  /// variant's. Written, it replaces the inherited table outright.
  final List<ItemDropType>? ownItemDrops;

  /// Lines added to the main table, on top of whichever [itemDrops]
  /// resolves to — inherited or written. Never scaled: they are written at
  /// the counts and qualities this variant drops them at.
  final List<ItemDropType> extraItemDrops;

  /// The bonus rolls as written here, or null to inherit the common
  /// variant's. `const []` turns the inherited ones off.
  final List<DropRoll>? ownBonusDrops;

  /// Bonus rolls added to whichever [bonusDrops] resolves to.
  final List<DropRoll> extraBonusDrops;

  const CombatEntityDefinition(
    this.archetype, {
    required super.name,
    super.rarity,
    List<ItemDropType>? itemDrops,
    this.extraItemDrops = const [],
    List<DropRoll>? bonusDrops,
    this.extraBonusDrops = const [],
    this.isDungeonBoss = false,
    // art comes from the archetype, and the combat stats are derived from
    // level and type by the getters below; the fields the parent stores
    // for all of them are never read. Nor are the drop lists it stores:
    // the getters below resolve them against the common variant.
  }) : ownItemDrops = itemDrops,
       ownBonusDrops = bonusDrops,
       super(
         iconAsset: '',
         entityType: SkillId.ATTACK,
         defence: 0,
         hitpoints: 0,
         itemDrops: const [],
       );

  /// The regular COMMON variant of [archetype] — the one whose drops every
  /// other variant inherits by default. Null for an archetype with no
  /// common regular (some monsters start at uncommon), and for any common,
  /// which is the rung the scaling starts from. A boss is
  /// never the base, even a common one: its table is bulk loot written for
  /// the end of a floor.
  CombatEntityDefinition? get base =>
      rarity == Rarity.COMMON ? null : _commonByArchetype[archetype];

  static final Map<CombatArchetype, CombatEntityDefinition> _commonByArchetype =
      {
        for (final id in EntityId.values.reversed)
          if (id.definition case final CombatEntityDefinition def
              when def.rarity == Rarity.COMMON && !def.isDungeonBoss)
            def.archetype: def,
      };

  /// Resolved tables, built once per definition: rolled on every kill, and
  /// scaling a table flattens it.
  static final Expando<List<ItemDropType>> _itemDropsCache = Expando();
  static final Expando<List<DropRoll>> _bonusDropsCache = Expando();

  /// The main table: [ownItemDrops] if written, otherwise the common
  /// variant's scaled to this rarity ([WeightedDrops.scaledTo] — more of
  /// each stack, equipment a rung up per rarity step), then
  /// [extraItemDrops] on top.
  @override
  List<ItemDropType> get itemDrops => _itemDropsCache[this] ??= [
    ...ownItemDrops ?? base?.itemDrops.scaledTo(rarity) ?? const [],
    ...extraItemDrops,
  ];

  /// The bonus rolls, resolved the way [itemDrops] is: each inherited roll
  /// keeps its chance and has its entries scaled.
  @override
  List<DropRoll> get bonusDrops => _bonusDropsCache[this] ??= [
    ...ownBonusDrops ??
        [
          for (final roll in base?.bonusDrops ?? const <DropRoll>[])
            DropRoll(
              chance: roll.chance,
              entries: roll.entries.scaledTo(rarity),
            ),
        ],
    ...extraBonusDrops,
  ];

  @override
  String get iconAsset => archetype.iconAsset;

  /// Index into [Util.fibonacciCache] of the COMMON variant's level.
  int get fibLevel => archetype.fibLevel;

  CombatType get combatType => archetype.combatType;

  double get attackInterval => archetype.attackInterval;

  /// The stat budget. A variant's rarity walks it up the same Fibonacci
  /// ladder its tier sits on: common is the archetype's own rung and
  /// legendary is four rungs higher, so an epic chicken and a common
  /// scarecrow can land on the same number and mean the same thing.
  ///
  /// Recoverable from the three stats via [CombatType.levelOf] — for a
  /// regular; a boss's hitpoints are multiplied past what its level gives.
  int get level => Util.fib(fibLevel + rarity.index);

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
  /// (or the rarity) instead.
  @override
  CombatEntityDefinition copyWith({
    CombatArchetype? archetype,
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
      'art and combat stats are derived: pass an archetype or a rarity, '
      'not iconAsset/defence/hitpoints',
    );
    return CombatEntityDefinition(
      archetype ?? this.archetype,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      // the written tables, not the resolved ones, so a copy at another
      // rarity re-scales what it inherits rather than freezing this one's
      itemDrops: itemDrops ?? ownItemDrops,
      extraItemDrops: extraItemDrops ?? this.extraItemDrops,
      bonusDrops: bonusDrops ?? ownBonusDrops,
      extraBonusDrops: extraBonusDrops ?? this.extraBonusDrops,
      isDungeonBoss: isDungeonBoss ?? this.isDungeonBoss,
    );
  }
}
