import 'package:flutter/material.dart';

import '../catalogs/entities/entities.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_theme.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';

/// What a sprite frame holds, which decides its tint.
enum SpriteKind {
  /// A creature that fights back.
  combat,

  /// A spot worked for materials: ponds, trees, ore.
  gathering,

  /// A crafting station or a crafting input.
  crafting,

  /// A fire, or anything firemaking.
  fire,

  /// A dungeon entrance; framed by its rarity.
  dungeon,
}

/// The rounded, tinted frame a sprite sits in on list rows, recipe cards
/// and the status row. The tint says what kind of thing it is; an entity
/// rarer than common is outlined in its rarity colour instead of the
/// tint's border, as it was before.
class SpriteFrame extends StatelessWidget {
  const SpriteFrame({
    super.key,
    required this.id,
    required this.kind,
    this.size = 52,
    this.spriteSize,
    this.radius = 12,
    this.depleted = false,
    this.onTap,
  });

  final Enum id;
  final SpriteKind kind;
  final double size;

  /// The sprite inside, ~40 on the standard frames.
  final double? spriteSize;
  final double radius;

  /// A used-up node: the sprite darkens.
  final bool depleted;
  final VoidCallback? onTap;

  /// The frame fill and border for [kind] in the current theme.
  static SpriteTint tintFor(BuildContext context, SpriteKind kind) {
    final colors = context.gameColors;
    final palette = context.palette;
    return switch (kind) {
      SpriteKind.combat => colors.combatTint,
      SpriteKind.gathering => SpriteTint(
        fill: palette.gatherTintFill,
        border: palette.gatherTintBorder,
      ),
      SpriteKind.crafting => colors.craftingTint,
      SpriteKind.fire => colors.fireTint,
      SpriteKind.dungeon => SpriteTint(
        fill: colors.dungeonTintFill,
        border: palette.borderStrong,
      ),
    };
  }

  /// The bare sprite a frame holds, for frames built elsewhere.
  static Widget sprite(Enum id, {required double size}) =>
      IconRenderer(size: size, id: id);

  @override
  Widget build(BuildContext context) {
    final tint = tintFor(context, kind);
    final currentId = id;
    final rarity = currentId is EntityId
        ? rarityBorderColor(currentId.definition.rarity)
        : null;

    Widget sprite = SpriteFrame.sprite(id, size: spriteSize ?? size - 12);
    if (depleted) {
      // srcATop paints only where the sprite is opaque, so the art dims
      // without laying a dark rectangle over its transparent edges
      sprite = ColorFiltered(
        colorFilter: ColorFilter.mode(
          context.palette.bg.withValues(alpha: 0.65),
          BlendMode.srcATop,
        ),
        child: sprite,
      );
    }

    final frame = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: rarity ?? tint.border,
          width: rarity != null ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: sprite,
    );

    if (onTap == null) return frame;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: frame,
    );
  }
}
