import 'dart:convert';

import 'package:rpg/services/file_manager_service.dart';

/// [SaveStore] held in memory, round-tripping each document through JSON
/// exactly like a write to disk.
class MemorySaveStore implements SaveStore {
  final Map<String, String> documents = {};

  Map<String, dynamic>? peek(String name) {
    final raw = documents[name];
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>?> read(String name) async => peek(name);

  @override
  Future<void> write(String name, Map<String, dynamic> json) async {
    documents[name] = jsonEncode(json);
  }
}
