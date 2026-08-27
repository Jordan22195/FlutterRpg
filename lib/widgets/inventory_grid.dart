import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
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
    this.showActiveBuffTimers = false,
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

  /// Counts down a potion you have active, in the corner of its own stack.
  /// Off by default: most grids show loot and drops rather than what the
  /// player is carrying, and a timer there would be answering a question
  /// nobody asked of a pile of rewards.
  final bool showActiveBuffTimers;

  @override
  Widget build(BuildContext context) {
    // watched, not read: BuffController notifies on its own tick, which is
    // what clears a timer from the grid the moment its buff runs out
    final buffController = showActiveBuffTimers
        ? context.watch<BuffController>()
        : null;

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
          buffExpirationTime: buffController
              ?.getGlobalBuff(stack.id)
              ?.expirationTime,
          showInfoDialogOnTap: showInfoDialogOnTap && onItemTap == null,
          title: titleForItem?.call(stack) ?? stack.id.definition?.name,
          description:
              descriptionForItem?.call(stack) ??
              stack.id.definition?.description,
          //onTap: onItemTap != null ? () => onItemTap!(stack) : null,
        );
      },
    );
  }
}
