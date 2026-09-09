import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// An equipment drop is paid into the encounter's own tally as an instance,
/// not as a count in the item map - that is what keeps its quality. The
/// session drop list read only the item map, so a charm off Big Red landed
/// in the bag and the panel underneath the fight reported nothing.
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

  int countOf(List<ObjectStack> stacks, ItemId id) => stacks
      .where((s) => s.id == id)
      .fold<int>(0, (sum, s) => sum + s.count);

  test('a charm off Big Red lands in the session drops, not just the bag', () {
    final session = buildSession();
    final save = session.saveGameData;

    // strong enough to fell it in a swing or two, so the run is short
    setLevel(session, SkillId.ATTACK, 60);
    setLevel(session, SkillId.STRENGTH, 60);
    setLevel(session, SkillId.DEFENCE, 60);
    setLevel(session, SkillId.HITPOINTS, 60);

    final bigRed = EntityId.BIG_RED.build() as EncounterEntity;
    bigRed.count = 60;
    save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities.add(
      bigRed,
    );
    // the panel only reports the session it is looking at, so the view has
    // to be on Big Red the way it is when the player is fighting it
    save.playerData.currentEntityViewId = EntityId.BIG_RED;
    expect(session.encounterController.startEncounterActionFor(bigRed), isTrue);
    expect(session.encounterController.isViewingActiveEncounter(), isTrue);

    // three of Big Red's five drop lines are the charm, so a few dozen
    // kills makes one a certainty rather than a coin flip
    final rng = Random(20260909);
    for (var i = 0; i < 400; i++) {
      session.encounterSystem.executePlayerAction(
        playerState: save.playerData,
        encounter: save.encounterData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
        instantRespawn: true,
        rng: rng,
      );
    }

    // it reached the bag as an instance, with its quality intact
    final inBag = save.inventoryData.equipment
        .where((e) => e.id == ItemId.CHICKEN_CHARM)
        .fold<int>(0, (sum, e) => sum + e.count);
    expect(inBag, greaterThan(0), reason: 'no charm dropped in this run');

    // and the panel under the fight reports the same number
    final drops = session.encounterController.itemDrops();
    expect(countOf(drops, ItemId.CHICKEN_CHARM), inBag);

    // the stackable drops still come through untouched
    expect(countOf(drops, ItemId.CHICKEN_MEAT), greaterThan(0));

    session.actionTimingController.stop();
    session.dispose();
  });

  test('the tally folds every quality of a piece onto one line', () {
    final session = buildSession();
    final drops = session.saveGameData.encounterData.itemDrops;

    for (final rarity in [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE]) {
      final piece = ItemId.CHICKEN_CHARM.build() as EquipmentItem;
      piece.quality = rarity;
      session.inventoryService.addEquipment(drops, piece);
    }
    // stacked per quality, so the inventory holds three separate instances
    expect(drops.equipment, hasLength(3));

    // but the session tally is a count of what fell, and the grid draws one
    // tile per id - so they are one line of three
    final tally = session.inventoryService.getStackListWithEquipment(drops);
    expect(tally.where((s) => s.id == ItemId.CHICKEN_CHARM), hasLength(1));
    expect(countOf(tally, ItemId.CHICKEN_CHARM), 3);

    // and the stackable-only list is left as it was, since moving one
    // inventory into another still has to leave equipment alone
    expect(
      session.inventoryService.getObjectStackList(drops),
      isEmpty,
    );

    session.dispose();
  });
}
