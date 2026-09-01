import 'package:rpg/catalogs/items/item_id.dart';
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
class CombatEntityDefinition extends EncounterEntityDefinition {
  /// The monster this is a variant of.
  final CombatArchetype archetype;

  const CombatEntityDefinition(
    this.archetype, {
    required super.name,
    super.rarity,
    required super.itemDrops,
    super.bonusDrops,
    // art comes from the archetype, and the combat stats are derived from
    // level and type by the getters below; the fields the parent stores
    // for all of them are never read.
  }) : super(
         iconAsset: '',
         entityType: SkillId.ATTACK,
         defence: 0,
         hitpoints: 0,
       );

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
  /// Recoverable from the three stats via [CombatType.levelOf].
  int get level => Util.fib(fibLevel + rarity.index);

  int get attack => combatType.attackAt(level);

  @override
  int get defence => combatType.defenceAt(level);

  @override
  int get hitpoints => combatType.hitpointsAt(level);

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
    List<DropRoll<ItemId>>? bonusDrops,
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
      itemDrops: itemDrops ?? this.itemDrops,
      bonusDrops: bonusDrops ?? this.bonusDrops,
    );
  }
}
