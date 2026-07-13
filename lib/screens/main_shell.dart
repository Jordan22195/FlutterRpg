import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dungeon_screen.dart';
import 'explore_screen.dart';
import 'gear_screen.dart';
import 'inventory_screen.dart';
import 'map_screen.dart';
import 'queue_screen.dart';
import 'skills_screen.dart';
import '../catalogs/dungeon_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/dungeon_controller.dart';
import '../controllers/world_controller.dart';
import '../game_session.dart';
import '../services/entity_screen_router_service.dart';
import '../utilities/top_route_observer.dart';
import '../widgets/progress_bars.dart';

class MainShell extends StatefulWidget {
  /// Fired whenever the saved ui state (active tab / map tab stack) is
  /// updated, so the owner can persist it promptly.
  final VoidCallback? onUiStateChanged;

  const MainShell({super.key, this.onUiStateChanged});

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

  // the map tab stack to rebuild after the first frame, copied from the
  // save in initState before route changes start overwriting the ui state
  List<String> _restoreRoutes = const [];
  DungeonId _restoreDungeonId = DungeonId.NULL;

  void _onMapTabRouteChanged() {
    _captureUiState();

    // route changes can fire while the navigator is building; defer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();

    final ui = context.read<GameSession>().saveGameData.uiState;
    if (ui.tabIndex >= 0 && ui.tabIndex < _navKeys.length) {
      index = ui.tabIndex;
    }
    _restoreRoutes = List.of(ui.mapRouteStack);
    _restoreDungeonId = ui.dungeonId;

    // the tab navigators don't exist until after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreMapTabStack();
    });
  }

  // snapshots the active tab and the map tab's named route stack into the
  // save's ui state; called on every tab switch and map tab route change
  void _captureUiState() {
    if (!mounted) return;

    final ui = context.read<GameSession>().saveGameData.uiState;
    ui.tabIndex = index;
    ui.mapRouteStack = [];
    ui.dungeonId = DungeonId.NULL;
    for (final settings in _mapTabObserver.namedRouteSettings) {
      ui.mapRouteStack.add(settings.name!);
      if (settings.name == EntityScreenRouterService.dungeonRouteName &&
          settings.arguments is DungeonId) {
        ui.dungeonId = settings.arguments as DungeonId;
      }
    }

    widget.onUiStateChanged?.call();
  }

  // rebuilds the map tab's stack from the saved route names. an entry
  // that can't be restored (entity gone from the zone, unknown dungeon)
  // stops the walk, landing on the nearest valid ancestor screen
  void _restoreMapTabStack() {
    final nav = _navKeys[0].currentState;
    final navContext = _navKeys[0].currentContext;
    if (nav == null || navContext == null) return;

    final world = context.read<WorldController>();
    final dungeons = context.read<DungeonController>();

    for (final name in _restoreRoutes) {
      switch (name) {
        case EntityScreenRouterService.exploreRouteName:
          nav.push(
            MaterialPageRoute(
              settings: const RouteSettings(
                name: EntityScreenRouterService.exploreRouteName,
              ),
              builder: (_) => const ExploreScreen(),
            ),
          );
        case EntityScreenRouterService.dungeonRouteName:
          // an active run knows its dungeon; otherwise use the saved id
          final dungeonId = _restoreDungeonId != DungeonId.NULL
              ? _restoreDungeonId
              : dungeons.activeDungeonId;
          if (dungeons.definitionFor(dungeonId) == null) return;
          nav.push(
            MaterialPageRoute(
              settings: RouteSettings(
                name: EntityScreenRouterService.dungeonRouteName,
                arguments: dungeonId,
              ),
              builder: (_) => DungeonScreen(dungeonId: dungeonId),
            ),
          );
        case EntityScreenRouterService.encounterRouteName:
        case EntityScreenRouterService.craftingRouteName:
        case EntityScreenRouterService.enchantingRouteName:
        case EntityScreenRouterService.shopRouteName:
          if (!world.restoreEntityView(navContext)) return;
        default:
          return; // unknown route: stop at the last restored screen
      }
    }
  }

  // jumps to the screen of the running activity: switches to the map tab
  // and rebuilds its stack as Map -> Explore (-> entity screen when the
  // activity is an encounter or crafting entity)
  void _openActivityScreen(Enum activityIconId) {
    setState(() => index = 0);

    final nav = _navKeys[0].currentState!;
    nav.popUntil((route) => route.isFirst);

    // a running dungeon opens straight to its screen; other activities
    // rebuild the Map -> Explore (-> entity) stack
    if (activityIconId is DungeonId) {
      nav.push(
        MaterialPageRoute(
          settings: RouteSettings(
            name: EntityScreenRouterService.dungeonRouteName,
            arguments: activityIconId,
          ),
          builder: (_) => DungeonScreen(dungeonId: activityIconId),
        ),
      );
      return;
    }

    nav.push(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: EntityScreenRouterService.exploreRouteName,
        ),
        builder: (_) => const ExploreScreen(),
      ),
    );

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
          onTap: (i) {
            setState(() => index = i);
            _captureUiState();
          },
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
