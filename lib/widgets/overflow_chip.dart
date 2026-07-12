import 'package:flutter/material.dart';

/// "+N" chip appended to a capped tile row (skill rings, buffs) when the
/// row has more items than it shows. Tapping opens the row's full list.
class OverflowChip extends StatelessWidget {
  const OverflowChip({
    super.key,
    required this.count,
    required this.onTap,
    this.size = 48,
    this.shape = BoxShape.rectangle,
  });

  final int count;
  final VoidCallback onTap;
  final double size;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(
      shape == BoxShape.circle ? size : 10,
    );

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? radius : null,
          border: Border.all(color: scheme.outline.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          '+$count',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
