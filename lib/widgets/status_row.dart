import 'package:flutter/material.dart';

import 'progress_bars.dart';

/// What the shell tells every status row below it: where tapping the
/// activity button goes, and whether an encounter screen is in view (it
/// shows its own damage numbers, so the row stays quiet).
///
/// The status row used to live only in the shell's app bar; screens that
/// draw it over their own art read these from here instead.
class StatusRowScope extends InheritedWidget {
  const StatusRowScope({
    super.key,
    required this.onActivityTap,
    required this.encounterScreenInView,
    required super.child,
  });

  final void Function(Enum activityIconId)? onActivityTap;
  final bool encounterScreenInView;

  static StatusRowScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StatusRowScope>();

  @override
  bool updateShouldNotify(StatusRowScope old) =>
      old.onActivityTap != onActivityTap ||
      old.encounterScreenInView != encounterScreenInView;
}

/// The status row as a screen draws it: [ProgressBars] wired to the
/// nearest [StatusRowScope]. Outside a shell (a widget test) it still
/// draws, with nothing behind the activity button.
class StatusRow extends StatelessWidget {
  const StatusRow({super.key});

  static const double height = ProgressBars.height;

  @override
  Widget build(BuildContext context) {
    final scope = StatusRowScope.maybeOf(context);
    return ProgressBars(
      onActivityTap: scope?.onActivityTap,
      encounterScreenInView: scope?.encounterScreenInView ?? false,
    );
  }
}
