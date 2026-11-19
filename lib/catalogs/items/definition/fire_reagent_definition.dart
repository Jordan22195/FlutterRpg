import 'package:rpg/catalogs/items/definition/item_definition.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/skill_data.dart';

/// Something laid into a bonfire to pick the stat it buffs.
///
/// The reagent picks the stat and the wood sets the size: every wood has a
/// bonfire per reagent (see FireItemDefinition and firemaking_recipes). The
/// first seven come off the first two trees as woodcutting side-drops, so
/// every combat stat can be buffed early, the way every stat has a minor
/// potion; better wood is what makes them bigger.
class FireReagentDefinition extends ItemDefinition {
  /// The stat a bonfire laid with this one buffs.
  final SkillId stat;

  /// The lowest Firemaking level a bonfire laid with it asks for. Also the
  /// xp it adds to that bonfire's, so both climb the same Fibonacci rungs
  /// (5 / 8 / 13).
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
