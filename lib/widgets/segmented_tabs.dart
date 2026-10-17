import 'package:flutter/material.dart';

import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';

/// One segment of a [SegmentedTabs].
class TabSegment<T> {
  const TabSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;

  /// Drawn before the label, e.g. the combat style switch's swords.
  final Widget? icon;
}

/// A row of equal-width segments in a sunken container, the selected one on
/// a raised pill. The zone, combat and crafting tabs all use it, and so does
/// the combat style switch.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 48,
  });

  final List<TabSegment<T>> segments;

  /// The raised segment; null raises none.
  final T? selected;
  final ValueChanged<T> onChanged;

  /// 48 for tab bars, 44 for the combat style switch.
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // four segments share the same width as three, so their labels step down
    final fontSize = segments.length > 3 ? 14.0 : 15.0;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _Segment<T>(
                segment: segments[i],
                selected: segments[i].value == selected,
                fontSize: fontSize,
                onTap: () => onChanged(segments[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.fontSize,
    required this.onTap,
  });

  final TabSegment<T> segment;
  final bool selected;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = (selected ? HearthText.tabActive : HearthText.tab).copyWith(
      fontSize: fontSize,
      color: selected ? palette.text : palette.textMuted,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? palette.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                segment.icon!,
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
