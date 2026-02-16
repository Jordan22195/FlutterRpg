import 'package:flutter/material.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import '../data/entity.dart';
import '../controllers/encounter_controller.dart';
import '../widgets/fill_bar.dart';
import '../widgets/primary_button.dart';
import '../data/skill.dart';
import '../widgets/skil_tile.dart';
import '../screens/skill_detail_screen.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/fading_number.dart';

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
  int playerDamage = 0;
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
          playerDamage = EncounterController.instance.lastPlayerDamage;
          print("Player dealt $playerDamage damage");
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
    return SkillTile(id: skillId);
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

  Widget buildPlayerStatStack(PlayerDataController controller) {
    double fontSize = 14;
    double iconSize = 20;
    final skillId = EncounterController.instance.getEncounterSkillType();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconRenderer(id: Skills.HITPOINTS, size: iconSize),
            SizedBox(width: 4),
            Text(
              controller.getStatTotal(Skills.HITPOINTS).toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: Skills.DEFENCE, size: iconSize),
            SizedBox(width: 4),
            Text(
              controller.getStatTotal(Skills.DEFENCE).toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: skillId, size: iconSize),
            SizedBox(width: 4),
            Text(
              controller.getStatTotal(skillId).toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),

        // Add more stats here, e.g. mana, stamina, etc.
      ],
    );
  }

  Widget buildEntityStatStack(PlayerDataController controller) {
    double fontSize = 14;
    double iconSize = 20;
    final skillId = EncounterController.instance.getEncounterSkillType();
    final entity = EncounterController.instance.getEntity();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconRenderer(id: Skills.HITPOINTS, size: iconSize),
            SizedBox(width: 4),
            Text(
              entity.hitpoints.toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: Skills.DEFENCE, size: iconSize),
            SizedBox(width: 4),
            Text(
              entity.defence.toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        if (entity is CombatEntity)
          Row(
            children: [
              IconRenderer(id: Skills.ATTACK, size: iconSize),
              SizedBox(width: 4),
              Text(
                entity.attack.toString(),
                style: TextStyle(fontSize: fontSize),
              ),
            ],
          ),

        // Add more stats here, e.g. mana, stamina, etc.
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

    final _fadeKey = GlobalKey<FadingNumberState>();

    // ...

    // whenever you want to show+fade (even if count didn’t change):
    _fadeKey.currentState?.replay();

    return Scaffold(
      appBar: AppBar(
        title: enemy.name != null ? Text(enemy.name) : null,
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
                // Left: Player stats (left-justified)
                Align(
                  alignment: Alignment.centerLeft,
                  child: buildPlayerStatStack(controller),
                ),

                // Center: Item stack tile (always centered)
                Expanded(
                  child: Center(
                    child: ItemStackTile(
                      size: 200,
                      count: EncounterController.instance.getEntityCount(),
                      id: enemy.id,
                    ),
                  ),
                ),

                // Right side: Fading number centered between tile and entity stats,
                // and entity stats right-aligned
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Fading number centered in remaining space before stats
                    Center(
                      child: FadingNumber(
                        key: _fadeKey,
                        number: playerDamage,
                        color: Colors.amber,
                      ),
                    ),

                    // Entity stats right-aligned
                    Align(
                      alignment: Alignment.centerRight,
                      child: buildEntityStatStack(controller),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

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
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(0),
              child: MomentumPrimaryButton(
                enabled: true,
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
