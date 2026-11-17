import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../utilities/util.dart';

/// The big tinted panel the subject of a combat or crafting screen stands
/// in: the same tints as the sprite frames, at radius 20, with the sprite
/// centred.
class StagePanel extends StatelessWidget {
  const StagePanel({
    super.key,
    required this.tint,
    required this.sprite,
    this.height = 164,
    this.corner,
    this.leading,
    this.onTap,
    this.outline,
    this.heading,
    this.isBoss = false,
    this.hit,
    this.footer,
    this.footerRightInset = 0,
    this.footerHeight = 0,
    this.banner,
    this.bannerHeight = 0,
    this.side,
    this.spotlight,
  });

  /// Lights the subject in a pool of this colour on a clear panel, with a
  /// shadow at its feet, in place of the tinted fill — for a stage standing
  /// over the zone's art, where a solid box would hide the place.
  final Color? spotlight;

  /// Pinned down the right edge from the top, between any [banner] and a
  /// [footer] with a [footerHeight], e.g. a fire's burn levels.
  final Widget? side;

  /// Pinned across the top edge, e.g. the reagent buffs burning on a fire.
  /// The sprite and [leading] stand below its [bannerHeight].
  final Widget? banner;
  final double bannerHeight;

  /// Pinned along the bottom edge from the left, e.g. a fire's fuel gauge.
  /// [footerRightInset] keeps it clear of [corner]. A [footerHeight] keeps
  /// the sprite and [leading] above it; without one it floats over them.
  final Widget? footer;
  final double footerRightInset;
  final double footerHeight;

  /// The last hit on the subject, floated up beside the sprite — clear of
  /// every bar, where the eye already is.
  final Widget? hit;

  final SpriteTint tint;

  /// Drawn 2px in place of the tint's border — the subject's rarity, as its
  /// tile on the zone and its frame in a queue are outlined. Null keeps the
  /// tint's own 1px border.
  final Color? outline;
  final Widget sprite;
  final double height;

  /// Pinned to the bottom-right corner, e.g. a [StageCountPill].
  final Widget? corner;

  /// Pinned down the left edge, e.g. a dungeon's queue.
  final Widget? leading;

  /// Pinned to the top-left corner, e.g. a dungeon member's name and
  /// level. With one, the sprite stands a little right of centre so the
  /// two don't meet.
  final Widget? heading;

  /// A dungeon boss: the panel wears the boss's gold frame — 2px of
  /// [GameColors.bossFrame] with a 2px dark line inside it — over any
  /// [outline].
  final bool isBoss;
  final VoidCallback? onTap;

  static const double _bossBorder = 2;

  Color get _lit => Color.lerp(spotlight, Colors.white, 0.3)!;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: spotlight == null ? tint.fill : null,
          // the pool is lifted toward white, so it reads as light even over
          // a backdrop of the same colour
          gradient: spotlight == null
              ? null
              : RadialGradient(
                  center: const Alignment(0, 0.1),
                  radius: 0.75,
                  colors: [
                    _lit.withValues(alpha: 0.7),
                    _lit.withValues(alpha: 0.22),
                    _lit.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.55, 1],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBoss
                ? GameColors.bossFrame
                : outline ??
                      (spotlight == null ? tint.border : Colors.transparent),
            width: isBoss || outline != null ? _bossBorder : 1,
          ),
        ),
        foregroundDecoration: isBoss
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20 - _bossBorder),
                border: Border.all(
                  color: GameColors.bossFrameInner,
                  width: _bossBorder,
                ),
              )
            : null,
        child: Stack(
          children: [
            // under a spotlight the subject stands on the ground: a soft
            // shadow at its feet
            if (spotlight != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Center(
                  child: Container(
                    width: 104,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(52, 8),
                      ),
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            // with a banner the sprite is centred in the room left under it
            Positioned.fill(
              top: banner == null ? 0 : 10 + bannerHeight,
              bottom: footer == null || footerHeight <= 0
                  ? 0
                  : 10 + footerHeight,
              child: Align(
                alignment: heading == null
                    ? Alignment.center
                    : const Alignment(0.3, 0.4),
                child: sprite,
              ),
            ),
            if (banner != null)
              Positioned(left: 12, right: 12, top: 10, child: banner!),
            if (heading != null) Positioned(left: 14, top: 12, child: heading!),
            if (leading != null)
              Positioned(
                left: 10,
                top: banner == null ? 10 : 16 + bannerHeight,
                bottom: footer == null || footerHeight <= 0
                    ? 10
                    : 16 + footerHeight,
                child: leading!,
              ),
            if (footer != null)
              Positioned(
                left: 10,
                right: 12 + footerRightInset,
                bottom: 10,
                child: footer!,
              ),
            if (side != null)
              Positioned(
                right: 12,
                top: 10,
                bottom: footer == null || footerHeight <= 0
                    ? 10
                    : 16 + footerHeight,
                child: side!,
              ),
            if (corner != null)
              Positioned(right: 12, bottom: 12, child: corner!),
            if (hit != null)
              Align(
                // up and to the right of the sprite, wherever it stands
                alignment: heading == null
                    ? const Alignment(0.55, -0.35)
                    : const Alignment(0.85, -0.3),
                child: IgnorePointer(child: hit!),
              ),
          ],
        ),
      ),
    );
  }
}

/// How many are left, in the corner of a stage panel: the number only,
/// unless a [label] says it in words ("3 of 10 left", "Boss").
class StageCountPill extends StatelessWidget {
  const StageCountPill({
    super.key,
    required this.count,
    required this.borderColor,
    this.label,
    this.color,
  });

  final int count;
  final Color borderColor;

  /// Shown in place of the bare count.
  final String? label;

  /// The text colour; the palette's text by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: label ?? '$count left',
      excludeSemantics: true,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: palette.bg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          label ?? Util.formatShortCount(count),
          style: HearthText.timer.copyWith(
            fontSize: label == null ? 14 : 13,
            color: color ?? palette.text,
          ),
        ),
      ),
    );
  }
}
