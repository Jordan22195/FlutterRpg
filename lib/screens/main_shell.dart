import 'package:flutter/material.dart';
import 'package:rpg/controllers/player_data_controller.dart';

import 'gear_screen.dart';
import 'inventory_screen.dart';
import 'map_screen.dart';
import 'skills_screen.dart';
import '../widgets/progress_bars.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int index = 0;

  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  NavigatorState get _currentNavigator => _navKeys[index].currentState!;

  @override
  void initState() {
    print("MainShell: initState");
    super.initState();
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
  }) {
    return Navigator(
      key: key,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: ProgressBars()),
        body: IndexedStack(
          index: index,
          children: [
            _tabNavigator(key: _navKeys[0], root: const MapScreen()),
            _tabNavigator(key: _navKeys[1], root: const SkillsScreen()),
            _tabNavigator(key: _navKeys[2], root: const InventoryScreen()),
            _tabNavigator(key: _navKeys[3], root: const GearScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
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
          ],
        ),
      ),
    );
  }
}
