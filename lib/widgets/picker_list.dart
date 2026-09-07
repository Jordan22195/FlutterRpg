import 'package:flutter/material.dart';

/// The list of rows a picker dialog offers, opened centred on the row that is
/// already in play.
///
/// A picker that always opens at the top makes the player hunt for their own
/// selection, and the further down the list it sits the worse that gets — a
/// smith picking between forty recipes opens the dialog on the first four of
/// them every time. Centring costs nothing and answers "what am I making?"
/// before the player has scrolled anywhere.
///
/// Every row is [rowExtent] tall, which is what lets the list place the
/// selected one by arithmetic rather than by measuring a widget that has not
/// been built yet: a lazy list has no idea where its thirtieth row is until
/// something scrolls near it.
class PickerList extends StatefulWidget {
  const PickerList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.selectedIndex,
    this.rowExtent = defaultRowExtent,
  });

  /// What one picker row occupies: a 68 high card, plus the 4 of [Card]
  /// margin above and below it. Every card the pickers list is built to that
  /// height — the recipe cards and the enchanting tiers alike.
  static const double defaultRowExtent = 76;

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// The row to open centred on. Negative when nothing is selected yet, which
  /// opens the list at the top.
  final int selectedIndex;

  final double rowExtent;

  @override
  State<PickerList> createState() => _PickerListState();
}

class _PickerListState extends State<PickerList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // after the first layout rather than through initialScrollOffset: the
    // offset depends on how tall the viewport turned out to be, and inside a
    // dialog that is not known until the dialog has sized its content. the
    // jump lands on the frame the dialog is still fading in on.
    WidgetsBinding.instance.addPostFrameCallback((_) => _centreOnSelection());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centreOnSelection() {
    if (!mounted || widget.selectedIndex < 0) return;
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final centre =
        widget.selectedIndex * widget.rowExtent +
        widget.rowExtent / 2 -
        position.viewportDimension / 2;
    // a list too short to scroll, or a selection near either end, simply
    // opens as far that way as it goes
    _controller.jumpTo(
      centre.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      shrinkWrap: true,
      itemExtent: widget.rowExtent,
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }
}
