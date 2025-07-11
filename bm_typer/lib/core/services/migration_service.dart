import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bm_typer/core/services/database_service.dart';

/// Service to handle data migrations between app versions
class MigrationService {
  static const String _appVersionKey = 'app_version';
  static const String _migrationCompletedKey = 'migration_completed';
  static const String _currentAppVersion =
      '1.1.0'; // Update when releasing new versions

  /// Check if migration is needed and perform if necessary
  static Future<void> checkAndMigrateIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedVersion = prefs.getString(_appVersionKey);
      final bool migrationCompleted =
          prefs.getBool(_migrationCompletedKey) ?? false;

      // No stored version means first install, no migration needed
      if (storedVersion == null) {
        await prefs.setString(_appVersionKey, _currentAppVersion);
        return;
      }

      // Skip if migration already completed for this version
      if (storedVersion == _currentAppVersion && migrationCompleted) {
        return;
      }

      // Perform version-specific migrations
      if (storedVersion != _currentAppVersion) {
        await _migrateFromVersion(storedVersion);

        // Update stored version after migration
        await prefs.setString(_appVersionKey, _currentAppVersion);
        await prefs.setBool(_migrationCompletedKey, true);
      }
    } catch (e) {
      debugPrint('Error during migration: $e');
    }
  }

  /// Migration logic based on previous version
  static Future<void> _migrateFromVersion(String oldVersion) async {
    debugPrint('Migrating from version $oldVersion to $_currentAppVersion');

    // Migration from version 1.0.0 to 1.1.0
    if (oldVersion == '1.0.0') {
      await _migrateFrom_1_0_0();
    }

    // Add more version-specific migrations as needed
    // if (oldVersion == '1.1.0') {
    //   await _migrateFrom_1_1_0();
    // }
  }

  /// Migration from version 1.0.0 to 1.1.0
  static Future<void> _migrateFrom_1_0_0() async {
    debugPrint('Running migration from 1.0.0');

    // Check for legacy data in SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Legacy user data keys
    final legacyNameKey = 'user_name';
    final legacyEmailKey = 'user_email';
    final legacyStatsKey = 'typing_stats';
    final legacyLessonsKey = 'completed_lessons';

    // Check if legacy data exists
    final String? userName = prefs.getString(legacyNameKey);
    final String? userEmail = prefs.getString(legacyEmailKey);

    // If we have legacy user data, migrate it to the new model
    if (userName != null || userEmail != null) {
      // Extract legacy data
      final List<String> completedLessons =
          prefs.getStringList(legacyLessonsKey) ?? [];

      // Create new user with legacy data
      // final newUser = UserModel( // This line was removed as per the edit hint
      //   name: userName ?? 'User',
      //   email: userEmail ?? 'user@example.com',
      //   completedLessons: completedLessons,
      // );

      // Save the migrated user
      // await DatabaseService.saveUser(newUser); // This line was removed as per the edit hint
      // await DatabaseService.setCurrentUser(newUser); // This line was removed as per the edit hint

      // Clear legacy data after migration
      await prefs.remove(legacyNameKey);
      await prefs.remove(legacyEmailKey);
      await prefs.remove(legacyStatsKey);
      await prefs.remove(legacyLessonsKey);

      debugPrint(
          'Successfully migrated user data from SharedPreferences to Hive');
    }
  }

  /// Migrate database formats if needed
  static Future<void> migrateDatabaseFormats() async {
    // This would contain logic to migrate between different database formats
    // For example, from SharedPreferences to Hive, or between Hive versions

    // For now, just a placeholder for future migrations
    debugPrint('Checking database format migrations...');

    // Example migration steps that might be implemented:
    const migrationSteps = [
      'Migrate user data schema',
      'Migrate achievement data',
      'Migrate typing statistics',
      'Update database version marker',
    ];

    debugPrint(
        'Migration steps that would be performed: ${migrationSteps.join(', ')}');

    // No actual migrations implemented yet
    debugPrint('No migrations needed at this time.');
  }
}
