import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/equipment_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/potion_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/gear_screen.dart';
import 'package:rpg/widgets/potions_panel.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/countdown_timer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

// The potions card: what it lists, what the toggle does, and how a card
// reads while its potion is up. Rendered through the real controllers so
// the cards follow the bag and the buff tick rather than a fixture. The
// last test covers the thing that used to be a screen push — the card is
// inline on the gear screen now, a scroll down from the gear itself.
void main() {
  // BuffController ticks a periodic timer that never settles, so these use
  // fixed pumps rather than pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  Widget withProviders(GameSession session, Widget home) {
    return MultiProvider(
      providers: [
        Provider<GameSession>.value(value: session),
        ChangeNotifierProvider<InventoryController>.value(
          value: session.inventoryController,
        ),
        ChangeNotifierProvider<BuffController>.value(
          value: session.buffController,
        ),
        ChangeNotifierProvider<PotionController>.value(
          value: session.potionController,
        ),
        ChangeNotifierProvider<EquipmentController>.value(
          value: session.equipmentController,
        ),
      ],
      child: MaterialApp(home: home),
    );
  }

  Future<GameSession> pumpPotions(
    WidgetTester tester, {
    Map<ItemId, int> held = const {},
    Set<ItemId> auto = const {},
  }) async {
    final session = buildSession();
    final save = session.saveGameData;
    save.inventoryData.itemMap.addAll(held);
    save.playerData.autoDrinkPotions.addAll(auto);

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      withProviders(
        session,
        const Scaffold(body: SingleChildScrollView(child: PotionsPanel())),
      ),
    );
    await settle(tester);
    return session;
  }

  Finder switchFor(ItemId id) => find.byKey(ValueKey('auto-drink-${id.name}'));

  /// What [held] doses of [id] are worth back to back, as the card writes it.
  String stackLasts(ItemId id, int held) => CountdownTimer.formatDuration(
    (id.definition as BuffItemDefinition).duration * held,
  );
  Finder cardFor(ItemId id) => find.byKey(ValueKey('potion-card-${id.name}'));

  testWidgets('lists held potions and armed ones, nothing else', (
    tester,
  ) async {
    final session = await pumpPotions(
      tester,
      held: {ItemId.MINOR_SPEED_POTION: 2},
      auto: {ItemId.MINOR_ATTACK_POTION},
    );

    expect(find.byType(ItemStackTile<ItemId>), findsNWidgets(2));
    expect(switchFor(ItemId.MINOR_SPEED_POTION), findsOneWidget);
    expect(switchFor(ItemId.MINOR_ATTACK_POTION), findsOneWidget);
    expect(switchFor(ItemId.MINOR_STRENGTH_POTION), findsNothing);
    // nothing is running, and the screen says what that means
    expect(find.textContaining('only runs while an action'), findsOneWidget);

    session.dispose();
  });

  testWidgets('the switch arms and disarms the potion', (tester) async {
    final session = await pumpPotions(
      tester,
      held: {ItemId.MINOR_SPEED_POTION: 2},
    );
    final armed = session.saveGameData.playerData.autoDrinkPotions;

    await tester.tap(switchFor(ItemId.MINOR_SPEED_POTION));
    await settle(tester);
    expect(armed, {ItemId.MINOR_SPEED_POTION});
    // armed, idle: the card says how long two doses would keep the buff
    // up, and nothing was drunk
    expect(find.text(stackLasts(ItemId.MINOR_SPEED_POTION, 2)), findsOneWidget);
    expect(
      session.saveGameData.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION],
      2,
    );

    await tester.tap(switchFor(ItemId.MINOR_SPEED_POTION));
    await settle(tester);
    expect(armed, isEmpty);
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);

    session.dispose();
  });

  testWidgets('a potion that is up outlines its card and counts down', (
    tester,
  ) async {
    final session = await pumpPotions(
      tester,
      held: {ItemId.MINOR_SPEED_POTION: 2},
      auto: {ItemId.MINOR_SPEED_POTION},
    );
    final save = session.saveGameData;

    RoundedRectangleBorder shape() =>
        tester.widget<Material>(cardFor(ItemId.MINOR_SPEED_POTION)).shape!
            as RoundedRectangleBorder;

    expect(shape().side.width, lessThan(2));
    expect(find.byType(CountdownTimer), findsNothing);

    session.inventoryController.drinkPotion(ItemId.MINOR_SPEED_POTION);
    await settle(tester);

    expect(shape().side.width, 2);
    // armed, so the timer is the whole runway: what is left on the dose that
    // is up plus the dose still in the bag behind it
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    final buff = session.potionController.activeBuff(
      ItemId.MINOR_SPEED_POTION,
    )!;
    final dose =
        (ItemId.MINOR_SPEED_POTION.definition as BuffItemDefinition).duration;
    final held = session.potionController.heldCount(ItemId.MINOR_SPEED_POTION);
    expect(held, 1);
    expect(
      tester.widget<CountdownTimer>(find.byType(CountdownTimer)).expirationTime,
      buff.expirationTime.add(dose * held),
    );

    // once it lapses the card drops back to what the one dose left is
    // worth, which says it is still armed
    session.buffService.checkBuffExpriations(
      save.playerData.buffData,
      at: DateTime.now().add(const Duration(minutes: 4)),
    );
    session.buffController.refresh();
    await settle(tester);

    expect(shape().side.width, lessThan(2));
    expect(find.byType(CountdownTimer), findsNothing);
    expect(find.text(stackLasts(ItemId.MINOR_SPEED_POTION, 1)), findsOneWidget);
    // still armed, so the hourglass stays: one dose of runway left
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);

    session.dispose();
  });

  testWidgets('unarmed, a potion that is up reads as just that potion', (
    tester,
  ) async {
    final session = await pumpPotions(
      tester,
      held: {ItemId.MINOR_SPEED_POTION: 3},
    );

    session.inventoryController.drinkPotion(ItemId.MINOR_SPEED_POTION);
    await settle(tester);

    final buff = session.potionController.activeBuff(
      ItemId.MINOR_SPEED_POTION,
    )!;
    // nothing is going to be drunk after it, so there is no runway to show
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);
    expect(
      tester.widget<CountdownTimer>(find.byType(CountdownTimer)).expirationTime,
      buff.expirationTime,
    );

    session.dispose();
  });

  testWidgets('an armed potion with none left is dimmed but still toggles', (
    tester,
  ) async {
    final session = await pumpPotions(
      tester,
      auto: {ItemId.MINOR_ATTACK_POTION},
    );

    final dimmed = tester.widget<Opacity>(
      find
          .ancestor(
            of: cardFor(ItemId.MINOR_ATTACK_POTION),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(dimmed.opacity, 0.45);
    // nothing to drink, so there is no stretch of time to promise
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);

    await tester.tap(switchFor(ItemId.MINOR_ATTACK_POTION));
    await settle(tester);
    expect(session.saveGameData.playerData.autoDrinkPotions, isEmpty);

    session.dispose();
  });

  testWidgets('an empty bag shows the hint', (tester) async {
    final session = await pumpPotions(tester);

    expect(find.textContaining('No potions'), findsOneWidget);
    expect(find.byType(ItemStackTile<ItemId>), findsNothing);

    session.dispose();
  });

  testWidgets('the card fits the narrowest phone the game ships on', (
    tester,
  ) async {
    // inlining the grid into a card cost it the screen's full width, and a
    // cell sized by aspect ratio then came out shorter than the fixed stack
    // it holds — so the row height is fixed and this is why
    final session = buildSession();
    session.saveGameData.inventoryData.itemMap.addAll({
      ItemId.MINOR_SPEED_POTION: 2,
      ItemId.MINOR_ATTACK_POTION: 1,
      ItemId.MINOR_STRENGTH_POTION: 1,
      ItemId.MINOR_DEFENCE_POTION: 1,
    });
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    tester.view.physicalSize = const Size(320, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      withProviders(
        session,
        const Scaffold(body: SingleChildScrollView(child: PotionsPanel())),
      ),
    );
    await settle(tester);

    // a RenderFlex overflow throws in a test, so this is the assertion
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(cardFor(ItemId.MINOR_SPEED_POTION)).height,
      greaterThanOrEqualTo(52 + 48 + 18),
    );

    session.dispose();
  });

  testWidgets('the gear screen carries the card inline, no push', (
    tester,
  ) async {
    final session = buildSession();
    session.saveGameData.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION] = 1;
    session.saveGameData.playerData.autoDrinkPotions.add(
      ItemId.MINOR_SPEED_POTION,
    );
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(withProviders(session, const GearScreen()));
    await settle(tester);

    // the card is below the gear, so it is scrolled to rather than tapped
    await tester.scrollUntilVisible(
      switchFor(ItemId.MINOR_SPEED_POTION),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);

    expect(find.byKey(const ValueKey('gear-potions-card')), findsOneWidget);
    expect(find.text('1 auto · 0 active'), findsOneWidget);

    // and it is the live card, not a summary: the switch works in place
    await tester.tap(switchFor(ItemId.MINOR_SPEED_POTION));
    await settle(tester);
    expect(session.saveGameData.playerData.autoDrinkPotions, isEmpty);
    // nothing was pushed: the gear screen is still the only route
    expect(find.text('Gear'), findsOneWidget);

    session.dispose();
  });
}
