import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/file_manager_service.dart';
import 'game_session.dart';

import 'catalogs/item_catalog.dart';
import 'catalogs/entity_catalog.dart';
import 'controllers/action_timing_controller.dart';
import 'controllers/buff_controller.dart';
import 'controllers/crafting_controller.dart';
import 'controllers/encounter_controller.dart';
import 'controllers/equipment_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/world_controller.dart';
import 'controllers/player_data_controller.dart';
import 'data/skill_data.dart';
import 'utilities/image_resolver.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fileManagerService = FileManagerService();
  final gameDataRaw = await fileManagerService.loadAppData();

  runApp(MyApp(rawSave: gameDataRaw));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> rawSave;

  const MyApp({super.key, required this.rawSave});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG',
      theme: ThemeData.dark(),
      home: GameBootstrap(rawSave: rawSave),
    );
  }
}

class GameBootstrap extends StatefulWidget {
  final Map<String, dynamic> rawSave;

  const GameBootstrap({super.key, required this.rawSave});

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
    final catalogs = factory.catalog1();

    SaveGameData saveData;
    try {
      saveData = SaveGameData.fromJson(widget.rawSave);
    } on FormatException {
      // first run or unreadable save: start a new game
      saveData = factory.newGame(catalogs);
    }

    session = factory.create(save: saveData, catalogs: catalogs, vsync: this);

    // register icon resolvers for data-driven widgets
    ItemCatalog.init();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    EnumImageProviderLookup.register<EntityId>(
      session.catalogBundle.entityCatalog.imageProviderFor,
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
        ChangeNotifierProvider<ActionTimingController>.value(
          value: session.actionTimingController,
        ),
        ChangeNotifierProvider<InventoryController>.value(
          value: session.inventoryController,
        ),
        ChangeNotifierProvider<EquipmentController>.value(
          value: session.equipmentController,
        ),
      ],
      child: const MainShell(),
    );
  }
}
