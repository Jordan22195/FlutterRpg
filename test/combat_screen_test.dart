import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/encounter_screen.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/zone_palette.dart';
import 'package:rpg/widgets/action_dock.dart';
import 'package:rpg/widgets/art_header.dart';
import 'package:rpg/widgets/eat_food_button.dart';
import 'package:rpg/widgets/empty_state.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';
import 'package:rpg/widgets/encounter_info_panel.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/stage_panel.dart';
import 'package:rpg/widgets/stance_button.dart';
import 'package:rpg/widgets/status_row.dart';

// The combat screen sits under its zone's art strip — always collapsed —
// with the creature on a stage, the two fighters' rows, the tabs, and the
// style switch riding in the dock with Stop, Start and Eat.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

/// The border the stage panel draws around the creature.
BorderSide stageBorder(WidgetTester tester) {
  final box = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(StagePanel),
          matching: find.byType(Container),
        )
        .first,
  );
  return ((box.decoration! as BoxDecoration).border! as Border).top;
}

/// Boots the app and walks into a fight with a chicken in the starting
/// zone, the way a player would.
Future<({GameSession session, EncounterEntity chicken})> openChickenFight(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
  );
  await settle(tester);

  // a chicken turned up in the starting zone
  const zoneId = ZoneId.TUTORIAL_FARM;
  final session = Provider.of<GameSession>(
    tester.element(find.byType(MapScreen)),
    listen: false,
  );
  final chicken = EntityId.CHICKEN.build() as EncounterEntity;
  session.saveGameData.worldData.zones[zoneId]!.discoveredEntities.add(chicken);

  await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
  await settle(tester);
  await tester.tap(find.text('Enter'));
  await settle(tester);
  await tester.scrollUntilVisible(
    find.text(chicken.name),
    100,
    // the page's own scroll, not the horizontal chip row inside it
    scrollable: find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  // built isn't on screen: bring the row fully into the viewport
  await tester.ensureVisible(find.text(chicken.name));
  await settle(tester);
  await tester.tap(find.text(chicken.name));
  await settle(tester);
  return (session: session, chicken: chicken);
}

