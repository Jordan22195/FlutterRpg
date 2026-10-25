import 'equipment_data.dart';
import 'skill_data.dart';

/// One piece a [GearSet] asks for.
///
/// Remembered by [instanceId] first, but that alone is not a stable handle:
/// identical pieces share a stack in the bag, and taking one off folds it
/// back into a stack that keeps the stack's id, not the piece's. So the
/// piece's [stackKey] is kept too — any piece with the same key is the same
/// in every way that matters, and wearing it is wearing this one.
class GearSetPiece {
  final String instanceId;
  final String stackKey;

  /// What the piece was called when the set was saved, for saying which
  /// piece a swap had to leave out even after the piece itself is gone.
  final String label;

  const GearSetPiece({
    required this.instanceId,
    required this.stackKey,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'stackKey': stackKey,
    'label': label,
  };

  /// Null for an entry too broken to find anything with.
  static GearSetPiece? fromJson(dynamic json) {
    if (json is! Map) return null;
    final instanceId = json['instanceId'];
    final stackKey = json['stackKey'];
    if (instanceId is! String || stackKey is! String) return null;
    final label = json['label'];
    return GearSetPiece(
      instanceId: instanceId,
      stackKey: stackKey,
      label: label is String ? label : '',
    );
  }
}

/// A saved outfit the player can swap back into in one tap.
///
/// A set is the whole outfit, empty slots included: swapping to a set with
/// nothing on its head takes the helmet off. Tools are only part of it when
/// [includesTools] — a combat set leaves the gathering tools where they are.
class GearSet {
  String name;
  final Map<ArmorSlots, GearSetPiece> armor;
  final bool includesTools;

  /// Only read when [includesTools].
  final Map<SkillId, GearSetPiece> tools;

  GearSet({
    required this.name,
    required this.armor,
    this.includesTools = false,
    Map<SkillId, GearSetPiece>? tools,
  }) : tools = tools ?? {};

  /// Longest name the gear screen lets a set have.
  static const int maxNameLength = 24;

  Map<String, dynamic> toJson() => {
    'name': name,
    'armor': {
      for (final entry in armor.entries) entry.key.name: entry.value.toJson(),
    },
    'includesTools': includesTools,
    if (includesTools)
      'tools': {
        for (final entry in tools.entries) entry.key.name: entry.value.toJson(),
      },
  };

  /// Tolerant like the rest of the save: a slot or skill the game no longer
  /// has is dropped, and a set with no name gets a placeholder.
  factory GearSet.fromJson(Map<String, dynamic> json) {
    final armor = <ArmorSlots, GearSetPiece>{};
    final rawArmor = json['armor'];
    if (rawArmor is Map) {
      for (final entry in rawArmor.entries) {
        final slot = ArmorSlots.values.asNameMap()[entry.key];
        final piece = GearSetPiece.fromJson(entry.value);
        if (slot == null || slot == ArmorSlots.TOOL || piece == null) continue;
        armor[slot] = piece;
      }
    }

    final tools = <SkillId, GearSetPiece>{};
    final rawTools = json['tools'];
    if (rawTools is Map) {
      for (final entry in rawTools.entries) {
        final skill = SkillId.values.asNameMap()[entry.key];
        final piece = GearSetPiece.fromJson(entry.value);
        if (skill == null || piece == null) continue;
        tools[skill] = piece;
      }
    }

    final name = json['name'];
    return GearSet(
      name: name is String && name.trim().isNotEmpty ? name : 'Gear set',
      armor: armor,
      includesTools: json['includesTools'] == true,
      tools: tools,
    );
  }
}

/// Why a swap left a piece of the set out.
enum GearSetSkipReason {
  /// Not worn and not in the bag: sold, disenchanted, or otherwise gone.
  missing,

  /// Still owned, but asks for a level the player no longer meets.
  locked,

  /// Found and wearable, but the slot would not take it — the catalog has
  /// moved the piece to a different slot since the set was saved.
  wrongSlot,
}

class GearSetSkip {
  final GearSetPiece piece;
  final GearSetSkipReason reason;

  /// What the piece asks for, when it was left out for being [locked].
  final ({SkillId skill, int level})? requirement;

  const GearSetSkip(this.piece, this.reason, {this.requirement});
}
