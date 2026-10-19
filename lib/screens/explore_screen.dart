import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/inventory_grid.dart';

import '../data/skill_data.dart';
import '../data/zone_details.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../widgets/action_dock.dart';
import '../widgets/empty_state.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/list_row.dart';
import '../widgets/place_tile.dart';
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

  /// Skills trained by the explore action itself. The action loop's own
  /// three come from [ActivitySkillRingRow].
  static const _exploreSkills = [SkillId.EXPLORATION];

  /// The kind a discovery clusters under in the list. Everything that fights
  /// back pools under Combat whatever weapon skill it happens to train;
  /// everything else groups by the skill that gathers it.
  static SkillId _resourceGroupKey(EncounterEntity e) =>
      e is CombatEntity ? SkillId.ATTACK : e.entityType;

  /// The top-level tabs. Entities carries no count of its own: the list
  /// under it is the count.
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
  /// places, and the resource nodes exploring has turned up. [above] is the
  /// room over the label; 8 always sits under it. The body is inset 16, so
  /// the label's 4 puts it 20 from the screen's edge.
  Widget _sectionHeader(
    BuildContext context,
    String label, {
    required double above,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, above, 4, 8),
      child: Align(alignment: Alignment.centerLeft, child: SectionLabel(label)),
    );
  }

  Widget _emptyBody(BuildContext context, String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: EmptyState(message: text, icon: icon),
    );
  }

  /// A crafting skill's name, shortened where the full one would not fit a
  /// place tile's line.
  static String _shortSkillName(SkillId skill) => switch (skill) {
    SkillId.BLACKSMITHING => 'Smithing',
    SkillId.LEATHERWORKING => 'Leatherwork',
    SkillId.JEWELCRAFTING => 'Jewelcraft',
    _ => skillDisplayName(skill),
  };

  static IconData _craftIcon(SkillId skill) => switch (skill) {
    SkillId.BLACKSMITHING => Icons.hardware,
    SkillId.ENCHANTING => Icons.auto_awesome,
    SkillId.JEWELCRAFTING => Icons.diamond_outlined,
    SkillId.ALCHEMY => Icons.science_outlined,
    SkillId.LEATHERWORKING || SkillId.TAILORING => Icons.content_cut,
    _ => Icons.handyman,
  };

  /// One of the zone's places, as a tile in the places grid. Tapping it
  /// opens the place, as the card it replaces did.
  Widget _buildPlaceTile(WorldController worldController, Entity e) {
    void open() => worldController.navigateToEntity(e.id, context);

    // a firepit shows whatever is burning in it — the fire's art, its name
    // and its remaining time — and advertises cooking while a cookfire is
    // lit. check first: FirePitEntity is also a CraftingEntity.
    if (e is FirePitEntity) {
      final fire = context.watch<BuffController>().getZoneBuffFor(e.id);
      final lit =
          fire is FireItem && fire.expirationTime.isAfter(DateTime.now());
      return PlaceTile(
        key: ValueKey(e.id),
        id: lit ? fire.id : e.id,
        name: lit ? fire.name : e.name,
        subtitle: lit && fire.canCook
            ? 'Firemaking · Cooking'
            : skillDisplayName(e.craftingSkill),
        subtitleIcon: Icons.local_fire_department_outlined,
        kind: SpriteKind.fire,
        corner: lit ? _BurnTime(expirationTime: fire.expirationTime) : null,
        onTap: open,
      );
    }
    if (e is CraftingEntity) {
      return PlaceTile(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        subtitle: _shortSkillName(e.craftingSkill),
        subtitleIcon: _craftIcon(e.craftingSkill),
        kind: SpriteKind.crafting,
        onTap: open,
      );
    }
    if (e is ShopEntity) {
      return PlaceTile(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        subtitle: 'Buy & sell',
        subtitleIcon: Icons.paid_outlined,
        kind: SpriteKind.shop,
        fallbackIcon: Icons.storefront,
        onTap: open,
      );
    }
    if (e is FishingEntity) {
      // a spot asks for a Fishing level of its own, and locks until then
      return PlaceTile(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        subtitle: 'Fishing · Lv ${worldController.requiredLevelFor(e.id)}',
        subtitleIcon: Icons.phishing,
        kind: SpriteKind.gathering,
        locked: !worldController.meetsEntityRequirement(e.id),
        onTap: open,
      );
    }
    if (e is DungeonEntity) {
      // zone dungeons carry a rarity but no key: the rarity is the frame's
      // outline, and the line just says what it is
      return PlaceTile(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        subtitle: 'Dungeon',
        subtitleIcon: Icons.castle_outlined,
        kind: SpriteKind.dungeon,
        fallbackIcon: Icons.fort,
        onTap: open,
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

    // everything the zone can turn up that exploring hasn't found yet
    final discoveredIds = {for (final e in resources) e.id};
    final undiscovered = worldController
        .zoneDetails(worldController.viewedZoneId)
        .entities
        .where((d) => d.id is EntityId && !discoveredIds.contains(d.id))
        .toList();

    // every discoverable has one fixed slot, found or not: clustered by kind
    // (combat first, then the gathering skills in skill order), and in the
    // zone's own table order within a kind. an unfound card sits where it
    // will be once found, so a find never reshuffles the list
    final tableOrder = {
      for (var i = 0; i < zoneDef.discoverableEntities.length; i++)
        zoneDef.discoverableEntities[i].id: i,
    };
    int groupRank(SkillId key) => key == SkillId.ATTACK ? -1 : key.index;
    int slot(EntityId id) => tableOrder[id] ?? tableOrder.length;
    int bySlot(_ListSlot a, _ListSlot b) {
      final byGroup = groupRank(a.group).compareTo(groupRank(b.group));
      return byGroup != 0 ? byGroup : a.slot.compareTo(b.slot);
    }

    final foundSlots = [
      for (final e in resources)
        _ListSlot(
          group: _resourceGroupKey(e),
          slot: slot(e.id),
          build: () => _buildResourceCard(worldController, e),
        ),
    ];
    final unfoundSlots = [
      for (final d in undiscovered)
        _ListSlot(
          group: switch ((d.id as EntityId).build()) {
            final EncounterEntity e => _resourceGroupKey(e),
            _ => SkillId.NULL,
          },
          slot: slot(d.id as EntityId),
          build: () => _UndiscoveredCard(
            key: ValueKey('undiscovered-${d.name}'),
            discovery: d,
          ),
        ),
    ];

    final discoveries = [...foundSlots, ...unfoundSlots]..sort(bySlot);

    final tabBar = _tabBar(context, lootCount: zoneItems.length);

    final Widget tabBody = switch (_tab) {
      // permanent places and the resource nodes worked for materials share
      // a tab: the places as a grid of tiles, then the discoveries as a list
      _ExploreTab.entities =>
        structures.isEmpty && resources.isEmpty && undiscovered.isEmpty
            ? _emptyBody(context, 'Nothing here yet')
            : Column(
                children: [
                  if (structures.isNotEmpty) ...[
                    // 16 under the tabs, with their own 4 and the body's 4
                    _sectionHeader(context, 'Places', above: 8),
                    PlaceGrid(
                      tiles: [
                        for (final e in structures)
                          _buildPlaceTile(worldController, e),
                      ],
                    ),
                  ],
                  if (discoveries.isNotEmpty) ...[
                    _sectionHeader(
                      context,
                      'Discoveries',
                      above: structures.isEmpty ? 8 : 24,
                    ),
                    for (final entry in discoveries) entry.build(),
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
                // exploring is wandering the zone, so the button wears the
                // compass the activity button shows for it
                idleIcon: Icons.explore_outlined,
                isActive: worldController.isExploringViewed,
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

/// One row of the discoveries list: the kind it clusters under, its place
/// in the zone's table, and how to draw it — found or not.
class _ListSlot {
  const _ListSlot({
    required this.group,
    required this.slot,
    required this.build,
  });

  final SkillId group;
  final int slot;
  final Widget Function() build;
}

/// Something the zone can turn up that exploring hasn't found yet: its card,
/// blurred past reading so what it is stays a surprise. One still behind an
/// exploration level carries a lock and the level over the blur. It opens
/// nothing — there is nothing here to work until it is found.
class _UndiscoveredCard extends StatelessWidget {
  const _UndiscoveredCard({super.key, required this.discovery});

  final ZoneDiscovery discovery;

  @override
  Widget build(BuildContext context) {
    final world = context.read<WorldController>();
    final palette = context.palette;
    final id = discovery.id as EntityId;
    final entity = id.build();
    final encounter = entity is EncounterEntity ? entity : null;

    final card = ObjectCard(
      key: ValueKey(id),
      id: id,
      name: entity.name,
      count: 0,
      typeId: encounter?.entityType ?? id,
      kind: entity is CombatEntity ? SpriteKind.combat : SpriteKind.gathering,
      statLevel: encounter == null ? null : world.entityLevel(encounter),
      onTap: () {},
    );

    return Semantics(
      label: discovery.locked
          ? 'Undiscovered, unlocks at Exploration ${discovery.unlockLevel}'
          : 'Undiscovered',
      excludeSemantics: true,
      child: Stack(
        children: [
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: card,
            ),
          ),
          if (discovery.locked)
            Positioned.fill(
              // the card keeps an 8pt gap under itself; centre on the card
              bottom: 8,
              child: Center(
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: palette.bg.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.borderOverArt),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 16, color: palette.text),
                      const SizedBox(width: 6),
                      Text(
                        'Exploration ${discovery.unlockLevel}',
                        style: HearthText.timer.copyWith(color: palette.text),
                      ),
                    ],
                  ),
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

/// A lit fire's remaining burn time, in a pill over its tile's sprite.
class _BurnTime extends StatelessWidget {
  const _BurnTime({required this.expirationTime});

  final DateTime expirationTime;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.gameColors.fireTint.border),
      ),
      alignment: Alignment.center,
      child: CountdownTimer(expirationTime: expirationTime, size: 11),
    );
  }
}
