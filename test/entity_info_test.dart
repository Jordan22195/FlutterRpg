import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/data/entity_details.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';

/// What the encounter screen's info tab reports about the player's own side
/// of the fight — in particular the damage rate, which is the number the
/// incoming section's rate is read against.
void main() {
  late GameSession session;
  late SaveGameData save;

  setUp(() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    save = factory.newGame(catalogs);
    session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
  });

  tearDown(() => session.dispose());

  void setLevel(SkillId skill, int level) {
    final data = save.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  EntityDetails detailsFor(EntityId id) => session.worldController.entityDetails(
    id.build() as EncounterEntity,
  );

  group('the player damage rate', () {
    test('is the average damage over one action interval', () {
      final details = detailsFor(EntityId.GOBLIN);

      expect(details.playerActionInterval, greaterThan(0));
      expect(
        details.playerDamagePerSecond,
        closeTo(
          details.playerAverageDamage / details.playerActionInterval,
          1e-9,
        ),
      );
    });

    test('reads against the interval the idle timer would show', () {
      final goblin = EntityId.GOBLIN.build() as EncounterEntity;
      final expected =
          session.actionTimingController
              .idleActionDurationFor(goblin.entityType)
              .inMicroseconds /
          1e6;

      expect(detailsFor(EntityId.GOBLIN).playerActionInterval, expected);
    });

    test('rises with the level that drives the damage roll', () {
      setLevel(SkillId.ATTACK, 1);
      final low = detailsFor(EntityId.GOBLIN).playerDamagePerSecond;
      setLevel(SkillId.ATTACK, 60);
      final high = detailsFor(EntityId.GOBLIN).playerDamagePerSecond;

      expect(low, greaterThan(0));
      expect(high, greaterThan(low));
    });

    test('is zero where actions do not roll damage', () {
      // a fishing spot never depletes and a herb is picked in one action,
      // so neither has a damage rate to report
      expect(detailsFor(EntityId.TRANQUIL_POND).playerDamagePerSecond, 0);
    });
  });

  group('the info tab', () {
    Future<void> pumpInfo(WidgetTester tester, EntityId id) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GameSession>.value(value: session),
            ChangeNotifierProvider<WorldController>.value(
              value: session.worldController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EntityInfoBody(entity: id.build() as EncounterEntity),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the damage rate under the player attack rolls', (
      tester,
    ) async {
      setLevel(SkillId.ATTACK, 40);
      await pumpInfo(tester, EntityId.GOBLIN);

      // section headings render upper case
      expect(find.text('YOUR ATTACKS'), findsOneWidget);
      // one row in the player's section, one in the entity's
      expect(find.text('Damage per second'), findsNWidgets(2));

      final details = detailsFor(EntityId.GOBLIN);
      expect(
        find.text(details.playerDamagePerSecond.toStringAsFixed(1)),
        findsWidgets,
      );
    });

    testWidgets('a gathering node reports one, a fishing spot none', (
      tester,
    ) async {
      await pumpInfo(tester, EntityId.TREE);
      // no incoming section on a tree, so the only rate is the player's
      expect(find.text('Damage per second'), findsOneWidget);

      await pumpInfo(tester, EntityId.TRANQUIL_POND);
      expect(find.text('Damage per second'), findsNothing);
    });
  });
}
