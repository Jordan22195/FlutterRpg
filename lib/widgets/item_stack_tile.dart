import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/repeat_press_button.dart';
import '../utilities/image_resolver.dart';
import '../data/skill_data.dart';
import '../utilities/util.dart';
import '../widgets/countdown_timer.dart';

/// Border color used to signal rarity — an entity's, or the tier a piece of
/// equipment rolled, which are one ladder. A rare vein and a rare sword are
/// framed in the same blue. Common has no special color (falls back to the
/// theme outline).
Color? rarityBorderColor(Rarity rarity) {
  switch (rarity) {
    case Rarity.COMMON:
      return null;
    case Rarity.UNCOMMON:
      return Colors.green;
    case Rarity.RARE:
      return Colors.blue;
    case Rarity.EPIC:
      return Colors.purple;
    case Rarity.LEGENDARY:
      return Colors.orange;
  }
}

class ItemStackTile<T extends Enum> extends StatelessWidget {
  const ItemStackTile({
    super.key,
    required this.size,
    this.id,
    required this.count,
    this.onTap,
    this.showInfoDialogOnTap = true,
    this.title,
    this.description,
    this.isTimerStackTile = false,
    this.expirationTime,
    this.buffExpirationTime,
    this.borderColor,
    this.quality = Rarity.COMMON,
    this.depleted = false,
    this.alwaysShowCount = false,
    this.compactCount = true,
  });

  final double size;

  /// The rarity this tile's contents are, which frames the tile when no
  /// [borderColor] overrides it. Equipment passes the tier it rolled; an
  /// entity tile leaves it alone and is framed by its own rarity instead.
  final Rarity quality;

  /// The enum id for this stack (e.g., Items.copperOre, Skills.blacksmithing, etc.)
  final T? id;

  final int count;
  final DateTime? expirationTime;
  final bool isTimerStackTile;

  /// When this item's own buff is running, when it runs out. Puts a
  /// countdown in the bottom-left corner, opposite the count badge, so a
  /// potion you have active reads as active from the inventory grid.
  ///
  /// Distinct from [expirationTime], which replaces the count badge outright
  /// ([isTimerStackTile]) for a tile that *is* a timer — an active buff in
  /// the buff row. This one sits alongside the count.
  final DateTime? buffExpirationTime;

  final VoidCallback? onTap;

  final bool showInfoDialogOnTap;
  final String? title;
  final String? description;

  /// Overrides the tile border, e.g. to show equipment quality. An entity
  /// tile needs no override: it takes its border from its own rarity.
  final Color? borderColor;

  /// Renders the tile as spent: the art is darkened and the count badge
  /// stays up even at zero, so a used-up entity reads as unusable rather
  /// than as an ordinary single-item stack.
  final bool depleted;

  /// Keeps the count badge up even at 1. Off by default — a lone inventory
  /// item needs no "1" — but a recipe's amounts are the point of the tile,
  /// so a one-of input has to say so rather than read as unquantified.
  final bool alwaysShowCount;

  /// Shrinks the count badge and abbreviates the number
  /// ([Util.formatShortCount]). For dense preview rows of small tiles, where
  /// a six-digit count at full size covers the art it is counting and the
  /// reader only wants the magnitude anyway.
  final bool compactCount;

