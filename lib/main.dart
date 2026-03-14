import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/file_manager_service.dart';
import 'game_session.dart';

import 'controllers/buff_controller.dart';
import 'controllers/crafting_controller.dart';
import 'controllers/encounter_controller.dart';
import 'controllers/world_controller.dart';
import 'controllers/action_timing_controller.dart';
import 'controllers/player_data_controller.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fileManagerService = FileManagerService();
  final gameDataRaw = await fileManagerService.loadAppData();
  final gameData = SaveGameData.fromJson(gameDataRaw);

  runApp(MyApp(saveData: gameData));
}

class MyApp extends StatelessWidget {
  final SaveGameData saveData;

  const MyApp({super.key, required this.saveData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG',
      theme: ThemeData.dark(),
      home: GameBootstrap(saveData: saveData),
    );
  }
}

class GameBootstrap extends StatefulWidget {
  final SaveGameData saveData;

  const GameBootstrap({super.key, required this.saveData});

  @override
  State<GameBootstrap> createState() => _GameBootstrapState();
}

class _GameBootstrapState extends State<GameBootstrap>
    with TickerProviderStateMixin {
  late final GameSession session;

  @override
  void initState() {
    super.initState();

    final factory = GameSessionFactory();

    session = factory.create(
      save: widget.saveData,
      catalogs: factory.catalog1(),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GameSession>.value(value: session),

        ChangeNotifierProvider<BuffController>.value(
          value: session.buffController,
        ),
        ChangeNotifierProvider<CraftingController>.value(
          value: session.craftingController,
        ),
        ChangeNotifierProvider<EncounterController>.value(
          value: session.encounterController,
        ),
        ChangeNotifierProvider<WorldController>.value(
          value: session.worldController,
        ),
        ChangeNotifierProvider<PlayerDataController>.value(
          value: session.playerDataController,
        ),

        //ChangeNotifierProvider<ActionTimingController>.value(
        //  value: session.encounterController.actionTimingController,
        //),
      ],
      child: const MainShell(),
    );
  }
}
