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

/// One line of an [InfoTable]: a label and one value per column.
class InfoTableRow {
  const InfoTableRow(this.label, this.values);

  final String label;

  /// One entry per column, in the order [InfoTable.headers] gives them.
  /// Use [InfoTable.blank] where a row has nothing to say for a column.
  final List<String> values;
}

/// A label column plus one or more value columns under their own headings.
///
/// What [InfoStatRow] can't do: put two sides of the same quantity on one
/// line. The player's hit chance and the entity's are the same measurement
/// and are read against each other, which is a column apart rather than
/// twenty rows apart.
class InfoTable extends StatelessWidget {
  const InfoTable({super.key, required this.headers, required this.rows});

  /// Headings for the value columns. All-empty drops the heading row, for a
  /// one-sided table that has nothing to distinguish.
  final List<String> headers;

  final List<InfoTableRow> rows;

  /// The stand-in for a cell a row doesn't measure — an en dash, so the
  /// column still reads as a column.
  static const String blank = '–';

  /// Wide enough for a percentage at this text size.
  static const double _columnWidth = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final showHeaders = headers.any((h) => h.isNotEmpty);

    return Table(
      columnWidths: {
        0: const FlexColumnWidth(),
        for (var i = 0; i < headers.length; i++)
          i + 1: const FixedColumnWidth(_columnWidth),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        if (showHeaders)
          TableRow(
            children: [
              const SizedBox.shrink(),
              for (final header in headers)
                _cell(
                  header.toUpperCase(),
                  theme.textTheme.labelSmall?.copyWith(
                    color: onSurface.withOpacity(0.5),
                    letterSpacing: 0.8,
                  ),
                ),
            ],
          ),
        for (final row in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  row.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              for (final value in row.values)
                _cell(
                  value,
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// A value cell: right-aligned, so a column of numbers stays readable,
  /// and clipped rather than wrapped so one long entity name can't set the
  /// height of every row above it.
  Widget _cell(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
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