  void _showInfoDialog(BuildContext context) {
    final currentId = id;
    if (currentId is! ItemId) return;
    final itemDef = currentId.definition;
    final inventoryController = context.read<InventoryController>();
    final buffController = context.read<BuffController>();
    final devCountController = TextEditingController(
      text: '${inventoryController.getItemCount(currentId)}',
    );
    // read through the controllers rather than the providers: the dialog
    // sits on its own route, and holding Drink has to rebuild it in place
    // as the stack drains and the buff climbs
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: Listenable.merge([inventoryController, buffController]),
        builder: (context, _) => _buildInfoDialog(
          dialogContext,
          currentId,
          itemDef,
          inventoryController,
          buffController,
          devCountController,
        ),
      ),
    );
  }

  Widget _buildInfoDialog(
    BuildContext dialogContext,
    ItemId currentId,
    ItemDefinition itemDef,
    InventoryController inventoryController,
    BuffController buffController,
    TextEditingController devCountController,
  ) {
    // what the player is holding, which is not the tile's own [count]: that
    // is whatever the screen is quantifying — a recipe's inputs, a shop's
    // stock — so a potion you do not own must not offer a drink just
    // because a recipe listed it, and the dialog's badge must not claim you
    // have one because a recipe asked for one
    final held = inventoryController.getItemCount(currentId);
    final canDrink = inventoryController.isDrinkable(currentId) && held > 0;
    // what this potion is putting up right now, if anything — drinking
    // extends it, so this is what climbs while the button is held
    final activeBuff = inventoryController.isDrinkable(currentId)
        ? buffController.getGlobalBuff(currentId)
        : null;
    return AlertDialog(
      title: Text(itemDef.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // the same badge the tiles wear, on the big icon: how many you
            // are holding is the thing the dialog is most often opened to
            // check, and it has to follow a drink down
            SizedBox(
              width: size * 2,
              height: size * 2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IconRenderer(size: size * 2, id: currentId),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: _CountBadge(
                      count: held,
                      alwaysShow: true,
                      compact: false,
                      tileSize: size * 2,
                    ),
                  ),
                ],
              ),
            ),
            Text(itemDef.description ?? "No description available."),
            Row(
              children: [
                IconRenderer(size: 40, id: ItemId.COINS),
                Text("${itemDef.value}"),
              ],
            ),
            if (itemDef is BuffItemDefinition)
              Row(
                children: [
                  Icon(Icons.timer),
                  Text("${itemDef.duration.inSeconds}s"),
                  // what is actually on the clock, next to what one dose
                  // is worth. drinking extends rather than restarts, so
                  // this is the number that grows as the button is held.
                  if (activeBuff != null) ...[
                    const SizedBox(width: 16),
                    CountdownTimer(expirationTime: activeBuff.expirationTime),
                    const Text(" left"),
                  ],
                ],
              ),
            if (itemDef is EquipmentItemDefinition)
              Text("Slot: ${itemDef.armorSlot}"),
            if (itemDef is EquipmentItemDefinition)
              for (var stat in itemDef.skillBonus.entries)
                Row(
                  children: [
                    IconRenderer(size: 40, id: stat.key),
                    Text("${stat.value}"),
                  ],
                ),

            if (itemDef is BuffItemDefinition)
              for (var stat in itemDef.skillBonus.entries)
                Row(
                  children: [
                    IconRenderer(size: 40, id: stat.key),
                    Text("${stat.value}"),
                  ],
                ),
            if (itemDef is FoodItemDefinition)
              Row(
                children: [
                  IconRenderer(size: 40, id: SkillId.HITPOINTS),
                  Text("+${itemDef.restoreAmount}"),
                ],
              ),

            // dev tool: force the player-inventory stack count
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: devCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Dev: stack count',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final count = int.tryParse(devCountController.text);
                    if (count != null) {
                      inventoryController.devSetItemCount(currentId, count);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // stays open on a drink, and holding it drinks the stack down —
        // drinkPotion is a no-op once the last one is gone, which is what
        // RepeatPressButton's repeat relies on
        if (canDrink)
          RepeatPressButton(
            label: 'Drink',
            onPressed: () => inventoryController.drinkPotion(currentId),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  ImageProvider? _resolveImage() {
    final currentId = id;
    if (currentId == null) return null;

    return EnumImageProviderLookup.resolveDynamic(currentId);
  }

  /// An entity frames itself: its rarity is a property of the entity, not
  /// of the screen showing it, so every tile in the game picks the color
  /// up without its caller having to know about rarity at all. Anything
  /// else is framed by the [quality] it was handed, unless [borderColor]
  /// overrides the lot to say something that is not about rarity.
  Color? get _effectiveBorderColor {
    if (borderColor != null) return borderColor;
    final currentId = id;
    if (currentId is EntityId) {
      return rarityBorderColor(currentId.definition.rarity);
    }
    return rarityBorderColor(quality);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImage = _resolveImage();
    final effectiveBorderColor = _effectiveBorderColor;

    Widget icon = _IconOrFallback(imageProvider: resolvedImage);
    if (depleted) {
      // srcATop paints only where the sprite is opaque, so the art dims
      // without laying a black rectangle over its transparent edges
      icon = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.65),
          BlendMode.srcATop,
        ),
        child: icon,
      );
    }

    final child = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background + icon
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  width: effectiveBorderColor != null ? 2 : 1,
                  color:
                      effectiveBorderColor ??
                      Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(depleted ? 0.25 : 0.5),
                ),
              ),
              child: Padding(padding: const EdgeInsets.all(6), child: icon),
            ),
          ),

          // Count badge
          if (isTimerStackTile)
            Positioned(
              right: 4,
              bottom: 4,
              child: CountdownTimer(
                expirationTime: expirationTime!,
                size: .25 * size,
              ),
            )
          else
            Positioned(
              right: 4,
              bottom: 4,
              child: _CountBadge(
                count: count,
                depleted: depleted,
                alwaysShow: alwaysShowCount,
                compact: compactCount,
                tileSize: size,
              ),
            ),

          // this item's own buff, ticking down in the corner opposite the
          // count. no clock icon: the two corners share one tile's width,
          // and the count is the one that must never be crowded out
          if (buffExpirationTime != null)
            Positioned(
              left: 4,
              bottom: 4,
              child: _BuffTimerBadge(
                expirationTime: buffExpirationTime!,
                tileSize: size,
              ),
            ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap:
          onTap ??
          (showInfoDialogOnTap ? () => _showInfoDialog(context) : null),
      child: child,
    );
  }
}

