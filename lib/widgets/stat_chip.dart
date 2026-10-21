import 'package:flutter/material.dart';

/// Delta colors for stat comparisons: green = better than what's
/// equipped, red = worse.
const Color statGainColor = Color(0xFF7EE0A6);
const Color statLossColor = Color(0xFFEF8F8F);

/// Compact icon + value pill for one equipment stat, optionally
/// followed by a colored delta (e.g. "+4" / "−2") vs. the equipped item.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    this.deltaText,
    this.deltaColor,
    this.fontSize = 12,
  });

  final Widget icon;
  final String value;
  final String? deltaText;
  final Color? deltaColor;

  /// 12 for the compact chips in lists; the equipment details set it larger.
  /// The padding and gaps grow with it.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize / 2,
        vertical: fontSize / 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(fontSize / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: fontSize / 4),
          Text(value, style: TextStyle(fontSize: fontSize)),
          if (deltaText != null) ...[
            SizedBox(width: fontSize / 3),
            Text(
              deltaText!,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: deltaColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
