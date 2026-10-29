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
import '../data/bound_action.dart';
import '../controllers/encounter_controller.dart';
import '../controllers/action_timing_controller.dart';
import '../data/level_standing.dart';
import '../controllers/player_data_controller.dart';
import '../data/zone_details.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../widgets/action_dock.dart';
import '../widgets/empty_state.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/list_row.dart';
import '../widgets/place_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/travel_row.dart';
import '../widgets/entity_info_dialog.dart';
import '../widgets/discovery_tile.dart';
import '../widgets/find_flash.dart';
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

  /// What the loop is running, read once per build so the tiles light up
  /// as an action starts, stops or moves on — and only then.
  BoundAction? _running;

  /// Whether [e] is what the action loop is running on right now: the
  /// fight, node or station it is bound to in the zone on screen, or the
  /// dungeon one of whose floors is running. A paused loop runs nothing.
  bool _isActive(WorldController worldController, Entity e) {
    final running = _running;
    if (running == null) return false;
    switch (running.kind) {
      case BoundActionKind.ENCOUNTER || BoundActionKind.CRAFT:
        return running.zoneId == worldController.viewedZoneId &&
            running.entityId == e.id;
      case BoundActionKind.DUNGEON_SLOT:
        return e is DungeonEntity &&
            context.read<EncounterController>().runningDungeonId == e.dungeonId;
      default:
        return false;
    }
  }

  /// Whether [e] lists under Places rather than Discoveries: anything that
  /// isn't fought or gathered for materials. A fishing spot is an encounter
  /// but never depletes, so it sits with the places too.
  static bool _isPlace(Entity e) => e is! EncounterEntity || e is FishingEntity;

  /// One of the zone's places, as a tile in the places grid. Tapping it
  /// opens the place, as the card it replaces did.
  Widget _buildPlaceTile(WorldController worldController, Entity e) {
    final active = _isActive(worldController, e);
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
        active: active,
        id: lit ? fire.id : e.id,
        name: lit ? fire.name : e.name,
        subtitle: lit && fire.canCook
            ? 'Firemaking · Cooking'
            : skillDisplayName(e.craftingSkill),
        // the skills it trains, by their sprites: a lit cookfire adds
        // cooking beside firemaking
        subtitleRow: PlaceLine(
          skills: [e.craftingSkill, if (lit && fire.canCook) SkillId.COOKING],
        ),
        kind: SpriteKind.fire,
        corner: lit ? _BurnTime(expirationTime: fire.expirationTime) : null,
        // what the burning fire is giving, in the chips its item wears
        leadingCorner: lit
            ? StatChips(
                key: const ValueKey('place-tile-fire-stats'),
                id: fire.id,
                tileSize: 56,
              )
            : null,
        onTap: open,
      );
    }
    if (e is CraftingEntity) {
      return PlaceTile(
        key: ValueKey(e.id),
        active: active,
        id: e.id,
        name: e.name,
        subtitle: skillDisplayName(e.craftingSkill),
        subtitleRow: PlaceLine(skills: [e.craftingSkill]),
        kind: SpriteKind.crafting,
        onTap: open,
      );
    }
    if (e is ShopEntity) {
      return PlaceTile(
        key: ValueKey(e.id),
        active: active,
        id: e.id,
        name: e.name,
        // a shop trains nothing, so its tile is its name alone
        subtitle: 'Shop',
        subtitleRow: const SizedBox.shrink(),
        kind: SpriteKind.shop,
        fallbackIcon: Icons.storefront,
        onTap: open,
      );
    }
    if (e is FishingEntity) {
      // a spot asks for a Fishing level of its own and a rod, and locks
      // until it has both. the level reads first; with it met, the rod
      final underLevel = !worldController.meetsEntityRequirement(e.id);
      final noRod = worldController.missingToolFor(e.id) != null;
      final required = worldController.requiredLevelFor(e.id);
      final needsRod = !underLevel && noRod;
      return PlaceTile(
        key: ValueKey(e.id),
        active: active,
        id: e.id,
        name: e.name,
        subtitle: needsRod
            ? noToolEquipped(SkillId.FISHING)
            : 'Fishing · Lv $required',
        // the skill's sprite and the level the spot asks for, coloured
        // against the player's fishing; a missing rod keeps its words
        subtitleRow: needsRod
            ? null
            : PlaceLine(
                skills: const [SkillId.FISHING],
                level: required > 0 ? required : null,
                // coloured against earned Fishing, which is what opens it
                standing: LevelStanding.of(
                  required,
                  context.watch<PlayerDataController>().getSkillLevel(
                    SkillId.FISHING,
                  ),
                ),
              ),
        kind: SpriteKind.gathering,
        locked: underLevel || noRod,
        onTap: open,
      );
    }
    if (e is DungeonEntity) {
      // zone dungeons carry a rarity but no key: the rarity is the frame's
      // outline, and the line is its combat level, read like a fight's
      final level = worldController.dungeonLevel(e);
      return PlaceTile(
        key: ValueKey(e.id),
        active: active,
        id: e.id,
        name: e.name,
        subtitle: level == null ? 'Dungeon' : 'Combat · Lv $level',
        subtitleRow: level == null
            ? const SizedBox.shrink()
            : PlaceLine(
                skills: const [SkillId.ATTACK],
                level: level,
                standing: LevelStanding.of(
                  level,
                  context.watch<PlayerDataController>().getCombatLevel(),
                ),
              ),
        kind: SpriteKind.dungeon,
        fallbackIcon: Icons.fort,
        onTap: open,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final worldController = context.watch<WorldController>();
    _running = context.select<ActionTimingController, BoundAction?>(
      (timing) => timing.runningAction,
    );
    final zoneDef = worldController.viewedZoneDefinition();
    final entities = worldController.viewedZoneEntities();
    final zoneItems = worldController.viewedZoneItems();

    // split the zone's entities into permanent structures and resource
    // nodes. fishing spots are encounter entities but never deplete, so
    // they belong with the structures rather than the counted nodes
    final structures = <Entity>[];
    final resources = <EncounterEntity>[];
    for (final e in entities) {
      if (_isPlace(e)) {
        structures.add(e);
      } else {
        resources.add(e as EncounterEntity);
      }
    }

    // everything the zone can turn up that exploring hasn't found yet —
    // places as well as resources, so a found dungeon isn't listed twice
    final discoveredIds = {for (final e in entities) e.id};
    final undiscovered = worldController
        .zoneDetails(worldController.viewedZoneId)
        .entities
        .where((d) => d.id is EntityId && !discoveredIds.contains(d.id))
        .toList();
    // an unfound place waits under Places, in the slot it will take once
    // found; only things to fight or gather wait under Discoveries
    final unfoundPlaces = [
      for (final d in undiscovered)
        if (_isPlace((d.id as EntityId).build())) d,
    ];
    final unfoundResources = [
      for (final d in undiscovered)
        if (!_isPlace((d.id as EntityId).build())) d,
    ];

    // every discoverable has one fixed slot, found or not: clustered by kind
    // (combat first, then the gathering skills in skill order). fights run
    // easiest first, by combat level; the gathering kinds keep the zone's own
    // table order. ties fall back to the table too. an unfound card sits
    // where it will be once found, so a find never reshuffles the list
    final tableOrder = {
      for (var i = 0; i < zoneDef.discoverableEntities.length; i++)
        zoneDef.discoverableEntities[i].id: i,
    };
    int groupRank(SkillId key) => key == SkillId.ATTACK ? -1 : key.index;
    int slot(EntityId id) => tableOrder[id] ?? tableOrder.length;
    int bySlot(_ListSlot a, _ListSlot b) {
      final byGroup = groupRank(a.group).compareTo(groupRank(b.group));
      if (byGroup != 0) return byGroup;
      if (a.group == SkillId.ATTACK) {
        final byLevel = a.level.compareTo(b.level);
        if (byLevel != 0) return byLevel;
      }
      return a.slot.compareTo(b.slot);
    }

    final foundSlots = [
      for (final e in resources)
        _ListSlot(
          group: _resourceGroupKey(e),
          slot: slot(e.id),
          level: worldController.entityLevel(e),
          build: () => FindFlash(
            key: ValueKey('find-flash-${e.id.name}'),
            sequence: worldController.exploreFindSequence,
            hit: worldController.lastFoundEntityIds.contains(e.id),
            foundAt: worldController.lastFoundAt,
            child: DiscoveryTile(
              key: ValueKey(e.id),
              entity: e,
              active: _isActive(worldController, e),
              onTap: () => worldController.navigateToEntity(e.id, context),
              onLongPress: () => showEntityInfoDialog(context, e),
            ),
          ),
        ),
    ];
    final unfoundSlots = [
      for (final d in unfoundResources)
        _ListSlot(
          group: switch ((d.id as EntityId).build()) {
            final EncounterEntity e => _resourceGroupKey(e),
            _ => SkillId.NULL,
          },
          slot: slot(d.id as EntityId),
          level: switch ((d.id as EntityId).build()) {
            final EncounterEntity e => worldController.entityLevel(e),
            _ => 0,
          },
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
      // a tab, each as a grid of tiles
      _ExploreTab.entities =>
        structures.isEmpty && resources.isEmpty && undiscovered.isEmpty
            ? _emptyBody(context, 'Nothing here yet')
            : Column(
                children: [
                  if (structures.isNotEmpty || unfoundPlaces.isNotEmpty) ...[
                    // 16 under the tabs, with their own 4 and the body's 4
                    _sectionHeader(context, 'Places', above: 8),
                    PlaceGrid(
                      tiles: [
                        for (final e in structures)
                          _buildPlaceTile(worldController, e),
                        for (final d in unfoundPlaces)
                          _UndiscoveredCard(
                            key: ValueKey('undiscovered-${d.name}'),
                            discovery: d,
                          ),
                      ],
                    ),
                  ],
                  if (discoveries.isNotEmpty) ...[
                    _sectionHeader(
                      context,
                      'Discoveries',
                      above: structures.isEmpty && unfoundPlaces.isEmpty
                          ? 8
                          : 24,
                    ),
                    PlaceGrid(
                      tiles: [for (final entry in discoveries) entry.build()],
                    ),
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
                  // a zone the player is not standing in has nothing to
                  // explore yet: its row is the road there instead
                  child: worldController.isViewingCurrentZone
                      ? ActionTimerRow(
                          key: const ValueKey('explore-row'),
                          label: 'Exploring',
                          color: context.gameColors.exploration,
                          // empty unless exploring is the action running:
                          // working an entity must not fill this zone's timer
                          progress: worldController.exploreProgress,
                          interval: worldController.exploreInterval,
                        )
                      : const TravelRow(key: ValueKey('travel-row')),
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

/// A discovery tile's second line: the skill's icon with the level beside
/// it, then how many are standing, in a chip.
/// One row of the discoveries list: the kind it clusters under, its place
/// in the zone's table, and how to draw it — found or not.
class _ListSlot {
  const _ListSlot({
    required this.group,
    required this.slot,
    required this.level,
    required this.build,
  });

  final SkillId group;
  final int slot;

  /// How hard it is — a fight's combat level, a node's defence. Fights
  /// sort by it.
  final int level;
  final Widget Function() build;
}

/// Something the zone can turn up that exploring hasn't found yet: its tile,
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

    final tile = PlaceTile(
      key: ValueKey(id),
      id: id,
      name: entity.name,
      subtitle: encounter == null ? '' : 'Lv ${world.entityLevel(encounter)}',
      kind: switch (entity) {
        CombatEntity() => SpriteKind.combat,
        DungeonEntity() => SpriteKind.dungeon,
        _ => SpriteKind.gathering,
      },
      onTap: null,
      // a creature's art has a margin of its own; sit closer
      spriteScale: 1.25,
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
              child: tile,
            ),
          ),
          if (discovery.locked)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.bg.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.borderOverArt),
                  ),
                  // stacked, so it fits a third of the screen's width
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 18, color: palette.text),
                      const SizedBox(height: 2),
                      Text(
                        'Exploration ${discovery.unlockLevel}',
                        maxLines: 1,
                        style: HearthText.timer.copyWith(
                          fontSize: 11,
                          color: palette.text,
                        ),
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
