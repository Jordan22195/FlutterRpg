import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/items/items.dart';
import '../catalogs/recipes/recipes.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/crafting_controller.dart';
import '../controllers/player_data_controller.dart';
import '../data/skill_data.dart';
import '../theme/hearth_text.dart';
import '../utilities/util.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';

/// Colours of the recipe picker sheet. Its own dark surface, the same in
/// every zone, so they live here rather than on the palette.
abstract final class _Sheet {
  static const Color background = Color(0xFF1D1914);
  static const Color border = Color(0xFF3A3226);
  static const Color handle = Color(0xFF4A3F30);
  static const Color closeFill = Color(0xFF211C16);
  static const Color muted = Color(0xFFB0A38C);
  static const Color cardFill = Color(0xFF211C16);
  static const Color cardBorder = Color(0xFF2F281F);
  static const Color lockedFill = Color(0xFF1A1612);
  static const Color iconFill = Color(0xFF262019);
  static const Color iconBorder = Color(0xFF43382A);
  static const Color chipFill = Color(0xFF15130F);
  static const Color chipShortBorder = Color(0xFF6A3328);
  static const Color have = Color(0xFFF2EADB);
  static const Color needed = Color(0xFF8F836E);
  static const Color short = Color(0xFFE8806B);
  static const Color xp = Color(0xFFE8C766);
  static const Color crafting = Color(0xFF9BCB4F);
  static const Color onCrafting = Color(0xFF16200A);
  static const Color text = Color(0xFFF2EADB);
}

/// Opens the recipe picker as a bottom sheet. The same sheet serves every
/// crafting station; only the [title], [skill] and [recipes] change.
Future<void> showRecipePickerSheet(
  BuildContext context, {
  required String title,
  required SkillId skill,
  required List<CraftingRecipe> recipes,
  required void Function(CraftingRecipe recipe) onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: _Sheet.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: _Sheet.border),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) => RecipePickerSheet(
      title: title,
      skill: skill,
      recipes: recipes,
      onSelected: (recipe) {
        onSelected(recipe);
        Navigator.of(ctx).pop();
      },
    ),
  );
}

/// The metal a blacksmithing recipe belongs to, read from its id
/// (`smelt_copper_bar`, `forge_iron_helmet`) — null for recipes with no
/// metal, which is every other station's.
String? _metalOf(CraftingRecipe recipe) {
  final m = RegExp(r'^(?:smelt|forge)_([a-z]+)_').firstMatch(recipe.id);
  if (m == null) return null;
  final name = m.group(1)!;
  return name[0].toUpperCase() + name.substring(1);
}

class RecipePickerSheet extends StatefulWidget {
  const RecipePickerSheet({
    super.key,
    required this.title,
    required this.skill,
    required this.recipes,
    required this.onSelected,
  });

  final String title;
  final SkillId skill;
  final List<CraftingRecipe> recipes;
  final void Function(CraftingRecipe recipe) onSelected;

  @override
  State<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<RecipePickerSheet> {
  /// The metal tab showing; null is every metal.
  String? _metal;

  String get title => widget.title;
  SkillId get skill => widget.skill;
  void Function(CraftingRecipe recipe) get onSelected => widget.onSelected;

  @override
  Widget build(BuildContext context) {
    final level = context.watch<PlayerDataController>().getSkillLevel(skill);
    // one tab per metal, lowest-opening first; a station whose recipes have
    // no metals gets none
    final metalLevels = <String, int>{};
    for (final r in widget.recipes) {
      final metal = _metalOf(r);
      if (metal == null) continue;
      final low = metalLevels[metal];
      if (low == null || r.levelRequirement < low) {
        metalLevels[metal] = r.levelRequirement;
      }
    }
    final metals = metalLevels.keys.toList()
      ..sort((a, b) => metalLevels[a]!.compareTo(metalLevels[b]!));
    final showTabs = metals.length > 1;
    final recipes = _metal == null
        ? widget.recipes
        : [
            for (final r in widget.recipes)
              if (_metalOf(r) == _metal) r,
          ];
    // lowest level first; List.sort is not stable, so ties keep data order
    // by comparing the original index
    final indexed = recipes.asMap().entries.toList()
      ..sort((a, b) {
        final byLevel = a.value.levelRequirement.compareTo(
          b.value.levelRequirement,
        );
        return byLevel != 0 ? byLevel : a.key.compareTo(b.key);
      });
    final sorted = [for (final e in indexed) e.value];
    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + media.viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: _Sheet.handle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: HearthText.pixel,
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            height: 1.1,
                            color: _Sheet.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${skillDisplayName(skill)} · Lv $level',
                          style: const TextStyle(
                            fontFamily: HearthText.body,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: _Sheet.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _Sheet.closeFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _Sheet.border),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: _Sheet.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showTabs) ...[
              const SizedBox(height: 14),
              _MetalTabs(
                metals: metals,
                selected: _metal,
                onChanged: (m) => setState(() => _metal = m),
              ),
            ],
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = sorted[i];
                  return RecipePickerCard(
                    recipe: r,
                    skill: skill,
                    locked: level < r.levelRequirement,
                    onTap: () => onSelected(r),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetalTabs extends StatelessWidget {
  const _MetalTabs({
    required this.metals,
    required this.selected,
    required this.onChanged,
  });

  final List<String> metals;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, String? value) {
      final on = value == selected;
      return Semantics(
        button: true,
        selected: on,
        label: '$label tab',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? _Sheet.border : _Sheet.closeFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? _Sheet.muted : _Sheet.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: HearthText.body,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: on ? _Sheet.text : _Sheet.muted,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          tab('All', null),
          for (final m in metals) ...[const SizedBox(width: 8), tab(m, m)],
        ],
      ),
    );
  }
}

