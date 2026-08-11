import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/inventory_grid.dart';

import '../data/skill_data.dart';
import '../widgets/primary_button.dart';
import '../widgets/entity_info_dialog.dart';
import '../widgets/explore_card.dart';
import '../widgets/skill_ring_row.dart';
import 'zone_detail_screen.dart';

/// What the zone list is showing: the permanent things you can walk into,
/// the nodes you work for materials, or what exploring has turned up here.
enum _ExploreTab { structures, resources, loot }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  /// The zone list is one slot switched by tab, so the three kinds of thing
  /// a zone holds don't compete for the same scroll.
  _ExploreTab _tab = _ExploreTab.resources;

  /// Which resource sub-tab is open, keyed the way [_resourceGroupKey] keys
  /// them. Null is the All chip — every resource in the zone, which is where
  /// the tab opens and where a group that leaves the zone falls back to.
  SkillId? _resourceGroup;

  /// Skills trained by the explore action itself. The action loop's own
  /// three come from [ActivitySkillRingRow].
  static const _exploreSkills = [SkillId.EXPLORATION];

  /// The sub-tab a resource node belongs to. Everything that fights back
  /// pools under one Combat group whatever weapon skill it happens to
  /// train; everything else groups by the skill that gathers it.
  static SkillId _resourceGroupKey(EncounterEntity e) =>
      e is CombatEntity ? SkillId.ATTACK : e.entityType;

  static String _resourceGroupLabel(SkillId key) =>
      key == SkillId.ATTACK ? 'Combat' : skillDisplayName(key);

  Widget _filterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required int count,
    Widget? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        avatar: icon,
        // the count rides alongside the label and inherits the chip's own
        // label color, so it stays legible selected or not
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 5),
            Opacity(opacity: 0.6, child: Text("$count")),
          ],
        ),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onSelected(),
      ),
    );
  }

  /// The three top-level tabs, each carrying how much of that kind the zone
  /// holds. The segments share the row's width evenly, so the labels are
  /// kept compact enough to survive a narrow screen.
  Widget _tabBar(BuildContext context, Map<_ExploreTab, int> counts) {
    const labels = {
      _ExploreTab.structures: 'Structures',
      _ExploreTab.resources: 'Resources',
      _ExploreTab.loot: 'Loot',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_ExploreTab>(
          segments: [
            for (final tab in _ExploreTab.values)
              ButtonSegment<_ExploreTab>(
                value: tab,
                label: Text(
                  '${labels[tab]} · ${counts[tab] ?? 0}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          selected: {_tab},
          // single-select: the set always holds exactly one tab
          onSelectionChanged: (selection) =>
              setState(() => _tab = selection.first),
          // the label already says which tab is open; the checkmark only
          // costs width the counts need
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _emptyBody(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildStructureCard(WorldController worldController, Entity e) {
    // a firepit shows whatever is burning in it — the fire's art, its name
    // and its remaining time — and advertises cooking while a cookfire is
    // lit. check first: FirepitEntity is also a CraftingEntity.
    if (e is FirepitEntity) {
      final fire = context.watch<BuffController>().getZoneBuffFor(e.id);
      final lit =
          fire is FireItem && fire.expirationTime.isAfter(DateTime.now());

      // the id is an ItemId when lit and an EntityId when cold, so the card
      // is built over Enum. art resolves dynamically either way.
      return ObjectCard<Enum>(
        key: ValueKey(e.id),
        id: lit ? fire.id : e.id,
        name: lit ? fire.name : e.name,
        count: 0,
        expirationTime: lit ? fire.expirationTime : null,
        typeId: e.craftingSkill,
        typeIds: [e.craftingSkill, if (lit && fire.canCook) SkillId.COOKING],
        isStructure: true,
        onTap: () => worldController.navigateToEntity(e.id, context),
      );
    }
    if (e is CraftingEntity) {
      return ObjectCard(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        count: 0,
        typeId: e.craftingSkill,
        isStructure: true,
        onTap: () => worldController.navigateToEntity(e.id, context),
      );
    }
    if (e is ShopEntity) {
      return ObjectCard(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        count: 0,
        typeId: e.id,
        subtitle: "Shop",
        isStructure: true,
        onTap: () => worldController.navigateToEntity(e.id, context),
      );
    }
    if (e is FishingEntity) {
      return ObjectCard(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        count: 0,
        typeId: e.entityType,
        isStructure: true,
        onTap: () => worldController.navigateToEntity(e.id, context),
        onIconTap: () => showEntityInfoDialog(context, e),
      );
    }
    if (e is DungeonEntity) {
      return ObjectCard(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        count: 0,
        typeId: e.id,
        subtitle: "Dungeon",
        isStructure: true,
        onTap: () => worldController.navigateToEntity(e.id, context),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildResourceCard(
    WorldController worldController,
    EncounterEntity e,
  ) {
    final requiredLevel = worldController.requiredLevelFor(e.id);
    final locked = !worldController.meetsEntityRequirement(e.id);

    // level-gated nodes surface their gate even when unlocked
    final subtitle = requiredLevel > 0 && !locked
        ? "${skillDisplayName(e.entityType)} · Lv $requiredLevel"
        : null;

    return ObjectCard(
      key: ValueKey(e.id),
      id: e.id,
      name: e.name,
      count: e.count,
      typeId: e.entityType,
      subtitle: subtitle,
      xpPerUnit: worldController.xpPerUnit(e),
      locked: locked,
      requiredLevel: requiredLevel,
      onTap: () => worldController.navigateToEntity(e.id, context),
      onIconTap: () => showEntityInfoDialog(context, e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldController = context.watch<WorldController>();
    final zoneDef = worldController.getCurrentZoneDefinition();
    final entities = worldController.getCurrentZoneEntities();
    final zoneItems = worldController.getCurrentZoneItems();

    // split the zone's entities into permanent structures and resource
    // nodes. fishing spots are encounter entities but never deplete, so
    // they belong with the structures rather than the counted nodes
    final structures = <Entity>[];
    final resources = <EncounterEntity>[];
    for (final e in entities) {
      if (e is EncounterEntity && e is! FishingEntity) {
        resources.add(e);
      } else {
        structures.add(e);
      }
    }

    // resource sub-tabs: one group per skill the zone's nodes train, with
    // everything that fights back pooled under Combat
    final groups = <SkillId, List<EncounterEntity>>{};
    for (final e in resources) {
      groups.putIfAbsent(_resourceGroupKey(e), () => []).add(e);
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        // combat leads; the gathering skills follow in SkillId order
        if (a == b) return 0;
        if (a == SkillId.ATTACK) return -1;
        if (b == SkillId.ATTACK) return 1;
        return a.index.compareTo(b.index);
      });

    // counters: resource nodes stack, so a group's total is the sum of its
    // node counts rather than the number of cards. structures are always
    // one apiece, and loot is counted in stacks.
    final groupTotals = <SkillId, int>{
      for (final key in groupKeys)
        key: groups[key]!.fold(0, (sum, e) => sum + e.count),
    };
    final totalResourceCount = groupTotals.values.fold(0, (sum, c) => sum + c);

    // a sub-tab whose nodes just left the zone falls back to All
    if (_resourceGroup != null && !groups.containsKey(_resourceGroup)) {
      _resourceGroup = null;
    }
    // All lists every group in sub-tab order, so the kinds stay clustered
    final openGroup = _resourceGroup != null
        ? groups[_resourceGroup]!
        : [for (final key in groupKeys) ...groups[key]!];

    final listChildren = <Widget>[
      _tabBar(context, {
        _ExploreTab.structures: structures.length,
        _ExploreTab.resources: totalResourceCount,
        _ExploreTab.loot: zoneItems.length,
      }),

      switch (_tab) {
        _ExploreTab.structures =>
          structures.isEmpty
              ? _emptyBody(context, 'Nothing built here')
              : Column(
                  children: [
                    for (final e in structures)
                      _buildStructureCard(worldController, e),
                  ],
                ),

        _ExploreTab.resources =>
          resources.isEmpty
              ? _emptyBody(context, 'No resources here')
              : Column(
                  children: [
                    // sub-tabs, each with its own total node count
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        children: [
                          _filterChip(
                            context: context,
                            label: 'All',
                            count: totalResourceCount,
                            selected: _resourceGroup == null,
                            onSelected: () =>
                                setState(() => _resourceGroup = null),
                          ),
                          for (final key in groupKeys)
                            _filterChip(
                              context: context,
                              label: _resourceGroupLabel(key),
                              count: groupTotals[key] ?? 0,
                              selected: _resourceGroup == key,
                              onSelected: () =>
                                  setState(() => _resourceGroup = key),
                              icon: IconRendererChipAvatar(skill: key),
                            ),
                        ],
                      ),
                    ),
                    for (final e in openGroup)
                      _buildResourceCard(worldController, e),
                  ],
                ),

        // items turned up by exploring, kept per-zone
        _ExploreTab.loot =>
          zoneItems.isEmpty
              ? _emptyBody(context, 'Nothing found here yet')
              : Card(child: InventoryGrid(items: zoneItems, shrinkWrap: true)),
      },
    ];
    listChildren.insert(
      0, // Exploration + energy-system skills trained by exploring
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ActivitySkillRingRow(
          skills: _exploreSkills,
          alignment: MainAxisAlignment.spaceEvenly,
        ),
      ),
    );
    listChildren.insert(
      0,
      // exploring has no target and no health, so the action timer is a row
      // of its own — same label column and same slot on the screen the
      // combat and gathering timers occupy, so it never moves between them
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
        child: ActionTimerRow(
          label: 'Exploring',
          // empty unless exploring is the action running: working an entity
          // must not fill this zone's timer
          progress: worldController.exploreProgress,
          interval: worldController.exploreInterval,
        ),
      ),
    );
    listChildren.insert(
      0,
      // the zone art doubles as the way into the zone's detail screen,
      // where its discoveries and exploration gates are listed
      InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ZoneDetailScreen(zoneId: zoneDef.id),
          ),
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 140,
              child: zoneDef.iconAsset.isEmpty
                  ? const ColoredBox(color: Colors.black26)
                  : Image.asset(
                      zoneDef.iconAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Colors.black26),
                    ),
            ),
            // the art alone doesn't read as tappable, so say so
            Positioned(
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.travel_explore, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Zone details',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // IMPORTANT: no Scaffold here — MainShell owns the Scaffold + BottomNav.
    return SafeArea(
      child: Column(
        children: [
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
          // Zone header, art and skill rings, then the tabbed zone list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: listChildren,
            ),
          ),

          // Bottom action bar (sits above the shell bottom nav automatically)
          ActionButtonRow(
            actionButton: MomentumPrimaryButton(
              enabled: true,
              label: "Explore",
              startActionFunction: () {
                worldController.startExplore();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Small skill icon sized for a ChoiceChip avatar.
class IconRendererChipAvatar extends StatelessWidget {
  const IconRendererChipAvatar({super.key, required this.skill});

  final SkillId skill;

  @override
  Widget build(BuildContext context) {
    final image = SkillController.imageProviderFor(skill);
    if (image == null) return const SizedBox.shrink();
    return Image(
      image: image,
      width: 18,
      height: 18,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
