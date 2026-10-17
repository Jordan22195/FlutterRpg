import 'package:flutter/material.dart';

import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';

/// A filter chip: the active one is filled with the text colour, the rest
/// sit on the surface with a border and their count in the muted colour.
class HearthChip extends StatelessWidget {
  const HearthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Shown after the label, e.g. "Combat 6,082".
  final int? count;
  final Widget? icon;

  static const double height = 44;

  static String _grouped(int n) {
    final text = '$n';
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = selected ? palette.bg : palette.text;
    final countColor = selected ? palette.bg : palette.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? palette.text : palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? palette.text : palette.borderStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: (selected ? HearthText.chipActive : HearthText.chip)
                    .copyWith(color: fg),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  _grouped(count!),
                  style: HearthText.chip.copyWith(color: countColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
