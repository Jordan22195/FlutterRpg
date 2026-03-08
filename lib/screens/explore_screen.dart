import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/catalogs/location_catalog.dart';
import 'package:rpg/screens/crafting_screen.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

import '../services/player_data_service.dart';
import '../data/zone.dart';
import '../data/skill.dart';
import '../widgets/primary_button.dart';
import '../widgets/explore_card.dart';
import 'encounter_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  void navigateToEncounter(EntityId id) {
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

  void navigateToCrafting(SkillId skill, Enum locationId) {
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

  // todo update how navigation works. don't to navigation checks in the ui.
  // instead call the controller to update a state. have the ui reflect the state.
  // ex: click on entity or location. controllers sets the the new active player view.
  // navigator swiches based on player view state.
  void navigateToLocation(ZoneLocation location) {
    if (location is CraftingLocation) {
      navigateToCrafting(location.craftingSkill, location.id);
    }
    if (location is FishingLocation) {
      navigateToEncounter(location.fishingSpotEntity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worldController = context.watch<WorldController>();
    final zoneDef = worldController.getCurrentZoneDefinition();
    final entities = worldController.getCurrentZoneEntities();
    final locations = zoneDef.permanentLocations;

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
                    zoneDef.name,
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

                  final loc = LocationCatalog.definitionFor(id);
                  return ObjectCard(
                    key: ValueKey(id),
                    id: id,
                    count: 1,
                    onTap: () => navigateToLocation(loc),
                    typeId: loc.typeForIcon,
                    expirationTime: id == LocationId.CAMPFIRE
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
                      EntityCatalog.definitionFor(e.id)?.entityType ??
                      SkillId.NULL,
                );
              },
            ),
          ),

          Row(
            children: [
              // Firemaking button
              Container(
                padding: const EdgeInsets.all(1),

                child: TextButton(
                  onPressed: () {
                    PlayerDataController.instance.restoreStaminaToFull();
                    navigateToCrafting(SkillId.FIREMAKING, SkillId.FIREMAKING);
                  },
                  child: ItemStackTile(
                    size: 56,
                    count: 0,
                    id: SkillId.FIREMAKING,
                    showInfoDialogOnTap: false,
                  ),
                ),
              ),

              // primary action button
              Padding(
                padding: const EdgeInsets.all(12),
                child: MomentumPrimaryButton(
                  maxInterval: WorldData.instance.maxInterval(),
                  enabled: true,
                  label: "Explore",
                  controller: worldController.actionTimingController,
                  onFireFunction: () {
                    worldController.discoverEntity();
                  },
                  appBarTile: ItemStackTile(
                    size: 1,
                    count: 1,
                    id: SkillId.EXPLORATION,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // stop action button
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
