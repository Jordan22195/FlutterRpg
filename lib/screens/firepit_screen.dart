import 'package:flutter/material.dart';
import 'package:rpg/theme/hearth_theme.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:provider/provider.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/buff_controller.dart';
import '../controllers/crafting_controller.dart';
import '../data/skill_data.dart';
import '../controllers/world_controller.dart';
import '../theme/hearth_text.dart';
import '../widgets/action_dock.dart';
import '../widgets/art_header.dart';
import '../widgets/crafting_info_panel.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/list_row.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/stage_panel.dart';
import '../widgets/travel_row.dart';
import '../widgets/recipe_picker_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/recipe_card.dart';
import '../widgets/skill_ring_row.dart';
import '../widgets/stage_buff_icons.dart';

/*
firepit screen contents:
-the zone's art strip, naming whatever is burning, or the firepit when it
 is cold
-the fire on a stage, with a small chip in its corner: each stat it gives
 as its icon and +x, and the time it has left. every fire is a steady burn
 - each lay adds its burn time
-a firemaking recipe tile with the cooking tile beside it; the highlighted
 tile is what the action button runs. tapping a tile highlights it;
 tapping the highlighted tile opens its recipe picker (an empty card opens
 it on the first tap). with the fire card highlighted the button builds
 the picked fire over and over. a bonfire is its own recipe per stat: its
 logs and the reagent that picks the stat. the cooking card is locked
 until a cookfire is picked; the button then cooks, lighting the picked
 cookfire on its first tick and relighting it whenever it burns out
-the Tending timer and the skill rings
-tabbed panel of items cooked this session and recipe stats
-the dock: stop, the button naming its action, and put-out beside it
*/

/// The firepit's recipe cards: the fire, and the cooking card beside it.
enum _Section { fire, cook }

class FirepitScreen extends StatefulWidget {
  const FirepitScreen({super.key});

  @override
  State<FirepitScreen> createState() => _FirepitScreenState();
}

