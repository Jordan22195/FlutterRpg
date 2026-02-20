import 'package:flutter/material.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../data/item.dart';

class BuffRow extends StatelessWidget {
  const BuffRow({super.key});

  @override
  Widget build(BuildContext context) {
    final buffs = BuffController.instance.activeBuffs;
    final campfireBuff = BuffController.instance.campfireBuff;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (DateTime.now().isBefore(campfireBuff.expirationTime))
            ItemStackTile(
              size: 56,
              count: 0,
              id: campfireBuff.id,
              isTimerStackTile: true,
              expirationTime: campfireBuff.expirationTime,
            ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: buffs.length,
              itemBuilder: (context, index) {
                final buff = buffs.values.elementAt(index);
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
          ),
        ],
      ),
    );
  }
}
