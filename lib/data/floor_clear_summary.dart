import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/entities/entities.dart';
import 'ObjectStack.dart';

/// A floor just cleared, as the pause before the next one reports it: what
/// fell on the lap, how long it took and what it cost, against the bests
/// that stood before it.
///
/// Built once, at the clear, so the summary stays put while the run moves
/// on underneath it.
class FloorClearSummary {
  final DungeonId dungeonId;
  final int floorIndex;
  final String floorName;

  /// The floor's last member — its boss, on a floor that has one.
  final EntityId lastMemberId;
  final String lastMemberName;

  /// The last member is a dungeon boss, so its drops are told apart.
  final bool boss;

  /// How many members the floor started with, all now defeated.
  final int defeated;

  /// The lap's fighting time and damage taken; null for a lap that was not
  /// watched from its start.
  final Duration? time;
  final int? damageTaken;

  /// The bests on record before this lap; null before the floor had one.
  final Duration? bestTimeBefore;
  final int? leastDamageBefore;

  /// Lifetime clears of the floor, this one included, and how many of them
  /// came since it last started.
  final int clears;
  final int sessionClears;

  /// What the lap dropped: [loot] from the floor's ordinary members,
  /// [bossLoot] from its boss.
  final List<ObjectStack> loot;
  final List<ObjectStack> bossLoot;

  /// When the pause ends and the next floor starts on its own.
  final DateTime endsAt;

  const FloorClearSummary({
    required this.dungeonId,
    required this.floorIndex,
    required this.floorName,
    required this.lastMemberId,
    required this.lastMemberName,
    this.boss = false,
    required this.defeated,
    required this.time,
    required this.damageTaken,
    required this.bestTimeBefore,
    required this.leastDamageBefore,
    required this.clears,
    required this.sessionClears,
    required this.loot,
    this.bossLoot = const [],
    required this.endsAt,
  });

  /// The lap beat the time on record. A first timed lap sets a best but
  /// beats nothing, so it isn't called new.
  bool get newBestTime =>
      time != null && bestTimeBefore != null && time! < bestTimeBefore!;

  bool get newLeastDamage =>
      damageTaken != null &&
      leastDamageBefore != null &&
      damageTaken! < leastDamageBefore!;
}
