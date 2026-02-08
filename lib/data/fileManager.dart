import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class FileManager {
  // save the current app data to the app folder
  Future<void> saveAppData(Map<String, dynamic> json) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/appdata.json');

    final jsonString = jsonEncode(json);
    await file.writeAsString(jsonString);
  }

  // create new instance of app data from saved json
  // in app folder
  Future<Map<String, dynamic>> loadAppData() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/appdata.json');

    if (!file.existsSync()) {
      // Return an empty structure on first run
      return {};
    }

    final jsonString = await file.readAsString();
    final Map<String, dynamic> json = jsonDecode(jsonString);

    return json;
  }
}
