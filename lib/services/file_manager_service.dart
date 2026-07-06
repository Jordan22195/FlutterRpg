import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class FileManagerService {
  // save the current app data to the app folder.
  // a failed save must not crash the game loop
  Future<void> saveAppData(Map<String, dynamic> json) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/appdata.json');

      final jsonString = jsonEncode(json);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Failed to save app data: $e');
    }
  }

  // create new instance of app data from saved json
  // in app folder. an unreadable file falls back to {} (new game)
  Future<Map<String, dynamic>> loadAppData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/appdata.json');

      if (!file.existsSync()) {
        // Return an empty structure on first run
        return {};
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonString);

      return json;
    } catch (e) {
      debugPrint('Failed to load app data: $e');
      return {};
    }
  }
}
