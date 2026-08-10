import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/buff_controller.dart';
import '../controllers/crafting_controller.dart';
import '../data/skill_data.dart';
import '../widgets/crafting_info_panel.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/recipe_card.dart';
import '../widgets/skill_ring_row.dart';

/*
firepit screen contents:
-header naming whatever is burning, or the firepit when it is cold
-hero image of the fire, with its remaining burn time in the corner
-skill rings, matching the encounter screen
-a firemaking recipe card, split into Firemaking/Cooking tabs while a
 cookfire burns; the open tab is what the action button runs
-tabbed panel of items cooked this session, active buffs, and recipe stats
-put-out control in the action bar's trailing slot
*/

class FirepitScreen extends StatefulWidget {
  const FirepitScreen({super.key});

  @override
  State<FirepitScreen> createState() => _FirepitScreenState();
}

class _FirepitScreenState extends State<FirepitScreen>
    with TickerProviderStateMixin {
  /// Which section the action button runs. Null until the player picks, so
  /// the screen can default to cooking whenever a cookfire is lit.
  SkillId? _activeSection;

  SkillId _resolveActiveSection(CraftingController controller, bool canCook) {
    // a running action owns the selection: the button must describe what it
    // is actually doing
    final running = context.read<ActionTimingController>().isRunning;
    if (running) {
      final activeSkill = controller.getRecipe(controller.activeRecipeId).skill;
      if (activeSkill == SkillId.COOKING && canCook) return SkillId.COOKING;
      if (activeSkill == SkillId.FIREMAKING) return SkillId.FIREMAKING;
    }

    // cooking is the reason you walked over to a lit cookfire
    if (_activeSection == SkillId.COOKING) {
      return canCook ? SkillId.COOKING : SkillId.FIREMAKING;
    }
    if (_activeSection == SkillId.FIREMAKING) return SkillId.FIREMAKING;
    return canCook ? SkillId.COOKING : SkillId.FIREMAKING;
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: recipes.length,
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
    final activeSection = _resolveActiveSection(controller, canCook);

    final fireRecipeId = controller.selectedRecipeIdFor(SkillId.FIREMAKING);
    final cookRecipeId = controller.selectedRecipeIdFor(SkillId.COOKING);
    final selectedId = activeSection == SkillId.COOKING
        ? cookRecipeId
        : fireRecipeId;

    final canAct =
        selectedId.isNotEmpty &&
        controller.getMaxNumberCraftsForRecipe(selectedId) > 0 &&
        (activeSection != SkillId.COOKING || canCook);

    // both rings always: a firepit is where cooking is trained, and a row
    // that grows from one ring to two re-centres itself, sliding the
    // firemaking ring sideways the moment a cookfire catches
    const skills = <SkillId>[SkillId.FIREMAKING, SkillId.COOKING];

    final actionLabel = _actionLabel(activeSection, fire, fireRecipeId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      fire?.name ?? 'Firepit',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  // the fire itself, with its burn time where an entity
                  // count would normally sit
                  Center(
                    child: _FireHero(
                      fire: fire,
                      key: ValueKey(fire?.id ?? ItemId.NULL),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // the skills the pit trains stay in view whichever tab is
                  // open; the buffs a fire grants moved into the panel below
                  const ActivitySkillRingRow(skills: skills),

                  // a lit cookfire is a pit doing two jobs, so they split
                  // into tabs. the open tab is the one the action button
                  // runs, which is what the section markers used to say.
                  // an ordinary fire has nothing to split.
                  const SizedBox(height: 10),
                  if (canCook) ...[
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<SkillId>(
                        segments: const [
                          ButtonSegment<SkillId>(
                            value: SkillId.FIREMAKING,
                            label: Text('Firemaking'),
                          ),
                          ButtonSegment<SkillId>(
                            value: SkillId.COOKING,
                            label: Text('Cooking'),
                          ),
                        ],
                        selected: {activeSection},
                        // single-select: the set always holds exactly one
                        onSelectionChanged: (selection) =>
                            setState(() => _activeSection = selection.first),
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // the open tab's recipe. sized rather than swapped outright
                  // so switching tabs slides the panel below instead of
                  // teleporting it
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: activeSection == SkillId.COOKING
                        ? RecipeCard(
                            recipeId: cookRecipeId,
                            onTap: () {
                              setState(() => _activeSection = SkillId.COOKING);
                              _showRecipePicker(
                                context,
                                controller,
                                SkillId.COOKING,
                              );
                            },
                          )
                        : _FireRecipeCard(
                            recipeId: fireRecipeId,
                            burningFireId: fire?.id,
                            onTap: () {
                              setState(
                                () => _activeSection = SkillId.FIREMAKING,
                              );
                              _showRecipePicker(
                                context,
                                controller,
                                SkillId.FIREMAKING,
                              );
                            },
                          ),
                  ),

                  // what the session cooked, the fire's buffs and the recipe
                  // stats share one slot, switched by tab
                  CraftingInfoPanel(
                    items: controller.craftedItems(),
                    equipment: controller.craftedEquipment(),
                    craftedLabel: 'Cooked',
                    emptyCraftedLabel: 'Nothing cooked this session',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // MomentumPrimaryButton takes a label but never draws one, and
            // which of the two sections the button runs is the whole point
            // of this screen, so name the action here.
            Text(
              actionLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: canAct ? 0.9 : 0.4),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            ActionButtonRow(
              actionButton: MomentumPrimaryButton(
                enabled: canAct,
                label: actionLabel,
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
          ],
        ),
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
}

/// The fire in the entity image slot. Lit fires carry a countdown badge
/// instead of a stack count; a cold firepit shows the bare pit.
class _FireHero extends StatelessWidget {
  const _FireHero({super.key, required this.fire});

  final FireItem? fire;

  @override
  Widget build(BuildContext context) {
    final f = fire;
    if (f == null) {
      return const ItemStackTile(
        size: 160,
        count: 0,
        id: EntityId.FIREPIT,
        showInfoDialogOnTap: false,
      );
    }

    return ItemStackTile(
      size: 160,
      count: 0,
      id: f.id,
      showInfoDialogOnTap: false,
      isTimerStackTile: true,
      expirationTime: f.expirationTime,
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
  });

  final String recipeId;
  final ItemId? burningFireId;
  final VoidCallback onTap;

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
        RecipeCard(recipeId: recipeId, onTap: onTap),
        if (replaces)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Replaces the current fire',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Discrete, destructive tap, so unlike the action button it confirms first.
///
/// Icon only: the action bar's side slots are narrow equal-width flexes
/// either side of the 168px primary button, and a labelled button does not
/// fit at phone widths.
class _PutOutFireButton extends StatelessWidget {
  const _PutOutFireButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Put out the fire',
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.water_drop_outlined, size: 24),
          ),
        ),
      ),
    );
  }
}
