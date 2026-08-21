import '../data/action_result.dart';
import '../data/offline_progress_data.dart';
import '../data/skill_data.dart';
import 'inventory_service.dart';

/// Collects what an offline settle paid out into one report, and hands the
/// finished report to the ui.
///
/// Every recording method is a no-op while [OfflineProgressData.processing]
/// is down, so the action controllers can call in unconditionally: the
/// buffer only opens for the stretch of a settle.
///
/// Everything in the report comes from the action results: the items, the
/// kills, the xp, and the count of actions that actually happened. Nothing
/// is inferred from the player's own totals, and nothing is counted before
/// the action has had its say - an action that declines to act (its fire
/// went out, its materials ran out) reports the nothing it did.
class OfflineProgressService {
  final InventoryService _inventoryService;

  OfflineProgressService(this._inventoryService);

  /// How long the player has to have been away before a settle is worth a
  /// popup. Progress still settles below this - [ActionTimingService
  /// .offlineThreshold] is only a few seconds, and backgrounding the app for
  /// a moment should not raise a dialog.
  static const Duration reportThreshold = Duration(seconds: 5);

  /// Opens the buffer for one settle, discarding whatever the last one left.
  void begin(OfflineProgressData data, Duration timeAway) {
    data.report = OfflineProgressReport()..timeAway = timeAway;
    data.processing = true;
  }

  void record(OfflineProgressData data, EncounterActionResult result) {
    if (!data.processing) return;
    _recordActions(data, result.actionsPerformed);
    _recordXp(data, result.xp);
    _inventoryService.addItems(data.report.items, result.items);
    for (final item in result.equipment) {
      // its own copy: sharing one instance between two inventories would
      // double-count when stacks merge. a copy is a single piece, so a
      // batch's stack size is carried across explicitly.
      _inventoryService.addEquipment(
        data.report.items,
        item.copy()..count = item.count,
      );
    }
    for (final entity in result.entitiesDefeated) {
      if (entity.count <= 0) continue;
      data.report.entitiesDefeated.update(
        entity.id,
        (count) => count + entity.count,
        ifAbsent: () => entity.count,
      );
    }
  }

  /// Explore has its own result type: it settles a whole batch in one fire
  /// rather than one action at a time, and what it turns up is as much
  /// entities as loot.
  void recordExplore(OfflineProgressData data, ExploreResult result) {
    if (!data.processing) return;
    _recordActions(data, result.actionsPerformed);
    // explore trains one skill, so its result carries a bare number rather
    // than a map
    _recordXp(data, {SkillId.EXPLORATION: result.xp});
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
  void finish(OfflineProgressData data) {
    data.processing = false;
    if (data.report.isEmpty) return;
    if (data.report.timeAway < reportThreshold) return;
    data.pending = data.report;
    data.reportSequence++;
  }

  /// Called once the ui has shown the report.
  void consume(OfflineProgressData data) {
    data.pending = null;
  }

  /// The actions one fire actually performed, which is not always the count
  /// it was handed.
  void _recordActions(OfflineProgressData data, int count) {
    if (count <= 0) return;
    data.report.actionCount += count;
  }

  void _recordXp(OfflineProgressData data, Map<SkillId, double> xp) {
    for (final entry in xp.entries) {
      if (entry.value <= 0) continue;
      data.report.xp.update(
        entry.key,
        (total) => total + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }
}
