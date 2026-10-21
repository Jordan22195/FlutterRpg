import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/entities/entities.dart';
import '../controllers/action_timing_controller.dart';
import '../data/level_standing.dart';
import '../data/skill_data.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../utilities/image_resolver.dart';
import 'fill_bar.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';
import 'progress_bars.dart';
import 'sprite_frame.dart';

/// One of a zone's places or discoveries, as a tile in a 3-column grid: the
/// sprite in a frame tinted by what kind of thing it is, its name, and a
/// short line saying what it is ("Fishing · Lv 1", "Smithing", "Lv 3 · 43").
/// The whole tile is the tap target; a long press can open its details.
class PlaceTile extends StatelessWidget {
  const PlaceTile({
    super.key,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.kind,
    required this.onTap,
    this.subtitleIcon,
    this.onLongPress,
    this.fallbackIcon = Icons.help_outline,
    this.locked = false,
    this.dimmed = false,
    this.corner,
    this.semanticsLabel,
    this.subtitleRow,
    this.spriteScale = 1,
    this.active = false,
  });

  /// The sprite shown; usually the place's own entity id, or what is
  /// burning in it.
  final Enum id;
  final String name;
  final String subtitle;

  /// Before the subtitle; none when the line speaks for itself.
  final IconData? subtitleIcon;
  final SpriteKind kind;
  final VoidCallback? onTap;

  /// E.g. a discovery's details popup.
  final VoidCallback? onLongPress;

  /// Drawn in place of a sprite the art for which hasn't been made yet.
  final IconData fallbackIcon;

  /// Gated above the player's level: the tile dims and its subtitle wears a
  /// lock in place of its icon.
  final bool locked;

  /// Spent, like a node with nothing left: the tile dims, with no lock.
  final bool dimmed;

  /// Overrides the label read out, which is otherwise the name and the
  /// subtitle as spoken.
  final String? semanticsLabel;

  /// Drawn in place of the subtitle line when the line is more than an
  /// icon and words — a discovery's level beside its skill and its count in
  /// a chip. [subtitle] is still what a screen reader hears.
  final Widget? subtitleRow;

  /// How far the sprite is zoomed past fitting its frame — a creature's
  /// art carries a margin a place's does not, so discoveries sit closer.
  /// Clipped to the frame either way.
  final double spriteScale;

  /// Laid over the sprite frame's top-right corner, e.g. a fire's burn time.
  final Widget? corner;

  /// The action running right now is this place's: the tile is ringed in
  /// the accent and a thin bar along its foot fills with each action, so
  /// the thing being worked stands out from the grid it sits in.
  final bool active;

  static const double height = 120;
  static const double _frameWidth = 64;
  static const double _frameHeight = 56;

  /// The sprite's box inside the frame, before [spriteScale].
  static const double _spriteWidth = 57.2;
  static const double _spriteHeight = 48.4;

  /// The subtitle as a screen reader should say it: "Fishing level 1".
  static String spoken(String subtitle) =>
      subtitle.replaceAll(' · Lv ', ' level ').replaceAll(' · ', ', ');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = SpriteFrame.tintFor(context, kind);
    final currentId = id;
    // an entity rarer than common — a dungeon, a rare creature — is
    // outlined in its rarity, 2px, as its stack tile was
    final rarity = currentId is EntityId
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
      // the frame's own radius, less its border, so a zoomed sprite is cut
      // at the frame's edge rather than spilling over it
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        // the clip spans the whole frame, so a zoomed sprite fills it to
        // the border before it is cut
        child: SizedBox.expand(
          child: Center(
            child: Transform.scale(
              scale: spriteScale,
              child: SizedBox(
                width: _spriteWidth,
                height: _spriteHeight,
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
            ),
          ),
        ),
      ),
    );

    final muted = palette.textMuted;
    final tile = Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: active
            ? BorderSide(color: palette.accent, width: 2)
            : BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
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
                    // a custom line runs taller than the text one, so the gaps
                    // around the name give it back to fit the tile
                    SizedBox(height: subtitleRow != null ? 5 : 6),
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
                    SizedBox(height: subtitleRow != null ? 4 : 6),
                    if (subtitleRow != null)
                      SizedBox(height: 18, child: subtitleRow)
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (locked || subtitleIcon != null) ...[
                            Icon(
                              locked ? Icons.lock_outline : subtitleIcon,
                              size: 12,
                              color: muted,
                            ),
                            const SizedBox(width: 4),
                          ],
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
              if (active)
                const Positioned(
                  left: 18,
                  right: 18,
                  bottom: 5,
                  child: ActiveProgressBar(
                    key: ValueKey('place-tile-progress'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label:
          semanticsLabel ??
          [
            name,
            spoken(subtitle),
            if (locked) 'locked',
            if (active) 'active',
          ].join(', '),
      excludeSemantics: true,
      child: locked || dimmed ? Opacity(opacity: 0.55, child: tile) : tile,
    );
  }
}

/// How far through its action the thing being worked is: a thin accent bar
/// along the foot of an active tile or dungeon floor card. Ticks off the
/// action loop on its own, so the grid or list around it isn't rebuilt
/// every frame.
class ActiveProgressBar extends StatelessWidget {
  const ActiveProgressBar({super.key});

  static const double _height = 3;

  @override
  Widget build(BuildContext context) {
    final timing = context.read<ActionTimingController>();
    final palette = context.palette;
    return AnimatedBuilder(
      animation: timing,
      builder: (_, _) => FillBar(
        value: timing.actionProgress,
        height: _height,
        borderRadius: _height / 2,
        backgroundColor: palette.track,
        foregroundColor: palette.accent,
      ),
    );
  }
}

/// Places or discoveries as a grid of [PlaceTile]s: three equal columns, 10 apart both
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

/// The line under a tile's name: the sprites of the skills it is worked
/// with, then — when there is one — the level it is fought at or asks for,
/// and how many are standing.
class PlaceLine extends StatelessWidget {
  const PlaceLine({
    super.key,
    required this.skills,
    this.level,
    this.count,
    this.standing = LevelStanding.even,
  });

  final List<SkillId> skills;
  final int? level;
  final int? count;

  /// Colours the level: red well above the player, yellow about even,
  /// green well below.
  final LevelStanding standing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final level = this.level;
    final count = this.count;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final skill in skills) ...[
          if (skill != skills.first) const SizedBox(width: 4),
          IconRenderer(id: skill, size: 14),
        ],
        if (level != null) ...[
          const SizedBox(width: 3),
          Text(
            '$level',
            style: HearthText.rowMeta.copyWith(
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: switch (standing) {
                LevelStanding.hard => context.gameColors.levelHard,
                LevelStanding.even => context.gameColors.levelEven,
                LevelStanding.easy => context.gameColors.levelEasy,
              },
            ),
          ),
        ],
        if (count != null) ...[
          const SizedBox(width: 8),
          CountPill(
            count: count,
            borderColor: palette.borderStrong,
            height: 18,
            fontSize: 12,
          ),
        ],
      ],
    );
  }
}
