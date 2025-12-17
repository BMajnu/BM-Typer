import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/subscription_model.dart';
import 'package:bm_typer/core/services/subscription_service.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State class for subscription with usage tracking
class SubscriptionState {
  final SubscriptionModel? subscription;
  final int usedMinutesToday;
  final DateTime lastResetDate;
  final bool isLoading;
  
  const SubscriptionState({
    this.subscription,
    this.usedMinutesToday = 0,
    required this.lastResetDate,
    this.isLoading = false,
  });
  
  SubscriptionState copyWith({
    SubscriptionModel? subscription,
    int? usedMinutesToday,
    DateTime? lastResetDate,
    bool? isLoading,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  /// Check if user is premium
  bool get isPremium => subscription != null && 
      subscription!.type != 'free' && 
      subscription!.isValid;
  
  /// Get remaining practice minutes
  int get remainingMinutes {
    if (isPremium) return -1; // Unlimited
    return (FreeFeatureLimits.dailyPracticeMinutes - usedMinutesToday).clamp(0, FreeFeatureLimits.dailyPracticeMinutes);
  }
  
  /// Check if daily limit is reached
  bool get isDailyLimitReached => !isPremium && remainingMinutes <= 0;
  
  /// Get accessible lesson count
  int get accessibleLessons => isPremium ? -1 : FreeFeatureLimits.maxLessons;
  
  /// Check if a lesson is accessible (0-indexed)
  bool isLessonAccessible(int lessonIndex) {
    if (isPremium) return true;
    return lessonIndex < FreeFeatureLimits.maxLessons;
  }
  
  /// Check feature access
  bool hasFeature(String featureId) {
    if (isPremium) return true;
    
    switch (featureId) {
      case 'achievements':
        return FreeFeatureLimits.hasAchievements;
      case 'leaderboard':
        return FreeFeatureLimits.canSubmitLeaderboard;
      case 'tts':
        return FreeFeatureLimits.hasTTS;
      case 'unlimited_lessons':
      case 'unlimited_practice':
        return false;
      default:
        return false;
    }
  }
}

/// Provider for subscription state
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _service;
  final Ref _ref;
  
  static const String _usedMinutesKey = 'used_minutes_today';
  static const String _lastResetDateKey = 'last_reset_date';
  
  SubscriptionNotifier(this._service, this._ref) : super(SubscriptionState(
    lastResetDate: DateTime.now(),
  ));
  
  /// Initialize subscription for a user
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Load usage data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedDate = prefs.getString(_lastResetDateKey);
      final today = DateTime.now();
      
      int usedMinutes = 0;
      DateTime lastReset = today;
      
      if (storedDate != null) {
        lastReset = DateTime.parse(storedDate);
        // Reset if it's a new day
        if (lastReset.day != today.day || 
            lastReset.month != today.month || 
            lastReset.year != today.year) {
          // New day - reset usage
          await prefs.setInt(_usedMinutesKey, 0);
          await prefs.setString(_lastResetDateKey, today.toIso8601String());
          usedMinutes = 0;
          lastReset = today;
        } else {
          usedMinutes = prefs.getInt(_usedMinutesKey) ?? 0;
        }
      } else {
        await prefs.setString(_lastResetDateKey, today.toIso8601String());
      }
      
      // Fetch subscription from service
      final subscription = await _service.getSubscription(userId);
      
      state = SubscriptionState(
        subscription: subscription,
        usedMinutesToday: usedMinutes,
        lastResetDate: lastReset,
        isLoading: false,
      );
      
      debugPrint('📦 Subscription loaded: ${subscription?.type}, used: $usedMinutes mins');
    } catch (e) {
      debugPrint('❌ Error loading subscription: $e');
      state = state.copyWith(isLoading: false);
    }
  }
  
  /// Add used practice time
  Future<void> addUsedTime(int minutes) async {
    if (state.isPremium) return; // Don't track for premium
    
    final newUsed = state.usedMinutesToday + minutes;
    state = state.copyWith(usedMinutesToday: newUsed);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_usedMinutesKey, newUsed);
    
    debugPrint('⏱️ Used time updated: $newUsed minutes');
  }
  
  /// Refresh subscription from cloud
  Future<void> refresh() async {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      await initialize(user.id);
    }
  }
}

/// Main subscription state provider
final subscriptionStateProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service, ref);
});

/// Helper provider to check if a feature is accessible
final featureAccessProvider = Provider.family<bool, String>((ref, featureId) {
  final state = ref.watch(subscriptionStateProvider);
  return state.hasFeature(featureId);
});

/// Helper provider to check if a lesson is accessible
final lessonAccessProvider = Provider.family<bool, int>((ref, lessonIndex) {
  final state = ref.watch(subscriptionStateProvider);
  return state.isLessonAccessible(lessonIndex);
});

/// Helper provider for premium status
final isPremiumProvider = Provider<bool>((ref) {
  final state = ref.watch(subscriptionStateProvider);
  return state.isPremium;
});

/// Helper provider for remaining minutes
final remainingMinutesProvider = Provider<int>((ref) {
  final state = ref.watch(subscriptionStateProvider);
  return state.remainingMinutes;
});
