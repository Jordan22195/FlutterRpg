import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'explore_screen.dart';
import '../catalogs/zone_catalog.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  Widget _zoneButton(
    BuildContext context,
    PlayerDataController playerDataController,
    ZoneId zoneId,
    String label,
  ) {
    return ElevatedButton(
      onPressed: () {
        playerDataController.setCurrentZone(zoneId);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ExploreScreen()));
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerDataController = context.watch<PlayerDataController>();

    // IMPORTANT: no Scaffold here — MainShell owns the Scaffold + BottomNav.
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/map.png', fit: BoxFit.cover),
          ),
          Positioned(
            left: 16,
            top: 8,
            right: 16,
            child: Text(
              'World Map',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          // Zone buttons. each pushes onto the MAP TAB's nested navigator,
          // so switching tabs and coming back returns to ExploreScreen.
          Positioned(
            left: 80,
            top: 160,
            child: _zoneButton(
              context,
              playerDataController,
              ZoneId.TUTORIAL_FARM,
              'Farm',
            ),
          ),
          Positioned(
            left: 80,
            top: 220,
            child: _zoneButton(
              context,
              playerDataController,
              ZoneId.STARTING_FOREST,
              'Forest',
            ),
          ),
          Positioned(
            left: 80,
            top: 280,
            child: _zoneButton(
              context,
              playerDataController,
              ZoneId.DEV_FOREST,
              'Dev Forest',
            ),
          ),
        ],
      ),
    );
  }
}
