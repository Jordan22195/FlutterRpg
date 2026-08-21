import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/dungeons/dungeon_type.dart';
import 'package:rpg/catalogs/dungeons/definition/dungeon_entry.dart';

class DungeonDefinition {
  final String name;
  final String iconAsset;
  final DungeonType type;

  /// Landmark dungeons consume this item to start the first card. NULL for
  /// free-entry (transient/zone) dungeons.
  final ItemId keyItemId;

  /// Optional soft/hard level gate, mirroring the zone gate convention.
  /// NULL/0 means no explicit requirement.
  final SkillId requiredSkill;
  final int requiredLevel;

  final List<DungeonEntry> entries;

  const DungeonDefinition({
    required this.name,
    required this.iconAsset,
    required this.type,
    required this.entries,
    this.keyItemId = ItemId.NULL,
    this.requiredSkill = SkillId.NULL,
    this.requiredLevel = 0,
  });

  /// Whether the first card requires (and consumes) a key.
  bool get isKeyed => keyItemId != ItemId.NULL;

  /// Whether a cleared card can be re-tapped to fight it again. Only the
  /// permanent zone dungeons farm; keyed and transient runs are one-shot.
  bool get repeatableEntries => type == DungeonType.ZONE;

  /// A variant of this definition. Definitions are `const` and shared, so a
  /// caller needing a tweaked dungeon builds a new value here.
  DungeonDefinition copyWith({
    String? name,
    String? iconAsset,
    DungeonType? type,
    List<DungeonEntry>? entries,
    ItemId? keyItemId,
    SkillId? requiredSkill,
    int? requiredLevel,
  }) {
    return DungeonDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      type: type ?? this.type,
      entries: entries ?? this.entries,
      keyItemId: keyItemId ?? this.keyItemId,
      requiredSkill: requiredSkill ?? this.requiredSkill,
      requiredLevel: requiredLevel ?? this.requiredLevel,
    );
  }
}
