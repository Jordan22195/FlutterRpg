import 'entity_queue.dart';
import 'inventory_data.dart';
import '../catalogs/dungeons/dungeons.dart';

/// Live state of a dungeon run: the cards built from the definition, which
/// of them are cleared, and which one the action loop is firing into.
///
/// Serialized with the save so a run survives app close (resume in place).
/// What resets it is leaving the dungeon — or dying in it, which counts as
/// leaving. Every dungeon type resets on leave; the types differ in what
/// that costs (a spent key, a consumed entrance).
///
/// The cards hold live [EntityQueue]s of real entities, so hp and counts
/// serialize for free and the existing combat services operate on them
/// directly. [loot] is the whole run's haul — the encounter screen's own
/// drop log resets per card, so this is the only place that adds up.
class DungeonRun {
  bool active;
  DungeonId dungeonId;

  /// One queue per card, in definition order.
  List<EntityQueue> slots;

  /// Indices of the cards cleared this run. Kept separately from the
  /// queues, because a repeatable card that has been refilled is still a
  /// card you have cleared — that is what keeps the next card unlocked.
  List<int> cleared;

  /// The card the action loop is currently running, or -1 for none. Only
  /// ever one at a time: starting a card stops whatever was running.
  int runningSlot;

  /// Keyed dungeons: whether this run's key has already been paid.
  bool keySpent;

  /// Every drop collected across the run, card to card.
  InventoryData loot;

  DungeonRun({
    this.active = false,
    this.dungeonId = DungeonId.NULL,
    List<EntityQueue>? slots,
    List<int>? cleared,
    this.runningSlot = -1,
    this.keySpent = false,
    InventoryData? loot,
  }) : slots = slots ?? [],
       cleared = cleared ?? [],
       loot = loot ?? InventoryData(itemMap: {});

  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'dungeonId': dungeonId.name,
      'slots': slots.map((s) => s.toJson()).toList(),
      'cleared': cleared,
      'runningSlot': runningSlot,
      'keySpent': keySpent,
      'loot': loot.toJson(),
    };
  }

  /// Tolerant by design: a save written before dungeons became card lists
  /// carries floor/pack fields that mean nothing here, and yields an
  /// inactive run rather than failing the load.
  factory DungeonRun.fromJson(Map<String, dynamic> json) {
    final rawDungeonId = json['dungeonId'];
    final dungeonId = rawDungeonId is String
        ? DungeonId.values.firstWhere(
            (d) => d.name == rawDungeonId,
            orElse: () => DungeonId.NULL,
          )
        : DungeonId.NULL;

    final rawSlots = json['slots'];
    final slots = <EntityQueue>[];
    if (rawSlots is List) {
      for (final raw in rawSlots) {
        if (raw is Map<String, dynamic>) slots.add(EntityQueue.fromJson(raw));
      }
    }

    final rawCleared = json['cleared'];
    final cleared = rawCleared is List
        ? rawCleared.whereType<int>().toList()
        : <int>[];

    final rawRunningSlot = json['runningSlot'];
    final rawLoot = json['loot'];

    return DungeonRun(
      // a run with no cards is not a run, whatever the flag says
      active: json['active'] == true && slots.isNotEmpty,
      dungeonId: dungeonId,
      slots: slots,
      cleared: cleared,
      runningSlot: rawRunningSlot is int && rawRunningSlot < slots.length
          ? rawRunningSlot
          : -1,
      keySpent: json['keySpent'] == true,
      loot: rawLoot is Map<String, dynamic>
          ? InventoryData.fromJson(rawLoot)
          : InventoryData(itemMap: {}),
    );
  }
}
