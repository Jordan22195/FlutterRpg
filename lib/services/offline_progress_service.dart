import '../data/action_result.dart';
import '../data/offline_progress_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../systems/exploration_system.dart';
import 'inventory_service.dart';

/// Collects what an offline settle paid out into one report, and hands the
/// finished report to the ui.
///
/// Every recording method is a no-op while [OfflineProgressData.processing]
/// is down, so the action controllers can call in unconditionally: the
/// buffer only opens for the stretch of a settle.
///
/// Items and kills come from the action results; xp does not. Xp is read off
/// the player's own totals across the settle ([begin] to [finish]) because
/// the systems apply it internally - a disenchant rolls its xp from the item
/// it just consumed, and no result carries the number back out.
class OfflineProgressService {
  final InventoryService _inventoryService;

  OfflineProgressService(this._inventoryService);

  /// How long the player has to have been away before a settle is worth a
  /// popup. Progress still settles below this - [ActionTimingService
  /// .offlineThreshold] is only a few seconds, and backgrounding the app for
  /// a moment should not raise a dialog.
  static const Duration reportThreshold = Duration(seconds: 5);

  /// Opens the buffer for one settle, discarding whatever the last one left.
  void begin(
    OfflineProgressData data,
    Duration timeAway,
    PlayerData playerState,
  ) {
    data.report = OfflineProgressReport()..timeAway = timeAway;
    data.xpAtStart = _xpTotals(playerState);
    data.processing = true;
  }

  /// Counts the actions one stretch of the settle paid for. Called with the
  /// count handed to the action, not once per action.
  void recordActions(OfflineProgressData data, int count) {
    if (!data.processing || count <= 0) return;
    data.report.actionCount += count;
  }

  void record(OfflineProgressData data, ActionResult result) {
    if (!data.processing) return;
    _inventoryService.addItems(data.report.items, result.items);
    for (final item in result.equipment) {
      // its own copy: sharing one instance between two inventories would
      // double-count when stacks merge
      _inventoryService.addEquipment(data.report.items, item.copy());
    }
    if (result.enemyDied) data.report.enemiesDefeated++;
  }

  /// Explore has its own result type: it settles a whole batch in one fire
  /// rather than one action at a time, and what it turns up is as much
  /// entities as loot.
  void recordExplore(OfflineProgressData data, ExploreResult result) {
    if (!data.processing) return;
    _inventoryService.addItems(data.report.items, result.items);
    for (final entity in result.entities) {
      if (entity.count <= 0) continue;
      data.report.entities.update(
        entity.id,
        (count) => count + entity.count,
        ifAbsent: () => entity.count,
      );
    }
  }

  /// Closes the buffer. A report that is empty, or covers too short a gap to
  /// be worth interrupting the player over, is dropped rather than shown.
  void finish(OfflineProgressData data, PlayerData playerState) {
    data.processing = false;
    data.report.xp = _xpGainedSince(data.xpAtStart, playerState);
    if (data.report.isEmpty) return;
    if (data.report.timeAway < reportThreshold) return;
    data.pending = data.report;
    data.reportSequence++;
  }

  /// Called once the ui has shown the report.
  void consume(OfflineProgressData data) {
    data.pending = null;
  }

  Map<SkillId, double> _xpTotals(PlayerData playerState) {
    return {
      for (final entry in playerState.skillData.entries)
        entry.key: entry.value.xp,
    };
  }

  Map<SkillId, double> _xpGainedSince(
    Map<SkillId, double> before,
    PlayerData playerState,
  ) {
    final gained = <SkillId, double>{};
    for (final entry in playerState.skillData.entries) {
      final delta = entry.value.xp - (before[entry.key] ?? 0);
      if (delta > 0) gained[entry.key] = delta;
    }
    return gained;
  }
}
