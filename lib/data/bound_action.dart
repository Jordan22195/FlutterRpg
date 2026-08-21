import '../catalogs/entities/entities.dart';
import '../catalogs/zones/zones.dart';

enum BoundActionKind { EXPLORE, ENCOUNTER, CRAFT, ENCHANT, DUNGEON_SLOT }

/// A serializable description of the action bound to the timing loop.
///
/// The loop fires a closure, which no save can hold, so this records what
/// would have to be bound to run the same action again. On relaunch
/// [GameSession.resumeBoundAction] reads it and re-runs the controller's own
/// start path, which is what actually rebinds the closure.
class BoundAction {
  final BoundActionKind kind;
  final ZoneId zoneId;

  /// Encounter target, or the crafting station.
  final EntityId entityId;

  /// Craft recipe, or enchant recipe.
  final String recipeId;

  /// The equipment instance an enchant is working on.
  final String targetInstanceId;

  /// Card index within the running dungeon.
  final int dungeonSlot;

  const BoundAction._({
    required this.kind,
    this.zoneId = ZoneId.NULL,
    this.entityId = EntityId.NULL,
    this.recipeId = '',
    this.targetInstanceId = '',
    this.dungeonSlot = -1,
  });

  const BoundAction.explore({required ZoneId zoneId})
    : this._(kind: BoundActionKind.EXPLORE, zoneId: zoneId);

  const BoundAction.encounter({
    required ZoneId zoneId,
    required EntityId entityId,
  }) : this._(
         kind: BoundActionKind.ENCOUNTER,
         zoneId: zoneId,
         entityId: entityId,
       );

  const BoundAction.craft({
    required ZoneId zoneId,
    required EntityId entityId,
    required String recipeId,
  }) : this._(
         kind: BoundActionKind.CRAFT,
         zoneId: zoneId,
         entityId: entityId,
         recipeId: recipeId,
       );

  const BoundAction.enchant({
    required String recipeId,
    required String targetInstanceId,
  }) : this._(
         kind: BoundActionKind.ENCHANT,
         recipeId: recipeId,
         targetInstanceId: targetInstanceId,
       );

  const BoundAction.dungeonSlot({required int dungeonSlot})
    : this._(kind: BoundActionKind.DUNGEON_SLOT, dungeonSlot: dungeonSlot);

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      'zoneId': zoneId.name,
      'entityId': entityId.name,
      'recipeId': recipeId,
      'targetInstanceId': targetInstanceId,
      'dungeonSlot': dungeonSlot,
    };
  }

  /// Null when the kind no longer parses: an action that can't be identified
  /// can't be rebound, and coming back idle beats failing the save load.
  static BoundAction? fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind'];
    if (rawKind is! String) return null;
    final kind = BoundActionKind.values.asNameMap()[rawKind];
    if (kind == null) return null;

    final rawZone = json['zoneId'];
    final rawEntity = json['entityId'];
    final rawRecipe = json['recipeId'];
    final rawTarget = json['targetInstanceId'];
    final rawSlot = json['dungeonSlot'];

    return BoundAction._(
      kind: kind,
      zoneId: rawZone is String
          ? ZoneId.values.asNameMap()[rawZone] ?? ZoneId.NULL
          : ZoneId.NULL,
      entityId: rawEntity is String
          ? EntityId.values.asNameMap()[rawEntity] ?? EntityId.NULL
          : EntityId.NULL,
      recipeId: rawRecipe is String ? rawRecipe : '',
      targetInstanceId: rawTarget is String ? rawTarget : '',
      dungeonSlot: rawSlot is int ? rawSlot : -1,
    );
  }
}
