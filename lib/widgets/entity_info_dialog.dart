import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/widgets/stat_chip.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/world_controller.dart';
import '../data/entity_details.dart';
import '../data/skill_data.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';
import 'info_section.dart';
import 'item_stack_tile.dart';

/// Details popup for a world entity, used where there is no room to show
/// them inline — the explore screen's entity icons, and combat encounters.
/// Gathering encounters render [EntityInfoBody] in their info tab instead.
void showEntityInfoDialog(BuildContext context, EncounterEntity entity) {
  if (entity.id == EntityId.NULL) return;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(entity.name),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: EntityInfoBody(
            entity: entity,
            onDevSetCount: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Everything there is to say about a world entity that the encounter
/// screen around it doesn't already: the rolls both ways against the
/// player's current stats (hit / miss / block chances and damage), and the
/// drop table with per-action odds. The entity's own stat block is left out
/// deliberately — hitpoints, level and remaining count are all read off the
/// encounter screen itself. Also carries the dev control for forcing the
/// entity's remaining count.
///
/// Sizes to its content, so it can be dropped into a scrolling page as
/// readily as into the details dialog.
class EntityInfoBody extends StatefulWidget {
  const EntityInfoBody({super.key, required this.entity, this.onDevSetCount});

  final EncounterEntity entity;

  /// Called after the dev count is applied — the dialog closes on it, an
  /// inline panel has nothing to do.
  final VoidCallback? onDevSetCount;

  @override
  State<EntityInfoBody> createState() => _EntityInfoBodyState();
}

class _EntityInfoBodyState extends State<EntityInfoBody> {
  late final TextEditingController _devCountController = TextEditingController(
    text: '${widget.entity.count}',
  );

  @override
  void dispose() {
    _devCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // every number below is resolved against the player's stats as they
    // stand this frame, and boosting moves them: a speed boost cuts the
    // interval the damage rate is divided by, and a strength one adds
    // points to the stat being rolled. The timing controller notifies on
    // each tick, so watching it is what keeps the readouts honest while the
    // button is held rather than freezing them at the rate you started at.
    context.watch<ActionTimingController>();
    final worldController = context.read<WorldController>();
    final details = worldController.entityDetails(widget.entity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(details: details),
        _RollTable(details: details),
        _DropTable(details: details),

        // dev tool: force how many of this entity are left in the zone
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _devCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Dev: entity count',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final count = int.tryParse(_devCountController.text);
                if (count != null) {
                  worldController.devSetEntityCount(widget.entity.id, count);
                }
                widget.onDevSetCount?.call();
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Portrait, plus the skill this entity trains and its level gate.
class _Header extends StatelessWidget {
  const _Header({required this.details});

  final EntityDetails details;

  @override
  Widget build(BuildContext context) {
    final entity = details.entity;
    final gate = details.requiredLevel > 0
        ? ' · Lv ${details.requiredLevel}'
        : '';

    return Column(
      children: [
        Center(
          child: ItemStackTile(
            size: 96,
            count: entity.count,
            id: entity.id,
            showInfoDialogOnTap: false,
            depleted: entity.count <= 0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 4),
            StatChip(
              icon: IconRenderer(size: 18, id: details.skill),
              value: '${details.requiredLevel}',
            ),
            Text(
              '${skillDisplayName(details.skill)}$gate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Both sides of the roll on one table: how often each side lands, how
/// hard, and how fast. The player's column and the entity's carry the same
/// measurements, so a fight is read across a line instead of by holding one
/// section's numbers in your head while you scroll to the other's.
///
/// Everything here is resolved against the player's *current* stats, boost
/// included, so the rates move as the fight does.
class _RollTable extends StatelessWidget {
  const _RollTable({required this.details});

  final EntityDetails details;

  String get _title {
    if (details.isCombat) return 'Combat Stats';
    switch (details.skill) {
      case SkillId.HERBALISM:
        return 'Your picks';
      case SkillId.FISHING:
        return 'Your casts';
      default:
        return 'Your actions';
    }
  }

  /// The rows, with an entity column only when something is rolling back.
  List<InfoTableRow> _rows() {
    final combat = details.isCombat;
    InfoTableRow row(String label, String you, [String? them]) =>
        InfoTableRow(label, [you, if (combat) them ?? InfoTable.blank]);

    // herbs are never missed: the roll only decides how much the pick
    // yields, so hit/miss and damage don't apply
    if (details.skill == SkillId.HERBALISM) {
      return [
        row('Bonus yield chance', formatPercent(details.playerHitChance)),
        row('Expected yield', formatDecimal(details.expectedYield)),
      ];
    }

    final actionsToKill = details.actionsToKill;

    return [
      row(
        combat ? 'Hit chance' : 'Success chance',
        formatPercent(details.playerHitChance),
        formatPercent(details.entityHitChance),
      ),
      // the entity's misses are the player's blocks - the same roll read
      // from the other end, which is exactly what a column is for
      row(
        combat ? 'Miss chance' : 'Fail chance',
        formatPercent(details.playerMissChance),
        formatPercent(details.blockChance),
      ),
      row('Max hit', '${details.playerMaxHit}', '${details.entityMaxHit}'),
      row(
        'Avg damage',
        formatDecimal(details.playerAverageDamage),
        formatDecimal(details.entityAverageDamage),
      ),
      if (details.usesDamage) ...[
        row(
          'Damage per second',
          formatDecimal(details.playerDamagePerSecond),
          formatDecimal(details.entityDamagePerSecond),
        ),
        row(
          combat ? 'Actions to kill' : 'Actions to clear',
          actionsToKill.isFinite ? '~${actionsToKill.ceil()}' : 'never',
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final combat = details.isCombat;
    final skill = skillDisplayName(details.skill).toLowerCase();
    final levels = combat
        ? 'Your $skill ${details.playerSkillLevel} · '
              'your defence ${details.playerDefence}'
        : 'Your $skill ${details.playerSkillLevel}';

    return InfoSection(
      title: _title,
      children: [
        // the levels the columns below are rolled from. A line rather than
        // rows of their own: they belong to the player either way, so a
        InfoTable(
          headers: combat ? ['You', 'Them'] : const [''],
          rows: _rows(),
        ),
      ],
    );
  }
}

class _DropTable extends StatelessWidget {
  const _DropTable({required this.details});

  final EntityDetails details;

  @override
  Widget build(BuildContext context) {
    if (details.drops.isEmpty) {
      return const SizedBox.shrink();
    }

    final subtleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return InfoSection(
      title: 'Drop table',
      children: [
        for (final drop in details.drops)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                // the standard tile, so a drop is framed by the quality
                // it rolls and opens the same item dialog the bag does -
                // the table is where you go to find out what a monster is
                // worth killing for, which is exactly when you want to read
                // the item. No count on the badge: a drop is a range, and
                // the column to the right is the one that can say so
                ItemStackTile<ItemId>(
                  size: 36,
                  id: drop.itemId,
                  count: 0,
                  quality: drop.rarity,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // the quality prefix, the way EquipmentItem.displayName
                      // writes it: a table can list the same item at two
                      // qualities, which reads as a duplicate row without it
                      Text(
                        drop.rarity.label.isEmpty
                            ? drop.name
                            : '${drop.rarity.label} ${drop.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      // a layered roll lands on top of the main drop, so
                      // its odds are independent of the rows above
                      if (drop.bonus) Text('bonus roll', style: subtleStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  drop.hasCountRange
                      ? '${drop.minCount}-${drop.maxCount}'
                      : '${drop.minCount}',
                  style: subtleStyle,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text(
                    formatPercent(drop.chance),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A labelled block of rows, matching the explore screen's section labels.

/// One label/value line. Values are right-aligned so a column of numbers
/// stays readable.