void main() {
  testWidgets('a boosted stat is tinted part way up and held full', (
    tester,
  ) async {
    final (:session, chicken: _) = await openChickenFight(tester);
    expect(find.byType(EncounterScreen), findsOneWidget);

    Text chipText(SkillId skill) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('playerStat-${skill.name}')),
        matching: find.byType(Text),
      ),
    );

    final player = session.saveGameData.playerData;
    session.playerDataController.debugSetSkillLevel(SkillId.STRENGTH, 40);
    session.playerDataController.setStance(Stance.offensive);
    await settle(tester);

    final palette = ZonePalette.meadow;
    final colors = GameColors.standard;

    // standing still with the bar empty: plain, like defence beside it
    expect(chipText(SkillId.ATTACK).style!.color, palette.text);
    expect(chipText(SkillId.DEFENCE).style!.color, palette.text);
    final resting = int.parse(chipText(SkillId.ATTACK).data!);

    // part way up the bar
    player.boostFill = 0.5;
    session.actionTimingController.notifyListeners();
    await tester.pump();
    expect(chipText(SkillId.ATTACK).style!.color, colors.boostPartial);
    expect(int.parse(chipText(SkillId.ATTACK).data!), greaterThan(resting));
    // defence is not what the offensive stance lends to
    expect(chipText(SkillId.DEFENCE).style!.color, palette.text);

    // held full
    player.boostFill = 1.0;
    session.actionTimingController.notifyListeners();
    await tester.pump();
    expect(chipText(SkillId.ATTACK).style!.color, colors.boostFull);

    // and plain again once the bar drains
    player.boostFill = 0.0;
    session.actionTimingController.notifyListeners();
    await tester.pump();
    expect(chipText(SkillId.ATTACK).style!.color, palette.text);
    expect(int.parse(chipText(SkillId.ATTACK).data!), resting);
  });

  testWidgets('a fight in the meadow wears the Hearth layout', (tester) async {
    const zoneId = ZoneId.TUTORIAL_FARM;
    final (:session, :chicken) = await openChickenFight(tester);

    expect(find.byType(EncounterScreen), findsOneWidget);

    // the shell's app bar steps aside for the collapsed art strip, which
    // carries the status row, the creature's name, its zone and its level
    expect(find.byType(AppBar), findsNothing);
    final header = tester.widget<ArtHeader>(find.byType(ArtHeader));
    expect(header.collapse, 1);
    expect(header.title, chicken.name);
    expect(header.subtitle, zoneId.definition.name);
    expect(header.backLabel, 'Back to ${zoneId.definition.name}');
    expect(
      find.descendant(
        of: find.byType(ArtHeader),
        matching: find.byType(StatusRow),
      ),
      findsOneWidget,
    );
    final level = (chicken as CombatEntity).level;
    expect(find.text('Lv $level'), findsOneWidget);

    // the creature stands on a combat-tinted stage, with how many are left
    // as a bare number in the corner
    final stage = tester.widget<StagePanel>(find.byType(StagePanel));
    expect(stage.tint, GameColors.standard.combatTint);
    expect(find.byType(StageCountPill), findsOneWidget);
    // a common creature keeps the tint's own 1px border
    expect(stage.outline, isNull);
    expect(stageBorder(tester).width, 1);
    // and nothing under its feet: no shadow disc drawn on the stage
    expect(
      find.descendant(
        of: find.byType(StagePanel),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).borderRadius ==
                  const BorderRadius.all(Radius.elliptical(75, 11)),
        ),
      ),
      findsNothing,
    );

    // both hp bars are the hp colour, on the track
    final hpBars = tester
        .widgetList<FillBar>(find.byType(FillBar))
        .where((bar) => bar.height == 22)
        .toList();
    expect(hpBars, hasLength(2));
    for (final bar in hpBars) {
      expect(bar.foregroundColor, GameColors.standard.hp);
      expect(bar.backgroundColor, ZonePalette.meadow.track);
    }
    expect(find.text('Enemy'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);

    // the tabs, opening on an empty loot list. there is no buffs tab
    expect(find.text('Loot · 0'), findsOneWidget);
    expect(find.text('Skills'), findsWidgets);
    expect(find.textContaining('Buffs'), findsNothing);
    expect(find.text('Info'), findsOneWidget);
    expect(
      find.widgetWithText(EmptyState, 'No loot this session'),
      findsOneWidget,
    );

    // the style switch rides in the dock, above Stop, Start and Eat
    final dock = find.byType(ActionDock);
    expect(
      find.descendant(of: dock, matching: find.byType(StanceButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dock, matching: find.byType(EatFoodButton)),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(EatFoodButton)).width,
      greaterThanOrEqualTo(92),
    );

    // an empty loot tab fits the screen with nothing under it, so a drag
    // springs back to rest rather than leaving the page scrolled. at this
    // height the page only just fits: padding left under the tabs would tip
    // it into scrolling
    tester.view.physicalSize = const Size(390, 780);
    await settle(tester);
    final page = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(EncounterScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    expect(page.maxScrollExtent, 0);
    tester.view.physicalSize = const Size(390, 844);
    await settle(tester);

    // the entity's info page runs past the screen, so it keeps room under it for the
    // dock's fade to fall on
    final infoTab = find.descendant(
      of: find.byType(EncounterInfoPanel),
      matching: find.text('Info'),
    );
    await tester.ensureVisible(infoTab);
    await settle(tester);
    await tester.tap(infoTab);
    await settle(tester);
    expect(
      tester.getBottomLeft(find.byType(EncounterInfoPanel)).dy -
          tester.getBottomLeft(find.byType(EntityInfoBody)).dy,
      32,
    );

    // and back goes back to the zone, under its open art again
    await tester.tap(find.byTooltip('Back to ${zoneId.definition.name}'));
    await settle(tester);
    expect(find.byType(EncounterScreen), findsNothing);
    expect(find.byType(ArtHeader), findsOneWidget);
  });

  testWidgets('a rare creature stands on a stage outlined in its rarity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    const zoneId = ZoneId.TUTORIAL_FARM;
    final session = Provider.of<GameSession>(
      tester.element(find.byType(MapScreen)),
      listen: false,
    );
    final rare = EntityId.CHICKEN_RARE.build() as EncounterEntity;
    session.saveGameData.worldData.zones[zoneId]!.discoveredEntities.add(rare);

    await tester.tap(find.byKey(ValueKey('map-node-${zoneId.name}')));
    await settle(tester);
    await tester.tap(find.text('Enter'));
    await settle(tester);
    final tile = find.byKey(const ValueKey(EntityId.CHICKEN_RARE));
    await tester.scrollUntilVisible(
      tile,
      100,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(tile);
    await settle(tester);
    await tester.tap(tile);
    await settle(tester);
    expect(find.byType(EncounterScreen), findsOneWidget);

    final rarity = rarityBorderColor(EntityId.CHICKEN_RARE.definition.rarity);
    expect(rarity, isNotNull);
    expect(tester.widget<StagePanel>(find.byType(StagePanel)).outline, rarity);
    final side = stageBorder(tester);
    expect(side.color, rarity);
    expect(side.width, 2);
  });
}
