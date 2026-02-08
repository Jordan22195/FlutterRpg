import 'package:flutter/material.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/item.dart'; // <-- uses ItemController.imageProviderFor
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
    this.showInfoDialogOnTap = false,
    this.titleForItem,
    this.descriptionForItem,
  });

  final List<ObjectStack> items;

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

  ImageProvider? _resolveImage(ObjectStack stack) {
    // If caller provided a resolver, use it.
    final fromCallback = imageForItem?.call(stack);
    if (fromCallback != null) return fromCallback;

    // Otherwise, resolve from item registry using dynamic enum key.
    return ItemController.imageProviderFor(stack.id);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
              ItemController.definitionFor(stack.id)?.name,
          description:
              descriptionForItem?.call(stack) ??
              ItemController.definitionFor(stack.id)?.description,
          //onTap: onItemTap != null ? () => onItemTap!(stack) : null,
        );
      },
    );
  }
}
