import 'package:flutter/material.dart';

import '../catalogs/entity_catalog.dart';
import 'item_stack_tile.dart';
import 'primary_button.dart';

/// One card in a list of ordered content: a named run of entities, shown as
/// the stack tiles you will work through, left to right.
///
/// Deliberately knows nothing about dungeons — it takes entities, a title,
/// and a lock reason, so any "do these in order" list can use it.
///
/// The tiles stay tappable while the card is locked: previewing what a
/// sealed card holds, and what it drops, is the whole reason the contents
/// are entities rather than a summary line.
class EntityQueueCard extends StatelessWidget {
  const EntityQueueCard({
    super.key,
    required this.title,
    required this.entities,
    this.cleared = false,
    this.lockReason,
    this.note,
    this.onTap,
    this.onEntityTap,
  });

  final String title;
  final List<EncounterEntity> entities;

  /// Fully worked through. A cleared card can still be tappable — that is
  /// how repeatable content is farmed.
  final bool cleared;

  /// Why this card can't be started, or null when it can. Non-null dims the
  /// card and renders the reason under the title.
  final String? lockReason;

  /// Anything else this card has to say about itself, under the title — a
  /// dungeon uses it for the entry key it is about to charge.
  final Widget? note;

  /// Starts the card. Null means it can't be started at all (a one-shot
  /// card already cleared), which also drops the play button.
  final VoidCallback? onTap;

  /// Tapping one of the entity tiles, for its details popup.
  final void Function(EncounterEntity entity)? onEntityTap;

  /// The play button is smaller than the action bar's, but built from the
  /// same [RaisedSurface], so it reads as the same control.
  static const double _playButtonHeight = 38;
  static const double _playButtonWidth = 64;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locked = lockReason != null;
    // the button is an affordance, not its own target: it has no gesture of
    // its own, so a tap on it lands on the card's InkWell like any other
    final startable = !locked && onTap != null;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
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
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
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
                        child: const Center(
                          child: Icon(Icons.play_arrow, size: 22),
                        ),
                      ),
                    ),
                ],
              ),
              if (locked) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        lockReason!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (note != null) ...[const SizedBox(height: 6), note!],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entity in entities)
                    ItemStackTile(
                      size: 44,
                      count: entity.count,
                      id: entity.id,
                      // the tile resolves a details popup only for items;
                      // an entity's popup has to be passed in
                      showInfoDialogOnTap: false,
                      onTap: onEntityTap == null
                          ? null
                          : () => onEntityTap!(entity),
                      depleted: entity.count <= 0,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return locked ? Opacity(opacity: 0.55, child: card) : card;
  }
}
