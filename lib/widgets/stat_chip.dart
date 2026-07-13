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
  });

  final Widget icon;
  final String value;
  final String? deltaText;
  final Color? deltaColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 3),
          Text(value, style: const TextStyle(fontSize: 12)),
          if (deltaText != null) ...[
            const SizedBox(width: 4),
            Text(
              deltaText!,
              style: TextStyle(
                fontSize: 12,
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
