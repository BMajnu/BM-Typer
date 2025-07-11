import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/services/database_service.dart';

/// Service for importing user data from external sources (legacy files, backups)
class DataImportService {
  /// Import user data from a legacy JSON file
  static Future<UserModel?> importFromJson() async {
    try {
      if (kIsWeb) {
        // Web platform implementation would require a different approach
        // For now, we'll return a placeholder message
        debugPrint('Web import not implemented in this version');
        return null;
      } else {
        return _importFromJsonMobile();
      }
    } catch (e) {
      debugPrint('Error importing data: $e');
      return null;
    }
  }

  /// Import user data on mobile platforms
  static Future<UserModel?> _importFromJsonMobile() async {
    try {
      // In a real implementation, we would use a file picker
      // For now, we'll look for a predefined file in the app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/bm_typer_import.json';

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Import file not found at: $filePath');
        return null;
      }

      final jsonString = await file.readAsString();
      return _processJsonData(jsonString);
    } catch (e) {
      debugPrint('Error importing data from mobile: $e');
      return null;
    }
  }

  /// Process JSON data into UserModel
  static Future<UserModel?> _processJsonData(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check if it's a valid user data format
      if (!_isValidUserDataFormat(jsonData)) {
        debugPrint('Invalid user data format');
        return null;
      }

      // Extract user data
      final name = jsonData['name'] as String? ?? 'User';
      final email = jsonData['email'] as String? ?? 'user@example.com';

      // Extract typing statistics
      List<double> wpmHistory = [];
      if (jsonData.containsKey('wpm_history')) {
        wpmHistory = (jsonData['wpm_history'] as List)
            .map((e) => (e is num) ? e.toDouble() : 0.0)
            .toList();
      }

      List<double> accuracyHistory = [];
      if (jsonData.containsKey('accuracy_history')) {
        accuracyHistory = (jsonData['accuracy_history'] as List)
            .map((e) => (e is num) ? e.toDouble() : 0.0)
            .toList();
      }

      // Extract lesson progress
      List<String> completedLessons = [];
      if (jsonData.containsKey('completed_lessons')) {
        completedLessons = (jsonData['completed_lessons'] as List)
            .map((e) => e.toString())
            .toList();
      }

      // Create new user model
      final user = UserModel(
        name: name,
        email: email,
        wpmHistory: wpmHistory,
        accuracyHistory: accuracyHistory,
        highestWpm:
            wpmHistory.isEmpty ? 0 : wpmHistory.reduce((a, b) => a > b ? a : b),
        completedLessons: completedLessons,
      );

      // Save imported user
      await DatabaseService.saveUser(user);

      return user;
    } catch (e) {
      debugPrint('Error processing JSON data: $e');
      return null;
    }
  }

  /// Check if the JSON data has a valid user data format
  static bool _isValidUserDataFormat(Map<String, dynamic> jsonData) {
    // Basic validation - at least name or email should be present
    return jsonData.containsKey('name') || jsonData.containsKey('email');
  }

  /// Export current user data to a JSON file
  static Future<String?> exportUserData(UserModel user) async {
    try {
      // Convert user to JSON
      final userData = {
        'name': user.name,
        'email': user.email,
        'wpm_history': user.wpmHistory,
        'accuracy_history': user.accuracyHistory,
        'highest_wpm': user.highestWpm,
        'completed_lessons': user.completedLessons,
        'unlocked_achievements': user.unlockedAchievements,
        'export_date': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(userData);

      if (kIsWeb) {
        // Web platform doesn't support file system directly
        // Would require a download mechanism
        return jsonString;
      } else {
        // Mobile/desktop platforms - save to file
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'bm_typer_data_${DateTime.now().millisecondsSinceEpoch}.json';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsString(jsonString);

        return filePath;
      }
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      return null;
    }
  }
}
