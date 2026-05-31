import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/typing_test_service.dart';
import 'package:bm_typer/core/models/typing_test_result.dart';
import 'package:bm_typer/core/providers/user_provider.dart';

// Provider for the typing test service
final typingTestServiceProvider = Provider<TypingTestService>((ref) {
  return TypingTestService();
});

// Provider for the current user's typing test results
final userTypingTestResultsProvider =
    FutureProvider<List<TypingTestResult>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final typingTestService = ref.watch(typingTestServiceProvider);

  if (user == null) {
    return [];
  }

  return typingTestService.getUserResults(user.id);
});

// Provider for the user's best typing test result
final userBestResultProvider = FutureProvider<TypingTestResult?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final typingTestService = ref.watch(typingTestServiceProvider);

  if (user == null) {
    return null;
  }

  return typingTestService.getUserBestResult(user.id);
});

// Provider for the user's recent progress
final userRecentProgressProvider =
    FutureProvider<List<TypingTestResult>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final typingTestService = ref.watch(typingTestServiceProvider);

  if (user == null) {
    return [];
  }

  return typingTestService.getUserRecentProgress(user.id);
});

// Provider for the user's average stats
final userAverageStatsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final typingTestService = ref.watch(typingTestServiceProvider);

  if (user == null) {
    return {
      'averageWpm': 0.0,
      'averageAccuracy': 0.0,
    };
  }

  return typingTestService.getUserAverageStats(user.id);
});
