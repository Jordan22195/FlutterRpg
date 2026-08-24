import 'package:flutter/material.dart';

/// The chrome an info body is built from: a labelled section and a
/// label/value line. Shared by the entity details body and the bench
/// panel's recipe info, so the two read as the same kind of page.

/// A percentage, to one decimal: `12.5%`.
String formatPercent(double value) => '${(value * 100).toStringAsFixed(1)}%';

/// A number, to one decimal.
String formatDecimal(double value) => value.toStringAsFixed(1);

class InfoSection extends StatelessWidget {
  const InfoSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class InfoStatRow extends StatelessWidget {
  const InfoStatRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
