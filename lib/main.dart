import 'package:rpg/catalogs/catalog_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/file_manager_service.dart';
import 'game_session.dart';

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
import 'controllers/save_slot_controller.dart';
import 'controllers/settings_controller.dart';
import 'data/save_slot_index.dart';
import 'controllers/shop_controller.dart';
import 'data/skill_data.dart';
import 'utilities/image_resolver.dart';
import 'screens/main_shell.dart';
import 'theme/hearth_theme.dart';
import 'catalogs/zones/zone_id.dart';
import 'controllers/potion_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fileManagerService = FileManagerService();
  final saveSlots = await fileManagerService.loadIndex();
  final gameDataRaw = await fileManagerService.loadSlot(saveSlots.activeSlotId);

  runApp(
    MyApp(
      rawSave: gameDataRaw,
      fileManagerService: fileManagerService,
      saveSlots: saveSlots,
    ),
  );
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic> rawSave;
  final FileManagerService fileManagerService;

  /// The device's save slots. Defaults to a single slot holding [rawSave].
  final SaveSlotIndex? saveSlots;

  const MyApp({
    super.key,
    required this.rawSave,
    required this.fileManagerService,
    this.saveSlots,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Map<String, dynamic> _rawSave = widget.rawSave;

  // bumped whenever a save is booted in place of the running one, so the
  // whole session is torn down and rebuilt
  int _generation = 0;

  late final SaveSlotController _saveSlots = SaveSlotController(
    fileManagerService: widget.fileManagerService,
    index: widget.saveSlots ?? SaveSlotIndex.single(_slotIdOf(widget.rawSave)),
    boot: _boot,
  );

  static String _slotIdOf(Map<String, dynamic> rawSave) {
    final id = rawSave['slotId'];
    return id is String && id.isNotEmpty ? id : 'slot_1';
  }

  void _boot(Map<String, dynamic> rawSave) {
    if (!mounted) return;
    setState(() {
      _rawSave = rawSave;
      _generation++;
    });
  }

  @override
  void dispose() {
    _saveSlots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // the slot controller outlives every session, so it sits above the
    // bootstrap rather than among the session's providers
    return ChangeNotifierProvider<SaveSlotController>.value(
      value: _saveSlots,
      // GameBootstrap owns the providers and wraps MaterialApp so that
      // dialogs (pushed on the root navigator) can also see them.
      child: GameBootstrap(
        key: ValueKey(_generation),
        rawSave: _rawSave,
        saveSlots: _saveSlots,
      ),
    );
  }
}

class GameBootstrap extends StatefulWidget {
  final Map<String, dynamic> rawSave;
  final SaveSlotController saveSlots;

  const GameBootstrap({
    super.key,
    required this.rawSave,
    required this.saveSlots,
  });

  @override
  State<GameBootstrap> createState() => _GameBootstrapState();
}

class _GameBootstrapState extends State<GameBootstrap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final GameSession session;
  late final BoundSaveSession _binding;
  Timer? _autosaveTimer;
  Timer? _navSaveDebounce;

  // set once another save has replaced this session: its save must not be
  // written on the way out
  bool _discarded = false;

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
      // first run, empty slot or unreadable save: start a new game
      saveData = factory.newGame(
        catalogs,
        slotId: widget.saveSlots.activeSlotId,
      );
    }

    session = factory.create(save: saveData, catalogs: catalogs, vsync: this);

    _binding = BoundSaveSession(
      save: () => session.saveGameData,
      discard: _discard,
    );
    widget.saveSlots.bindSession(_binding);

    // register icon resolvers for data-driven widgets
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    // autosave safety net for platforms where lifecycle events are
    // unreliable (e.g. closing a desktop window)
    _autosaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveGame(),
    );
  }

  void _discard() {
    _discarded = true;
    _autosaveTimer?.cancel();
    _navSaveDebounce?.cancel();
  }

  void _saveGame() {
    if (_discarded) return;
    widget.saveSlots.writeSave(session.saveGameData);
  }

  // navigation fires this on every tab/route change; debounced so a
  // quick flurry of taps writes the save once
  void _onUiStateChanged() {
    _navSaveDebounce?.cancel();
    _navSaveDebounce = Timer(const Duration(seconds: 1), _saveGame);
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
    _navSaveDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _saveGame();
    widget.saveSlots.unbindSession(_binding);
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
        ChangeNotifierProvider<PotionController>.value(
          value: session.potionController,
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
        ChangeNotifierProvider<SettingsController>.value(
          value: session.settingsController,
        ),
      ],
      // the whole app wears the palette of the zone being shown, so the
      // shell and every screen inside a zone (combat, crafting) share it.
      // selecting just the zone id keeps world ticks from rebuilding the app
      child: Selector<WorldController, ZoneId>(
        selector: (_, world) => world.viewedZoneId,
        builder: (_, zoneId, home) => MaterialApp(
          title: 'RPG',
          theme: hearthTheme(zoneId.definition.palette),
          home: home,
        ),
        child: MainShell(onUiStateChanged: _onUiStateChanged),
      ),
    );
  }
}
