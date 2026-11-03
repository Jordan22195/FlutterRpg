import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/widgets/chest_info_dialog.dart';

void main() {
  testWidgets('a roll that lists the same item twice still opens', (
    tester,
  ) async {
    // the stand-in chest pools every floor boss's drops, and two bosses
    // can share a line
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showChestInfoDialog(
              context,
              title: 'Spider Den Chest',
              rolls: const [
                DropRoll(
                  chance: 0.25,
                  entries: [
                    ItemDropType(id: ItemId.SILK, lowCount: 1, highCount: 2),
                    ItemDropType(id: ItemId.SILK, lowCount: 1, highCount: 2),
                    ItemDropType(id: ItemId.VENOM),
                  ],
                ),
              ],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Spider Den Chest'), findsOneWidget);
    expect(find.text('Silk'), findsNWidgets(2));
  });
}
