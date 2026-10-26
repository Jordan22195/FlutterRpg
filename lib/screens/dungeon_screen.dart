import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/zones/zone_id.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/dungeon_controller.dart';
import '../data/entity_queue.dart';
import '../data/skill_data.dart';
import '../services/entity_screen_router_service.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../widgets/discovery_tile.dart';
import '../widgets/dungeon_floor_card.dart';
import '../widgets/entity_info_dialog.dart';
import '../widgets/fill_bar.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/zone_header.dart';
import 'encounter_screen.dart';

/// A dungeon: its art, how far down it the player has got, and its floors
/// on a rail, first at the top. The floor in hand — the one running, or the
/// next to clear — is open, its creatures in a 3-column grid over its boss
/// and a button that enters it: the ordinary encounter screen against its
/// queue, not yet fighting. Its action button starts the floor, which then
/// loops until something else takes the action. Every other floor is a
/// single row that opens on a tap.
///
/// There is no lobby and no leaving. Opening the list costs nothing and
/// backing out costs nothing — the floor you started keeps swinging while
/// you read the zone or the map. A floor cleared once is unlocked forever;
/// what an open floor holds, and what those entities drop, is read by
/// tapping their tiles. A sealed floor keeps its tiles blurred and shut
/// until it opens.
class DungeonScreen extends StatefulWidget {
  const DungeonScreen({super.key, required this.dungeonId});

  final DungeonId dungeonId;

  /// The open header's height: a touch shorter than a zone's, so the floor
  /// in hand starts in view.
  static const double headerHeight = 300;

