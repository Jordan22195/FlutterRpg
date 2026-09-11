import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'equipment_info_dialog.dart';
import 'item_stack_tile.dart';

/// One flat grid of everything an inventory holds: its stackable [items]
/// first, then its unique [equipment] instances, one tile per instance.
///
/// The two live in different lists because they are different types — a
/// stack is an id and a count, a piece of equipment carries its own rolled
/// quality and enchant — but the player reads them as one bag, so the grid
/// draws them as one. An equipment tile is framed in the quality it rolled
/// and opens the equipment dialog, which prices its stats at that tier.
class InventoryGrid extends StatelessWidget {
  const InventoryGrid({
    super.key,
    required this.items,
    this.equipment = const [],
    this.imageForItem, // optional override
    this.columns = 5,
    this.tileSize = 56,
    this.spacing = 10,
    this.onItemTap,
    this.onEquipmentTap,
    this.showInfoDialogOnTap = true,
    this.titleForItem,
    this.descriptionForItem,
    this.shrinkWrap = false,
    this.showActiveBuffTimers = false,
  });

  final List<ObjectStack> items;

  /// Unique equipment instances, drawn after [items]. Identical pieces
  /// already share one instance with a count, so each entry is one tile.
  final List<EquipmentItem> equipment;

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

  /// Replaces the equipment info dialog for a screen that wants to do
  /// something else with a tapped piece.
  final void Function(EquipmentItem item)? onEquipmentTap;

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
      itemCount: items.length + equipment.length,
      itemBuilder: (context, i) {
        if (i >= items.length) {
          return _equipmentTile(context, equipment[i - items.length]);
        }

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
          onTap: onItemTap != null ? () => onItemTap!(stack) : null,
        );
      },
    );
  }

  /// A piece of equipment in the quality it rolled. `quality:` rather than
  /// a bare border color, so the frame and the dialog's stat tier agree.
  Widget _equipmentTile(BuildContext context, EquipmentItem item) {
    final tap = onEquipmentTap;
    return ItemStackTile(
      size: tileSize,
      id: item.id,
      count: item.count,
      quality: item.quality,
      showInfoDialogOnTap: false,
      onTap: tap != null
          ? () => tap(item)
          : () => showEquipmentInfoDialog(context, item),
    );
  }
}
