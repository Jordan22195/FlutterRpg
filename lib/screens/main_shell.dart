import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'explore_screen.dart';
import 'gear_screen.dart';
import 'inventory_screen.dart';
import 'map_screen.dart';
import 'queue_screen.dart';
import 'skills_screen.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/world_controller.dart';
import '../services/entity_screen_router_service.dart';
import '../utilities/top_route_observer.dart';
import '../widgets/progress_bars.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  // watches the map tab's stack so the shell knows which screen is on top
  late final TopRouteObserver _mapTabObserver = TopRouteObserver(
    _onMapTabRouteChanged,
  );

  NavigatorState get _currentNavigator => _navKeys[index].currentState!;

  // true when an encounter screen is actually visible to the user
  bool get _encounterScreenInView =>
      index == 0 &&
      _mapTabObserver.topRouteName ==
          EntityScreenRouterService.encounterRouteName;

  void _onMapTabRouteChanged() {
    // route changes can fire while the navigator is building; defer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
  }

  // jumps to the screen of the running activity: switches to the map tab
  // and rebuilds its stack as Map -> Explore (-> entity screen when the
  // activity is an encounter or crafting entity)
  void _openActivityScreen(Enum activityIconId) {
    setState(() => index = 0);

    final nav = _navKeys[0].currentState!;
    nav.popUntil((route) => route.isFirst);
    nav.push(MaterialPageRoute(builder: (_) => const ExploreScreen()));

    if (activityIconId is EntityId) {
      context.read<WorldController>().navigateToEntity(
        activityIconId,
        _navKeys[0].currentContext!,
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentNavigator.canPop()) {
      _currentNavigator.pop();
      return false; // handled here; don't pop the app
    }
    return true; // allow system back to close app / pop shell
  }

  Widget _tabNavigator({
    required GlobalKey<NavigatorState> key,
    required Widget root,
    List<NavigatorObserver> observers = const [],
  }) {
    return Navigator(
      key: key,
      observers: observers,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: ProgressBars(
            onActivityTap: _openActivityScreen,
            encounterScreenInView: _encounterScreenInView,
          ),
        ),
        body: IndexedStack(
          index: index,
          children: [
            _tabNavigator(
              key: _navKeys[0],
              root: const MapScreen(),
              observers: [_mapTabObserver],
            ),
            _tabNavigator(key: _navKeys[1], root: const SkillsScreen()),
            _tabNavigator(key: _navKeys[2], root: const InventoryScreen()),
            _tabNavigator(key: _navKeys[3], root: const GearScreen()),
            _tabNavigator(key: _navKeys[4], root: const QueueScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          // five tabs: fixed keeps labels visible (default flips to
          // shifting at 4+ items)
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph),
              label: 'Skills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.backpack),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Gear'),
            BottomNavigationBarItem(
              icon: Icon(Icons.playlist_play),
              label: 'Queue',
            ),
          ],
        ),
      ),
    );
  }
}
