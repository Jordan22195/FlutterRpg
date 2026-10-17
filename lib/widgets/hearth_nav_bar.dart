import 'package:flutter/material.dart';

import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';

/// One destination on the [HearthNavBar].
class HearthNavItem {
  const HearthNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The bottom navigation: equal-width items over a 1px divider. The active
/// item sits on a raised pill with its label in full text colour; the rest
/// are quieter.
class HearthNavBar extends StatelessWidget {
  const HearthNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<HearthNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// The bar's height above the bottom safe area.
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final HearthNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.text : palette.textNavInactive;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? palette.raised : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (selected ? HearthText.navLabelActive : HearthText.navLabel)
                      .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
