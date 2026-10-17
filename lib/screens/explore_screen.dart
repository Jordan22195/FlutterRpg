import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/inventory_grid.dart';

import '../data/skill_data.dart';
import '../theme/hearth_theme.dart';
import '../widgets/action_dock.dart';
import '../widgets/empty_state.dart';
import '../widgets/hearth_chip.dart';
import '../widgets/list_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/entity_info_dialog.dart';
import '../widgets/explore_card.dart';
import '../widgets/skill_ring_row.dart';
import '../widgets/zone_header.dart';
import '../widgets/zone_info_body.dart';

/// What the zone list is showing: the permanent things you can walk into
/// or work for materials, what exploring has turned up here, or the zone's
/// own difficulty and discovery tables.
enum _ExploreTab { entities, loot, info }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  /// The zone list is one slot switched by tab, so the different kinds of
  /// thing a zone holds don't compete for the same scroll.
  _ExploreTab _tab = _ExploreTab.entities;

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
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required int count,
    Widget? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: HearthChip(
        label: label,
        count: count,
        icon: icon,
        selected: selected,
        onTap: onSelected,
      ),
    );
  }

  /// The top-level tabs. Entities carries no count of its own — the All
  /// chip under it does — so the list's size is said once.
  Widget _tabBar(BuildContext context, {required int lootCount}) {
    return SegmentedTabs<_ExploreTab>(
      segments: [
        const TabSegment(value: _ExploreTab.entities, label: 'Entities'),
        TabSegment(value: _ExploreTab.loot, label: 'Loot · $lootCount'),
        const TabSegment(value: _ExploreTab.info, label: 'Info'),
      ],
      selected: _tab,
      onChanged: (tab) => setState(() => _tab = tab),
    );
  }

  /// Labels the two halves of the entities tab: the zone's permanent
  /// places, and the resource nodes exploring has turned up.
  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Align(alignment: Alignment.centerLeft, child: SectionLabel(label)),
    );
  }

  Widget _emptyBody(BuildContext context, String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: EmptyState(message: text, icon: icon),
    );
  }

  Widget _buildStructureCard(WorldController worldController, Entity e) {
    // a firepit shows whatever is burning in it — the fire's art, its name
    // and its remaining time — and advertises cooking while a cookfire is
    // lit. check first: FirePitEntity is also a CraftingEntity.
    if (e is FirePitEntity) {
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
        kind: SpriteKind.fire,
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
        kind: SpriteKind.crafting,
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
        kind: SpriteKind.crafting,
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
        statLevel: worldController.entityLevel(e),
        kind: SpriteKind.gathering,
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
        kind: SpriteKind.dungeon,
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

    return ObjectCard(
      key: ValueKey(e.id),
      id: e.id,
      name: e.name,
      count: e.count,
      typeId: e.entityType,
      kind: e is CombatEntity ? SpriteKind.combat : SpriteKind.gathering,
      statLevel: worldController.entityLevel(e),
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
    final zoneDef = worldController.viewedZoneDefinition();
    final entities = worldController.viewedZoneEntities();
    final zoneItems = worldController.viewedZoneItems();

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

    final tabBar = _tabBar(context, lootCount: zoneItems.length);

    final Widget tabBody = switch (_tab) {
      // permanent structures and the resource nodes worked for materials
      // share a tab: structures list first, then the resource group chips
      _ExploreTab.entities =>
        structures.isEmpty && resources.isEmpty
            ? _emptyBody(context, 'Nothing here yet')
            : Column(
                children: [
                  if (structures.isNotEmpty) ...[
                    _sectionHeader(context, 'Places'),
                    for (final e in structures)
                      _buildStructureCard(worldController, e),
                  ],
                  if (resources.isNotEmpty) ...[
                    _sectionHeader(context, 'Discovered'),
                    // sub-tabs, each with its own total node count
                    SizedBox(
                      height: HearthChip.height,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip(
                            label: 'All',
                            count: totalResourceCount,
                            selected: _resourceGroup == null,
                            onSelected: () =>
                                setState(() => _resourceGroup = null),
                          ),
                          for (final key in groupKeys)
                            _filterChip(
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
                    const SizedBox(height: 8),
                    for (final e in openGroup)
                      _buildResourceCard(worldController, e),
                  ],
                ],
              ),

      // items turned up by exploring, kept per-zone
      _ExploreTab.loot =>
        zoneItems.isEmpty
            ? _emptyBody(
                context,
                'Nothing found here yet',
                icon: Icons.inventory_2_outlined,
              )
            : Card(child: InventoryGrid(items: zoneItems, shrinkWrap: true)),

      // the zone's own difficulty, finds-per-explore and discovery tables
      _ExploreTab.info => ZoneInfoBody(zoneId: worldController.viewedZoneId),
    };

    // IMPORTANT: no Scaffold here — MainShell owns the Scaffold + BottomNav.
    // the top is left open: the zone's art runs up behind the status bar,
    // and the header keeps its own rows clear of the inset
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // the zone's art and name collapse into a title bar as the list
          // scrolls, and the tabs pin beneath it, so switching tabs never
          // means scrolling back up
          Expanded(
            child: CustomScrollView(
              slivers: [
                ZoneHeader(
                  name: zoneDef.name,
                  iconAsset: zoneDef.iconAsset,
                  zoneLevel: zoneDef.explorationLevel,
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedTabBar(child: tabBar),
                ),
                SliverPadding(
                  // room at the bottom for the dock's fade to fall on
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverToBoxAdapter(child: tabBody),
                ),
              ],
            ),
          ),

          // the explore action's progress and the skills it trains sit with
          // the button that starts it, so they stay in view however far the
          // list is scrolled
          ActionDock(
            topRow: Row(
              children: [
                Expanded(
                  child: ActionTimerRow(
                    label: 'Exploring',
                    color: context.gameColors.exploration,
                    // empty unless exploring is the action running: working
                    // an entity must not fill this zone's timer
                    progress: worldController.exploreProgress,
                    interval: worldController.exploreInterval,
                  ),
                ),
                const SizedBox(width: 12),
                // Exploration + energy-system skills trained by exploring
                const ActivitySkillRingRow(
                  skills: _exploreSkills,
                  shrinkWrap: true,
                ),
              ],
            ),
            buttons: ActionButtonRow(
              padding: EdgeInsets.zero,
              actionButton: ActionOrTravelButton(
                enabled: true,
                label: "Explore",
                startActionFunction: () {
                  worldController.startExplore();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The explore tabs, held under the zone header while the list scrolls.
/// Opaque, so cards scrolling beneath it don't show through.
class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  const _PinnedTabBar({required this.child});

  final Widget child;

  /// The 48pt tabs, 12pt below whatever sits above them.
  static const double _height = 64;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: child,
      ),
    );
  }

  // the tab counts change with every find, and the delegate is rebuilt
  // with the screen anyway
  @override
  bool shouldRebuild(_PinnedTabBar oldDelegate) => true;
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
