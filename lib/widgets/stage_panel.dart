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
  final VoidCallback? onTap;

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
            color: outline ?? tint.border,
            width: outline != null ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(child: sprite),
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

/// How many are left, in the corner of a stage panel: the number only.
class StageCountPill extends StatelessWidget {
  const StageCountPill({
    super.key,
    required this.count,
    required this.borderColor,
  });

  final int count;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: '$count left',
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
          Util.formatShortCount(count),
          style: HearthText.timer.copyWith(fontSize: 14, color: palette.text),
        ),
      ),
    );
  }
}
