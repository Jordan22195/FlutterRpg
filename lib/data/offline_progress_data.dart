import '../catalogs/entity_catalog.dart';
import 'inventory_data.dart';
import 'skill_data.dart';

/// Everything one offline settle paid out, merged into a single summary.
///
/// The offline window can fire the bound action more than once (a locked
/// boost splits it into a boosted stretch and an unboosted remainder), and
/// an explore settles a whole batch in one fire, so this is an aggregate
/// rather than a log of individual actions.
class OfflineProgressReport {
  /// How long the player was away, as the settle measured it.
  Duration timeAway = Duration.zero;

  /// Actions the settle paid for, summed across every stretch.
  int actionCount = 0;

  /// Xp gained per skill.
  Map<SkillId, double> xp = {};

  /// What was gained. An inventory rather than a plain list because the
  /// stacks have to merge and equipment instances never stack.
  InventoryData items = InventoryData(itemMap: {});

  /// Entities exploring turned up, counted by kind. The zone keeps them;
  /// this is what to tell the player they walked into while away.
  Map<EntityId, int> entities = {};

  /// Entities the bound action killed, counted by kind. Combat kills and
  /// gathering nodes both land here - anything an encounter took down.
  Map<EntityId, int> entitiesDefeated = {};

  /// How many kills that adds up to, for the summary line above the tiles.
  int get enemiesDefeated =>
      entitiesDefeated.values.fold(0, (sum, count) => sum + count);

  /// Nothing worth showing the player. A settle can land here legitimately:
  /// a gap too short to complete an action, or one where the action's
  /// conditions were already unmet.
  bool get isEmpty =>
      actionCount == 0 &&
      xp.isEmpty &&
      items.itemMap.isEmpty &&
      items.equipment.isEmpty &&
      entities.isEmpty &&
      entitiesDefeated.isEmpty;
}

/// The buffer offline progress is collected into.
///
/// Not serialized: offline progress is recalculated from
/// [PlayerData.lastActionTime] on resume, so a report never has to survive a
/// save.
class OfflineProgressData {
  /// Up only while [ActionTimingSystem.offlineProgressUpdate] is settling.
  /// Action results are buffered while it is up and ignored otherwise, so
  /// normal play never feeds the report.
  bool processing = false;

  /// The report being filled.
  OfflineProgressReport report = OfflineProgressReport();

  /// Xp totals as the settle started, so the report can be the difference.
  Map<SkillId, double> xpAtStart = {};

  /// A finished report waiting for the ui to show it.
  OfflineProgressReport? pending;

  /// Bumped whenever a report becomes [pending]. The shell watches this
  /// rather than the report itself, so a second settle with identical
  /// numbers still raises the popup.
  int reportSequence = 0;
}
