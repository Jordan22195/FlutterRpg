import 'package:flutter/material.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import '../data/entity.dart';
import '../data/zone.dart';
import '../controllers/encounter_controller.dart';
import '../widgets/fill_bar.dart';
import '../widgets/primary_button.dart';
import '../data/skill.dart';
import '../widgets/skil_tile.dart';
import '../screens/skill_detail_screen.dart';
import '../data/item.dart';

class EncounterScreen extends StatefulWidget {
  const EncounterScreen({super.key, required this.entityId});
  final Entities entityId;

  @override
  State<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends State<EncounterScreen>
    with TickerProviderStateMixin {
  // Cache the provider so dispose() doesn't do ancestor lookup via context.
  late final PlayerDataController _playerController;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _playerController = context.read<PlayerDataController>();

    print("EncounterScreen: initState for ${widget.entityId}");

    Future.microtask(() async {
      final c = _playerController;
      await c.ensureLoaded();
      if (!mounted) return;

      c.initActionTiming(this);
      c.actionTimingController.onFire = () {
        if (!mounted) return;
        setState(() {
          EncounterController.instance.doPlayerEncounterAction();
        });
      };
      EncounterController.instance.initEncounter(widget.entityId);
      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
    });
  }

  @override
  void dispose() {
    print("dispose EncounterScreen for ${widget.entityId}");
    _playerController.actionTimingControllerOrNull?.stopNowSilently();
    //_playerController.actionTimingControllerOrNull?.onFire = () {};
    EncounterController.instance.endEncounter();

    super.dispose();
  }

  Widget buildSkillTile(
    BuildContext context,
    PlayerDataController controller,
    Skills skillId,
  ) {
    return SkillTile(
      title: skillId.name,
      progress: controller.getSkill(skillId).percentProgressToLevelUp(),
      icon: Icons.sports_martial_arts,
      size: 70,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SkillDetailScreen(skillId: skillId),
          ),
        );
      },
    );
  }

  Widget buildEncounterProgressBars(PlayerDataController controller) {
    const double speedBarPadding = 120;
    final timing = controller.actionTimingControllerOrNull;

    if (_initializing || timing == null) {
      // Build can run before async init finishes. Show placeholders.
      return Column(
        children: [
          const FillBar(value: 0),
          const SizedBox(height: 8),
          Row(
            children: const [
              SizedBox(width: speedBarPadding),
              Expanded(child: FillBar(value: 0)),
              SizedBox(width: speedBarPadding),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: timing,
          builder: (_, __) => FillBar(value: timing.actionProgress),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: speedBarPadding),
            Expanded(
              child: AnimatedBuilder(
                animation: timing,
                builder: (_, __) => FillBar(
                  value: timing.speed,
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: speedBarPadding),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();

    if (_initializing) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final enemy = EncounterController.instance.getEntity();

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: buildEncounterProgressBars(controller),
          ),
        ),
        //title: Text('Encounter: ${Encoutner.getEntity().name}'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                if (EncounterController.instance.isCombatEntity())
                  Text('Player HP: ${controller.data?.hitpoints}'),
                Spacer(),
                ItemStackTile(
                  size: 160,
                  count: EncounterController.instance.getEntityCount(),
                  id: enemy.id,
                ),
                Text(
                  'Enemy HP: ${EncounterController.instance.getEntity().hitpoints}',
                ),
                Spacer(),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                SizedBox(width: 50),
                Expanded(
                  child: FillBar(
                    value: EncounterController.instance.getHealtPercent(),
                    foregroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                SizedBox(width: 50),
              ],
            ),
            const SizedBox(height: 12),

            Row(children: [SizedBox(width: 50), Icon(Icons.gavel), Spacer()]),

            const SizedBox(height: 16),
            Divider(),
            buildSkillTile(
              context,
              controller,
              EncounterController.instance.getEncounterSkillType(),
            ),

            Card(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      controller.takeEncounterItems();
                    }),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 1,
                      ),
                    ),
                    child: Text("Take"),
                  ),
                  SizedBox(
                    height: 80,
                    child: InventoryGrid(
                      items: EncounterController.instance.encounterItemDrops
                          .getObjectStackList(),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: MomentumPrimaryButton(
                label: controller.getActionString(),
                controller: controller.actionTimingController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
