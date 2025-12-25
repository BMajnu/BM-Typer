import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Saves a file based on the platform.
Future<String?> saveFileUniversal(Uint8List bytes, String fileName) async {
  try {
    // Get the app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    // Write the file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  } catch (e) {
    print('Error saving file: $e');
    return null;
  }
}

/// Saves a string content (like CSV/JSON) as a file.
Future<String?> saveStringFileUniversal(String content, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(content);

    return filePath;
  } catch (e) {
    print('Error saving string file: $e');
    return null;
  }
}

/// Imports user data from a local file.
Future<String?> importFileUniversal() async {
  try {
    // Basic implementation: look for specific file in documents dir
    // Real implementation would use file_picker but we are minimizing deps for now if possible
    // detailed logic from original data_import_service is reused here
     final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/bm_typer_import.json';

      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      return await file.readAsString();
  } catch (e) {
    print('Error importing file: $e');
    return null;
  }
}
