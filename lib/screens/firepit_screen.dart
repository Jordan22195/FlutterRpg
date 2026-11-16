import '../data/skill_category.dart';
import 'package:flutter/material.dart';
import 'package:rpg/theme/hearth_theme.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:provider/provider.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../catalogs/recipes/recipes.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/buff_controller.dart';
import '../controllers/crafting_controller.dart';
import '../data/skill_data.dart';
import '../controllers/world_controller.dart';
import '../theme/hearth_text.dart';
import '../widgets/action_dock.dart';
import '../widgets/art_header.dart';
import '../widgets/fire_reagents.dart';
import '../widgets/crafting_info_panel.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/list_row.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/stage_panel.dart';
import '../widgets/travel_row.dart';
import '../widgets/recipe_picker_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/recipe_card.dart';
import '../widgets/skill_ring_row.dart';

/*
firepit screen contents:
-the zone's art strip, naming whatever is burning, or the firepit when it
 is cold
-the fire on a stage. a campfire or cookfire is a steady burn - each lay
 adds its burn time at its full bonus. a bonfire burns on heat - stoked up
 the bonus ladder to its ceiling, cooling back down when the logs stop:
 -down its right side, a chip per stretch still to come with its bonus and
  time: a campfire's one steady burn, or each rung a bonfire will cool
  through, the one burning now bold
 -along a bonfire's foot, its burn left from now and the most it could
  burn, stoked to full
 -across the top, a ring per reagent buff burning on it: the buff's time
  left out of the fire's, with a coarse time-left chip under it
-a firemaking recipe tile with a second tile beside it; the highlighted
 tile is what the action button runs. tapping a tile highlights it;
 tapping the highlighted tile opens its recipe picker (an
 empty card opens it on the first tap). with the fire card
 highlighted the button builds the picked fire over and over.
 the second card follows the picked fire:
 -a campfire or bonfire: the kindling card, holding the one reagent picked
  to keep topped up - a fire carries one kindling, so a second stat needs a
  second fire. each tick throws one while its ring has room, and stops once
  it is full. kindling only goes on a fire already lit
 -anything else: the cooking card, locked until a cookfire is picked. the
  button cooks, lighting the picked cookfire on its first tick and
  relighting it whenever it burns out
-the Tending timer and the skill rings
-tabbed panel of items cooked this session and recipe stats
-the dock: stop, the button naming its action, and put-out beside it
*/

