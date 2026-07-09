import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/controllers/shop_controller.dart';
import 'package:rpg/widgets/countdown_timer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

/*
shop screen contents:
-header with shop name and back button
-coin balance and restock countdown
-"for sale" list: shop stock with buy buttons (price = value + markup)
-"sell" list: the player's items with sell buttons (price = value)
*/

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }

  Widget _tradeRow({
    required BuildContext context,
    required Widget tile,
    required String name,
    required String buttonLabel,
    required VoidCallback? onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            tile,
            const SizedBox(width: 12),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
            TextButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShopController>();
    final stock = controller.stock();
    final sellableItems = controller.sellableItems();
    final sellableEquipment = controller.sellableEquipment();
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
                      tile: ItemStackTile(
                        size: 48,
                        count: entry.count,
                        id: entry.itemId,
                      ),
                      name: controller.itemName(entry.itemId),
                      buttonLabel: "Buy ${controller.buyPrice(entry.itemId)}c",
                      onPressed: controller.canAfford(entry.itemId)
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
                  for (final item in sellableItems)
                    _tradeRow(
                      context: context,
                      tile: ItemStackTile(
                        size: 48,
                        count: item.count,
                        id: item.id,
                      ),
                      name: controller.itemName(item.id),
                      buttonLabel: "Sell ${controller.sellPrice(item.id)}c",
                      onPressed: () => controller.sellOne(item.id),
                    ),
                  for (final item in sellableEquipment)
                    _tradeRow(
                      context: context,
                      tile: ItemStackTile(
                        size: 48,
                        count: item.count,
                        id: item.id,
                        showInfoDialogOnTap: false,
                        borderColor: qualityBorderColor(item.quality),
                      ),
                      name: item.name,
                      buttonLabel: "Sell ${item.value}c",
                      onPressed: () =>
                          controller.sellOneEquipment(item.instanceId),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
