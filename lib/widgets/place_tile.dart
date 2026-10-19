import 'package:flutter/material.dart';

import '../catalogs/entities/entities.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../utilities/image_resolver.dart';
import 'item_stack_tile.dart';
import 'sprite_frame.dart';

/// One of a zone's places, as a tile in the places grid: the place's sprite
/// in a frame tinted by what kind of place it is, its name, and a short
/// line saying what it is for ("Fishing · Lv 1", "Smithing"). The whole
/// tile is the tap target.
class PlaceTile extends StatelessWidget {
  const PlaceTile({
    super.key,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.subtitleIcon,
    required this.kind,
    required this.onTap,
    this.fallbackIcon = Icons.help_outline,
    this.locked = false,
    this.corner,
  });

  /// The sprite shown; usually the place's own entity id, or what is
  /// burning in it.
  final Enum id;
  final String name;
  final String subtitle;
  final IconData subtitleIcon;
  final SpriteKind kind;
  final VoidCallback onTap;

  /// Drawn in place of a sprite the art for which hasn't been made yet.
  final IconData fallbackIcon;

  /// Gated above the player's level: the tile dims and its subtitle wears a
  /// lock in place of its icon.
  final bool locked;

  /// Laid over the sprite frame's top-right corner, e.g. a fire's burn time.
  final Widget? corner;

  static const double height = 120;
  static const double _frameWidth = 64;
  static const double _frameHeight = 56;

  /// The subtitle as a screen reader should say it: "Fishing level 1".
  static String spoken(String subtitle) =>
      subtitle.replaceAll(' · Lv ', ' level ').replaceAll(' · ', ', ');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = SpriteFrame.tintFor(context, kind);
    final currentId = id;
    // a dungeon is outlined in its rarity, 2px, as it was as a card
    final rarity = kind == SpriteKind.dungeon && currentId is EntityId
        ? rarityBorderColor(currentId.definition.rarity)
        : null;

    final image = EnumImageProviderLookup.resolveDynamic(id);
    final fallback = Icon(fallbackIcon, size: 28, color: palette.textMuted);

    final frame = Container(
      width: _frameWidth,
      height: _frameHeight,
      decoration: BoxDecoration(
        color: tint.fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rarity ?? tint.border,
          width: rarity != null ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 52,
        height: 44,
        child: image == null
            ? fallback
            : Image(
                image: image,
                fit: BoxFit.contain,
                // pixel art: smoothing would blur it
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );

    final muted = palette.textMuted;
    final tile = Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    frame,
                    if (corner != null)
                      Positioned(top: -6, right: -10, child: corner!),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  // the frame and two gaps leave 32pt for both lines, so
                  // they run at a tight 1.1 leading rather than the default
                  style: HearthText.rowTitle.copyWith(
                    fontSize: 15,
                    height: 1.1,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      locked ? Icons.lock_outline : subtitleIcon,
                      size: 12,
                      color: muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HearthText.rowMeta.copyWith(
                          fontSize: 12,
                          height: 1.1,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: [name, spoken(subtitle), if (locked) 'locked'].join(', '),
      excludeSemantics: true,
      child: locked ? Opacity(opacity: 0.55, child: tile) : tile,
    );
  }
}

/// The places as a grid of [PlaceTile]s: three equal columns, 10 apart both
/// ways, filling left to right. A short last row stays left-aligned. It
/// never scrolls on its own; the page around it does.
class PlaceGrid extends StatelessWidget {
  const PlaceGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  static const int columns = 3;
  static const double gap = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}