/// The firepit's recipe cards: the fire, and the card stacked under it.
enum _Section { fire, cook, tend }

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
    required bool tendingUnlocked,
  }) {
    // until the player picks a card, a running action owns the selection,
    // so a screen opened mid-action describes what it is doing. a pick
    // always wins after that: the button runs whatever is highlighted
    final running = context.read<ActionTimingController>().isRunning;
    if (running && _activeSection == null) {
      final active = controller.getRecipe(controller.activeRecipeId);
      if (active.tendReagent != null || active.isReagentMix) {
        return _Section.tend;
      }
      if (active.skill == SkillId.COOKING) return _Section.cook;
      if (active.skill == SkillId.FIREMAKING) return _Section.fire;
    }

    // whatever card was picked runs — the second card only while it is the
    // one the picked fire shows, so picking another fire hands the button
    // back to the fire
    if (_activeSection == _Section.cook && cookingUnlocked) {
      return _Section.cook;
    }
    if (_activeSection == _Section.tend && tendingUnlocked) {
      return _Section.tend;
    }
    return _Section.fire;
  }

  /// The stat whose kindling is burning on [fire] when the picked kindling
  /// is a different one, which it won't take; null when the pick can go on.
  SkillId? _otherKindling(FireItem fire, List<CraftingRecipe> mix) {
    if (mix.isEmpty) return null;
    final stat =
        (mix.first.tendReagent!.definition as FireReagentDefinition).stat;
    if (fire.takesKindling(stat, DateTime.now())) return null;
    return fire.kindlingAt(DateTime.now());
  }

  void _showRecipePicker(
    BuildContext context,
    CraftingController controller,
    _Section section,
  ) {
    final skill = section == _Section.cook
        ? SkillId.COOKING
        : SkillId.FIREMAKING;
    final recipes = section == _Section.tend
        ? controller.availableReagentRecipes()
        : controller.availableRecipesFor(skill);
    showRecipePickerSheet(
      context,
      title: section == _Section.tend
          ? 'Kindling'
          : controller.stationEntityId.definition.name,
      skill: skill,
      recipes: recipes,
      // a fire carries one kindling: picking one closes the sheet
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
    // the reagents picked to keep topped up: the button runs them as a mix
    final reagentMix = controller.reagentMix();
    final reagentRecipeId = reagentMix.isEmpty ? '' : reagentMixRecipeId;

    // cooking is always on screen, but locked until the picked fire is a
    // cookfire: the cook lights and relights that fire itself, so without
    // one there is nothing for it to cook over
    final cookFireRecipe = controller.cookFireRecipe();
    final cookingUnlocked = cookFireRecipe != null;
    // a picked campfire or bonfire swaps the cooking card for the reagents
    // that go on it
    final tendFireRecipe = controller.tendFireRecipe();
    final tendingUnlocked = tendFireRecipe != null;
    final activeSection = _resolveActiveSection(
      controller,
      cookingUnlocked: cookingUnlocked,
      tendingUnlocked: tendingUnlocked,
    );

    final selectedId = switch (activeSection) {
      _Section.cook => cookRecipeId,
      _Section.tend => reagentRecipeId,
      _Section.fire => fireRecipeId,
    };

    // cooking runs on a lit cookfire, and a reagent on a lit campfire or
    // bonfire - or either on the logs to light the picked one
    final canAct =
        selectedId.isNotEmpty &&
        controller.getMaxNumberCraftsForRecipe(selectedId) > 0 &&
        switch (activeSection) {
          _Section.cook => canCook || controller.canRelight(),
          // every ring full has nothing to add until more logs go on
          _Section.tend => controller.canTend() && !controller.mixFull(),
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
                // the fire on its stage: its burn down the right, its
                // reagent buffs across the top, and how it is burning along
                // the foot
                _FireHero(
                  fire: fire,
                  key: ValueKey(fire?.id ?? ItemId.NULL),
                  steps: controller.fireSteps(),
                ),
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
                            if (tendingUnlocked) ...[
                              const _SectionLabel('Kindling'),
                              FirepitKindlingTile(
                                key: const ValueKey('firepit-reagent-card'),
                                mix: reagentMix,
                                selected: activeSection == _Section.tend,
                                onTap: () => _onCardTap(
                                  controller,
                                  _Section.tend,
                                  active: activeSection,
                                  recipeId: reagentRecipeId,
                                ),
                              ),
                              // reagents only go on a fire already burning
                              if (fire == null || !fire.tendable)
                                const _CardHint(
                                  icon: Icons.local_fire_department_outlined,
                                  text: 'Light the fire first',
                                )
                              // one kindling per fire: a different pick waits
                              // for the one burning to run out
                              else if (_otherKindling(fire, reagentMix)
                                  case final burning?)
                                _CardHint(
                                  icon: Icons.block,
                                  text:
                                      'Burning ${skillLabel(burning)} '
                                      'kindling - light another fire',
                                ),
                            ] else ...[
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
                // slot, switched by tab. the fire's reagent buffs are the
                // rings on its stage
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
    if (section == _Section.tend) return 'Add Kindling';
    if (fire == null) return 'Light Fire';
    final selected = context.read<CraftingController>().getRecipe(fireRecipeId);
    final selectedFireId = selected.output.isEmpty
        ? null
        : selected.output.first.id;
    return selectedFireId == fire.id ? 'Add Logs' : 'Light Fire';
  }
}

/// The fire on a fire-tinted stage; a cold firepit shows the bare pit. Its
/// burn chips run down the right, a tended fire's reagent rings across the
/// top, and its status and next-lay preview along the foot.
class _FireHero extends StatelessWidget {
  const _FireHero({super.key, required this.fire, required this.steps});

  final FireItem? fire;

  /// The burn still to come, highest bonus first.
  final List<BurnStep> steps;

  @override
  Widget build(BuildContext context) {
    final f = fire;
    final tint = context.gameColors.fireTint;

    return StagePanel(
      tint: tint,
      // room for the sprite above the status row; the reagent rings float
      // over its top
      height: 168,
      sprite: SpriteFrame.sprite(f?.id ?? EntityId.FIREPIT, size: 92),
      // a bonfire's whole burn from here, against the most it could hold
      footer: f != null && f.stokes ? _BurnTotal(fire: f) : null,
      footerHeight: f != null && f.stokes ? _BurnTotal.height : 0,
      banner: f != null && f.tendable ? const FireReagentRings() : null,
      // what the burn still to come gives and for how long, highest first
      side: f == null || steps.isEmpty
          ? null
          : _StepChips(fire: f, steps: steps),
      // the rings may sit over the sprite, so they take no room from it
      bannerHeight: 0,
      // what a cookfire is giving, in the chips its tile wears
      leading: f == null || f.tendable
          ? null
          : Align(
              alignment: Alignment.topLeft,
              child: StatChips(
                key: const ValueKey('fire-hero-stats'),
                id: f.id,
                tileSize: 80,
              ),
            ),
    );
  }
}

/// Along the foot of a bonfire's stage: how long it burns from now if the
/// logs stop, against the longest it could ever burn - stoked to its full
/// heat, at the burn its last lay set ("6:12 left · max 18:40").
class _BurnTotal extends StatelessWidget {
  const _BurnTotal({required this.fire});

  final FireItem fire;

  static const double height = 22;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final left = fire.expirationTime.difference(DateTime.now());
    final style = HearthText.rowMeta.copyWith(
      fontSize: 12,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          key: const ValueKey('fire-burn-total'),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: palette.bg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${_shortClock(left)} left',
                  style: style.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                TextSpan(
                  text: '  ·  max ${_shortClock(fire.maxBurn)}',
                  style: style.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A burn chip's colour. A campfire's steady burn is the fire's own orange.
/// A bonfire's rungs deepen the hotter they are: its ceiling deep red, the
/// rung under it orange, and everything lower a pale smoulder.
Color _stepColor(BuildContext context, FireItem fire, int bonus) {
  final colors = context.gameColors;
  if (!fire.stokes) return colors.firemaking;
  final ceiling = fire.ceiling;
  if (bonus >= ceiling) return colors.cooking;
  if (bonus >= FireItem.stepped(ceiling, -1)) return colors.firemaking;
  return colors.maxHit;
}

/// Down the right of the fire's stage: a chip for every stretch of burn
/// still to come - the bonus it gives and how long it lasts - highest first.
/// A campfire has one; a bonfire one per rung it will cool through. The one
/// burning now is bold.
class _StepChips extends StatelessWidget {
  const _StepChips({required this.fire, required this.steps});

  final FireItem fire;
  final List<BurnStep> steps;

  @override
  Widget build(BuildContext context) {
    // a bonfire stoked high has more rungs than the stage is tall
    return SingleChildScrollView(
      key: const ValueKey('fire-step-chips'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _LevelChip(
              key: ValueKey('fire-step-chip-${steps[i].bonus}'),
              bonus: steps[i].bonus,
              left: steps[i].left,
              color: _stepColor(context, fire, steps[i].bonus),
              active: i == 0,
            ),
            const SizedBox(height: 3),
          ],
        ],
      ),
    );
  }
}

/// One burn level: the bonus it gives and how long it has left, in the
/// level's colour. Bold while it is the one burning.
class _LevelChip extends StatelessWidget {
  const _LevelChip({
    super.key,
    required this.bonus,
    required this.left,
    required this.color,
    required this.active,
  });

  final int bonus;
  final Duration left;
  final Color color;
  final bool active;

  static const double height = 20;

  @override
  Widget build(BuildContext context) {
    final on = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final style = HearthText.rowMeta.copyWith(
      fontSize: 12,
      height: 1,
      color: on,
      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        border: active ? Border.all(color: on, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('+$bonus', style: style),
          const SizedBox(width: 5),
          Text(_shortClock(left), style: style),
        ],
      ),
    );
  }
}

/// "1:05": minutes and seconds, rounded up so a tier reads 0:00 only once
/// it is spent.
String _shortClock(Duration d) {
  if (d.inMilliseconds <= 0) return '0:00';
  final total = (d.inMilliseconds / 1000).ceil();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

/// One of the pit's two recipe tiles, side by side: what it makes (with how
/// many the bag can make), its name and what one costs.
/// A reagent also wears the ring of the stat it buffs. An empty slot is a
/// prompt to pick one.
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

    final reagent = recipe.tendReagent;
    final buffedStat = reagent == null
        ? null
        : (reagent.definition as FireReagentDefinition).stat;

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
                // what it makes, with its name and what one costs beside it;
                // a reagent also wears the stat it is buffing
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeOutputTile(recipeId: recipeId),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recipe.output.first.id.definition.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HearthText.rowTitle.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (buffedStat != null)
                                BuffRing(
                                  key: ValueKey(
                                    'recipe-buff-ring-${buffedStat.name}',
                                  ),
                                  stat: buffedStat,
                                  fullness: crafting.reagentFullness(
                                    buffedStat,
                                  ),
                                  size: 24,
                                ),
                            ],
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

/// The firepit's reagent tile: every reagent picked to keep topped up, each
/// as its stat's ring, filling as it goes on. Each press of the button
/// throws one of every one with room. Empty, it is a prompt to pick some.
class FirepitKindlingTile extends StatelessWidget {
  const FirepitKindlingTile({
    super.key,
    required this.mix,
    required this.selected,
    required this.onTap,
  });

  final List<CraftingRecipe> mix;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final crafting = context.watch<CraftingController>();
    // the rings drain on the buff tick
    context.watch<BuffController>();

    return Card(
      margin: EdgeInsets.zero,
      color: selected ? RecipeCard.selectedFill(context) : null,
      shape: selected ? RecipeCard.selectedShape(context) : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: FirepitRecipeTile.height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            child: mix.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: palette.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        'Pick kindling',
                        style: HearthText.rowMeta.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [for (final r in mix) _mixRing(crafting, r)],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _mixRing(CraftingController crafting, CraftingRecipe r) {
    final stat = (r.tendReagent!.definition as FireReagentDefinition).stat;
    final none = crafting.getItemCountInPlayerInventory(r.tendReagent!) <= 0;
    // a reagent the bag has run out of greys, its ring still showing what is
    // left of its buff
    return Opacity(
      opacity: none ? 0.4 : 1,
      child: BuffRing(
        key: ValueKey('mix-ring-${stat.name}'),
        stat: stat,
        fullness: crafting.reagentFullness(stat),
        size: 28,
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
