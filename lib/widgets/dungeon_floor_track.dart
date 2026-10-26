import 'package:flutter/material.dart';

import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/entities/entities.dart';
import '../data/entity_queue.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'fill_bar.dart';
import 'sprite_frame.dart';

/// A dungeon floor's progress over the fight on screen: a kill bar, and the
/// floor's members in queue order — cleared ones dimmed under a check, the
/// one being fought larger in the accent, the rest waiting, the boss in its
/// gold frame. Tiles open the member's details, which is how a boss's drops
/// are read before you reach it.
class DungeonFloorTrack extends StatelessWidget {
  const DungeonFloorTrack({
    super.key,
    required this.floor,
    required this.fullCounts,
    this.onMemberTap,
  });

  final EntityQueue floor;

  /// How many of each member the floor starts with, matching
  /// `floor.members` — what the kill bar counts against. Build it with
  /// [fullCountsFor].
  final List<int> fullCounts;

  final void Function(EncounterEntity member)? onMemberTap;

  static const double _tileSize = 34;
  static const double _currentTile = 42;

  /// Whether [entity] is the boss its floor builds to.
  static bool isBoss(EncounterEntity entity) =>
      entity is CombatEntity && entity.definition.isDungeonBoss;

  /// How many of each of [floor]'s members floor [index] of [id] starts
  /// with. A floor builds one member per entity of its entry, skipping what
  /// can't sit on a floor, so the two lists are walked together by id; a
  /// member the entry doesn't account for counts what it holds now.
  static List<int> fullCountsFor(DungeonId id, int index, EntityQueue floor) {
    final entries = id.definition.entries;
    final refs = index >= 0 && index < entries.length
        ? entries[index].entities
        : const <DungeonEntityRef>[];
    final counts = <int>[];
    var r = 0;
    for (final member in floor.members) {
      while (r < refs.length && refs[r].entityId != member.id) {
        r++;
      }
      counts.add(r < refs.length ? refs[r++].count : member.count);
    }
    return counts;
  }

  /// The members the kill bar counts: everything but a closing boss, which
  /// the bar builds to rather than counts.
  int get _counted =>
      floor.members.isNotEmpty && isBoss(floor.members.last)
      ? floor.members.length - 1
      : floor.members.length;

  int get _total {
    var total = 0;
    for (int i = 0; i < _counted && i < fullCounts.length; i++) {
      total += fullCounts[i];
    }
    return total;
  }

  int get _killed {
    var left = 0;
    for (int i = floor.index; i < _counted; i++) {
      left += floor.members[i].count;
    }
    return (_total - left).clamp(0, _total);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = _total;
    final killed = _killed;
    final current = floor.current;
    final onBoss = current != null && isBoss(current);
    final fights = floor.members.every((m) => m is CombatEntity);
    final count = onBoss
        ? '$killed / $total · Boss'
        : '$killed / $total ${fights ? 'kills' : 'done'}';

    return Semantics(
      container: true,
      label: 'Floor progress',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'FLOOR',
                  style: HearthText.sectionLabel.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FillBar(
                    value: total <= 0 ? 1 : killed / total,
                    height: 4,
                    borderRadius: 2,
                    backgroundColor: palette.track,
                    foregroundColor: GameColors.clearedColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  count,
                  style: HearthText.timer.copyWith(
                    fontSize: 12,
                    color: palette.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: LayoutBuilder(
                // spread across the card while they fit; a long floor
                // scrolls sideways instead of squeezing its tiles
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < floor.members.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          _tile(context, i),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, int i) {
    final palette = context.palette;
    final member = floor.members[i];
    final boss = isBoss(member);
    final cleared = i < floor.index;
    final isCurrent = i == floor.index;
    final name = member.name;
    final tap = onMemberTap == null ? null : () => onMemberTap!(member);

    Widget tile;
    if (isCurrent) {
      final frame = boss
          ? SpriteFrame(
              id: member.id,
              kind: SpriteKind.combat,
              size: _currentTile,
              spriteSize: 32,
              radius: 10,
              isBoss: true,
            )
          : Container(
              width: _currentTile,
              height: _currentTile,
              decoration: BoxDecoration(
                color: SpriteFrame.tintFor(context, SpriteKind.combat).fill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.accent, width: 2),
              ),
              alignment: Alignment.center,
              child: SpriteFrame.sprite(member.id, size: 30),
            );
      // a boss keeps its gold and takes the accent as a ring outside it
      tile = boss
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: palette.surface, spreadRadius: 2),
                  BoxShadow(color: palette.accent, spreadRadius: 4),
                ],
              ),
              child: frame,
            )
          : frame;
    } else if (boss && !cleared) {
      tile = SpriteFrame(
        id: member.id,
        kind: SpriteKind.combat,
        size: _tileSize,
        spriteSize: 22,
        radius: 8,
        isBoss: true,
      );
    } else {
      tile = Container(
        width: _tileSize,
        height: _tileSize,
        decoration: BoxDecoration(
          color: cleared ? palette.surfaceSunken : palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.borderStrong),
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: cleared ? 0.4 : 0.8,
          child: SpriteFrame.sprite(member.id, size: 22),
        ),
      );
      if (cleared) {
        tile = Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            Positioned(right: -4, bottom: -4, child: _ClearedBadge()),
          ],
        );
      }
    }

    final state = cleared
        ? 'cleared'
        : isCurrent
        ? 'fighting now'
        : 'upcoming';
    return Semantics(
      button: tap != null,
      label: '$name, ${boss ? 'boss, ' : ''}$state',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: tile,
      ),
    );
  }
}

/// The check on a cleared member's tile.
class _ClearedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: GameColors.clearedColor,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: context.palette.surface, spreadRadius: 2)],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.check_rounded, size: 10, color: context.palette.bg),
    );
  }
}
