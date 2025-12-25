import 'dart:typed_data';

/// Saves a file based on the platform.
Future<String?> saveFileUniversal(Uint8List bytes, String fileName) => throw UnsupportedError('Platform not supported');

/// Saves a string content (like CSV/JSON) as a file.
Future<String?> saveStringFileUniversal(String content, String fileName) => throw UnsupportedError('Platform not supported');

/// Imports user data from a local file.
Future<String?> importFileUniversal() => throw UnsupportedError('Platform not supported');
