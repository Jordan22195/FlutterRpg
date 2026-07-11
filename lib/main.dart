import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/file_manager_service.dart';
import 'game_session.dart';

import 'catalogs/item_catalog.dart';
import 'catalogs/entity_catalog.dart';
import 'catalogs/dungeon_catalog.dart';
import 'controllers/action_queue_controller.dart';
import 'controllers/dungeon_controller.dart';
import 'controllers/action_timing_controller.dart';
import 'controllers/buff_controller.dart';
import 'controllers/crafting_controller.dart';
import 'controllers/enchanting_controller.dart';
import 'controllers/encounter_controller.dart';
import 'controllers/equipment_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/world_controller.dart';
import 'controllers/player_data_controller.dart';
import 'controllers/shop_controller.dart';
import 'data/skill_data.dart';
import 'utilities/image_resolver.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fileManagerService = FileManagerService();
  final gameDataRaw = await fileManagerService.loadAppData();

  runApp(MyApp(rawSave: gameDataRaw, fileManagerService: fileManagerService));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> rawSave;
  final FileManagerService fileManagerService;

  const MyApp({
    super.key,
    required this.rawSave,
    required this.fileManagerService,
  });

  @override
  Widget build(BuildContext context) {
    // GameBootstrap owns the providers and wraps MaterialApp so that
    // dialogs (pushed on the root navigator) can also see them.
    return GameBootstrap(
      rawSave: rawSave,
      fileManagerService: fileManagerService,
    );
  }
}

class GameBootstrap extends StatefulWidget {
  final Map<String, dynamic> rawSave;
  final FileManagerService fileManagerService;

  const GameBootstrap({
    super.key,
    required this.rawSave,
    required this.fileManagerService,
  });

  @override
  State<GameBootstrap> createState() => _GameBootstrapState();
}

class _GameBootstrapState extends State<GameBootstrap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final GameSession session;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    EnumImageProviderLookup.register<DungeonId>(
      session.catalogBundle.dungeonCatalog.imageProviderFor,
    );

    // autosave safety net for platforms where lifecycle events are
    // unreliable (e.g. closing a desktop window)
    _autosaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveGame(),
    );
  }

  void _saveGame() {
    widget.fileManagerService.saveAppData(session.saveGameData.toJson());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveGame();
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _saveGame();
    session.dispose();
    super.dispose();
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
        ChangeNotifierProvider<EnchantingController>.value(
          value: session.enchantingController,
        ),
        ChangeNotifierProvider<ActionQueueController>.value(
          value: session.actionQueueController,
        ),
        ChangeNotifierProvider<ShopController>.value(
          value: session.shopController,
        ),
        ChangeNotifierProvider<DungeonController>.value(
          value: session.dungeonController,
        ),
      ],
      child: MaterialApp(
        title: 'RPG',
        theme: ThemeData.dark(),
        home: const MainShell(),
      ),
    );
  }
}
