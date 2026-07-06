import 'package:flutter/widgets.dart';

/// Tracks the name of the route currently on top of the [Navigator] this
/// observer is attached to. [onChanged] fires whenever the top route changes.
class TopRouteObserver extends NavigatorObserver {
  TopRouteObserver(this.onChanged);

  final VoidCallback onChanged;

  String? _topRouteName;
  String? get topRouteName => _topRouteName;

  void _setTop(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != _topRouteName) {
      _topRouteName = name;
      onChanged();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _setTop(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _setTop(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _setTop(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _setTop(newRoute);
}
