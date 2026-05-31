import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bm_typer/core/models/leaderboard_entry_model.dart';
import 'package:bm_typer/core/models/user_model.dart';

/// Service for managing the leaderboard
class LeaderboardService {
  static const _boxName = 'leaderboard_entries';
  static const _maxEntriesPerUser = 5;
  static const _maxEntriesToDisplay = 50;

  /// Initialize the leaderboard service
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<LeaderboardEntry>(_boxName);
    }
  }

  /// Add a new entry to the leaderboard
  static Future<void> addEntry({
    required UserModel user,
    required double wpm,
    required double accuracy,
    String? lessonId,
  }) async {
    final box = await _getBox();

    // Create the new entry
    final entry = LeaderboardEntry(
      userId: user.id,
      userName: user.name,
      wpm: wpm,
      accuracy: accuracy,
      timestamp: DateTime.now(),
      lessonId: lessonId,
      level: user.level,
      avatarUrl: null, // Could be added later for user avatars
    );

    // Add the entry
    await box.add(entry);

    // Clean up old entries if needed
    await _cleanUpUserEntries(user.id);
  }

  /// Get the top entries for the leaderboard
  static Future<List<LeaderboardEntry>> getTopEntries({
    String? lessonId,
    int limit = _maxEntriesToDisplay,
  }) async {
    final box = await _getBox();
    final entries = box.values.toList();

    // Filter by lesson if specified
    final filteredEntries = lessonId != null
        ? entries.where((entry) => entry.lessonId == lessonId).toList()
        : entries;

    // Sort by WPM (descending) and accuracy (descending) as tiebreaker
    filteredEntries.sort((a, b) {
      final wpmDiff = b.wpm.compareTo(a.wpm);
      return wpmDiff != 0 ? wpmDiff : b.accuracy.compareTo(a.accuracy);
    });

    // Return the top entries
    return filteredEntries.take(limit).toList();
  }

  /// Get the user's best entries
  static Future<List<LeaderboardEntry>> getUserBestEntries({
    required String userId,
    int limit = _maxEntriesPerUser,
  }) async {
    final box = await _getBox();
    final userEntries = box.values
        .where((entry) => entry.userId == userId)
        .cast<LeaderboardEntry>()
        .toList();

    // Sort by WPM (descending)
    userEntries.sort((a, b) => b.wpm.compareTo(a.wpm));

    // Return the top entries
    return userEntries.take(limit).toList();
  }

  /// Get the user's rank in the leaderboard
  static Future<int> getUserRank(String userId) async {
    final allEntries = await getTopEntries();

    // Find the highest entry for the user
    final userBestEntryIndex = allEntries.indexWhere((e) => e.userId == userId);

    // Return the rank (1-based) or -1 if not found
    return userBestEntryIndex >= 0 ? userBestEntryIndex + 1 : -1;
  }

  /// Clean up old entries for a user to keep only their best performances
  static Future<void> _cleanUpUserEntries(String userId) async {
    final box = await _getBox();
    final userEntryKeys = box.keys.where((key) {
      final entry = box.get(key);
      return entry is LeaderboardEntry && entry.userId == userId;
    }).toList();

    if (userEntryKeys.length <= _maxEntriesPerUser) {
      return; // No need to clean up
    }

    // Get all entries for the user
    final userEntries =
        userEntryKeys.map((key) => box.get(key) as LeaderboardEntry).toList();

    // Sort by WPM (descending)
    userEntries.sort((a, b) => b.wpm.compareTo(a.wpm));

    // Remove the lowest performing entries
    final entriesToRemove = userEntries.sublist(_maxEntriesPerUser);

    // Find keys of entries to remove
    final keysToRemove = userEntryKeys.where((key) {
      final entry = box.get(key) as LeaderboardEntry;
      return entriesToRemove.contains(entry);
    }).toList();

    // Delete entries
    await box.deleteAll(keysToRemove);
  }

  /// Clear all leaderboard entries (for testing)
  static Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }

  /// Get the Hive box
  static Future<Box<LeaderboardEntry>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<LeaderboardEntry>(_boxName);
    }
    return Hive.box<LeaderboardEntry>(_boxName);
  }

  /// Generate mock leaderboard data for testing
  static Future<void> generateMockData(int count) async {
    final box = await _getBox();
    final random = Random();

    final names = [
      'Alice',
      'Bob',
      'Charlie',
      'David',
      'Eva',
      'Frank',
      'Grace',
      'Hank',
      'Iris',
      'Jack',
      'Kelly',
      'Leo',
      'Mia',
      'Noah',
      'Olivia',
      'Pat',
      'Quinn',
      'Ray',
      'Sara',
      'Tom'
    ];

    for (var i = 0; i < count; i++) {
      final name = names[random.nextInt(names.length)];
      final userId = 'mock-${name.toLowerCase()}-${random.nextInt(1000)}';
      final wpm = 20.0 + random.nextDouble() * 80.0; // 20-100 WPM
      final accuracy = 70.0 + random.nextDouble() * 30.0; // 70-100% accuracy

      final entry = LeaderboardEntry(
        userId: userId,
        userName: name,
        wpm: wpm,
        accuracy: accuracy,
        timestamp: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        level: 1 + random.nextInt(10),
        lessonId: 'lesson-${1 + random.nextInt(10)}',
      );

      await box.add(entry);
    }
  }
}
