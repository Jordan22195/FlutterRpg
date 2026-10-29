import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/screens/firepit_screen.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/countdown_timer.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/recipe_picker_sheet.dart';
import 'package:rpg/widgets/skill_ring_row.dart';

// Renders the real FirepitScreen through the provider tree, so what the
// sections show comes from the live fire buff rather than a fixture.
void main() {
  // BuffController ticks a periodic timer that never settles, so these use
  // fixed pumps rather than pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<GameSession> pumpFirepit(
    WidgetTester tester, {
    String? lightRecipeId,
    // the firepit's own per-skill recipe selections, as the player would
    // have left them
    Map<SkillId, String>? selections,
    int logs = 200,
  }) async {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    // icon resolvers so IconRenderer doesn't throw
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    // tall enough that the whole ListView is built: the COOK section sits
    // below the fold at the default 800x600 surface
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final firemaking = save.playerData.skillData[SkillId.FIREMAKING]!;
    firemaking.xp = firemaking.xpTable[40];
    save.inventoryData.itemMap[ItemId.LOGS] = logs;
    save.inventoryData.itemMap[ItemId.MINNOW] = 20;

    // the player is standing at the firepit
    save.playerData.currentEntityViewId = EntityId.FIREPIT;
    if (selections != null) {
      save.craftingState.selectedRecipeByEntity[EntityId.FIREPIT] = selections;
    }

    if (lightRecipeId != null) {
      save.craftingState.craftingEntityId = EntityId.FIREPIT;
      save.craftingState.activeRecipeId = lightRecipeId;
      session.craftingSystem.craftActiveRecipe(
        save.craftingState,
        save.playerData,
        save.inventoryData,
        save.playerData.buffData,
        save.worldData,
      );
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorldController>.value(
            value: session.worldController,
          ),
          Provider<GameSession>.value(value: session),
          ChangeNotifierProvider<CraftingController>.value(
            value: session.craftingController,
          ),
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
          ChangeNotifierProvider<BuffController>.value(
            value: session.buffController,
          ),
          ChangeNotifierProvider<ActionTimingController>.value(
            value: session.actionTimingController,
          ),
          ChangeNotifierProvider<ActionQueueController>.value(
            value: session.actionQueueController,
          ),
          ChangeNotifierProvider<PlayerDataController>.value(
            value: session.playerDataController,
          ),
          // the status row on the art strip reads the encounter for its
          // damage numbers
          ChangeNotifierProvider<EncounterController>.value(
            value: session.encounterController,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FirepitScreen())),
      ),
    );
    await settle(tester);
    return session;
  }

  final cookingCard = find.byKey(const ValueKey('firepit-cooking-card'));

  /// Whether the cooking card is locked: greyed and shut to taps.
  bool cookingLocked(WidgetTester tester) {
    final gate = tester.widget<IgnorePointer>(
      find
          .ancestor(of: cookingCard, matching: find.byType(IgnorePointer))
          .first,
    );
    final dim = tester.widget<Opacity>(
      find.ancestor(of: cookingCard, matching: find.byType(Opacity)).first,
    );
    expect(dim.opacity, gate.ignoring ? 0.45 : 1);
    return gate.ignoring;
  }

  /// The pit's two recipe cards, in either form.
  final recipeCards = find.byWidgetPredicate(
    (w) => w is RecipeCard || w is RecipePickerCard,
  );

  bool isMarked(Widget w) =>
      w is RecipeCard ? w.selected : (w as RecipePickerCard).selected;

  /// Which card carries the mark, firemaking first.
  List<bool> marks(WidgetTester tester) =>
      tester.widgetList(recipeCards).map(isMarked).toList();

  bool buttonEnabled(WidgetTester tester) => tester
      .widget<MomentumPrimaryButton>(find.byType(MomentumPrimaryButton))
      .enabled;

  /// Opens the fire card's picker and takes row [row] (catalog order:
  /// 0 = cookfire, 1 = campfire).
  Future<void> pickFire(WidgetTester tester, int row) async {
    await tester.tap(recipeCards.first);
    await settle(tester);
    await tester.tap(
      find
          .descendant(
            of: find.byType(RecipePickerSheet),
            matching: find.byType(RecipePickerCard),
          )
          .at(row),
    );
    // the picker dismisses on a transition, so give it longer than the
    // shared two-pump settle to leave the tree
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Taps the cooking card — the highlight moves to it and its picker
  /// opens — and closes the picker again.
  Future<void> chooseCooking(WidgetTester tester) async {
    await tester.tap(cookingCard);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.close).hitTestable());
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a cold firepit shows cooking locked under the fire', (
    tester,
  ) async {
    final session = await pumpFirepit(tester);

    expect(find.text('Firepit'), findsOneWidget);
    // both recipes are always on screen, each named
    expect(recipeCards, findsNWidgets(2));
    expect(find.text('FIREMAKING'), findsOneWidget);
    expect(find.text('COOKING'), findsOneWidget);
    expect(
      tester.getTopLeft(cookingCard).dy,
      greaterThan(tester.getTopLeft(recipeCards.first).dy),
    );

    // no cookfire picked, so cooking is locked and says what opens it
    expect(cookingLocked(tester), isTrue);
    expect(find.text('Pick a cookfire to cook'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);

    // the fire is what the button runs
    expect(marks(tester), [true, false]);
    expect(find.text('Light Fire'), findsOneWidget);

    // nothing is burning, so there is no timer and nothing to put out
    expect(find.byType(CountdownTimer), findsNothing);
    expect(find.byIcon(Icons.water_drop_outlined), findsNothing);

    // a locked card takes no taps: no picker, and the mark stays put
    await tester.tap(cookingCard, warnIfMissed: false);
    await settle(tester);
    expect(find.byType(RecipePickerSheet), findsNothing);
    expect(marks(tester), [true, false]);

    session.dispose();
  });

  testWidgets(
    'a picker row\'s icon opens the item details without picking it',
    (tester) async {
      final session = await pumpFirepit(tester);

      await tester.tap(recipeCards.first);
      await settle(tester);
      final sheet = find.byType(RecipePickerSheet);
      expect(sheet, findsOneWidget);

      await tester.tap(
        find
            .descendant(
              of: find.descendant(
                of: sheet,
                matching: find.byType(RecipePickerCard),
              ),
              matching: find.byWidgetPredicate((w) => w is IconRenderer),
            )
            .first,
      );
      await settle(tester);

      // the details are up over the picker, which is still open: the row was
      // read, not chosen
      expect(find.byType(Dialog), findsOneWidget);
      expect(sheet, findsOneWidget);

      session.dispose();
    },
  );

  testWidgets('picking a cookfire unlocks cooking; the button still builds '
      'the fire', (tester) async {
    final session = await pumpFirepit(tester);

    await pickFire(tester, 0);

    // cooking opens, with what the cook would burn to light the pit
    expect(cookingLocked(tester), isFalse);
    expect(find.text('Burns 2 × Logs per fire'), findsOneWidget);
    expect(find.text('Pick a cookfire to cook'), findsNothing);

    // but the fire card is still the one picked, so the button lights it
    expect(marks(tester), [true, false]);
    expect(find.text('Light Fire'), findsOneWidget);
    expect(find.text('Cook'), findsNothing);
    expect(buttonEnabled(tester), isTrue);

    session.dispose();
  });

  testWidgets('with the cookfire picked, firemaking keeps building '
      'cookfires', (tester) async {
    final session = await pumpFirepit(
      tester,
      selections: {SkillId.FIREMAKING: 'cookfire'},
    );
    expect(marks(tester), [true, false]);

    // the button's start path for the highlighted card, then two ticks
    expect(
      session.craftingController.startCraftingActionFor(
        'cookfire',
        EntityId.FIREPIT,
      ),
      isTrue,
    );
    session.craftingController.doCraftingAction(1);
    session.buffController.refresh();
    await settle(tester);

    // the first tick lights a cookfire
    expect(
      find.text('Cookfire'),
      findsNWidgets(2),
    ); // the hero label and the card
    final fire = session.craftingController.activeFire()!;
    final firstBurnsUntil = fire.expirationTime;

    // and the loop carries on building it, logs going into the same fire
    session.craftingController.doCraftingAction(1);
    session.buffController.refresh();
    await settle(tester);
    expect(session.actionTimingController.isRunning, isTrue);
    expect(
      session.craftingController.activeFire()!.expirationTime.isAfter(
        firstBurnsUntil,
      ),
      isTrue,
    );
    // the fire card still carries the mark, now feeding the burning fire
    expect(marks(tester), [true, false]);
    expect(find.text('Add Logs'), findsOneWidget);

    session.actionTimingController.stop();
    session.dispose();
  });

  testWidgets('tapping the cooking card makes the button cook', (tester) async {
    final session = await pumpFirepit(
      tester,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );
    expect(marks(tester), [true, false]);

    await chooseCooking(tester);

    // the highlight moves down, and the cook lights the pit itself
    expect(marks(tester), [false, true]);
    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Light Fire'), findsNothing);
    expect(buttonEnabled(tester), isTrue);
    expect(find.text('Burns 2 × Logs per fire'), findsOneWidget);

    session.dispose();
  });

  testWidgets('without logs neither card can run', (tester) async {
    final session = await pumpFirepit(
      tester,
      logs: 0,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );

    // the fire card: nothing to burn
    expect(marks(tester), [true, false]);
    expect(buttonEnabled(tester), isFalse);

    // the cook: nothing to light the pit with
    await chooseCooking(tester);
    expect(marks(tester), [false, true]);
    expect(find.text('Burns 2 × Logs per fire'), findsOneWidget);
    expect(buttonEnabled(tester), isFalse);

    session.dispose();
  });

  testWidgets('picking a fire that cannot cook hands the button back', (
    tester,
  ) async {
    final session = await pumpFirepit(
      tester,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );
    await chooseCooking(tester);
    expect(marks(tester), [false, true]);

    // a campfire: cooking locks again, and the fire takes the button back
    await pickFire(tester, 1);
    expect(cookingLocked(tester), isTrue);
    expect(marks(tester), [true, false]);
    expect(find.text('Light Fire'), findsOneWidget);

    session.dispose();
  });

  testWidgets('a lit cookfire with a campfire picked keeps cooking locked', (
    tester,
  ) async {
    final session = await pumpFirepit(
      tester,
      lightRecipeId: 'cookfire',
      selections: {
        SkillId.FIREMAKING: 'basic_campfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );

    // it is the pick that opens cooking, not what happens to be burning
    expect(find.text('Cookfire'), findsOneWidget);
    expect(cookingLocked(tester), isTrue);
    expect(find.text('Pick a cookfire to cook'), findsOneWidget);
    expect(marks(tester), [true, false]);
    expect(find.text('Light Fire'), findsOneWidget);

    session.dispose();
  });

  testWidgets('pressing Cook on a cold pit lights the fire and stays on '
      'cooking', (tester) async {
    final session = await pumpFirepit(
      tester,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );
    expect(find.text('Firepit'), findsOneWidget);

    // the button's start path, and its first tick
    expect(
      session.craftingController.startCraftingActionFor(
        'cook_minnow',
        EntityId.FIREPIT,
      ),
      isTrue,
    );
    session.craftingController.doCraftingAction(1);
    session.buffController.refresh();
    await settle(tester);

    // the pit is lit, and the running cook keeps the highlight
    expect(
      find.text('Cookfire'),
      findsNWidgets(2),
    ); // the hero label and the card
    expect(find.byType(CountdownTimer), findsWidgets);
    expect(tester.widgetList(recipeCards).map(isMarked), [false, true]);
    expect(find.text('Cook'), findsOneWidget);

    session.actionTimingController.stop();
    session.dispose();
  });

  testWidgets('a campfire burns with cooking locked', (tester) async {
    final session = await pumpFirepit(
      tester,
      lightRecipeId: 'basic_campfire',
      selections: {SkillId.FIREMAKING: 'basic_campfire'},
    );

    expect(
      find.text('Campfire'),
      findsNWidgets(2),
    ); // the hero label and the card
    expect(recipeCards, findsNWidgets(2));
    expect(cookingLocked(tester), isTrue);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

    session.dispose();
  });

  testWidgets('putting the fire out leaves cooking open on a picked '
      'cookfire', (tester) async {
    final session = await pumpFirepit(
      tester,
      lightRecipeId: 'cookfire',
      selections: {SkillId.FIREMAKING: 'cookfire'},
    );
    expect(cookingLocked(tester), isFalse);

    await tester.tap(find.byIcon(Icons.water_drop_outlined));
    await settle(tester);
    // confirm in the dialog
    await tester.tap(find.text('Put out'));
    await settle(tester);

    expect(find.text('Firepit'), findsOneWidget);
    expect(find.byType(CountdownTimer), findsNothing);
    // the cookfire is still the pick, so the cook could light it again
    expect(recipeCards, findsNWidgets(2));
    expect(cookingLocked(tester), isFalse);

    session.dispose();
  });

  testWidgets('lighting a fire does not re-centre the skill rings', (
    tester,
  ) async {
    // the ring row used to re-centre as it grew from one ring to two. the
    // recipe cards now sit above the rings, so the cooking card appearing
    // pushes them down — but they must not slide sideways or change size
    final session = await pumpFirepit(tester);

    Offset ringsAt() => tester.getTopLeft(find.byType(SkillRingRow));
    Size ringsSize() => tester.getSize(find.byType(SkillRingRow));

    final coldRings = ringsAt();
    final coldRingsSize = ringsSize();

    // light a cookfire underneath the running screen
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = EntityId.FIREPIT;
    save.craftingState.activeRecipeId = 'cookfire';
    session.craftingSystem.craftActiveRecipe(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
    );
    session.buffController.refresh();
    await settle(tester);

    expect(recipeCards, findsNWidgets(2));
    expect(ringsAt().dx, coldRings.dx);
    expect(ringsSize(), coldRingsSize);

    session.dispose();
  });

  testWidgets('the button reads Add Logs only for the burning fire', (
    tester,
  ) async {
    final session = await pumpFirepit(tester, lightRecipeId: 'basic_campfire');

    // nothing picked yet, so the fire card runs and the button lights
    expect(find.text('Light Fire'), findsOneWidget);

    // picks the nth firemaking recipe out of the fire card's picker.
    // recipe cards carry no name, so they are addressed by catalog order:
    // 0 = cookfire, 1 = campfire.
    Future<void> pickFire(int index) async {
      await tester.tap(recipeCards.first);
      await settle(tester);
      final inPicker = find.descendant(
        of: find.byType(RecipePickerSheet),
        matching: find.byType(RecipePickerCard),
      );
      await tester.tap(inPicker.at(index));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
    }

    // choosing the fire that is already burning tops it up
    await pickFire(1);
    expect(find.text('Add Logs'), findsOneWidget);
    expect(find.text('Replaces the current fire'), findsNothing);

    // a cookfire would take the firepit over, and the card says so. the
    // fire card is still the one picked, so the button lights it by hand
    await pickFire(0);
    expect(find.text('Replaces the current fire'), findsOneWidget);
    expect(find.text('Light Fire'), findsOneWidget);
    expect(find.text('Cook'), findsNothing);

    session.dispose();
  });

  Finder buttonIcon(IconData icon) => find.descendant(
    of: find.byType(MomentumPrimaryButton),
    matching: find.byIcon(icon),
  );

  testWidgets('picking another fire mid-burn puts the button back at rest', (
    tester,
  ) async {
    final session = await pumpFirepit(
      tester,
      selections: {SkillId.FIREMAKING: 'basic_campfire'},
    );

    // building campfires: the button reads as running
    expect(
      session.craftingController.startCraftingActionFor(
        'basic_campfire',
        EntityId.FIREPIT,
      ),
      isTrue,
    );
    session.craftingController.doCraftingAction(1);
    session.buffController.refresh();
    await settle(tester);
    expect(buttonIcon(Icons.fast_forward), findsOneWidget);

    // pick the cookfire: it is not what is burning, so the button offers
    // to start it rather than claiming it is already running
    await pickFire(tester, 0);
    expect(find.text('Light Fire'), findsOneWidget);
    expect(buttonIcon(Icons.play_arrow), findsOneWidget);
    expect(buttonIcon(Icons.fast_forward), findsNothing);

    // and pressing it builds the pick
    await tester.tap(find.byType(MomentumPrimaryButton));
    await settle(tester);
    expect(session.craftingController.activeRecipeId, 'cookfire');
    expect(buttonIcon(Icons.fast_forward), findsOneWidget);

    session.actionTimingController.stop();
    session.dispose();
  });

  testWidgets('picking a fire mid-cook hands the button to the fire', (
    tester,
  ) async {
    final session = await pumpFirepit(
      tester,
      selections: {
        SkillId.FIREMAKING: 'cookfire',
        SkillId.COOKING: 'cook_minnow',
      },
    );
    await chooseCooking(tester);
    expect(
      session.craftingController.startCraftingActionFor(
        'cook_minnow',
        EntityId.FIREPIT,
      ),
      isTrue,
    );
    session.craftingController.doCraftingAction(1);
    session.buffController.refresh();
    await settle(tester);
    expect(marks(tester), [false, true]);
    expect(find.text('Cook'), findsOneWidget);

    // the fire card is picked: the button is the fire's now, at rest
    await pickFire(tester, 0);
    expect(marks(tester), [true, false]);
    expect(find.text('Cook'), findsNothing);
    expect(buttonIcon(Icons.play_arrow), findsOneWidget);

    session.actionTimingController.stop();
    session.dispose();
  });

  testWidgets('a lit fire wears what it gives, and the picker lists it', (
    tester,
  ) async {
    final session = await pumpFirepit(
      tester,
      lightRecipeId: 'cookfire',
      selections: {SkillId.FIREMAKING: 'cookfire'},
    );

    // the burning cookfire on the stage: a chip for cooking and hitpoints
    final hero = find.byKey(const ValueKey('fire-hero-stats'));
    expect(hero, findsOneWidget);
    Finder chipIn(Finder scope, SkillId skill) => find.descendant(
      of: scope,
      matching: find.byWidgetPredicate(
        (w) => w is BuffBadge && w.skill == skill,
      ),
    );
    expect(chipIn(hero, SkillId.COOKING), findsOneWidget);
    expect(chipIn(hero, SkillId.HITPOINTS), findsOneWidget);

    // every fire in the picker says what it burns for
    await tester.tap(recipeCards.first);
    await settle(tester);
    final rows = find.descendant(
      of: find.byType(RecipePickerSheet),
      matching: find.byType(RecipePickerCard),
    );
    expect(rows, findsWidgets);
    for (var i = 0; i < rows.evaluate().length; i++) {
      expect(
        find.descendant(of: rows.at(i), matching: find.byType(BuffBadge)),
        findsWidgets,
        reason: 'picker row $i',
      );
    }

    session.dispose();
  });

  testWidgets('a cold pit has nothing to wear', (tester) async {
    final session = await pumpFirepit(tester);
    expect(find.byKey(const ValueKey('fire-hero-stats')), findsNothing);
    session.dispose();
  });
}
