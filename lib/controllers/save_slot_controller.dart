import 'package:flutter/foundation.dart';

import '../data/save_slot_index.dart';
import '../data/skill_data.dart';
import '../game_session.dart';
import '../services/file_manager_service.dart';
import '../services/skill_service.dart';

/// Boots a session from [rawSave], replacing whatever session is running.
typedef SaveBoot = void Function(Map<String, dynamic> rawSave);

/// The session the slot controller is currently writing for, as registered
/// by the app bootstrap.
class BoundSaveSession {
  /// The live save to write.
  final SaveGameData Function() save;

  /// Called once the session is about to be replaced: from then on it must
  /// not write its save, or it would land on top of whatever replaces it.
  final VoidCallback discard;

  const BoundSaveSession({required this.save, required this.discard});
}

/// Save slots: lists them, writes the running session into its slot, and
/// swaps the running session for another slot's.
///
/// Outlives every [GameSession]: it sits above the bootstrap, which binds
/// each session it builds. Swapping is a close-and-reopen - the outgoing
/// save is written with its action still running, and the incoming one
/// boots the same way a relaunch does, so any time it spent away is
/// settled as offline progress.
class SaveSlotController extends ChangeNotifier {
  final FileManagerService _files;
  final SaveSlotIndex _index;
  final SaveBoot _boot;
  final SkillService _skillService = SkillService();

  BoundSaveSession? _session;
  bool _busy = false;

  // the last session's closing write lands after the app has been torn
  // down; it still reaches disk, but there is nobody left to tell
  bool _disposed = false;

  SaveSlotController({
    required FileManagerService fileManagerService,
    required SaveSlotIndex index,
    required SaveBoot boot,
  }) : _files = fileManagerService,
       _index = index,
       _boot = boot;

  List<SaveSlotInfo> get slots => List.unmodifiable(_index.slots);
  String get activeSlotId => _index.activeSlotId;

  /// True while a swap, new save or reset is under way.
  bool get busy => _busy;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void bindSession(BoundSaveSession session) => _session = session;

  void unbindSession(BoundSaveSession session) {
    if (identical(_session, session)) _session = null;
  }

  /// Writes [save] into its slot and refreshes the slot's summary.
  Future<void> writeSave(SaveGameData save) async {
    final info = _index.slot(save.slotId);
    if (info != null) {
      info.lastPlayed = DateTime.now();
      info.totalLevel = _totalLevel(save);
    }
    await _files.saveSlot(save.slotId, save.toJson());
    await _files.saveIndex(_index);
    notifyListeners();
  }

  /// Sets [slotId]'s tag; blank clears it. Only the index changes, so it is
  /// safe on any slot, running or not.
  Future<void> setTag(String slotId, String tag) async {
    final info = _index.slot(slotId);
    if (info == null) return;
    final cleaned = tag.trim();
    info.tag = cleaned.length > SaveSlotInfo.maxTagLength
        ? cleaned.substring(0, SaveSlotInfo.maxTagLength)
        : cleaned;
    notifyListeners();
    await _files.saveIndex(_index);
  }

  /// Leaves the running save and boots [slotId]'s.
  Future<void> switchTo(String slotId) async {
    if (_busy || slotId == _index.activeSlotId) return;
    if (_index.slot(slotId) == null) return;
    await _run(() async {
      await _leaveActive();
      _index.activeSlotId = slotId;
      await _files.saveIndex(_index);
      _boot(await _files.loadSlot(slotId));
    });
  }

  /// Makes a new slot holding a fresh game and switches to it.
  Future<void> createSlot() async {
    if (_busy) return;
    await _run(() async {
      final id = _index.nextSlotId();
      final fresh = _freshSave(id);
      _index.slots.add(
        SaveSlotInfo(
          id: id,
          name: 'Save ${_index.slots.length + 1}',
          totalLevel: _totalLevel(fresh),
        ),
      );
      await _files.saveSlot(id, fresh.toJson());

      await _leaveActive();
      _index.activeSlotId = id;
      await _files.saveIndex(_index);
      _boot(fresh.toJson());
    });
  }

  /// Throws the active slot's save away and boots a fresh game in it.
  Future<void> resetActive() async {
    if (_busy) return;
    await _run(() async {
      final id = _index.activeSlotId;
      final fresh = _freshSave(id);
      // the old session is discarded, not written: its save is what is
      // being thrown away
      _session?.discard();
      _session = null;
      _index.slot(id)
        ?..createdAt = DateTime.now()
        ..lastPlayed = DateTime.now()
        ..totalLevel = _totalLevel(fresh);
      await _files.saveSlot(id, fresh.toJson());
      await _files.saveIndex(_index);
      _boot(fresh.toJson());
    });
  }

  Future<void> _run(Future<void> Function() body) async {
    _busy = true;
    notifyListeners();
    try {
      await body();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // stops the running session writing and writes it one last time, with
  // its action still marked running so coming back pays out the gap
  Future<void> _leaveActive() async {
    final session = _session;
    if (session == null) return;
    session.discard();
    _session = null;
    await writeSave(session.save());
  }

  // a fresh game for [slotId]. debug settings follow the player from save
  // to save, so a cap set up for testing still applies
  SaveGameData _freshSave(String slotId) {
    final factory = GameSessionFactory();
    final fresh = factory.newGame(factory.catalog1(), slotId: slotId);
    final current = _session?.save().debugSettings;
    if (current != null) {
      fresh.debugSettings.maxSkillLevel = current.maxSkillLevel;
    }
    return fresh;
  }

  int _totalLevel(SaveGameData save) {
    var total = 0;
    for (final entry in save.playerData.skillData.entries) {
      if (entry.key == SkillId.NULL) continue;
      total += _skillService.getLevel(entry.value);
    }
    return total;
  }
}
