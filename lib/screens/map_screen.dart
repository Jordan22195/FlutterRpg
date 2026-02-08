import 'package:flutter/material.dart';
import 'explore_screen.dart';
import '../data/zone.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

          // Example zone button
          Positioned(
            left: 80,
            top: 220,
            child: ElevatedButton(
              onPressed: () {
                // This pushes onto the MAP TAB's nested navigator,
                // so switching tabs and coming back returns to ExploreScreen.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ExploreScreen(zoneId: Zones.STARTING_FOREST),
                  ),
                );
              },
              child: const Text('Forest'),
            ),
          ),
        ],
      ),
    );
  }
}
