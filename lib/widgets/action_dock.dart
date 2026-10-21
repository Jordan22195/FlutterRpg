import 'package:flutter/material.dart';

import '../theme/hearth_theme.dart';

/// The controls fixed to the bottom of an action screen: an optional row
/// (the zone's progress and rings, combat's style switch) over the button
/// row — with an optional banner such as the travel row above both — on the
/// palette's background with a divider along the top.
///
/// A short fade rises above it, so the list scrolling underneath melts into
/// the dock rather than being cut off by it. The fade is painted outside the
/// dock's own box, over whatever sits above it, and takes no touches.
class ActionDock extends StatelessWidget {
  const ActionDock({
    super.key,
    this.banner,
    this.topRow,
    required this.buttons,
  });

  /// A row above everything else, sized to itself — e.g. the road to a zone
  /// the player is not standing in, on a screen with no progress row of its
  /// own to give up for it.
  final Widget? banner;

  /// 44 tall when present.
  final Widget? topRow;

  /// Usually an `ActionButtonRow` with zero padding.
  final Widget buttons;

  static const double fadeHeight = 28;
  static const double topRowHeight = 44;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: -fadeHeight,
          height: fadeHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.bg.withValues(alpha: 0), palette.bg],
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.bg,
            border: Border(top: BorderSide(color: palette.divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (banner != null) ...[banner!, const SizedBox(height: 12)],
                if (topRow != null) ...[
                  SizedBox(height: topRowHeight, child: topRow),
                  const SizedBox(height: 12),
                ],
                buttons,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
