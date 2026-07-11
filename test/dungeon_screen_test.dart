import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/main.dart';
import 'package:rpg/screens/map_screen.dart';
import 'package:rpg/services/file_manager_service.dart';
import 'package:rpg/widgets/buff_row.dart';
import 'package:rpg/widgets/skil_tile.dart';

// Fixed pumps (the app has periodic timers that never settle).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('landmark opens inspect, key gates entry, entering starts a run', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(rawSave: const {}, fileManagerService: FileManagerService()),
    );
    await settle(tester);

    final session = Provider.of<GameSession>(
      tester.element(find.byType(MapScreen)),
      listen: false,
    );

    // ---- landmark on the map opens the free inspect screen ----
    expect(find.text("Goblin Queen's Lair"), findsOneWidget);
    await tester.tap(find.text("Goblin Queen's Lair"));
    await settle(tester);

    // inspect view: floors listed, and a locked entry (no key yet). the
    // entry row is pinned at the bottom; the Enter button is disabled
    expect(find.text('Warren Entrance'), findsOneWidget);
    expect(find.text("Queen's Chamber"), findsOneWidget);
    expect(find.text('No key'), findsOneWidget);
    final enterButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enter (uses key)'),
    );
    expect(enterButton.onPressed, isNull); // disabled without a key

    // ---- grant a key + strong stats, reopen so canEnter re-evaluates ----
    session.inventoryService.setItemCount(
      session.saveGameData.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );
    for (final id in [SkillId.ATTACK, SkillId.DEFENCE, SkillId.HITPOINTS]) {
      final s = session.saveGameData.playerData.skillData[id]!;
      s.xp = s.xpTable[99];
    }
    session.saveGameData.playerData.hitpoints = session.playerDataService
        .getStatTotals(session.saveGameData.playerData)[SkillId.HITPOINTS]!;

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await settle(tester);
    await tester.tap(find.text("Goblin Queen's Lair"));
    await settle(tester);

    expect(find.text('Key ready'), findsOneWidget);

    // ---- enter: the run view takes over ----
    await tester.tap(find.text('Enter (uses key)'));
    await tester.pump(); // one frame: enter notifies, run view builds

    // run view shows the pinned Leave control; the inspect entry row is gone
    expect(find.text('Leave'), findsOneWidget);
    expect(find.text('Key ready'), findsNothing);

    // mirrors world combat minus manual controls: fights auto-advance, so
    // there is no action/stop/eat button
    expect(find.text('Action'), findsNothing);
    expect(find.text('Stop'), findsNothing);
    expect(find.text('Eat'), findsNothing);

    // floor progression is listed alongside the fight (the floor name also
    // appears as the current-floor label next to Leave)
    expect(find.text('Warren Entrance'), findsWidgets);

    // the shared combat elements (buffs, skill tile) sit below the fold of
    // the lazy list; scroll them into build range before asserting
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pump();
    expect(find.byType(SkillTile), findsOneWidget);
    expect(find.byType(BuffRow), findsOneWidget);

    // key was consumed
    expect(
      session.inventoryService.getItemCount(
        session.saveGameData.inventoryData,
        ItemId.GOBLIN_QUEEN_KEY,
      ),
      0,
    );

    // unmount so the session disposes its timer and ticker
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
