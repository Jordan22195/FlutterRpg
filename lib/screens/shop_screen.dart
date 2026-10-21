import 'package:flutter/material.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/widgets/action_dock.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/travel_row.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/shop_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/services/shop_service.dart';
import 'package:rpg/widgets/countdown_timer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/repeat_press_button.dart';

/*
shop screen contents:
-header with shop name, back button and sort button
-coin balance and restock countdown
-"for sale" list: shop stock with buy buttons (price = value + markup)
-"sell" list: the player's items with sell buttons (price = value)
*/

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  /// The sell row under a held button, kept on the list in its place after
  /// its stack runs out, until the finger comes off. Without it the row
  /// would vanish mid-hold and the next one would slide under the finger
  /// and start selling instead. [_heldIndex] is where it sat.
  ItemId? _heldItem;
  EquipmentItem? _heldEquipment;
  int _heldIndex = 0;

  void _holdItem(ItemId id, int index, bool held) => setState(() {
    _heldItem = held ? id : null;
    _heldIndex = index;
  });

  void _holdEquipment(EquipmentItem item, int index, bool held) => setState(() {
    _heldEquipment = held ? item : null;
    _heldIndex = index;
  });

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }

  /// [onPressed] null greys the button out, which is what a shop read from
  /// a zone away does with every row: the stock is worth reading before you
  /// make the trip, but the counter is not in reach until you are standing
  /// at it — and this screen has no action bar to offer the trip on.
  ///
  /// [soldOut] keeps a bought-out shelf slot in its place, greyed, with the
  /// price swapped for a disabled "Sold out" until the restock.
  Widget _tradeRow({
    required BuildContext context,
    required Widget tile,
    required String name,
    required String buttonLabel,
    required VoidCallback? onPressed,
    bool soldOut = false,
    String soldOutLabel = 'Sold out',
    Key? key,
    ValueChanged<bool>? onHoldChanged,
  }) {
    final row = Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            tile,
            const SizedBox(width: 12),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
            RepeatPressButton(
              label: soldOut ? soldOutLabel : buttonLabel,
              onPressed: soldOut ? null : onPressed,
              onHoldChanged: onHoldChanged,
            ),
          ],
        ),
      ),
    );
    // one wrapper either way, so a row that empties under a held button
    // keeps its element, and with it the hold
    return Opacity(key: key, opacity: soldOut ? 0.5 : 1, child: row);
  }

  /// One control for the whole screen: the shelf and both sell lists read
  /// in whatever order is picked here. A menu rather than a cycling button,
  /// so the orderings on offer are readable without tapping through them.
  Widget _sortButton(ShopController controller) {
    final mode = controller.sortMode();
    return PopupMenuButton<ShopSortMode>(
      tooltip: 'Sort',
      initialValue: mode,
      onSelected: controller.setSortMode,
      itemBuilder: (_) => [
        for (final option in ShopSortMode.values)
          PopupMenuItem<ShopSortMode>(value: option, child: Text(option.label)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort),
          const SizedBox(width: 4),
          Text(mode.label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShopController>();
    final canTrade = context.watch<WorldController>().isViewingCurrentZone;
    final stock = controller.stock();
    final sellableItems = [...controller.sellableItems()];
    final sellableEquipment = [...controller.sellableEquipment()];

    // a held row whose stack just ran out stays where it was, at zero
    final heldItem = _heldItem;
    if (heldItem != null && sellableItems.every((s) => s.id != heldItem)) {
      sellableItems.insert(
        _heldIndex.clamp(0, sellableItems.length),
        ObjectStack(id: heldItem, count: 0),
      );
    }
    final heldEquipment = _heldEquipment;
    if (heldEquipment != null &&
        sellableEquipment.every(
          (e) => e.instanceId != heldEquipment.instanceId,
        )) {
      sellableEquipment.insert(
        _heldIndex.clamp(0, sellableEquipment.length),
        heldEquipment,
      );
    }
    final nextRestockAt = controller.nextRestockAt();

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
                      controller.shopName(),
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _sortButton(controller),
                ],
              ),
            ),

            // coin balance and time until the shelf rerolls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  ItemStackTile(
                    size: 40,
                    count: controller.playerCoins(),
                    id: ItemId.COINS,
                    showInfoDialogOnTap: false,
                  ),
                  const Spacer(),
                  const Text("Restock "),
                  if (nextRestockAt != null)
                    CountdownTimer(expirationTime: nextRestockAt),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  _sectionHeader(context, "For Sale"),
                  if (stock.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("Sold out."),
                    ),
                  for (final entry in stock)
                    _tradeRow(
                      context: context,
                      soldOut: entry.count <= 0,
                      tile: ItemStackTile(
                        size: 48,
                        count: entry.count,
                        id: entry.itemId,
                        // bought out: the art darkens with the row
                        depleted: entry.count <= 0,
                      ),
                      name: controller.itemName(entry.itemId),
                      buttonLabel: "Buy ${controller.buyPrice(entry.itemId)}c",
                      onPressed: canTrade && controller.canAfford(entry.itemId)
                          ? () => controller.buy(entry)
                          : null,
                    ),

                  const Divider(),
                  _sectionHeader(context, "Sell"),
                  if (sellableItems.isEmpty && sellableEquipment.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("Nothing to sell."),
                    ),
                  for (final (index, item) in sellableItems.indexed)
                    _tradeRow(
                      context: context,
                      key: ValueKey(('sell', item.id)),
                      onHoldChanged: (held) => _holdItem(item.id, index, held),
                      // sold down to nothing under a held button
                      soldOut: item.count <= 0,
                      soldOutLabel: 'None left',
                      tile: ItemStackTile(
                        size: 48,
                        count: item.count,
                        id: item.id,
                        depleted: item.count <= 0,
                      ),
                      name: controller.itemName(item.id),
                      buttonLabel: "Sell ${controller.sellPrice(item.id)}c",
                      onPressed: canTrade
                          ? () => controller.sellOne(item.id)
                          : null,
                    ),
                  for (final (index, item) in sellableEquipment.indexed)
                    _tradeRow(
                      context: context,
                      key: ValueKey(('sell', item.instanceId)),
                      onHoldChanged: (held) =>
                          _holdEquipment(item, index, held),
                      // sold out of the bag under a held button
                      soldOut: controller.sellableEquipment().every(
                        (e) => e.instanceId != item.instanceId,
                      ),
                      soldOutLabel: 'None left',
                      tile: ItemStackTile(
                        size: 48,
                        count: item.count,
                        id: item.id,
                        showInfoDialogOnTap: false,
                        quality: item.quality,
                      ),
                      name: item.name,
                      buttonLabel: "Sell ${item.value}c",
                      onPressed: canTrade
                          ? () => controller.sellOneEquipment(item.instanceId)
                          : null,
                    ),
                ],
              ),
            ),

            // a shop a zone away trades nothing until the player has walked
            // there, so under the shelves is the way there: the road, and
            // the travel button that walks it
            if (!canTrade)
              ActionDock(
                banner: const TravelRow(),
                buttons: ActionButtonRow(
                  padding: EdgeInsets.zero,
                  // away from the zone this is always the travel button; the
                  // shop has no action of its own to start
                  actionButton: ActionOrTravelButton(
                    enabled: true,
                    label: 'Trade',
                    startActionFunction: () {},
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
