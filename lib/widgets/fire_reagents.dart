import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/items/items.dart';
import '../controllers/buff_controller.dart';
import '../controllers/fire_controller.dart';
import '../data/skill_data.dart';
import '../systems/fire_tending_system.dart';
import 'countdown_timer.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';
import 'buff_toggle_card.dart';

/*
fire reagents, on the firepit screen:
-the stage row: one chip per reagent buff burning on the fire - its icon,
 the bonus, and its time left - with a + chip at the end. tapping a chip
 throws another of that reagent on; + opens the reagent sheet
-the reagent sheet: every fire reagent, with what is held and what stops it
 going on. tapping one throws it on by hand, which pays its xp
-the Reagents tab: the Keep fire fed switch, then one row per reagent held,
 armed or burning, with its auto-tend switch and what its buff is doing
*/

/// "Strength" for [SkillId.STRENGTH].
String statName(SkillId stat) {
  final name = stat.name;
  return name[0] + name.substring(1).toLowerCase();
}

String _blockText(TendBlock block, ItemId reagent) => switch (block) {
  TendBlock.none => 'Ready',
  TendBlock.notAReagent => 'Not a fire reagent',
  TendBlock.noFire => 'Light a campfire or bonfire first',
  TendBlock.cookfire => 'A cookfire cannot be tended',
  TendBlock.level =>
    'Firemaking ${FireTendingSystem.reagentDefinition(reagent)?.levelRequirement}',
  TendBlock.noneHeld => 'None held',
};

/// The reagent buffs burning on the fire, along the foot of its stage.
class FireReagentChipRow extends StatelessWidget {
  const FireReagentChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    // the buff tick is what counts the chips down and drops a spent one
    context.watch<BuffController>();
    final controller = context.watch<FireController>();
    final buffs = controller.activeBuffs();

    return SingleChildScrollView(
      key: const ValueKey('fire-reagent-chips'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final buff in buffs) ...[
            _ReagentChip(
              buff: buff,
              onTap: controller.isHere
                  ? () => controller.tend(buff.reagent)
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          if (controller.isHere)
            _AddChip(onTap: () => showTendReagentSheet(context)),
        ],
      ),
    );
  }
}

class _ReagentChip extends StatelessWidget {
  const _ReagentChip({required this.buff, this.onTap});

  final ReagentBuff buff;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey('fire-reagent-chip-${buff.stat.name}'),
      color: scheme.surface.withValues(alpha: 0.85),
      shape: StadiumBorder(
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: IconRenderer(size: 24, id: buff.reagent),
              ),
              const SizedBox(width: 4),
              Text(
                '+${buff.value}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              CountdownTimer(
                expirationTime: buff.endsAt,
                size: 12,
                showIcon: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Throw on a reagent',
      child: Material(
        key: const ValueKey('fire-reagent-add'),
        color: scheme.surface.withValues(alpha: 0.85),
        shape: CircleBorder(
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.add, size: 18),
          ),
        ),
      ),
    );
  }
}

/// Every fire reagent, to throw one on by hand.
Future<void> showTendReagentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const SafeArea(child: _TendSheet()),
  );
}

class _TendSheet extends StatelessWidget {
  const _TendSheet();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FireController>();
    final fire = controller.fire();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            fire != null && fire.tendable
                ? 'Each reagent gives +${fire.power} to its stat for '
                      '${fire.definition.reagentBurn.inMinutes} minutes'
                : 'Light a campfire or bonfire to tend it',
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
        ),
        for (final id in FireTendingSystem.reagents)
          _TendRow(id: id, block: controller.blockFor(id)),
      ],
    );
  }
}

class _TendRow extends StatelessWidget {
  const _TendRow({required this.id, required this.block});

  final ItemId id;
  final TendBlock block;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<FireController>();
    final def = FireTendingSystem.reagentDefinition(id)!;
    final held = controller.heldCount(id);
    final ready = block == TendBlock.none;
    return Opacity(
      opacity: ready ? 1 : 0.5,
      child: ListTile(
        key: ValueKey('tend-${id.name}'),
        leading: ItemStackTile<ItemId>(
          size: 40,
          id: id,
          count: held,
          alwaysShowCount: true,
          showInfoDialogOnTap: false,
          depleted: held == 0,
        ),
        title: Text(def.name),
        subtitle: Text(
          '${statName(def.stat)} · ${_blockText(block, id)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: ready ? const Icon(Icons.local_fire_department) : null,
        onTap: ready ? () => controller.tend(id) : null,
      ),
    );
  }
}

/// The Reagents tab: a summary line, Keep fire fed, then one card per
/// reagent held, armed or burning - the same cards the potions panel uses.
class FireReagentsPanel extends StatelessWidget {
  const FireReagentsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // the buff tick is what counts the timers down and clears a card's
    // outline when its reagent burns out
    context.watch<BuffController>();
    final controller = context.watch<FireController>();
    final scheme = Theme.of(context).colorScheme;
    final rows = controller.reagentRows();
    final burning = {for (final b in controller.activeBuffs()) b.reagent: b};
    final dose = controller.reagentDose();

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${controller.autoCount} auto · ${burning.length} active',
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
              const Spacer(),
              const Text('Keep fire fed', style: TextStyle(fontSize: 13)),
              Switch(
                key: const ValueKey('keep-fire-fed'),
                value: controller.keepFireFed,
                onChanged: controller.setKeepFireFed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No fire reagents yet. Trees drop them while you chop.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.outline),
              ),
            )
          else
            BuffToggleGrid(
              children: [
                for (final id in rows)
                  BuffToggleCard(
                    cardKey: ValueKey('auto-tend-card-${id.name}'),
                    switchKey: ValueKey('auto-tend-${id.name}'),
                    id: id,
                    held: controller.heldCount(id),
                    auto: controller.isAutoTend(id),
                    onChanged: (on) => controller.setAutoTend(id, on),
                    dose: dose,
                    activeUntil: burning[id]?.endsAt,
                  ),
              ],
            ),
          if (!controller.actionRunning)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Auto-tend and Keep fire fed only run while an action is going',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
            ),
        ],
      ),
    );
  }
}
