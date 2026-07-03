import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

class BuffRow extends StatelessWidget {
  const BuffRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BuffController>();
    final buffs = [
      ...controller.getCurrentZoneBuffs(),
      ...controller.getGlobalBuffs(),
    ];

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: buffs.length,
        itemBuilder: (context, index) {
          final buff = buffs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 4.0, left: 4.0),
            child: ItemStackTile(
              size: 56,
              count: 0,
              id: buff.id,
              isTimerStackTile: true,
              expirationTime: buff.expirationTime,
            ),
          );
        },
      ),
    );
  }
}
