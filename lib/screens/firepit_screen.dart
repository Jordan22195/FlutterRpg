import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/buff_controller.dart';
import '../controllers/crafting_controller.dart';
import '../data/skill_data.dart';
import '../widgets/buff_row.dart';
import '../widgets/inventory_grid.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/recipe_card.dart';
import '../widgets/skill_ring_row.dart';

/*
firepit screen contents:
-header naming whatever is burning, or the firepit when it is cold
-hero image of the fire, with its remaining burn time in the corner
-buff row and skill rings, matching the encounter screen
-a FIRE section (always) and a COOK section (only while a cookfire burns);
 whichever is active is what the action button runs
-inventory grid of items cooked this session
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

  /// Section header with a marker on the one the action button will run.
  Widget _sectionLabel(BuildContext context, String text, bool active) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: active ? 0.9 : 0.5),
              letterSpacing: 0.8,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (active)
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
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

                  // the buff slot stays open while the firepit is cold, so
                  // lighting a fire fills it instead of pushing the rest of
                  // the screen down by its height
                  const BuffRow(reserveWhenEmpty: true),
                  const SizedBox(height: 8),
                  const SkillRingRow(skills: skills),

                  _sectionLabel(
                    context,
                    'FIRE',
                    activeSection == SkillId.FIREMAKING,
                  ),
                  _FireRecipeCard(
                    recipeId: fireRecipeId,
                    burningFireId: fire?.id,
                    onTap: () {
                      setState(() => _activeSection = SkillId.FIREMAKING);
                      _showRecipePicker(
                        context,
                        controller,
                        SkillId.FIREMAKING,
                      );
                    },
                  ),

                  // cooking still appears only once a cookfire is lit, but it
                  // grows into place rather than snapping, so the session
                  // grid below it slides instead of teleporting
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: canCook
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _sectionLabel(
                                context,
                                'COOK',
                                activeSection == SkillId.COOKING,
                              ),
                              RecipeCard(
                                maxCraftable: false,
                                recipeId: cookRecipeId,
                                onTap: () {
                                  setState(
                                    () => _activeSection = SkillId.COOKING,
                                  );
                                  _showRecipePicker(
                                    context,
                                    controller,
                                    SkillId.COOKING,
                                  );
                                },
                              ),
                            ],
                          )
                        : const SizedBox(width: double.infinity),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Cooked this session',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Card(
                    child: SizedBox(
                      height: 80,
                      child: InventoryGrid(items: controller.craftedItems()),
                    ),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: canAct ? 0.9 : 0.4,
                ),
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
        RecipeCard(maxCraftable: false, recipeId: recipeId, onTap: onTap),
        if (replaces)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
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
