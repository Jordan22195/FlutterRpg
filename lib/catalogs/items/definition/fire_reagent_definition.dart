import 'package:rpg/catalogs/items/definition/item_definition.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/skill_data.dart';

/// Something thrown on a lit campfire or bonfire to buff [stat].
///
/// The reagent picks the stat and the fire sets the size: one reagent gives
/// the fire's power to [stat] for the fire's reagent burn time (see
/// FireItemDefinition). All seven come off the first two trees as
/// woodcutting side-drops, so every stat can be tended early, the way
/// every stat has a minor potion; better wood is what makes them bigger.
class FireReagentDefinition extends ItemDefinition {
  /// The stat a fire tended with this one buffs.
  final SkillId stat;

  /// The Firemaking level needed to throw it on. Also the xp a hand-thrown
  /// one pays, so both climb the same Fibonacci rungs (5 / 8 / 13).
  final int levelRequirement;

  const FireReagentDefinition({
    required super.name,
    required super.value,
    required this.stat,
    required this.levelRequirement,
    super.description,
    super.iconAsset,
    super.quality,
  });

  @override
  FireReagentDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    SkillId? stat,
    int? levelRequirement,
  }) {
    return FireReagentDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      stat: stat ?? this.stat,
      levelRequirement: levelRequirement ?? this.levelRequirement,
    );
  }
}
