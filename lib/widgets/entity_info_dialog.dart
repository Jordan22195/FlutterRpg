import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/widgets/stat_chip.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/buff_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/potion_controller.dart';
import '../controllers/world_controller.dart';
import '../data/entity_details.dart';
import '../data/skill_data.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';
import 'equipment_picker.dart';
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
  const EntityInfoBody({
    super.key,
    required this.entity,
    this.onDevSetCount,
    this.showImage = true,
  });

  final EncounterEntity entity;

  /// Draw the entity's picture at the top. The popup does; the encounter
  /// screen's info tab doesn't, since the entity stands on the stage right
  /// above it.
  final bool showImage;

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
    // a potion moves them too, and the timer doesn't tick while idle: the
    // bag notifies on a drink from the item dialog, the potion card on one
    // drunk by arming it, and the buff tick on auto-drink and on expiry
    context.watch<InventoryController>();
    context.watch<PotionController>();
    context.watch<BuffController>();
    final worldController = context.read<WorldController>();
    final details = worldController.entityDetails(widget.entity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(details: details, showImage: widget.showImage),
        _RollTable(details: details),
        // dev readout: the numbers a cast's catches are worked out from
        if (details.skill == SkillId.FISHING) _FishingDebug(details: details),
        // dev readout: what the monster's stats are built from
        if (widget.entity case final CombatEntity monster)
          _CombatDebug(monster: monster),
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

/// Portrait, plus the entity's own level beside the skill it trains, and
/// its level gate when it has one.
class _Header extends StatelessWidget {
  const _Header({required this.details, required this.showImage});

  final EntityDetails details;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final entity = details.entity;
    // how hard it is, the number its zone tile reads as "Lv N": a fight's
    // combat level, a node's defence. not the gate, which most things lack
    final level = entity is CombatEntity ? entity.level : entity.defence;
    final gate = details.requiredLevel > 0
        ? ' · Requires Lv ${details.requiredLevel}'
        : '';

    return Column(
      children: [
        if (showImage) ...[
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
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 4),
            StatChip(
              icon: IconRenderer(size: 18, id: details.skill),
              value: '$level',
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

/// The roll as one column of stats. A fight reads as the six numbers that
/// decide it — how often you land, how often you turn its swing aside, the
/// hardest either side hits, your damage rate and how many actions a kill
/// takes; anything else rolls one way and lists only its own side.
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

  /// The rows, one value each.
  List<InfoTableRow> _rows() {
    final combat = details.isCombat;
    InfoTableRow row(String label, String value) =>
        InfoTableRow(label, [value]);

    // herbs are never missed: the roll only decides how much the pick
    // yields, so hit/miss and damage don't apply
    if (details.skill == SkillId.HERBALISM) {
      return [
        row('Bonus yield chance', formatPercent(details.playerHitChance)),
        row('Expected yield', formatDecimal(details.expectedYield)),
      ];
    }

    // a cast either lands or it doesn't, and what it lands is counted in
    // fish rather than damage: overkill rolls the whole table again
    if (details.skill == SkillId.FISHING) {
      return [
        row('Catch chance', formatPercent(details.playerHitChance)),
        row('Max catch', '${details.playerMaxCatch}'),
      ];
    }

    final actionsToKill = details.actionsToKill;
    // to two places: a kill that takes 3.40 actions and one that takes 3.95
    // land on the same whole number, and it is the fraction that moves as
    // gear and the boost do
    final toKill = actionsToKill.isFinite
        ? actionsToKill.toStringAsFixed(2)
        : 'never';

    if (combat) {
      return [
        row('Hit chance', formatPercent(details.playerHitChance)),
        // the enemy's misses: a blocked swing deals nothing
        row('Block chance', formatPercent(details.blockChance)),
        row('Max hit', '${details.playerMaxHit}'),
        // what one swing deals before Attack multiplies it
        if (details.playerSwingDamage > 0)
          row('Weapon damage', formatDamage(details.playerSwingDamage)),
        // the hardest the enemy can hit back
        row('Max take', '${details.entityMaxHit}'),
        row('DPS', formatDecimal(details.playerDamagePerSecond)),
        row('Actions to kill', toKill),
        // at the action rate as it stands, boost and stance included
        row('Kills / hour', details.killsPerHour.toStringAsFixed(0)),
        row('Xp / hour', details.clearXpPerHour.toStringAsFixed(0)),
      ];
    }

    return [
      row('Success chance', formatPercent(details.playerHitChance)),
      row('Fail chance', formatPercent(details.playerMissChance)),
      row('Max hit', '${details.playerMaxHit}'),
      if (details.playerSwingDamage > 0)
        row('Tool damage', formatDamage(details.playerSwingDamage)),
      row('Avg damage', formatDecimal(details.playerAverageDamage)),
      if (details.usesDamage) ...[
        row('Damage per second', formatDecimal(details.playerDamagePerSecond)),
        row(
          'Actions to clear',
          actionsToKill.isFinite ? '~${actionsToKill.ceil()}' : 'never',
        ),
        row('Cleared / hour', details.killsPerHour.toStringAsFixed(0)),
        row('Xp / hour', details.clearXpPerHour.toStringAsFixed(0)),
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
        InfoTable(headers: const [''], rows: _rows()),
      ],
    );
  }
}

/// What a fishing cast's catches come from: the pool's hitpoints, and the
/// most damage a cast can deal to it. Max catch is the one over the other,
/// rounded up; the average is what a cast lands over many, misses and all.
class _FishingDebug extends StatelessWidget {
  const _FishingDebug({required this.details});

  final EntityDetails details;

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: 'Debug',
      children: [
        InfoTable(
          headers: const [''],
          rows: [
            InfoTableRow('Pool hp', ['${details.entity.maxHitPoints}']),
            InfoTableRow('Max hit', ['${details.playerMaxHit}']),
            // to two places: at a low max hit the overkill share is a few
            // hundredths, and it is the fraction that moves as levels do
            InfoTableRow('Avg catches / cast', [
              details.playerAverageCatches.toStringAsFixed(2),
            ]),
            // at the cast rate as it stands, boost and stance included
            InfoTableRow('Catches / hour', [
              details.playerCatchesPerHour.toStringAsFixed(0),
            ]),
            // those catches at what the fish this level reaches are worth
            InfoTableRow('Xp / hour', [
              details.playerXpPerHour.toStringAsFixed(0),
            ]),
          ],
        ),
      ],
    );
  }
}

/// What a monster's stats are built from: its combat type, which splits its
/// level's stat budget between attack, defence and hitpoints.
class _CombatDebug extends StatelessWidget {
  const _CombatDebug({required this.monster});

  final CombatEntity monster;

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: 'Debug',
      children: [
        InfoTable(
          headers: const [''],
          rows: [
            InfoTableRow('Combat type', [monster.definition.combatType.label]),
          ],
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
            // the quality is in it because a table can list one item at
            // several, and a key has to be unique among its rows
            key: ValueKey(
              'drop-${drop.itemId.name}-${drop.rarity.name}'
              '${drop.locked ? '-locked' : ''}',
            ),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Opacity(
              // a fish past the player's level: in the table, but dimmed, with
              // the level it opens at where its odds would be
              opacity: drop.locked ? 0.5 : 1,
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
                    // scaled to the odds column: "Lv 35" and a lock run
                    // wider than a percentage does
                    child: drop.locked
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  'Lv ${drop.lockedUntil}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            formatPercent(drop.chance),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A labelled block of rows, matching the explore screen's section labels.

/// One label/value line. Values are right-aligned so a column of numbers
/// stays readable.