  /// Whether [entity] is the boss its floor builds to.
  @visibleForTesting
  static bool isDungeonBoss(EncounterEntity entity) =>
      entity is CombatEntity && entity.definition.isDungeonBoss;

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends State<DungeonScreen> {
  /// Floors other than the current one the player has opened.
  final Set<int> _opened = {};

  static const double _floorGap = 16;
  static const double _railWidth = 28;

  /// From a floor's top to its rail node, which centres the node on a
  /// collapsed row.
  static const double _nodeTop =
      (DungeonFloorCard.collapsedHeight - FloorRailNode.size) / 2;

  /// The same for the chest card.
  static const double _chestNodeTop =
      (DungeonChestCard.height - FloorRailNode.size) / 2;

  DungeonId get dungeonId => widget.dungeonId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DungeonController>();
    if (!dungeonId.isReal) {
      return const SafeArea(child: Center(child: Text('Unknown dungeon')));
    }
    final def = dungeonId.definition;
    final slots = controller.slotsFor(dungeonId);
    final current = controller.currentFloor(dungeonId);
    // the floor the loop is firing into, while it fires — a paused loop
    // works nothing. read off the timing's run state alone, so the list
    // rebuilds as a floor starts or stops rather than every frame
    final looping = context.select<ActionTimingController, bool>(
      (timing) => timing.isRunning,
    );
    final activeFloor =
        looping &&
            controller.hasActiveRun &&
            controller.activeDungeonId == dungeonId
        ? controller.runningSlot
        : -1;
    final zoneName = _zoneNameOf(dungeonId);

    // IMPORTANT: no Scaffold here — MainShell owns the Scaffold + BottomNav.
    // the top is left open: the art runs up behind the status bar, and the
    // header keeps its own rows clear of the inset
    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          ZoneHeader(
            name: def.name,
            iconAsset: def.iconAsset,
            zoneLevel: 0,
            subtitle: [?zoneName, 'Dungeon'].join(' · '),
            expandedHeight: DungeonScreen.headerHeight,
            // nothing is left behind by walking out, so this is an ordinary
            // pop: the floor keeps running while the player looks around
            backLabel: zoneName == null ? 'Back' : 'Back to $zoneName',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (slots.isNotEmpty) ...[
                    _progress(context, controller, slots, current),
                    const SizedBox(height: 12),
                    _runControls(context, controller),
                    const SizedBox(height: 16),
                  ],
                  for (int i = 0; i < slots.length; i++) ...[
                    if (i > 0) const SizedBox(height: _floorGap),
                    _floor(
                      context,
                      controller,
                      slots,
                      i,
                      current: current,
                      activeFloor: activeFloor,
                    ),
                  ],
                  if (slots.isNotEmpty) ...[
                    const SizedBox(height: _floorGap),
                    _railed(
                      node: const ChestRailNode(),
                      nodeTop: _chestNodeTop,
                      child: DungeonChestCard(
                        title: '${def.name} Chest',
                        floorsCleared: controller.mainFloorsCleared(dungeonId),
                        floorCount: controller.mainFloorCount(dungeonId),
                        waiting: controller.chestsWaiting(dungeonId),
                        earned: controller.chestEarned(dungeonId),
                        onClaim: () => _claimChests(context, controller),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Floor 2 of 3" over one segment per floor: cleared floors full in the
  /// cleared green, the current one filling in the accent as its queue is
  /// fought down.
  Widget _progress(
    BuildContext context,
    DungeonController controller,
    List<EntityQueue> slots,
    int current,
  ) {
    final palette = context.palette;
    final style = HearthText.rowMeta.copyWith(fontWeight: FontWeight.w700);

    return Semantics(
      container: true,
      label: 'Dungeon progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progress',
                  style: style.copyWith(color: palette.text),
                ),
              ),
              Text(
                'Floor ${current + 1} of ${slots.length}',
                style: style.copyWith(color: palette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (int i = 0; i < slots.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: i == current
                      ? FillBar(
                          value: _foughtFraction(slots[i], i),
                          height: 6,
                          borderRadius: 3,
                          backgroundColor: palette.track,
                          foregroundColor: palette.accent,
                        )
                      : Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: controller.isCleared(dungeonId, i)
                                ? GameColors.clearedColor
                                : palette.track,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Loop floor / Loop dungeon, and Reset beside it.
  Widget _runControls(BuildContext context, DungeonController controller) {
    final palette = context.palette;
    Widget loopIcon(bool on) => Icon(
      on ? Icons.repeat_on_rounded : Icons.repeat_rounded,
      size: 14,
      color: palette.textMuted,
    );
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Loop mode',
            container: true,
            child: SegmentedTabs<bool>(
              height: 44,
              selected: controller.loopsDungeon(dungeonId),
              onChanged: (on) => controller.setLoopDungeon(dungeonId, on),
              segments: [
                TabSegment(
                  value: false,
                  label: 'Loop floor',
                  icon: loopIcon(false),
                ),
                TabSegment(
                  value: true,
                  label: 'Loop dungeon',
                  icon: loopIcon(true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        DungeonResetButton(onPressed: () => _reset(context, controller)),
      ],
    );
  }

  /// Sends the dungeon back to its first floor — asking first when that
  /// would throw anything away: floors cleared, or a floor mid-fight.
  Future<void> _reset(
    BuildContext context,
    DungeonController controller,
  ) async {
    final running =
        controller.hasActiveRun &&
        controller.activeDungeonId == dungeonId &&
        controller.runningSlot >= 0;
    var cleared = false;
    for (int i = 0; i < controller.slotsFor(dungeonId).length; i++) {
      if (controller.isCleared(dungeonId, i)) cleared = true;
    }
    if (running || cleared) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset to Floor 1?'),
          content: Text(
            [
              if (running) 'The floor you are fighting stops.',
              'Every floor below the first locks again until you clear '
                  'its way down, and the chest can be earned again.',
            ].join(' '),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    controller.resetDungeon(dungeonId);
    if (mounted) setState(_opened.clear);
  }

  /// Opens every waiting chest and shows what came out.
  Future<void> _claimChests(
    BuildContext context,
    DungeonController controller,
  ) async {
    final count = controller.chestsWaiting(dungeonId);
    final loot = controller.claimChests(dungeonId);
    if (count <= 0 || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          count == 1
              ? '${dungeonId.definition.name} Chest'
              : '$count ${dungeonId.definition.name} Chests',
        ),
        content: loot.isEmpty
            ? const Text('Empty this time.')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stack in loot)
                    ItemStackTile(size: 48, id: stack.id, count: stack.count),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// [child] beside its rail [node], [nodeTop] down from its top. With a
  /// [line], the rail runs on from the node down to the next one, which
  /// sits [nextNodeTop] into the item below.
  Widget _railed({
    required Widget node,
    required double nodeTop,
    required Widget child,
    Color? line,
    double nextNodeTop = _nodeTop,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (line != null)
          Positioned(
            left: _railWidth / 2 - 1,
            width: 2,
            top: nodeTop + FloorRailNode.size,
            bottom: -(_floorGap + nextNodeTop),
            child: ColoredBox(color: line),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _railWidth,
              child: Padding(
                padding: EdgeInsets.only(top: nodeTop),
                child: Center(child: node),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: child),
          ],
        ),
      ],
    );
  }

  /// One floor beside its rail node, with the rail running on down to the
  /// next floor's node — or, off the last floor, to the chest's.
  Widget _floor(
    BuildContext context,
    DungeonController controller,
    List<EntityQueue> slots,
    int i, {
    required int current,
    required int activeFloor,
  }) {
    final palette = context.palette;
    final floor = slots[i];
    final cleared = controller.isCleared(dungeonId, i);
    final lockReason = controller.lockReason(dungeonId, i);
    final isCurrent = i == current;
    final active = i == activeFloor;
    final expanded = isCurrent || _opened.contains(i);
    final standing = isCurrent
        ? FloorStanding.current
        : cleared
        ? FloorStanding.cleared
        : lockReason != null
        ? FloorStanding.locked
        : FloorStanding.open;

    final members = floor.members;
    final boss = members.isNotEmpty && DungeonScreen.isDungeonBoss(members.last)
        ? members.last
        : null;
    final queue = boss == null
        ? members
        : members.sublist(0, members.length - 1);
    final fights = members.every((m) => m is CombatEntity);
    final left = _left(floor);

    final card = DungeonFloorCard(
      label: 'Floor ${i + 1} · ${queue.length}${boss == null ? '' : ' + boss'}',
      title: floor.name,
      standing: standing,
      expanded: expanded,
      active: active,
      lockReason: lockReason,
      stats: _statsLine(controller, i),
      note: _keyNote(context, controller, i),
      pill: active
          ? FloorPill(
              label: 'Fighting · $left left',
              color: palette.accent,
              border: palette.accent,
            )
          : lockReason != null
          ? FloorPill(
              label: lockReason,
              icon: Icons.lock,
              color: palette.textMuted,
              border: palette.borderStrong,
            )
          : cleared
          ? FloorPill.cleared()
          : isCurrent
          ? FloorPill(
              label: 'Up next · $left ${fights ? 'kills' : 'left'}',
              color: palette.text,
              fill: palette.raised,
            )
          : null,
      // tapping a tile reads what it is and what it drops; a sealed floor's
      // tiles are hidden and take no taps
      tiles: [
        for (final entity in queue)
          DiscoveryTile(
            entity: entity,
            onTap: () => showEntityInfoDialog(context, entity),
          ),
      ],
      boss: boss == null
          ? null
          : BossRow(
              entity: boss,
              onTap: () => showEntityInfoDialog(context, boss),
            ),
      action: controller.startable(dungeonId, i)
          ? FloorActionButton(
              label: '${fights ? 'Fight' : 'Enter'} Floor ${i + 1}',
              icon: fights
                  ? const IconRenderer(id: SkillId.ATTACK, size: 20)
                  : Icon(Icons.login, size: 20, color: palette.onAccent),
              onPressed: () => _openSlot(context, controller, i),
            )
          : null,
      onToggle: isCurrent
          ? null
          : () => setState(() {
              if (!_opened.remove(i)) _opened.add(i);
            }),
    );

    final isLast = i == slots.length - 1;
    return _railed(
      node: FloorRailNode(standing: standing),
      nodeTop: _nodeTop,
      // green behind a cleared floor, plain ahead of the player
      line: cleared ? GameColors.clearedColor : palette.borderStrong,
      nextNodeTop: isLast ? _chestNodeTop : _nodeTop,
      child: card,
    );
  }

  /// How many are still standing on [floor], from the member being fought
  /// to the boss.
  static int _left(EntityQueue floor) {
    var left = 0;
    for (int i = floor.index; i < floor.members.length; i++) {
      left += floor.members[i].count;
    }
    return left;
  }

  /// How much of floor [index] has been fought down this lap, 0 to 1.
  double _foughtFraction(EntityQueue floor, int index) {
    final entries = dungeonId.definition.entries;
    if (index >= entries.length) return 0;
    var total = 0;
    for (final ref in entries[index].entities) {
      total += ref.count;
    }
    if (total <= 0) return 0;
    return (1 - _left(floor) / total).clamp(0.0, 1.0);
  }

  /// The zone whose entrance leads into [id], or null for a map landmark.
  static String? _zoneNameOf(DungeonId id) {
    bool leadsHere(EntityId e) {
      final def = e.definition;
      return def is DungeonEntityDefinition && def.dungeonId == id;
    }

    for (final zone in ZoneId.values) {
      final def = zone.definition;
      if (def.permanentEntities.any(leadsHere) ||
          def.discoverableEntities.any((entry) => leadsHere(entry.id))) {
        return def.name;
      }
    }
    return null;
  }

  /// How much of this floor the player has done: everything ever, and the
  /// laps since this floor last started. Null until it has been cleared once
  /// — a floor with nothing to report says nothing.
  String? _statsLine(DungeonController controller, int index) {
    final lifetime = controller.lifetimeRuns(dungeonId, index);
    if (lifetime <= 0) return null;
    final session = controller.sessionRuns(dungeonId, index);
    final runs = '$lifetime ${lifetime == 1 ? 'run' : 'runs'}';
    if (session <= 0) return runs;
    return '$runs · $session this session';
  }

  /// The entry key a keyed dungeon's first floor is about to charge, so it
  /// never leaves the bag unannounced. Charged once, ever.
  Widget? _keyNote(
    BuildContext context,
    DungeonController controller,
    int index,
  ) {
    if (!controller.showsKeyNote(dungeonId, index)) return null;

    final palette = context.palette;
    final paid = controller.keyPaid(dungeonId);
    final held = controller.keyCount(dungeonId);
    final label = paid
        ? 'Unlocked'
        : held > 0
        ? 'Key ready'
        : 'No key';

    return Row(
      children: [
        ItemStackTile(
          size: 28,
          count: held,
          id: controller.keyItemId(dungeonId),
          showInfoDialogOnTap: false,
          depleted: paid || held <= 0,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: HearthText.rowMeta.copyWith(
            fontSize: 12,
            color: paid || held > 0
                ? palette.textMuted
                : GameColors.missingColor,
          ),
        ),
      ],
    );
  }

  Future<void> _openSlot(
    BuildContext context,
    DungeonController controller,
    int i,
  ) async {
    final navigator = Navigator.of(context);

    // spending the key is irreversible, so it is never charged on a stray
    // tap — even though it only ever happens once
    if (controller.willSpendKey(dungeonId, i)) {
      final keyName = controller.keyItemId(dungeonId).definition.name;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Spend 1 $keyName?'),
          content: const Text(
            'Entering costs the key, once. After that this dungeon stays '
            'open for good.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Spend key'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // entering opens the floor without starting it: the fight begins on
    // the encounter screen's action button, as any other encounter does
    final token = controller.enterSlot(dungeonId, i);
    if (token == null) return;
    await navigator.push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: EntityScreenRouterService.encounterRouteName,
          arguments: i,
        ),
        builder: (_) => const EncounterScreen(),
      ),
    );
    controller.leaveSlot(token);
  }
}
