import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/screens/crafting_screen.dart';

import '../controllers/player_data_controller.dart';
import '../data/zone.dart';
import '../data/skill.dart';
import '../widgets/fill_bar.dart';
import '../widgets/primary_button.dart';
import 'encounter_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.zoneId});
  final Zones zoneId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  void bindActionButton() {
    print("binding explore action button for ${widget.zoneId}");
    final c = context.read<PlayerDataController>();

    c.initActionTiming(this);
    c.actionTimingController.onFire = () {
      print("ExploreScreen: action button fired for ${widget.zoneId}");
      if (!mounted) {
        print(
          "errr: ExploreScreen: action button fired but not mounted for ${widget.zoneId}",
        );
        return;
      }
      setState(() {
        c.explore();
      });
    };
  }

  void initState() {
    print("ExploreScreen: initState for ${widget.zoneId}");
    super.initState();
    bindActionButton();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final entities = controller.getZoneEntities();
    final locations = controller.getZoneLocations();
    context
        .watch<EncounterController>(); // Rebuild when encounter state changes.

    // IMPORTANT: no Scaffold here — MainShell owns the Scaffold + BottomNav.
    return SafeArea(
      child: Column(
        children: [
          // Top "app bar" row with a back button that pops the MAP tab navigator
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.zoneId.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Progress bars
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: controller.actionTimingController,
                  builder: (_, __) => FillBar(
                    value: controller.actionTimingController.actionProgress,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: controller.actionTimingController,
                  builder: (_, __) => FillBar(
                    value: controller.actionTimingController.speed,
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Location list
          Expanded(
            child: ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, i) {
                final e = locations[i];
                return Card(
                  child: ListTile(
                    title: Text(e.name.toString()),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CraftingScreen(skill: Skills.BLACKSMITHING),
                            ),
                          )
                          .then((_) {
                            print(
                              "return from crafting screen, re-binding explore action button",
                            );
                            if (!mounted) {
                              print(
                                "not mounted, not binding explore action button",
                              );
                              return;
                            }
                            controller.actionTimingController.stopNowSilently();
                            setState(() {
                              bindActionButton();
                            });
                          });
                    },
                  ),
                );
              },
            ),
          ),

          // Entity list
          Expanded(
            child: ListView.builder(
              itemCount: entities.length,
              itemBuilder: (context, i) {
                final e = entities[i];
                return Card(
                  child: ListTile(
                    title: Text(e.id.toString()),
                    trailing: Text('x${e.count}'),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => EncounterScreen(entityId: e.id),
                            ),
                          )
                          .then((_) {
                            EncounterController.instance.endEncounter();

                            print(
                              "return from encounter screen re-binding explore action button",
                            );
                            if (!mounted) return;
                            controller.actionTimingController.stopNowSilently();
                            bindActionButton();
                          });
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom action button (sits above the shell bottom nav automatically)
          Padding(
            padding: const EdgeInsets.all(12),
            child: MomentumPrimaryButton(
              label: "Explore",
              controller: controller.actionTimingController,
            ),
          ),
        ],
      ),
    );
  }
}