/// The time left on this item's own buff, worn in the tile's bottom-left
/// corner. Shaped like [_CountBadge] so the two corners read as a pair, and
/// tinted so an active potion stands out from the plain count opposite it.
class _BuffTimerBadge extends StatelessWidget {
  const _BuffTimerBadge({required this.expirationTime, required this.tileSize});

  final DateTime expirationTime;

  /// The tile this badge sits on. Matches [_CountBadge]'s scaling so the
  /// two corners stay the same size as each other on every tile.
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fontSize = (tileSize * 0.16).clamp(7.0, 28.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.45,
        vertical: fontSize * 0.11,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(fontSize * 0.9),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
        // CountdownTimer sizes its text at 0.8 of what it is given, and it
        // ticks itself, so the corner stays live without the tile rebuilding
        child: CountdownTimer(
          expirationTime: expirationTime,
          size: fontSize / 0.8,
          showIcon: false,
        ),
      ),
    );
  }
}

class _IconOrFallback extends StatelessWidget {
  const _IconOrFallback({required this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    if (imageProvider == null) {
      return const Center(child: Icon(Icons.help_outline));
    }

    return Image(
      image: imageProvider!,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none, // nice for pixel art
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.tileSize,
    this.depleted = false,
    this.alwaysShow = false,
    this.compact = false,
  });

  final int count;
  final bool depleted;
  final bool alwaysShow;
  final bool compact;

  /// The tile this badge sits on. The badge scales with it so the count is
  /// still readable on a 200px portrait, and the 9pt floor keeps the small
  /// inventory tiles looking exactly as they did.
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    // nothing left to count: a spent tile already reads as spent from its
    // darkened art, so a "0" only adds noise to it
    if (count <= 0) return const SizedBox.shrink();

    // a lone item needs no "1", unless the tile is quantifying something
    // (a recipe's amounts), where the number is the point
    if (count <= 1 && !depleted && !alwaysShow) return const SizedBox.shrink();

    // the compact floor goes under the usual 9pt one: on a 30px preview
    // tile a 9pt badge is most of the tile, and these rows are read as a
    // group rather than a number at a time
    final fontSize = (tileSize * 0.16).clamp(compact ? 7.0 : 9.0, 28.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.45,
        vertical: fontSize * 0.11,
      ),
      decoration: BoxDecoration(
        color: depleted
            ? Theme.of(context).colorScheme.error
            : Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(fontSize * 0.9),
      ),
      child: Text(
        compact ? Util.formatShortCount(count) : '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
