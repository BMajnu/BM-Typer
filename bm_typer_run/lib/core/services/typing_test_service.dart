import 'dart:async';
import 'package:bm_typer/core/models/typing_test_result.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class TypingTestService {
  static const String _boxName = 'typing_test_results';

  // Save a new typing test result
  Future<void> saveTestResult(TypingTestResult result, UserModel user) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final id = const Uuid().v4();

      // Store the result with the user ID
      await box.put(id, {
        ...result.toJson(),
        'userId': user.id,
      });

      // Update user stats if this is a personal best
      await _updateUserStats(result, user);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving typing test result: $e');
      }
      rethrow;
    }
  }

  // Get all test results for a user
  Future<List<TypingTestResult>> getUserResults(String userId) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);

      // Filter results by user ID
      final results = box.values
          .where((result) => result['userId'] == userId)
          .map((json) =>
              TypingTestResult.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Sort by timestamp (newest first)
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving typing test results: $e');
      }
      return [];
    }
  }

  // Get the user's best result (highest WPM with at least 90% accuracy)
  Future<TypingTestResult?> getUserBestResult(String userId) async {
    try {
      final results = await getUserResults(userId);

      // Filter for results with good accuracy
      final qualifyingResults =
          results.where((r) => r.accuracy >= 0.9).toList();

      if (qualifyingResults.isEmpty) {
        return null;
      }

      // Sort by WPM (highest first)
      qualifyingResults.sort((a, b) => b.wpm.compareTo(a.wpm));

      return qualifyingResults.first;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving best typing test result: $e');
      }
      return null;
    }
  }

  // Get the user's recent progress (last 10 tests)
  Future<List<TypingTestResult>> getUserRecentProgress(String userId,
      {int limit = 10}) async {
    try {
      final results = await getUserResults(userId);

      // Return the most recent results up to the limit
      return results.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving recent typing test progress: $e');
      }
      return [];
    }
  }

  // Get average stats for a user
  Future<Map<String, double>> getUserAverageStats(String userId) async {
    try {
      final results = await getUserResults(userId);

      if (results.isEmpty) {
        return {
          'averageWpm': 0.0,
          'averageAccuracy': 0.0,
        };
      }

      // Calculate averages
      final totalWpm =
          results.fold<double>(0, (sum, result) => sum + result.wpm);
      final totalAccuracy =
          results.fold<double>(0, (sum, result) => sum + result.accuracy);

      return {
        'averageWpm': totalWpm / results.length,
        'averageAccuracy': totalAccuracy / results.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating average typing test stats: $e');
      }
      return {
        'averageWpm': 0.0,
        'averageAccuracy': 0.0,
      };
    }
  }

  // Update user statistics based on test results
  Future<void> _updateUserStats(TypingTestResult result, UserModel user) async {
    try {
      // Get the user's current best result
      final currentBest = await getUserBestResult(user.id);

      // Check if this is a new personal best (with good accuracy)
      if (result.accuracy >= 0.9 &&
          (currentBest == null || result.wpm > currentBest.wpm)) {
        // Update the user's best WPM
        final updatedUser = user.copyWith(
          highestWpm:
              result.wpm > user.highestWpm ? result.wpm : user.highestWpm,
        );

        // Save the updated user
        await DatabaseService.saveUser(updatedUser);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user stats: $e');
      }
    }
  }

  // Delete a test result
  Future<void> deleteTestResult(String resultId) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.delete(resultId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting typing test result: $e');
      }
      rethrow;
    }
  }

  // Clear all test results for a user
  Future<void> clearUserResults(String userId) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);

      // Get all keys for the user's results
      final keysToDelete = box.keys.where((key) {
        final result = box.get(key);
        return result != null && result['userId'] == userId;
      }).toList();

      // Delete all matching results
      for (final key in keysToDelete) {
        await box.delete(key);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing typing test results: $e');
      }
      rethrow;
    }
  }
}
