import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/enchantments/enchantments.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/enchanting_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// The bench's controller: what it offers to work on, what it will let you
/// start, and what the running action does to the stack under it.
///
/// [EnchantingSystem] is covered by enchanting_test — the rules of what an
/// enchant costs and yields are its. These are the controller's own: the
/// selection, the action loop it binds, and the session results the screen
/// reads back. That loop is the part with something to go wrong in it,
/// because enchanting hands the selected instanceId to a *different* stack
/// each time it fires.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  /// The cheapest recipe, and enough material to run it [times] over.
  EnchantRecipe stockFor(GameSession session, {int times = 1}) {
    final recipe = EnchantmentCatalog().recipes.first;
    final inventory = session.saveGameData.inventoryData;
    for (final input in recipe.inputs.entries) {
      inventory.itemMap[input.key] =
          (inventory.itemMap[input.key] ?? 0) + input.value * times;
    }
    setLevel(session, SkillId.ENCHANTING, recipe.levelRequirement);
    return recipe;
  }

  EquipmentItem addHelmet(GameSession session, {int count = 1}) {
    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    helmet.count = count;
    session.saveGameData.inventoryData.equipment.add(helmet);
    return helmet;
  }

  group('what the bench offers', () {
    test('worn gear leads the target list, and says it is worn', () {
      final session = buildSession();
      final controller = session.enchantingController;

      final worn = addHelmet(session);
      expect(
        session.equipmentController.equipItem(worn),
        isTrue,
        reason: 'the helmet should be wearable at level 1',
      );
      final loose = addHelmet(session);
      session.inventoryController.refresh();

      final targets = controller.equipmentList();
      expect(targets.map((t) => t.instanceId), contains(worn.instanceId));
      expect(targets.map((t) => t.instanceId), contains(loose.instanceId));
      expect(
        targets.first.instanceId,
        worn.instanceId,
        reason: 'worn gear should not have to be taken off to be enchanted',
      );

      expect(controller.isEquipped(worn), isTrue);
      expect(controller.isEquipped(loose), isFalse);

      // and the list is a copy: the screen must not be able to edit the bag
      expect(() => targets.add(loose), throwsUnsupportedError);

      session.dispose();
    });

    test('the material header counts what is actually in the bag', () {
      final session = buildSession();
      final controller = session.enchantingController;

      for (final id in EnchantingController.materials) {
        expect(controller.materialCount(id), 0);
      }
      session.saveGameData.inventoryData.itemMap[ItemId.ENCHANTING_DUST] = 7;
      expect(controller.materialCount(ItemId.ENCHANTING_DUST), 7);

      session.dispose();
    });

    test('a recipe is available only once its level and materials are in', () {
      final session = buildSession();
      final controller = session.enchantingController;
      // the first recipe opens at level 1, which a new player already has,
      // so the gate is only observable on one that asks for more
      final recipe = EnchantmentCatalog().recipes.firstWhere(
        (r) => r.levelRequirement > 1,
      );

      expect(controller.recipeAvailable(recipe), isFalse);

      // materials, but still under the level
      final inventory = session.saveGameData.inventoryData;
      for (final input in recipe.inputs.entries) {
        inventory.itemMap[input.key] = input.value;
      }
      setLevel(session, SkillId.ENCHANTING, recipe.levelRequirement - 1);
      expect(
        controller.recipeAvailable(recipe),
        isFalse,
        reason: 'the level gate did not hold',
      );

      setLevel(session, SkillId.ENCHANTING, recipe.levelRequirement);
      expect(controller.recipeAvailable(recipe), isTrue);

      session.dispose();
    });
  });

  group('selection', () {
    test('selecting only selects: nothing starts until Action', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session);
      final helmet = addHelmet(session);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);

      expect(notifications, 2);
      expect(controller.selectedRecipeId, recipe.id);
      expect(controller.selectedRecipe?.id, recipe.id);
      expect(controller.selectedTarget?.instanceId, helmet.instanceId);
      expect(controller.disenchantSelected, isFalse);
      expect(
        session.actionTimingController.isRunning,
        isFalse,
        reason: 'picking a recipe started the bench on its own',
      );

      session.dispose();
    });

    test('the bench is not ready without both halves of the selection', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session);
      final helmet = addHelmet(session);

      expect(controller.selectionReady(), isFalse);

      controller.selectRecipe(recipe.id);
      expect(
        controller.selectionReady(),
        isFalse,
        reason: 'a recipe with nothing to apply it to is not ready',
      );

      controller.selectTarget(helmet);
      expect(controller.selectionReady(), isTrue);

      session.dispose();
    });

    test('an unaffordable enchant is not ready, but disenchant always is', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = EnchantmentCatalog().recipes.first;
      final helmet = addHelmet(session);

      // the level, but none of the materials
      setLevel(session, SkillId.ENCHANTING, recipe.levelRequirement);
      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);
      expect(controller.selectionReady(), isFalse);

      // disenchanting costs nothing but the item, so it is always available
      controller.selectRecipe(EnchantingController.disenchantRecipeId);
      expect(controller.disenchantSelected, isTrue);
      expect(controller.selectedRecipe, isNull);
      expect(controller.selectionReady(), isTrue);
      expect(controller.previewDisenchant(helmet), isNotNull);

      session.dispose();
    });

    test('starting with a selection the bench cannot fill does nothing', () {
      final session = buildSession();
      final controller = session.enchantingController;

      expect(controller.startEnchantingActionFor('minor_enchant', 'nope'),
          isFalse);
      expect(session.actionTimingController.isRunning, isFalse);

      session.dispose();
    });
  });

  group('the action loop', () {
    test('Action binds the bench loop and reports its progress', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session);
      final helmet = addHelmet(session);

      // idle: no progress, but the bench can still say what a fire costs
      expect(controller.enchantProgress(), 0.0);
      expect(controller.enchantInterval(), greaterThan(Duration.zero));

      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);
      controller.startEnchantingAction();

      expect(session.actionTimingController.isRunning, isTrue);
      expect(
        session.actionTimingController.isRunningAction(
          controller.doEnchantingAction,
        ),
        isTrue,
      );
      expect(controller.enchantInterval(), greaterThan(Duration.zero));

      session.actionTimingController.stop();
      session.dispose();
    });

    test('one fire enchants one item and files it in the session grid', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session);
      final helmet = addHelmet(session);
      final material = recipe.inputs.keys.first;
      final before = controller.materialCount(material);

      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);
      controller.startEnchantingAction();
      controller.doEnchantingAction(1);

      // the materials were spent. a stack spent to nothing leaves the item
      // map rather than sitting there as a zero, so count it the way the
      // bench header does
      expect(
        controller.materialCount(material),
        before - recipe.inputs[material]!,
      );

      // and the enchanted piece is in the session grid, carrying its enchant
      final made = controller.sessionEquipment();
      expect(made, hasLength(1));
      expect(made.single.id, ItemId.COPPER_HELMET);
      expect(
        made.single.effectiveSkillBonus.values.fold<int>(0, (a, b) => a + b),
        greaterThan(0),
      );
      // enchanting yields equipment, not stackable materials
      expect(controller.sessionResults(), isEmpty);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('a disenchant fire files materials instead', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final helmet = addHelmet(session);

      controller.selectRecipe(EnchantingController.disenchantRecipeId);
      controller.selectTarget(helmet);
      controller.startEnchantingAction();
      controller.doEnchantingAction(1);

      expect(controller.sessionEquipment(), isEmpty);
      final gained = controller.sessionResults();
      expect(gained, isNotEmpty);
      expect(
        session.saveGameData.playerData.skillData[SkillId.ENCHANTING]!.xp,
        greaterThan(0),
      );

      session.actionTimingController.stop();
      session.dispose();
    });

    test('the loop stops rather than enchanting what it just enchanted', () {
      // the regression the stack-key guard exists for. Enchanting the last
      // piece of a stack hands the *enchanted* item the same instanceId, so
      // the selection still resolves after the fire — to a different stack.
      // Following the instanceId alone, the next fire would enchant the
      // piece it just finished, compounding it for the price of one.
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session, times: 4); // material for four runs
      final helmet = addHelmet(session); // but only one thing to work on

      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);
      // the bench works the instance in place, so the key it started on has
      // to be read before the fire rather than off the item afterwards
      final startKey = helmet.stackKey;
      controller.startEnchantingAction();
      controller.doEnchantingAction(1);

      final made = controller.sessionEquipment().single;
      final bonus = made.effectiveSkillBonus.values.fold<int>(
        0,
        (a, b) => a + b,
      );

      // the selection still resolves — to the enchanted piece, which carries
      // the instanceId the bench started on but a different stack key
      final target = controller.selectedTarget;
      expect(target, isNotNull);
      expect(target!.instanceId, helmet.instanceId);
      expect(
        target.stackKey,
        isNot(startKey),
        reason: 'the enchant did not move the piece onto a new stack, so '
            'there is nothing here for the guard to catch',
      );
      // material is left, so nothing else would have stopped the bench
      expect(controller.selectionReady(), isTrue);

      // the next fire is the one that sees it, and it stops instead of
      // enchanting the piece it just finished
      controller.doEnchantingAction(1);
      expect(
        session.actionTimingController.isRunning,
        isFalse,
        reason: 'the bench walked onto the stack it had just created',
      );
      expect(controller.sessionEquipment(), hasLength(1));
      expect(
        controller.sessionEquipment().single.effectiveSkillBonus.values
            .fold<int>(0, (a, b) => a + b),
        bonus,
        reason: 'an enchant was applied on top of an enchant',
      );
      // and it did not pay for the run it did not make: one run's worth of
      // material is gone out of the four that were stocked
      expect(
        controller.materialCount(recipe.inputs.keys.first),
        recipe.inputs.values.first * 3,
      );

      session.actionTimingController.stop();
      session.dispose();
    });

    test('the loop stops when its target is gone', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session);
      final helmet = addHelmet(session);

      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);
      controller.startEnchantingAction();
      expect(session.actionTimingController.isRunning, isTrue);

      // the target leaves the bag under the running action
      session.saveGameData.inventoryData.equipment.remove(helmet);
      controller.doEnchantingAction(1);

      expect(session.actionTimingController.isRunning, isFalse);
      expect(controller.sessionEquipment(), isEmpty);

      session.dispose();
    });

    test('the loop stops when the materials run out', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session); // exactly one run's worth
      final helmet = addHelmet(session, count: 5);

      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);
      controller.startEnchantingAction();
      controller.doEnchantingAction(1);

      expect(controller.selectionReady(), isFalse);
      expect(
        session.actionTimingController.isRunning,
        isFalse,
        reason: 'the bench kept running with nothing left to spend',
      );

      session.dispose();
    });
  });

  group('the session grid', () {
    test('navigating away from an idle bench clears its results', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final helmet = addHelmet(session);

      controller.selectRecipe(EnchantingController.disenchantRecipeId);
      controller.selectTarget(helmet);
      controller.startEnchantingAction();
      controller.doEnchantingAction(1);
      expect(controller.sessionResults(), isNotEmpty);

      // the action stopped itself when the stack emptied; leaving the bench
      // now ends the session
      expect(session.actionTimingController.isRunning, isFalse);
      controller.onEntityViewChanged();
      expect(controller.sessionResults(), isEmpty);

      session.dispose();
    });

    test('a running bench keeps its results when the view changes', () {
      final session = buildSession();
      final controller = session.enchantingController;
      final recipe = stockFor(session, times: 4);
      final helmet = addHelmet(session, count: 4);

      controller.selectRecipe(recipe.id);
      controller.selectTarget(helmet);
      controller.startEnchantingAction();
      controller.doEnchantingAction(1);

      expect(session.actionTimingController.isRunning, isTrue);
      expect(controller.sessionEquipment(), isNotEmpty);

      controller.onEntityViewChanged();
      expect(
        controller.sessionEquipment(),
        isNotEmpty,
        reason: 'a session still running is not over',
      );

      session.actionTimingController.stop();
      session.dispose();
    });
  });
}
