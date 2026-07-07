import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

import '../data/skill_data.dart';
import '../widgets/primary_button.dart';
import '../widgets/explore_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final worldController = context.watch<WorldController>();
    final zoneDef = worldController.getCurrentZoneDefinition();
    final entities = worldController.getCurrentZoneEntities();

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
            child: zoneDef.iconAsset.isEmpty
                ? const ColoredBox(color: Colors.black26)
                : Image.asset(
                    zoneDef.iconAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: Colors.black26),
                  ),
          ),

          // Combined Location + Entity list
          Expanded(
            child: ListView.builder(
              itemCount: entities.length,
              itemBuilder: (context, index) {
                final e = entities[index];
                if (e is EncounterEntity) {
                  return ObjectCard(
                    key: ValueKey(e.id),
                    id: e.id,
                    name: e.name,
                    count: e.count,
                    onTap: () =>
                        worldController.navigateToEntity(e.id, context),
                    typeId: e.entityType,
                  );
                } else if (e is CampfireEntity) {
                  return ObjectCard(
                    key: ValueKey(e.id),
                    id: e.id,
                    name: e.name,
                    count: 0,
                    expirationTime: e.expirationTime,
                    onTap: () =>
                        worldController.navigateToEntity(e.id, context),

                    typeId: e.craftingSkill,
                  );
                } else if (e is CraftingEntity) {
                  return ObjectCard(
                    key: ValueKey(e.id),
                    id: e.id,
                    name: e.name,
                    count: 0,
                    onTap: () =>
                        worldController.navigateToEntity(e.id, context),
                    typeId: e.craftingSkill,
                  );
                }
                return null;
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
                    worldController.navigateToEntity(EntityId.FIREPIT, context);
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
                  enabled: true,
                  label: "Explore",
                  startActionFunction: () {
                    worldController.startExplore();
                  },
                ),
              ),
              SizedBox(width: 8),
              // stop action button
              StopPrimaryButton(),
            ],
          ),

          // Bottom action button (sits above the shell bottom nav automatically)
        ],
      ),
    );
  }
}
