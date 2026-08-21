import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/eat_food_button.dart';
import 'package:rpg/widgets/primary_button.dart';

// The action bar's side buttons are boxed to a fixed height and a narrow
// fixed width, so their contents have very little room: the face is the
// bar height minus the base lip it sits on, minus its own padding. These
// render them at exactly the size the bar gives them and fail on any
// overflow, which a RenderFlex reports through FlutterError.
void main() {
  setUpAll(() {
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
  });

  /// Renders [child] in the exact slot ActionButtonRow gives a side button.
  Future<void> pumpInSideSlot(
    WidgetTester tester,
    Widget child, {
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(width: kActionBarSideButtonWidth, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Widget eatButton({required bool hasFood, int count = 1}) {
    return EatFoodButton(
      foodItemId: hasFood ? ItemId.COOKED_CHICKEN : ItemId.NULL,
      foodItemCount: count,
      onEat: () {},
      onPickFood: () {},
    );
  }

  testWidgets('the eat button fits its slot with food equipped', (
    tester,
  ) async {
    await pumpInSideSlot(tester, eatButton(hasFood: true, count: 12));

    expect(tester.takeException(), isNull);
    expect(find.text('Eat 12'), findsOneWidget);
    expect(
      tester.getSize(find.byType(EatFoodButton)).height,
      kActionBarButtonHeight,
    );
  });

  testWidgets('the eat button fits its slot with nothing equipped', (
    tester,
  ) async {
    await pumpInSideSlot(tester, eatButton(hasFood: false));

    expect(tester.takeException(), isNull);
    expect(find.text('Eat'), findsOneWidget);
  });

  testWidgets('the eat button survives a large count and a big text scale', (
    tester,
  ) async {
    // the label grows with both, and the face it sits on does not
    await pumpInSideSlot(
      tester,
      eatButton(hasFood: true, count: 9999),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
  });
}
