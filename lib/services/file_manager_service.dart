import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '../data/save_slot_index.dart';

/// Where named json documents are kept. The app writes them to disk; tests
/// swap in an in-memory one.
abstract class SaveStore {
  /// The document called [name], or null if there is none or it can't be
  /// read.
  Future<Map<String, dynamic>?> read(String name);

  /// Writes [json] as the document called [name]. Never throws: a failed
  /// save must not crash the game loop.
  Future<void> write(String name, Map<String, dynamic> json);
}

/// [SaveStore] backed by `<name>.json` files in the app documents folder.
class DiskSaveStore implements SaveStore {
  // writes to one file run one after another, so a slow earlier write can't
  // land on top of a later one
  final Map<String, Future<void>> _pendingWrites = {};

  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name.json');
  }

  @override
  Future<Map<String, dynamic>?> read(String name) async {
    try {
      await _pendingWrites[name];
      final file = await _file(name);
      if (!file.existsSync()) return null;
      final json = jsonDecode(await file.readAsString());
      return json is Map<String, dynamic> ? json : null;
    } catch (e) {
      debugPrint('Failed to load $name: $e');
      return null;
    }
  }

  @override
  Future<void> write(String name, Map<String, dynamic> json) {
    final jsonString = jsonEncode(json);
    final previous = _pendingWrites[name] ?? Future<void>.value();
    final next = previous.then((_) async {
      try {
        final file = await _file(name);
        await file.writeAsString(jsonString);
      } catch (e) {
        debugPrint('Failed to save $name: $e');
      }
    });
    _pendingWrites[name] = next;
    return next;
  }
}

/// Reads and writes save slots: one document per slot's save, plus an
/// index of the slots and which one is active.
class FileManagerService {
  final SaveStore _store;

  FileManagerService({SaveStore? store}) : _store = store ?? DiskSaveStore();

  static const indexName = 'save_slots';

  /// The single save written before save slots existed.
  static const legacyName = 'appdata';

  static String slotName(String slotId) => 'save_$slotId';

  /// The slot index. On the first launch with save slots, the single
  /// pre-slot save becomes the first slot; the old file is left in place.
  Future<SaveSlotIndex> loadIndex() async {
    final raw = await _store.read(indexName);
    if (raw != null) {
      try {
        return SaveSlotIndex.fromJson(raw);
      } on FormatException catch (e) {
        debugPrint('Unreadable save slot index, rebuilding: $e');
      }
    }

    final legacy = await _store.read(legacyName);
    final legacyId = legacy?['slotId'];
    final slotId = legacyId is String && legacyId.isNotEmpty
        ? legacyId
        : 'slot_1';
    if (legacy != null) await _store.write(slotName(slotId), legacy);

    final index = SaveSlotIndex.single(slotId);
    await saveIndex(index);
    return index;
  }

  Future<void> saveIndex(SaveSlotIndex index) =>
      _store.write(indexName, index.toJson());

  /// The save in [slotId], or {} when the slot has none yet - which the
  /// bootstrap reads as a new game.
  Future<Map<String, dynamic>> loadSlot(String slotId) async =>
      await _store.read(slotName(slotId)) ?? {};

  Future<void> saveSlot(String slotId, Map<String, dynamic> json) =>
      _store.write(slotName(slotId), json);
}
