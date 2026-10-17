import 'package:flutter/material.dart';

import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';

/// The box every place and entity row sits in: the palette's surface with a
/// 1px border and 16 radius, the sprite on the left, title over a meta line,
/// and whatever the row ends with on the right.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    required this.meta,
    this.trailing,
    this.onTap,
    this.height = placeHeight,
    this.overlay,
  });

  /// Places are 64 tall, entities 68.
  static const double placeHeight = 64;
  static const double entityHeight = 68;

  final Widget leading;
  final String title;

  /// The line under the title, usually a [RowMeta].
  final Widget meta;

  /// A chevron, an xp column, a countdown.
  final Widget? trailing;
  final VoidCallback? onTap;
  final double height;

  /// Painted over the whole row, under the ink — e.g. a flash on a find.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: palette.border),
    );

    return Material(
      color: palette.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              if (overlay != null)
                Positioned.fill(child: IgnorePointer(child: overlay!)),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 14),
                child: Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HearthText.rowTitle.copyWith(
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          meta,
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row's meta line: optional small icons, then text in the muted colour
/// ("Fishing · Lv 1", "Lv 3 · 1.57k").
class RowMeta extends StatelessWidget {
  const RowMeta({super.key, required this.text, this.icons = const []});

  final String text;
  final List<Widget> icons;

  @override
  Widget build(BuildContext context) {
    final style = HearthText.rowMeta.copyWith(color: context.palette.textMuted);
    return Row(
      children: [
        for (final icon in icons) ...[icon, const SizedBox(width: 4)],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// The chevron that ends a place row.
class RowChevron extends StatelessWidget {
  const RowChevron({super.key, this.dimmed = false});

  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.chevron;
    return Icon(
      Icons.chevron_right,
      size: 18,
      color: dimmed ? color.withValues(alpha: 0.5) : color,
    );
  }
}

/// A list heading such as "PLACES".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: HearthText.sectionLabel.copyWith(color: context.palette.textMuted),
    );
  }
}
