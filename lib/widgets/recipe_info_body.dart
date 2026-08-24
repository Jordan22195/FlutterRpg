import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/crafting_controller.dart';
import '../data/recipe_details.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';
import 'info_section.dart';
import 'item_stack_tile.dart';
import 'recipe_card.dart';

/// Everything there is to say about the recipe on the bench: what it makes,
/// what it costs against the inventory on hand, and the odds behind the
/// craft.
///
/// Sizes to its content, so it drops into the bench panel's info tab as
/// readily as into a scrolling page.
class RecipeInfoBody extends StatelessWidget {
  const RecipeInfoBody({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final details = crafting.recipeDetails(recipeId);

    if (!details.isReal) {
      return _empty(context, 'No recipe selected');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(details: details),
        _Stats(details: details),
        _Materials(details: details),
        if (details.hasOdds) _Odds(details: details),
      ],
    );
  }
}

Widget _empty(BuildContext context, String text) {
  return SizedBox(
    height: 80,
    child: Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    ),
  );
}

/// The product, the recipe's name, and the skill it trains with its gate.
class _Header extends StatelessWidget {
  const _Header({required this.details});

  final RecipeDetails details;

  @override
  Widget build(BuildContext context) {
    final recipe = details.recipe;

    return Column(
      children: [
        Center(child: RecipeOutputTile(recipeId: recipe.id)),
        const SizedBox(height: 8),
        Center(
          child: Text(
            recipe.name,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconRenderer(size: 18, id: recipe.skill),
            const SizedBox(width: 4),
            Text(
              '${skillDisplayName(recipe.skill)} · Lv ${recipe.levelRequirement}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.details});

  final RecipeDetails details;

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: 'Stats',
      children: [
        InfoStatRow(
          label: 'Xp per craft',
          value: formatDecimal(details.recipe.xp),
        ),
        InfoStatRow(
          label: 'Level required',
          value: '${details.recipe.levelRequirement}',
        ),
        // the level the craft is actually judged at, gear and buffs
        // included — the same number the odds below are computed from
        InfoStatRow(
          label: 'Your level',
          value: '${details.effectiveSkillLevel}',
        ),
        InfoStatRow(label: 'Can make', value: '${details.craftableCount}'),
      ],
    );
  }
}

class _Materials extends StatelessWidget {
  const _Materials({required this.details});

  final RecipeDetails details;

  @override
  Widget build(BuildContext context) {
    if (details.materials.isEmpty) return const SizedBox.shrink();

    return InfoSection(
      title: 'Materials',
      children: [
        for (final material in details.materials)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                ItemStackTile(
                  size: 28,
                  id: material.itemId,
                  count: material.required,
                  alwaysShowCount: true,
                  // the input you are actually short of is the one worth
                  // pointing at, flagged the same way the recipe card does
                  borderColor: material.isShort
                      ? RecipeCard.missingMaterialColor
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(material.name, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text(
                  '${material.held} / ${material.required}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: material.isShort
                        ? RecipeCard.missingMaterialColor
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The odds behind one craft: the quality ladder for equipment, and the
/// output table for everything else — which is where cooking states its
/// burn chance.
class _Odds extends StatelessWidget {
  const _Odds({required this.details});

  final RecipeDetails details;

  @override
  Widget build(BuildContext context) {
    final subtleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return InfoSection(
      title: details.rollsQuality ? 'Quality' : 'Outcome',
      children: [
        for (final outcome in details.outcomes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                if (outcome.itemId != null) ...[
                  IconRenderer(size: 28, id: outcome.itemId),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    outcome.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // quality is a ladder, so the row wears its tier's
                      // colour the way a crafted piece wears its border
                      color: outcome.quality == null
                          ? null
                          : qualityBorderColor(outcome.quality!),
                    ),
                  ),
                ),
                if (outcome.hasCountRange) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${outcome.minCount}-${outcome.maxCount}',
                    style: subtleStyle,
                  ),
                ],
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text(
                    formatPercent(outcome.chance),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
