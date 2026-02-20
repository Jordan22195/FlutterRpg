import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/zone_controller.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/zone_location.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

import '../controllers/player_data_controller.dart';
import '../data/zone.dart';
import '../data/skill.dart';
import '../widgets/primary_button.dart';
import '../widgets/explore_card.dart';
import 'encounter_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.zoneId});
  final Zones zoneId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  void navigateToEncounter(Entities id) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => EncounterScreen(
              encounter: PlayerDataController.instance.data!.zones
                  .getEntityEncounter(
                    PlayerDataController.instance.getCurrentZone(),
                    id,
                  ),
            ),
          ),
        )
        .then((_) {
          print("return from encounter screen.");
        });
  }

  void navigateToCrafting(
    Skills skill,
    PlayerDataController controller,
    Enum locationId,
  ) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CraftingScreen(skill: skill, imageId: locationId),
          ),
        )
        .then((_) {
          print("return from crafting screen.");
        });
  }

  void navigateToLocation(
    ZoneLocation location,
    PlayerDataController controller,
  ) {
    if (location is CraftingLocation) {
      navigateToCrafting(location.craftingSkill, controller, location.id);
    }
    if (location is FishingLocation) {
      navigateToEncounter(location.fishingSpotEntity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final entities = controller.getZoneEntities();
    final locations = controller.getZoneLocations();

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
                    ZoneController.getZone(widget.zoneId)?.name ??
                        "Unknown Zone",
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

          // Combined Location + Entity list
          Expanded(
            child: ListView.builder(
              itemCount: locations.isEmpty
                  ? entities.length
                  : (locations.length + 1 + entities.length),
              itemBuilder: (context, index) {
                // Locations first
                if (index < locations.length) {
                  final id = locations[index];
                  final loc = ZoneLocationController.definitionFor(id);
                  return ObjectCard(
                    key: ValueKey(id),
                    id: id,
                    count: 1,
                    onTap: () => navigateToLocation(loc, controller),
                    typeId: loc.typeForIcon,
                    expirationTime: id == ZoneLocationId.CAMPFIRE
                        ? BuffController.instance.campfireBuff.expirationTime
                        : null,
                  );
                }

                // Divider between sections (only if there are locations)
                if (!locations.isEmpty && index == locations.length) {
                  return const Divider();
                }

                // Entities after divider (or immediately if no locations)
                final entityIndex = locations.isEmpty
                    ? index
                    : index - locations.length - 1;
                final e = entities[entityIndex];
                return ObjectCard(
                  key: ValueKey(e.id),
                  id: e.id,
                  count: e.count,
                  onTap: () => navigateToEncounter(e.id),
                  typeId:
                      EntityController.definitionFor(e.id)?.entityType ??
                      Skills.NULL,
                );
              },
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1),

                child: TextButton(
                  onPressed: () => navigateToCrafting(
                    Skills.FIREMAKING,
                    controller,
                    Skills.FIREMAKING,
                  ),
                  child: ItemStackTile(
                    size: 56,
                    count: 0,
                    id: Skills.FIREMAKING,
                    showInfoDialogOnTap: false,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: MomentumPrimaryButton(
                  enabled: true,
                  label: "Explore",
                  controller: controller.actionTimingController,
                  onFireFunction: () {
                    print(
                      "ExploreScreen: action button fired for ${widget.zoneId}",
                    );
                    PlayerDataController.instance.explore();
                  },
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton(
                  child: Text("Stop"),
                  onPressed: () {
                    PlayerDataController.instance.actionTimingController
                        .stopNow();
                  },
                ),
              ),
            ],
          ),

          // Bottom action button (sits above the shell bottom nav automatically)
        ],
      ),
    );
  }
}
