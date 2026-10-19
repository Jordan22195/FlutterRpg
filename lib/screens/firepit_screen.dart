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
import '../widgets/countdown_timer.dart';
import '../widgets/crafting_info_panel.dart';
import '../widgets/list_row.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/stage_panel.dart';
import '../widgets/picker_list.dart';
import '../widgets/primary_button.dart';
import '../widgets/recipe_card.dart';
import '../widgets/skill_ring_row.dart';

/*
firepit screen contents:
-the zone's art strip, naming whatever is burning, or the firepit when it
 is cold
-the fire on a stage, with its remaining burn time in the corner
-a firemaking recipe card, with the cooking recipe stacked below it as soon
 as a cookfire is picked; the highlighted card is what the action button
 runs. cooking tends its own fire: Cook lights the picked cookfire on its
 first tick and relights it whenever it burns out, so with a cookfire
 picked the button always cooks and the fire card only chooses the fire
-the Tending timer and the skill rings
-tabbed panel of items cooked this session, active buffs, and recipe stats
-the dock: stop, the button naming its action, and put-out beside it
*/

class FirepitScreen extends StatefulWidget {
  const FirepitScreen({super.key});

  @override
  State<FirepitScreen> createState() => _FirepitScreenState();
}

class _FirepitScreenState extends State<FirepitScreen>
    with TickerProviderStateMixin {
  /// Which of the stacked recipe cards the action button runs. Null until
  /// the player picks, so the screen can default to cooking whenever a
  /// cookfire is lit or picked.
  SkillId? _activeSection;

  SkillId _resolveActiveSection(
    CraftingController controller, {
    required bool showCooking,
    required bool cookfirePicked,
  }) {
    // a running action owns the selection: the button must describe what it
    // is actually doing
    final running = context.read<ActionTimingController>().isRunning;
    if (running) {
      final activeSkill = controller.getRecipe(controller.activeRecipeId).skill;
      if (activeSkill == SkillId.COOKING) return SkillId.COOKING;
      if (activeSkill == SkillId.FIREMAKING) return SkillId.FIREMAKING;
    }

    // a cookfire is only ever lit by cooking on it: the cook pays its logs
    // and relights it itself, so the button cooks and the fire card is just
    // the choice of which fire it burns
    if (cookfirePicked) return SkillId.COOKING;

    if (!showCooking) return SkillId.FIREMAKING;
    if (_activeSection == SkillId.FIREMAKING) return SkillId.FIREMAKING;
    // cooking is the reason you walked over to a lit cookfire
    return SkillId.COOKING;
  }

  void _showRecipePicker(
    BuildContext context,
    CraftingController controller,
    SkillId skill,
  ) {
    final recipes = controller.availableRecipesFor(skill);
    // each skill keeps its own selection at a station offering several
    final selectedId = controller.selectedRecipeIdFor(skill);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            skill == SkillId.FIREMAKING ? 'Select Fire' : 'Select Recipe',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: PickerList(
              itemCount: recipes.length,
              // opens on the recipe already selected rather than at the top
              selectedIndex: recipes.indexWhere((r) => r.id == selectedId),
              itemBuilder: (context, i) {
                final r = recipes[i];
                return RecipeCard(
                  recipeId: r.id,
                  lockWhenUnderLevel: true,
                  selected: r.id == selectedId,
                  onTap: () {
                    controller.selectRecipe(r.id);
                    setState(() => _activeSection = skill);
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
    // cook section and the put-out button disappear when a fire burns out
    context.watch<BuffController>();
    final fire = controller.activeFire();
    final canCook = fire?.canCook ?? false;

    final fireRecipeId = controller.selectedRecipeIdFor(SkillId.FIREMAKING);
    final cookRecipeId = controller.selectedRecipeIdFor(SkillId.COOKING);

    // picking a cookfire is enough to put the cooking recipe on screen: the
    // cook lights it itself. a lit cookfire shows it too, whatever is picked
    final cookFireRecipe = controller.cookFireRecipe();
    final showCooking = canCook || cookFireRecipe != null;
    final activeSection = _resolveActiveSection(
      controller,
      showCooking: showCooking,
      cookfirePicked: cookFireRecipe != null,
    );

    final selectedId = activeSection == SkillId.COOKING
        ? cookRecipeId
        : fireRecipeId;

    // cooking runs on a lit cookfire, or on the logs to light the picked one
    final canAct =
        selectedId.isNotEmpty &&
        controller.getMaxNumberCraftsForRecipe(selectedId) > 0 &&
        (activeSection != SkillId.COOKING ||
            canCook ||
            controller.canRelight());

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
              // room at the bottom for the dock's fade to fall on
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // the fire itself, with its burn time where an entity count
                // would normally sit
                _FireHero(fire: fire, key: ValueKey(fire?.id ?? ItemId.NULL)),
                const SizedBox(height: 12),

                // the fire the pit burns is always the first choice. a
                // cookfire is a pit doing two jobs, so its cooking recipe
                // stacks underneath rather than hiding in a tab: both
                // recipes stay in view, and the highlighted card is the one
                // the action button runs.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // the cards name themselves only when there are two of
                      // them; alone, the screen is already unambiguous
                      if (showCooking) const _SectionLabel('Firemaking'),
                      _FireRecipeCard(
                        recipeId: fireRecipeId,
                        burningFireId: fire?.id,
                        selected:
                            showCooking && activeSection == SkillId.FIREMAKING,
                        onTap: () {
                          setState(() => _activeSection = SkillId.FIREMAKING);
                          _showRecipePicker(
                            context,
                            controller,
                            SkillId.FIREMAKING,
                          );
                        },
                      ),
                      if (showCooking) ...[
                        const _SectionLabel('Cooking'),
                        RecipeCard(
                          recipeId: cookRecipeId,
                          selected: activeSection == SkillId.COOKING,
                          onTap: () {
                            setState(() => _activeSection = SkillId.COOKING);
                            _showRecipePicker(
                              context,
                              controller,
                              SkillId.COOKING,
                            );
                          },
                        ),
                        // what the cook burns to keep its fire going, lit or
                        // not: it relights out of the same logs either way.
                        // cooking shown only because a cookfire is burning
                        // has nothing to relight with, and says so
                        if (cookFireRecipe != null)
                          _CardHint(
                            icon: Icons.local_fire_department_outlined,
                            text: _fireCostLabel(cookFireRecipe),
                          )
                        else
                          const _CardHint(
                            icon: Icons.swap_horiz,
                            text: 'Pick a cookfire to cook',
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // the pit's action timer, in the row of its own the other
                // station screens give it
                ActionTimerRow(
                  label: 'Tending',
                  color: colors.firemaking,
                  progress: controller.craftProgress,
                  interval: controller.craftInterval,
                ),
                const SizedBox(height: 12),

                // the skills the pit trains stay in view whichever recipe is
                // picked; the buffs a fire grants are in the panel below
                const ActivitySkillRingRow(skills: skills, spacing: 14),
                const SizedBox(height: 16),

                // what the session cooked, the fire's buffs and the recipe
                // stats share one slot, switched by tab
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
                isActive: controller.isCraftingHere,
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
  String _actionLabel(SkillId section, FireItem? fire, String fireRecipeId) {
    if (section == SkillId.COOKING) return 'Cook';
    if (fire == null) return 'Light Fire';
    final selected = context.read<CraftingController>().getRecipe(fireRecipeId);
    final selectedFireId = selected.output.isEmpty
        ? null
        : selected.output.first.id;
    return selectedFireId == fire.id ? 'Add Logs' : 'Light Fire';
  }

  /// "Burns 2 × Logs per fire": the cost the cook pays each time it lights
  /// the picked cookfire.
  String _fireCostLabel(CraftingRecipe fire) {
    final cost = fire.inputs.entries.first;
    return 'Burns ${cost.value} × ${cost.key.definition.name} per fire';
  }
}

/// The fire on a fire-tinted stage. A lit fire carries its countdown in the
/// corner where a creature's count would sit; a cold firepit shows the bare
/// pit.
class _FireHero extends StatelessWidget {
  const _FireHero({super.key, required this.fire});

  final FireItem? fire;

  @override
  Widget build(BuildContext context) {
    final f = fire;
    final tint = context.gameColors.fireTint;

    return StagePanel(
      tint: tint,
      height: 148,
      shadow: false,
      sprite: SpriteFrame.sprite(f?.id ?? EntityId.FIREPIT, size: 116),
      corner: f == null
          ? null
          : Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: context.palette.bg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tint.border),
              ),
              alignment: Alignment.center,
              child: CountdownTimer(expirationTime: f.expirationTime, size: 13),
            ),
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
        RecipeCard(recipeId: recipeId, onTap: onTap, selected: selected),
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
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: HearthText.rowMeta.copyWith(fontSize: 12, color: color),
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