class _FirepitScreenState extends State<FirepitScreen>
    with TickerProviderStateMixin {
  /// Which of the stacked recipe cards the action button runs. Null until
  /// the player picks one, which reads as the fire.
  _Section? _activeSection;

  _Section _resolveActiveSection(
    CraftingController controller, {
    required bool cookingUnlocked,
  }) {
    // until the player picks a card, a running action owns the selection,
    // so a screen opened mid-action describes what it is doing. a pick
    // always wins after that: the button runs whatever is highlighted
    final running = context.read<ActionTimingController>().isRunning;
    if (running && _activeSection == null) {
      final active = controller.getRecipe(controller.activeRecipeId);
      if (active.skill == SkillId.COOKING) return _Section.cook;
      if (active.skill == SkillId.FIREMAKING) return _Section.fire;
    }

    // whatever card was picked runs — cooking only while a cookfire is
    // picked, so picking another fire hands the button back to the fire
    if (_activeSection == _Section.cook && cookingUnlocked) {
      return _Section.cook;
    }
    return _Section.fire;
  }

  void _showRecipePicker(
    BuildContext context,
    CraftingController controller,
    _Section section,
  ) {
    final skill = section == _Section.cook
        ? SkillId.COOKING
        : SkillId.FIREMAKING;
    showRecipePickerSheet(
      context,
      title: controller.stationEntityId.definition.name,
      skill: skill,
      recipes: controller.availableRecipesFor(skill),
      onSelected: (r) {
        controller.selectRecipe(r.id);
        setState(() => _activeSection = section);
      },
    );
  }

  /// A card's first tap makes it the one the action button runs; tapped
  /// again while it already is, it opens its recipe picker. An empty card
  /// has nothing to run, so it opens the picker straight away.
  void _onCardTap(
    CraftingController controller,
    _Section section, {
    required _Section active,
    required String recipeId,
  }) {
    if (section != active && recipeId.isNotEmpty) {
      setState(() => _activeSection = section);
      return;
    }
    setState(() => _activeSection = section);
    _showRecipePicker(context, controller, section);
  }

  Future<void> _confirmPutOut(
    BuildContext context,
    CraftingController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Put out the fire?'),
        content: const Text(
          'The remaining burn time and its buff are lost. The logs are '
          'not returned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Put out'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.putOutFire();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CraftingController>();
    // BuffController ticks once a second, so watching it is what makes the
    // put-out button disappear when a fire burns out
    context.watch<BuffController>();
    final fire = controller.activeFire();
    final canCook = fire?.canCook ?? false;

    final fireRecipeId = controller.selectedRecipeIdFor(SkillId.FIREMAKING);
    final cookRecipeId = controller.selectedRecipeIdFor(SkillId.COOKING);

    // cooking is always on screen, but locked until the picked fire is a
    // cookfire: the cook lights and relights that fire itself, so without
    // one there is nothing for it to cook over
    final cookFireRecipe = controller.cookFireRecipe();
    final cookingUnlocked = cookFireRecipe != null;
    final activeSection = _resolveActiveSection(
      controller,
      cookingUnlocked: cookingUnlocked,
    );

    final selectedId = switch (activeSection) {
      _Section.cook => cookRecipeId,
      _Section.fire => fireRecipeId,
    };

    // cooking runs on a lit cookfire, or on the logs to light the picked
    // one
    final canAct =
        selectedId.isNotEmpty &&
        controller.getMaxNumberCraftsForRecipe(selectedId) > 0 &&
        switch (activeSection) {
          _Section.cook => canCook || controller.canRelight(),
          _Section.fire => true,
        };

    // both rings always: a firepit is where cooking is trained, and a row
    // that grows from one ring to two re-centres itself, sliding the
    // firemaking ring sideways the moment a cookfire catches
    const skills = <SkillId>[SkillId.FIREMAKING, SkillId.COOKING];

    final actionLabel = _actionLabel(activeSection, fire, fireRecipeId);

    final zone = context.watch<WorldController>().viewedZoneDefinition();
    final topPadding = MediaQuery.paddingOf(context).top;
    final colors = context.gameColors;

    // the top is left open: the zone's art strip runs up behind the status
    // bar, as on the zone screen this one opens from
    return SafeArea(
      top: false,
      child: Column(
        children: [
          SizedBox(
            height: ArtHeader.collapsedHeight(topPadding),
            child: ArtHeader(
              title: fire?.name ?? 'Firepit',
              subtitle: zone.name,
              collapse: 1,
              artAsset: zone.iconAsset.isEmpty ? null : zone.iconAsset,
              backLabel: 'Back to ${zone.name}',
              trailing: ArtHeaderChip(
                icon: Icon(
                  Icons.local_fire_department_outlined,
                  size: 16,
                  color: colors.firemaking,
                ),
                label: 'Firemaking',
              ),
            ),
          ),

          Expanded(
            child: ListView(
              // no room under the tabs: a screen whose content fits springs
              // back to rest when dragged, instead of settling scrolled
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                // the fire on its stage, what it gives and its time left in
                // the corner
                _FireHero(fire: fire, key: ValueKey(fire?.id ?? ItemId.NULL)),
                const SizedBox(height: 4),

                // the fire the pit burns is always the first choice, and the
                // second recipe stands beside it rather than hiding in a
                // tab: both stay in view, and the highlighted tile is the
                // one the action button runs. cooking waits, locked, until a
                // cookfire is the picked fire.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel('Firemaking'),
                            _FireRecipeCard(
                              recipeId: fireRecipeId,
                              burningFireId: fire?.id,
                              selected: activeSection == _Section.fire,
                              onTap: () => _onCardTap(
                                controller,
                                _Section.fire,
                                active: activeSection,
                                recipeId: fireRecipeId,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel('Cooking'),
                            // locked: greyed and shut to taps, so it can be neither
                            // picked nor run until the fire above is a cookfire
                            IgnorePointer(
                              ignoring: !cookingUnlocked,
                              child: Opacity(
                                opacity: cookingUnlocked ? 1 : 0.45,
                                child: FirepitRecipeTile(
                                  key: const ValueKey('firepit-cooking-card'),
                                  recipeId: cookRecipeId,
                                  skill: SkillId.COOKING,
                                  selected: activeSection == _Section.cook,
                                  onTap: () => _onCardTap(
                                    controller,
                                    _Section.cook,
                                    active: activeSection,
                                    recipeId: cookRecipeId,
                                  ),
                                ),
                              ),
                            ),
                            // locked, it says what opens it
                            if (cookFireRecipe == null)
                              const _CardHint(
                                icon: Icons.lock_outline,
                                text: 'Pick a cookfire to cook',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // the pit's action timer, in the row of its own the other
                // station screens give it
                // a pit a zone away is walked to first: its row is the road
                // there until the player arrives
                if (context.watch<WorldController>().isViewingCurrentZone)
                  ActionTimerRow(
                    label: 'Tending',
                    color: colors.firemaking,
                    progress: controller.craftProgress,
                    interval: controller.craftInterval,
                  )
                else
                  const TravelRow(),
                const SizedBox(height: 12),

                // the skills the pit trains stay in view whichever recipe is
                // picked; the buffs a fire grants are in the panel below
                const ActivitySkillRingRow(skills: skills, spacing: 14),
                const SizedBox(height: 16),

                // what the session cooked and the recipe stats share one
                // slot, switched by tab
                CraftingInfoPanel(
                  items: controller.craftedItems(),
                  equipment: controller.craftedEquipment(),
                  craftedLabel: 'Cooked',
                  emptyCraftedLabel: 'Nothing cooked this session',
                  emptyIcon: Icons.local_fire_department_outlined,
                  // the highlighted card owns the stats tab: the firepit
                  // keeps a separate selection per skill
                  recipeId: selectedId,
                ),
              ],
            ),
          ),

          // which of the two sections the button runs is the whole point of
          // this screen, so the button names its action on its face
          ActionDock(
            buttons: ActionButtonRow(
              padding: EdgeInsets.zero,
              trailingWidth: kActionBarSideButtonWidth,
              actionButton: ActionOrTravelButton(
                enabled: canAct,
                label: actionLabel,
                showLabel: true,
                // running only when the highlighted recipe is the one being
                // made: picking another fire mid-burn puts it back at rest
                isActive: () =>
                    controller.isCraftingHere() &&
                    controller.activeRecipeId == selectedId,
                startActionFunction: () {
                  controller.startCraftingActionFor(
                    selectedId,
                    controller.stationEntityId,
                  );
                },
              ),
              trailing: [
                if (fire != null)
                  _PutOutFireButton(
                    onTap: () => _confirmPutOut(context, controller),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Add Logs" only when the selected fire is the one already burning —
  /// anything else lights a new fire in its place.
  String _actionLabel(_Section section, FireItem? fire, String fireRecipeId) {
    if (section == _Section.cook) return 'Cook';
    if (fire == null) return 'Light Fire';
    final selected = context.read<CraftingController>().getRecipe(fireRecipeId);
    final selectedFireId = selected.output.isEmpty
        ? null
        : selected.output.first.id;
    return selectedFireId == fire.id ? 'Add Logs' : 'Light Fire';
  }
}

/// The fire on a fire-tinted stage; a cold firepit shows the bare pit. A
/// small chip in its corner says what the fire gives and how long it has
/// left.
class _FireHero extends StatelessWidget {
  const _FireHero({super.key, required this.fire});

  final FireItem? fire;

  @override
  Widget build(BuildContext context) {
    final f = fire;
    return StagePanel(
      tint: context.gameColors.fireTint,
      height: 168,
      sprite: SpriteFrame.sprite(f?.id ?? EntityId.FIREPIT, size: 92),
      corner: f == null ? null : _FireTimerChip(fire: f),
      buffs: StageBuffIcons.ifAny(context),
    );
  }
}

/// In the corner of a burning fire's stage: each stat it gives, as the
/// stat's icon and "+x", then the time it has left ("4:05").
class _FireTimerChip extends StatelessWidget {
  const _FireTimerChip({required this.fire});

  final FireItem fire;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = HearthText.rowMeta.copyWith(
      fontSize: 12,
      height: 1,
      color: palette.text,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final left = fire.expirationTime.difference(DateTime.now());
    return Container(
      key: const ValueKey('fire-timer-chip'),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final bonus in fire.skillBonus.entries) ...[
            IconRenderer<SkillId>(
              key: ValueKey('fire-timer-skill-${bonus.key.name}'),
              size: 14,
              id: bonus.key,
            ),
            const SizedBox(width: 2),
            Text('+${bonus.value}', style: style),
            const SizedBox(width: 6),
          ],
          Icon(Icons.timer_outlined, size: 13, color: palette.textMuted),
          const SizedBox(width: 2),
          Text(
            _shortClock(left),
            style: style.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// "1:05": minutes and seconds, rounded up so a fire reads 0:00 only once
/// it is out.
String _shortClock(Duration d) {
  if (d.inMilliseconds <= 0) return '0:00';
  final total = (d.inMilliseconds / 1000).ceil();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

/// One of the pit's two recipe tiles, side by side: what it makes (with how
/// many the bag can make), its name and what one costs.
/// An empty slot is a prompt to pick one.
class FirepitRecipeTile extends StatelessWidget {
  const FirepitRecipeTile({
    super.key,
    required this.recipeId,
    required this.skill,
    required this.onTap,
    required this.selected,
  });

  final String recipeId;
  final SkillId skill;
  final VoidCallback onTap;
  final bool selected;

  static const double height = 80;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);

    if (recipeId.isEmpty || recipe.output.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: selected ? RecipeCard.selectedFill(context) : null,
        shape: selected ? RecipeCard.selectedShape(context) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: palette.textMuted),
                const SizedBox(height: 6),
                Text(
                  'Pick a recipe',
                  style: HearthText.rowMeta.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: selected ? RecipeCard.selectedFill(context) : null,
      shape: selected ? RecipeCard.selectedShape(context) : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // what it makes, with its name and what one costs beside it
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeOutputTile(recipeId: recipeId),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.output.first.id.definition.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HearthText.rowTitle.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 3),
                          // what one costs, each flagged red when the bag is
                          // short
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              for (final input in recipe.inputs.entries)
                                _CostChip(
                                  id: input.key,
                                  needed: input.value,
                                  short:
                                      crafting.getItemCountInPlayerInventory(
                                        input.key,
                                      ) <
                                      input.value,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One ingredient on a recipe tile: its icon and how many one craft takes,
/// in red when the bag is short of it.
class _CostChip extends StatelessWidget {
  const _CostChip({
    required this.id,
    required this.needed,
    required this.short,
  });

  final ItemId id;
  final int needed;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpriteFrame.sprite(id, size: 18),
        const SizedBox(width: 2),
        Text(
          '×$needed',
          style: HearthText.rowMeta.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: short ? RecipeCard.missingMaterialColor : palette.textMuted,
          ),
        ),
      ],
    );
  }
}

/// The firemaking recipe card, with a warning when picking it would replace
/// a different fire that is still burning.
class _FireRecipeCard extends StatelessWidget {
  const _FireRecipeCard({
    required this.recipeId,
    required this.burningFireId,
    required this.onTap,
    this.selected = false,
  });

  final String recipeId;
  final ItemId? burningFireId;
  final VoidCallback onTap;

  /// Marks this as the card the action button runs. Only set while a
  /// cooking card is stacked below it and the two are a choice.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);
    final outputId = recipe.output.isEmpty ? null : recipe.output.first.id;
    final replaces =
        burningFireId != null && outputId != null && outputId != burningFireId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FirepitRecipeTile(
          recipeId: recipeId,
          skill: SkillId.FIREMAKING,
          onTap: onTap,
          selected: selected,
        ),
        if (replaces)
          const _CardHint(
            icon: Icons.swap_horiz,
            text: 'Replaces the current fire',
          ),
      ],
    );
  }
}

/// A quiet line under a recipe card, for the one thing about it the card
/// itself cannot show: which fire it would replace, or that it is waiting on
/// a lit one.
class _CardHint extends StatelessWidget {
  const _CardHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: HearthText.rowMeta.copyWith(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Names one of the stacked recipe cards. Only drawn when a cookfire puts
/// two of them on screen and the player has to tell them apart.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
      child: SectionLabel(text),
    );
  }
}

/// Discrete, destructive tap, so unlike the action button it confirms first.
///
/// Icon only: the primary button names the fire's action, so this square
/// keeps to the stop button's footprint.
class _PutOutFireButton extends StatelessWidget {
  const _PutOutFireButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // a quiet square like Stop on the other side of the bar
    return Tooltip(
      message: 'Put out the fire',
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: kActionBarSideButtonWidth,
            height: kActionBarButtonHeight,
            child: Icon(
              Icons.water_drop_outlined,
              size: 24,
              color: palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
