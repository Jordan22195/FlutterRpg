import 'dart:io';

import 'package:rpg/controllers/interval_runner.dart';
import 'package:rpg/controllers/momentum_loop_controller.dart';
import 'package:rpg/controllers/zone_controller.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/armor_equipment.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/data/exploration_state.dart';
import 'package:rpg/data/inventory.dart';
import 'package:rpg/data/zone.dart';
import 'package:rpg/data/zone_location.dart';

import '../data/player_data.dart';
import '../data/fileManager.dart';
import '../data/entity.dart';
import '../data/skill.dart';
import '../data/item.dart';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';

class PlayerDataController extends ChangeNotifier {
  ZoneController _zoneController = ZoneController();

  late final FileManager _fileManager;
  bool _encounterActive = false;

  PlayerData? _data;
  bool _isLoading = true;
  String? _error;

  PlayerData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlayerData get _d {
    final d = _data;
    if (d == null) {
      throw StateError(
        'PlayerDataController: PlayerData is not loaded yet. '
        'Check isLoading/error or wait for ensureLoaded() before using.',
      );
    }
    return d;
  }

  Future<void>? _loadFuture;
  Future<void> ensureLoaded() => _loadFuture ?? Future.value();

  MomentumLoopController? _actionTimingController;

  bool get isActionTimingReady => _actionTimingController != null;

  MomentumLoopController get actionTimingController {
    final c = _actionTimingController;
    if (c == null) {
      throw StateError(
        'PlayerDataController: actionTimingController is not initialized yet. '
        'Call initActionTiming(vsync) (after ensureLoaded if needed) before using.',
      );
    }
    return c;
  }

  MomentumLoopController? get actionTimingControllerOrNull =>
      _actionTimingController;

  void initActionTiming(TickerProvider vsync) {
    // If it already exists, just rebind vsync (important when routes change)
    if (_actionTimingController == null) {
      print("building new MomentumLoopController for PlayerDataController");
      _actionTimingController = MomentumLoopController(
        vsync: vsync,
        onFire: () {},
      );
    } else {
      _actionTimingController!.rebindVsync(vsync);
    }
    _actionTimingController?.stopNowSilently();
  }

  @override
  void dispose() {
    _actionTimingController?.dispose();
    super.dispose();
  }

  PlayerDataController() {
    _loadFuture = _load();
    EncounterController.instance.playerDataController = this;
    ItemController.init();
    EntityController.init();
  }

  PlayerData _createNewPlayerData() {
    return PlayerData(
      currentZoneId: Zones.TUTORIAL_FARM,
      skills: {
        Skills.HITPOINTS: Skill(name: "Hitpoints", xp: 0),
        Skills.WOODCUTTING: Skill(name: "Woodcutting", xp: 0),
        Skills.MINING: Skill(name: "Mining", xp: 0),
        Skills.ATTACK: Skill(name: "Attack", xp: 0),
        Skills.DEFENCE: Skill(name: "Defence", xp: 0),
        Skills.FIREMAKING: Skill(name: "Firemaking", xp: 0),
      },
      inventory: Inventory(itemMap: {}),
      gear: ArmorEquipment(),
      zones: ZoneState(discoveredEntities: {}),
    );
  }

  Future<void> _load() async {
    _fileManager = FileManager();
    try {
      final json = await _fileManager.loadAppData();

      _data = PlayerData.fromJson(json);
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(stackTrace: st);

      // Fall back to a fresh save so the app can still run.
      _data = _createNewPlayerData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void saveAppData() {
    _fileManager.saveAppData(_d.toJson());
  }

  Zones getCurrentZone() {
    return _d.currentZoneId;
  }

  List<ObjectStack> getZoneEntities() {
    return _d.zones.getEntityList(getCurrentZone());
  }

  List<ZoneLocationType> getZoneLocations() {
    return ZoneController.getZoneLocations(getCurrentZone());
  }

  int getEntityCount(Zones zoneId, Entities entityId) {
    return _d.zones.getEntityCount(zoneId, entityId);
  }

  int getPlayerSkillStatTotal(Skills skill) {
    return _d.skills[skill]?.getLevel() ?? 1;
  }

  void explore() {
    print("explore called in PlayerDataController");
    final entity = _zoneController.discoverEntity(_d.currentZoneId);
    _d.zones.addEntities(getCurrentZone(), entity.id, entity.count);
    notifyListeners();
  }

  Skill getSkill(Skills id) {
    return data?.skills[id] ?? Skill(name: "Error", xp: 1);
  }

  void addXp(Skills skill, int xp) {
    _d.skills[skill]?.addXp(xp);
    notifyListeners();
  }

  void decrimentEntity(Zones zoneId, Entities entityId) {
    _d.zones.decrimentEntity(zoneId, entityId);
    notifyListeners();
  }

  IntervalRunner intervalRunner = IntervalRunner();

  void playerDeath() {
    _d.hitpoints = _d.skills[Skills.HITPOINTS]!.getLevel();

    _d.zones.clearEntities();
  }

  void takeEncounterItems() {
    _data?.inventory.addOtherInventory(
      EncounterController.instance.encounterItemDrops,
    );
    EncounterController.instance.encounterItemDrops.clear();
  }

  String getActionString() {
    switch (EncounterController.instance.getEncounterSkillType()) {
      case Skills.ATTACK:
        return "Attack";
      case Skills.FIREMAKING:
        return "Burn";
      case Skills.MINING:
        return "Mine";
      case Skills.WOODCUTTING:
        return "Chop";
      default:
        return "Action";
    }
  }
}
