import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

 

class JsonStorage {
  Future<File> _getFile() async {
    final directory = await getApplicationSupportDirectory();

    return File('${directory.path}/dataSayltApp.json');
  }


  Future<void> save(Map<String, dynamic> data) async {
    final file = await _getFile();

    await file.writeAsString(
      jsonEncode(data),
      flush: true,
    );
  }



  Future<Map<String, dynamic>> load() async {
    final file = await _getFile();

    if (!await file.exists()) {
      return {};
    }

    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(content);

    return Map<String, dynamic>.from(decoded as Map);
  }
}