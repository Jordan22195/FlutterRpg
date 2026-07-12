import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

import '../controllers/action_queue_controller.dart';
import '../data/skill_data.dart';
import '../widgets/primary_button.dart';
import '../widgets/explore_card.dart';
import '../widgets/queue_add_button.dart';
import '../widgets/skill_ring_row.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  /// Active list filter: everything, only structures (permanent zone
  /// entities), or only one skill's resource nodes.
  bool _structuresOnly = false;
  SkillId? _skillFilter;

  /// Skills passively trained by the explore action itself.
  static const _exploreSkills = [
    SkillId.EXPLORATION,
    SkillId.STAMINA,
    SkillId.SPEED,
    SkillId.RECOVERY,
  ];

  void _selectAll() {
    setState(() {
      _structuresOnly = false;
      _skillFilter = null;
    });
  }

  void _selectStructures() {
    setState(() {
      _structuresOnly = true;
      _skillFilter = null;
    });
  }

  void _selectSkill(SkillId skill) {
    setState(() {
      _structuresOnly = false;
      _skillFilter = skill;
    });
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _filterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Widget? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        avatar: icon,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Widget _buildStructureCard(WorldController worldController, Entity e) {
    // campfires are crafting entities with a burn-out timer; check first
    if (e is CampfireEntity) {
      return ObjectCard(
        key: ValueKey(e.id),
        id: e.id,
        name: e.name,
        count: 0,
        expirationTime: e.expirationTime,
        typeId: e.craftingSkill,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldController = context.watch<WorldController>();
    final zoneDef = worldController.getCurrentZoneDefinition();
    final entities = worldController.getCurrentZoneEntities();

    // split the zone's entities into permanent structures and resource nodes
    final structures = <Entity>[];
    final resources = <EncounterEntity>[];
    for (final e in entities) {
      if (e is EncounterEntity) {
        resources.add(e);
      } else {
        structures.add(e);
      }
    }

    // one chip per skill actually present in this zone, in SkillId order
    final zoneSkills = resources.map((e) => e.entityType).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    resources.sort(
      (a, b) => a.entityType.index.compareTo(b.entityType.index),
    );

    // a filtered skill that just vanished from the zone falls back to All
    if (_skillFilter != null && !zoneSkills.contains(_skillFilter)) {
      _skillFilter = null;
    }

    final showAll = !_structuresOnly && _skillFilter == null;
    final visibleStructures = _structuresOnly || showAll
        ? structures
        : const <Entity>[];
    final visibleResources = _structuresOnly
        ? const <EncounterEntity>[]
        : resources
              .where((e) => _skillFilter == null || e.entityType == _skillFilter)
              .toList();

    final listChildren = <Widget>[
      if (visibleStructures.isNotEmpty) ...[
        if (showAll) _sectionLabel(context, "Structures"),
        for (final e in visibleStructures)
          _buildStructureCard(worldController, e),
      ],
      if (visibleResources.isNotEmpty) ...[
        if (showAll) _sectionLabel(context, "Resources"),
        for (final e in visibleResources)
          _buildResourceCard(worldController, e),
      ],
    ];

    // IMPORTANT: no Scaffold here — MainShell owns the Scaffold + BottomNav.
    return SafeArea(
      child: Column(
        children: [
          // Top "app bar" row with a back button that pops the MAP tab navigator
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

          // Exploration + energy-system skills trained by exploring
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SkillRingRow(
              skills: _exploreSkills,
              alignment: MainAxisAlignment.spaceEvenly,
            ),
          ),

          // Filter chips: All / Structures / one per zone skill
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _filterChip(
                  context: context,
                  label: "All",
                  selected: showAll,
                  onSelected: _selectAll,
                ),
                if (structures.isNotEmpty)
                  _filterChip(
                    context: context,
                    label: "Structures",
                    selected: _structuresOnly,
                    onSelected: _selectStructures,
                  ),
                for (final skill in zoneSkills)
                  _filterChip(
                    context: context,
                    label: skillDisplayName(skill),
                    selected: _skillFilter == skill,
                    onSelected: () => _selectSkill(skill),
                    icon: IconRendererChipAvatar(skill: skill),
                  ),
              ],
            ),
          ),

          // Filtered entity list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: listChildren,
            ),
          ),

          Row(
            children: [
              // Firemaking button
              Container(
                padding: const EdgeInsets.all(1),

                child: TextButton(
                  onPressed: () {
                    worldController.navigateToEntity(EntityId.FIREPIT, context);
                  },
                  child: ItemStackTile(
                    size: 56,
                    count: 0,
                    id: SkillId.FIREMAKING,
                    showInfoDialogOnTap: false,
                  ),
                ),
              ),

              // primary action button
              Padding(
                padding: const EdgeInsets.all(12),
                child: MomentumPrimaryButton(
                  enabled: true,
                  label: "Explore",
                  startActionFunction: () {
                    worldController.startExplore();
                  },
                ),
              ),
              SizedBox(width: 8),
              // stop action button
              StopPrimaryButton(),
              SizedBox(width: 8),
              QueueAddButton(
                enabled: true,
                onQueue: () =>
                    context.read<ActionQueueController>().enqueueExplore(),
              ),
            ],
          ),

          // Bottom action button (sits above the shell bottom nav automatically)
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
