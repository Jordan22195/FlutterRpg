import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/zone_location.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

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

Widget buildObjectCard<T extends Enum>(
  T id,
  int count,
  Function() navigationCallback,
) {
  return Card(
    child: InkWell(
      onTap: () => navigationCallback(),
      borderRadius: BorderRadius.circular(12), // match Card shape
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Row(
            children: [
              ItemStackTile(size: 56, count: count, id: id),
              const SizedBox(width: 12),
              Text(id.toString()),
            ],
          ),
        ),
      ),
    ),
  );
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

  void navigateToEncounter(Entities id, PlayerDataController controller) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => EncounterScreen(entityId: id)))
        .then((_) {
          EncounterController.instance.endEncounter();

          print(
            "return from encounter screen re-binding explore action button",
          );
          if (!mounted) return;
          controller.actionTimingController.stopNowSilently();
          bindActionButton();
        });
  }

  void navigateToCrafting(Skills skill, PlayerDataController controller) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CraftingScreen(skill: skill)))
        .then((_) {
          print("return from crafting screen re-binding explore action button");
          if (!mounted) return;
          controller.actionTimingController.stopNowSilently();
          bindActionButton();
        });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final entities = controller.getZoneEntities();
    final locations = controller.getZoneLocations();
    final media = MediaQuery.of(context);
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

          SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.asset(
              'assets/images/zones/forest.png',
              fit: BoxFit.cover,
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

          // Location list (resizable + still scrollable)
          LayoutBuilder(
            builder: (context, constraints) {
              // Approximate per-row height (Card + padding). Keep in sync with buildObjectCard.
              const rowExtent = 72.0;

              // Cap the list so it doesn't eat the screen; it can scroll once it hits this.
              final maxHeight = min(constraints.maxHeight * 0.35, 260.0);

              // Grow with content but clamp to maxHeight; shrink to fit if few items.
              final desiredHeight = min(
                locations.length * rowExtent,
                maxHeight,
              );

              // If there are no locations, avoid reserving space.
              if (locations.isEmpty) {
                return const SizedBox.shrink();
              }

              return SizedBox(
                height: desiredHeight,
                child: ListView.builder(
                  itemCount: locations.length,
                  itemExtent: rowExtent,
                  itemBuilder: (context, i) {
                    final id = locations[i];
                    return buildObjectCard(
                      id,
                      0,
                      () =>
                          navigateToCrafting(Skills.BLACKSMITHING, controller),
                    );
                  },
                ),
              );
            },
          ),
          const Divider(),

          // Entity list
          Expanded(
            child: ListView.builder(
              itemCount: entities.length,
              itemBuilder: (context, i) {
                final e = entities[i];
                return buildObjectCard(
                  e.id,
                  e.count,
                  () => navigateToEncounter(e.id, controller),
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
