import 'package:flutter/widgets.dart';

/// Tracks the route stack of the [Navigator] this observer is attached to.
/// [onChanged] fires whenever the stack changes. [topRouteName] identifies
/// the screen on top; [namedRouteSettings] lists every named route bottom
/// to top so the stack can be serialized and rebuilt on relaunch.
class TopRouteObserver extends NavigatorObserver {
  TopRouteObserver(this.onChanged);

  final VoidCallback onChanged;

  final List<Route<dynamic>> _stack = [];

  String? get topRouteName =>
      _stack.isEmpty ? null : _stack.last.settings.name;

  /// Settings of the named routes on the stack, bottom to top. Unnamed
  /// routes (the tab root, dialogs) are skipped.
  List<RouteSettings> get namedRouteSettings => [
    for (final route in _stack)
      if (route.settings.name != null) route.settings,
  ];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute != null) {
        _stack[index] = newRoute;
      } else {
        _stack.removeAt(index);
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    onChanged();
  }
}
