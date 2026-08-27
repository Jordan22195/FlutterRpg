import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/shop_controller.dart';
import 'package:rpg/utilities/interval_runner.dart';
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
            _RepeatPressButton(label: buttonLabel, onPressed: onPressed),
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

/// A trade button that fires once on tap, then keeps firing on an interval
/// for as long as it's held — long-pressing "Buy" or "Sell" repeats the
/// trade instead of one tap per item. Past [_accelerateAfter] the interval
/// drops to [_fastRepeatInterval], so clearing out a big stack doesn't mean
/// sitting through it one buy at a time. The trade calls this repeats into
/// (buy/sellOne/sellOneEquipment) are all safe no-ops once coins, stock or
/// the stack run out, so this doesn't re-check affordability itself.
class _RepeatPressButton extends StatefulWidget {
  const _RepeatPressButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_RepeatPressButton> createState() => _RepeatPressButtonState();
}

class _RepeatPressButtonState extends State<_RepeatPressButton> {
  static const _repeatInterval = Duration(milliseconds: 120);
  static const _fastRepeatInterval = Duration(milliseconds: 15);
  static const _accelerateAfter = Duration(seconds: 1);

  final _repeat = IntervalRunner();
  Timer? _accelerateTimer;

  void _startRepeating() {
    // the long press already stood in for the first tap, so fire once
    // immediately rather than waiting a full interval for the first trade
    widget.onPressed?.call();
    _repeat.start(_repeatInterval, () => widget.onPressed?.call());
    _accelerateTimer = Timer(_accelerateAfter, () {
      _repeat.stop();
      _repeat.start(_fastRepeatInterval, () => widget.onPressed?.call());
    });
  }

  void _stopRepeating() {
    _repeat.stop();
    _accelerateTimer?.cancel();
    _accelerateTimer = null;
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.onPressed == null
          ? null
          : (_) => _startRepeating(),
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: TextButton(onPressed: widget.onPressed, child: Text(widget.label)),
    );
  }
}
