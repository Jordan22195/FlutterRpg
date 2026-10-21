import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../catalogs/entities/entities.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'place_tile.dart';
import 'primary_button.dart';

/// One card in a list of ordered content: a named run of entities, shown as
/// a row of tiles you will work through, left to right — three across, the
/// rest a swipe away.
///
/// Deliberately knows nothing about dungeons — it takes entities, a title,
/// and a lock reason, so any "do these in order" list can use it.
///
/// A locked card blurs its row, with the lock and its reason laid over the
/// blur, and its tiles take no taps: what a sealed card holds stays hidden
/// until it opens.
class EntityQueueCard extends StatelessWidget {
  const EntityQueueCard({
    super.key,
    required this.title,
    required this.entities,
    this.cleared = false,
    this.lockReason,
    this.stats,
    this.note,
    this.onTap,
    required this.entityTileBuilder,
    this.active = false,
  });

  final String title;
  final List<EncounterEntity> entities;

  /// Worked through at least once. A cleared card can still be tappable —
  /// that is how repeatable content is farmed.
  final bool cleared;

  /// Why this card can't be started, or null when it can. Non-null blurs
  /// the row, with the lock and this reason over the blur.
  final String? lockReason;

  /// A tally line under the title — how much of this card has been done. Null
  /// when there is nothing to say yet.
  final String? stats;

  /// Anything else this card has to say about itself, under the title — a
  /// dungeon uses it for the entry key it is about to charge.
  final Widget? note;

  /// Enters the card. Null means it can't be entered at all, which also
  /// drops the enter button.
  final VoidCallback? onTap;

  /// The action running right now is this card's: it is ringed in the
  /// accent and a thin bar along its foot fills with each action, as an
  /// active place tile is.
  final bool active;

  /// Draws one of [entities] in the row, e.g. as a discovery tile that
  /// opens its details.
  final Widget Function(EncounterEntity entity) entityTileBuilder;

  /// The gap between tiles, matching the places grid's.
  static const double _tileGap = PlaceGrid.gap;

  /// The enter button is smaller than the action bar's, but built from the
  /// same [RaisedSurface], so it reads as the same kind of control.
  static const double _playButtonHeight = 38;
  static const double _playButtonWidth = 64;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locked = lockReason != null;
    // the button is an affordance, not its own target: it has no gesture of
    // its own, so a tap on it lands on the card's InkWell like any other
    final startable = !locked && onTap != null;

    final palette = context.palette;
    final card = Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: active
            ? BorderSide(color: palette.accent, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cleared) ...[
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: scheme.primary,
                        ),
                        if (startable) const SizedBox(width: 10),
                      ],
                      // the same face the action bar's primary button wears, so
                      // a card reads as the thing that starts an action rather
                      // than as another screen to drill into
                      if (startable)
                        // RaisedSurface stacks a face over a base, so it needs a
                        // bounded width — the action bar gives it one with an
                        // Expanded; here it is a fixed key
                        SizedBox(
                          width: _playButtonWidth,
                          child: RaisedSurface(
                            pressed: false,
                            height: _playButtonHeight,
                            depth: 4,
                            radius: 12,
                            color: scheme.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            // entering, not starting: the card opens the floor,
                            // and the fight starts on its screen
                            child: const Center(
                              child: Icon(Icons.login, size: 22),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (stats != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      stats!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (note != null) ...[const SizedBox(height: 6), note!],
                  const SizedBox(height: 8),
                  // tiles a third of the card wide, as in the places grid, so
                  // they read the same here as on the zone; a longer floor
                  // scrolls sideways rather than wrapping
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          (constraints.maxWidth -
                              _tileGap * (PlaceGrid.columns - 1)) /
                          PlaceGrid.columns;
                      final row = SizedBox(
                        height: PlaceTile.height,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: entities.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: _tileGap),
                          itemBuilder: (_, i) => SizedBox(
                            width: width,
                            child: entityTileBuilder(entities[i]),
                          ),
                        ),
                      );
                      if (!locked) return row;
                      // sealed: the row blurred past reading and shut to taps, as
                      // an undiscovered tile is, with why it is shut laid over it
                      return Stack(
                        children: [
                          IgnorePointer(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 7,
                                sigmaY: 7,
                              ),
                              child: row,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: _LockBadge(reason: lockReason!),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // in the card's own padding, so starting a floor doesn't
            // grow the card and shift the list under the player's thumb
            if (active)
              const Positioned(
                left: 18,
                right: 18,
                bottom: 4,
                child: ActiveProgressBar(key: ValueKey('queue-card-progress')),
              ),
          ],
        ),
      ),
    );

    return card;
  }
}

/// The lock and the reason a card is shut, on a wash that reads over the
/// blurred row — the same badge an undiscovered tile wears.
class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderOverArt),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 18, color: palette.text),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HearthText.rowMeta.copyWith(
                fontSize: 13,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
