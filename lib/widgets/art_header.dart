import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'status_row.dart';

/// The zone's art with the status row over its top and the title row over
/// its foot. [collapse] runs from 0 (open: the art fills 360pt from the very
/// top of the screen and melts into the page) to 1 (a strip under a heavy
/// scrim, the status row and title stacked on it).
///
/// The zone screen drives [collapse] from its scroll; combat and crafting
/// screens sit at 1 for good.
class ArtHeader extends StatelessWidget {
  const ArtHeader({
    super.key,
    required this.title,
    required this.collapse,
    this.artAsset,
    this.subtitle,
    this.trailing,
    this.backLabel = 'Back',
  });

  final String title;

  /// 0 open, 1 collapsed.
  final double collapse;

  /// The art behind the header; null draws the plain background.
  final String? artAsset;

  /// A line under the title, e.g. the zone a combat screen is in.
  final String? subtitle;

  /// The chip on the right of the title row.
  final Widget? trailing;

  /// What the back button says to a screen reader.
  final String backLabel;

  /// The open header's height, safe area included.
  static const double expandedHeight = 360;

  /// The status row, the title row, and 8 above and below the title.
  static const double _collapsedBody =
      StatusRow.height + _titleRowHeight + 2 * _collapsedTitleGap;

  static const double _titleRowHeight = 48;
  static const double _collapsedTitleGap = 8;
  static const double _expandedTitleGap = 24;
  static const double _scrimHeight = 150;

  /// The collapsed header's height under a top safe area of [topPadding]:
  /// 166 on a phone with a 54pt inset.
  static double collapsedHeight(double topPadding) =>
      topPadding + _collapsedBody;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final t = collapse.clamp(0.0, 1.0);
    final topPadding = MediaQuery.paddingOf(context).top;
    final bg = palette.bg;

    LinearGradient vertical(List<Color> colors, List<double> stops) =>
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        );

    return ColoredBox(
      color: bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (artAsset != null)
            Image.asset(
              artAsset!,
              fit: BoxFit.cover,
              // the crop slides down the picture as the header closes, so
              // the strip shows the middle of the scene rather than the sky
              alignment: Alignment(0, lerpDouble(0.1, 0.45, t)!),
              // zone art is pixel art; smoothing it blurs the pixels
              filterQuality: FilterQuality.none,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),

          // open: a scrim at each end, so the status row reads over the art
          // and the art melts into the page
          IgnorePointer(
            child: Opacity(
              opacity: 1 - t,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: _scrimHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: vertical(
                          [
                            bg.withValues(alpha: 0.92),
                            bg.withValues(alpha: 0.7),
                            bg.withValues(alpha: 0),
                          ],
                          const [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _scrimHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: vertical(
                          [
                            bg.withValues(alpha: 0),
                            bg.withValues(alpha: 0.75),
                            bg,
                          ],
                          const [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // collapsed: one heavy scrim over the strip and a divider under it
          IgnorePointer(
            child: Opacity(
              opacity: t,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: vertical(
                    [
                      bg.withValues(alpha: 0.94),
                      bg.withValues(alpha: 0.88),
                      bg.withValues(alpha: 0.45),
                    ],
                    const [0, 0.6, 1],
                  ),
                  border: Border(bottom: BorderSide(color: palette.divider)),
                ),
              ),
            ),
          ),

          // the status row stays put under the safe area however far the
          // header closes
          Positioned(
            left: 16,
            right: 16,
            top: topPadding,
            child: const StatusRow(),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: lerpDouble(_expandedTitleGap, _collapsedTitleGap, t)!,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _titleRowHeight),
              child: Row(
                children: [
                  _BackButton(label: backLabel),
                  const SizedBox(width: 12),
                  Expanded(child: _title(context, t)),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(BuildContext context, double t) {
    final palette = context.palette;
    final titleText = Text(
      title,
      // open, a long name may take two lines at 30pt; closed, one line
      maxLines: t < 0.5 ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: HearthText.title.copyWith(
        fontSize: lerpDouble(30, 24, t),
        color: palette.text,
        shadows: [
          Shadow(offset: const Offset(0, 2), color: palette.titleShadow),
        ],
      ),
    );
    if (subtitle == null) return titleText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        Text(
          subtitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HearthText.rowMeta.copyWith(
            fontSize: 12,
            color: palette.textSubtitle,
          ),
        ),
      ],
    );
  }
}

/// 44pt square on a translucent wash, so it reads over the art.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton(
      tooltip: label,
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back, size: 22),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        foregroundColor: palette.text,
        backgroundColor: palette.bg.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// A 32pt pill on the art's title row: an icon and a short value, such as
/// the zone's exploration level.
class ArtHeaderChip extends StatelessWidget {
  const ArtHeaderChip({
    super.key,
    this.icon,
    required this.label,
    this.semanticsLabel,
  });

  final Widget? icon;
  final String label;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: palette.bg.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.borderOverArt),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 6)],
            Text(
              label,
              style: HearthText.statusStat.copyWith(
                fontSize: 15,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
