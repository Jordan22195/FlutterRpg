import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/catalogs/items/items.dart';

class ZoneDefinition {
  final String name;
  final List<EntityId> permanentEntities;
  final List<WeightedDropTableEntry<EntityId>> discoverableEntities;
  // items are on a separate drop table and have a chance to drop when
  // an exploration action happens.
  final List<WeightedDropTableEntry<ItemId>> discoverableItems;
  final String iconAsset;

  /// Skill level gate for entering the zone; NULL/0 means unrestricted.
  /// Separate from (and additional to) [explorationLevel].
  final SkillId requiredSkill;
  final int requiredLevel;

  /// The zone's base difficulty, as an Exploration level. It gates entry
  /// and is the baseline every discoverable's [WeightedDropTableEntry
  /// .unlockLevel] and the find-count curve are measured against. 0 means
  /// unrestricted.
  final int explorationLevel;

  /// Average Exploration xp one explore action in this zone is worth. The
  /// per-entity award divides this pool by drop weight, so rare finds pay
  /// more while the expected rate stays exactly this number — extra finds
  /// grant no xp, which keeps a zone's xp/hr flat however far it has been
  /// outlevelled.
  final double xpPerExplore;

  const ZoneDefinition({
    required this.name,
    required this.discoverableEntities,
    required this.permanentEntities,
    this.discoverableItems = const [],
    required this.iconAsset,
    this.requiredSkill = SkillId.NULL,
    this.requiredLevel = 0,
    this.explorationLevel = 0,
    this.xpPerExplore = 0,
  });
}
