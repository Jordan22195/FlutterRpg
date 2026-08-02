import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import '../utilities/image_resolver.dart';
import '../data/skill_data.dart';
import '../widgets/countdown_timer.dart';

/// Border color used to signal an equipment item's quality tier.
/// Common quality has no special color (falls back to the theme outline).
Color? qualityBorderColor(ItemQuality quality) {
  switch (quality) {
    case ItemQuality.COMMON:
      return null;
    case ItemQuality.UNCOMMON:
      return Colors.green;
    case ItemQuality.RARE:
      return Colors.blue;
    case ItemQuality.EPIC:
      return Colors.purple;
    case ItemQuality.LEGENDARY:
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
    this.borderColor,
    this.depleted = false,
  });

  final double size;

  /// The enum id for this stack (e.g., Items.copperOre, Skills.blacksmithing, etc.)
  final T? id;

  final int count;
  final DateTime? expirationTime;
  final bool isTimerStackTile;

  final VoidCallback? onTap;

  final bool showInfoDialogOnTap;
  final String? title;
  final String? description;

  /// Overrides the tile border, e.g. to show equipment quality.
  final Color? borderColor;

  /// Renders the tile as spent: the art is darkened and the count badge
  /// stays up even at zero, so a used-up entity reads as unusable rather
  /// than as an ordinary single-item stack.
  final bool depleted;

  void _showInfoDialog(BuildContext context) {
    final currentId = id;
    if (currentId is! ItemId) return;
    final itemDef =
        context.read<GameSession>().catalogBundle.itemCatalog.definitionFor(
          currentId,
        ) ??
        ItemDefinition(name: "error", value: -1);
    final inventoryController = context.read<InventoryController>();
    final devCountController = TextEditingController(
      text: '${inventoryController.getItemCount(currentId)}',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(itemDef.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconRenderer(size: size * 2, id: id as ItemId),
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
                  ],
                ),
              if (itemDef is EquipmentItemDefition)
                Text("Slot: ${itemDef.armorSlot}"),
              if (itemDef is EquipmentItemDefition)
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  ImageProvider? _resolveImage() {
    final currentId = id;
    if (currentId == null) return null;

    return EnumImageProviderLookup.resolveDynamic(currentId);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImage = _resolveImage();

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
                  width: borderColor != null ? 2 : 1,
                  color:
                      borderColor ??
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
  });

  final int count;
  final bool depleted;

  /// The tile this badge sits on. The badge scales with it so the count is
  /// still readable on a 200px portrait, and the 9pt floor keeps the small
  /// inventory tiles looking exactly as they did.
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    // a lone item needs no "1", but a depleted stack has to say "0" —
    // that zero is the whole point of the badge
    if (count <= 1 && !depleted) return const SizedBox.shrink();

    final fontSize = (tileSize * 0.16).clamp(9.0, 28.0);

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
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
