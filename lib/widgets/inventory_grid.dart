import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/game_session.dart';
import 'item_stack_tile.dart';

class InventoryGrid extends StatelessWidget {
  const InventoryGrid({
    super.key,
    required this.items,
    this.imageForItem, // optional override
    this.columns = 5,
    this.tileSize = 56,
    this.spacing = 10,
    this.onItemTap,
    this.showInfoDialogOnTap = true,
    this.titleForItem,
    this.descriptionForItem,
    this.shrinkWrap = false,
  });

  final List<ObjectStack> items;

  /// Set when embedding in an unbounded-height parent (e.g. a ListView):
  /// the grid sizes to its content and scrolls with the parent instead.
  final bool shrinkWrap;

  /// Optional image resolver override.
  /// If null, the grid will try to resolve via ItemController.imageProviderFor(stack.objectId).
  final ImageProvider? Function(ObjectStack stack)? imageForItem;

  final int columns;
  final double tileSize;
  final double spacing;

  final void Function(ObjectStack stack)? onItemTap;
  final bool showInfoDialogOnTap;

  final String Function(ObjectStack stack)? titleForItem;
  final String Function(ObjectStack stack)? descriptionForItem;

  @override
  Widget build(BuildContext context) {
    final itemCatalog = context.read<GameSession>().catalogBundle.itemCatalog;

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final stack = items[i];

        return ItemStackTile(
          size: tileSize,
          id: stack.id,
          count: stack.count,
          showInfoDialogOnTap: showInfoDialogOnTap && onItemTap == null,
          title:
              titleForItem?.call(stack) ??
              itemCatalog.definitionFor(stack.id)?.name,
          description:
              descriptionForItem?.call(stack) ??
              itemCatalog.definitionFor(stack.id)?.description,
          //onTap: onItemTap != null ? () => onItemTap!(stack) : null,
        );
      },
    );
  }
}