String _formatXp(double xp) =>
    xp == xp.roundToDouble() ? '${xp.round()}' : xp.toStringAsFixed(1);

/// One recipe: output first, ingredients underneath. The picker lists them,
/// and the crafting screen shows the selected one in the same form.
class RecipePickerCard extends StatelessWidget {
  const RecipePickerCard({
    super.key,
    required this.recipe,
    required this.skill,
    required this.locked,
    required this.onTap,
    this.selected = false,
  });

  final CraftingRecipe recipe;
  final SkillId skill;
  final bool locked;
  final VoidCallback onTap;

  /// Marks the card the action button runs, where several are on screen at
  /// once (the firepit's fire and cook cards).
  final bool selected;

  // 60% of the way to greyscale
  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.6 * 0.2126 + 0.4, 0.6 * 0.7152, 0.6 * 0.0722, 0, 0, //
    0.6 * 0.2126, 0.6 * 0.7152 + 0.4, 0.6 * 0.0722, 0, 0, //
    0.6 * 0.2126, 0.6 * 0.7152, 0.6 * 0.0722 + 0.4, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final isCrafting =
        !locked &&
        crafting.activeRecipeId == recipe.id &&
        context.watch<ActionTimingController>().isRunning;
    final outputId = recipe.output.first.id;
    final name = outputId.definition.name;
    final xp = _formatXp(recipe.xp);

    final semantics = locked
        ? '$name, locked, requires level ${recipe.levelRequirement}'
        : '$name, level ${recipe.levelRequirement}, $xp xp'
              '${isCrafting ? ', crafting now' : ''}';

    final card = Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: locked ? _Sheet.lockedFill : _Sheet.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCrafting
              ? _Sheet.crafting
              : selected
              ? _Sheet.text
              : (locked ? _Sheet.border : _Sheet.cardBorder),
          width: isCrafting || selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Sheet.iconFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Sheet.iconBorder),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _maybeGrey(IconRenderer(size: 36, id: outputId)),
                // a fire's or food's stats, top-left as on every item tile,
                // so a fire in the picker still says what it burns for
                if (StatChips.hasAny(outputId))
                  Positioned(
                    left: 3,
                    top: 3,
                    child: StatChips(id: outputId, tileSize: 52),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: HearthText.body,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _Sheet.text,
                        ),
                      ),
                    ),
                    if (isCrafting) ...[
                      const SizedBox(width: 8),
                      const _CraftingTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final input in recipe.inputs.entries)
                      _IngredientChip(
                        id: input.key,
                        have: crafting.getItemCountInPlayerInventory(input.key),
                        needed: input.value,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          locked ? _requires() : _levelAndXp(xp),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: !locked,
      label: semantics,
      excludeSemantics: true,
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: locked ? null : onTap,
          child: card,
        ),
      ),
    );
  }

  Widget _maybeGrey(Widget child) =>
      locked ? ColorFiltered(colorFilter: _greyscale, child: child) : child;

  Widget _levelAndXp(String xp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Lv ${recipe.levelRequirement}',
          style: const TextStyle(
            fontFamily: HearthText.body,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _Sheet.text,
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: '+$xp ',
            style: const TextStyle(
              fontFamily: HearthText.body,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _Sheet.xp,
            ),
            children: const [
              TextSpan(
                text: 'xp',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _requires() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Requires',
          style: TextStyle(
            fontFamily: HearthText.body,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _Sheet.needed,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Sheet.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 12, color: _Sheet.muted),
              const SizedBox(width: 4),
              Text(
                'Lv ${recipe.levelRequirement}',
                style: const TextStyle(
                  fontFamily: HearthText.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _Sheet.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CraftingTag extends StatelessWidget {
  const _CraftingTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _Sheet.crafting,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'CRAFTING',
        style: TextStyle(
          fontFamily: HearthText.body,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: _Sheet.onCrafting,
        ),
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({
    required this.id,
    required this.have,
    required this.needed,
  });

  final ItemId id;
  final int have;
  final int needed;

  @override
  Widget build(BuildContext context) {
    final short = have < needed;
    const base = TextStyle(
      fontFamily: HearthText.body,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      label: '${id.definition.name}: have $have, need $needed',
      excludeSemantics: true,
      child: Container(
        height: 26,
        padding: const EdgeInsets.only(left: 4, right: 8),
        decoration: BoxDecoration(
          color: _Sheet.chipFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: short ? _Sheet.chipShortBorder : _Sheet.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Center(child: IconRenderer(size: 18, id: id)),
            ),
            const SizedBox(width: 5),
            Text(
              Util.formatShortCount(have),
              style: base.copyWith(color: short ? _Sheet.short : _Sheet.have),
            ),
            const SizedBox(width: 5),
            Text(
              '/ ${Util.formatShortCount(needed)}',
              style: base.copyWith(color: _Sheet.needed),
            ),
          ],
        ),
      ),
    );
  }
}
