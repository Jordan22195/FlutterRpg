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
  });

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: tint.fill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBoss ? GameColors.bossFrame : outline ?? tint.border,
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
            Align(
              alignment: heading == null
                  ? Alignment.center
                  : const Alignment(0.3, 0.4),
              child: sprite,
            ),
            if (heading != null)
              Positioned(left: 14, top: 12, child: heading!),
            if (leading != null)
              Positioned(left: 10, top: 10, bottom: 10, child: leading!),
            if (corner != null)
              Positioned(right: 12, bottom: 12, child: corner!),
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
