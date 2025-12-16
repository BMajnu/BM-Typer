import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/subscription_model.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';

/// Service to manage user subscriptions
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = ConnectivityService();

  SubscriptionModel? _currentSubscription;
  SubscriptionModel? get currentSubscription => _currentSubscription;

  /// Get subscription for a user
  Future<SubscriptionModel?> getSubscription(String userId) async {
    try {
      if (_connectivity.isOnline) {
        final snapshot = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('endDate', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          _currentSubscription = SubscriptionModel.fromJson({
            'id': snapshot.docs.first.id,
            ...snapshot.docs.first.data(),
          });
          return _currentSubscription;
        }
      }

      // Return free subscription if no active subscription found
      _currentSubscription = SubscriptionModel.free(userId);
      return _currentSubscription;
    } catch (e) {
      debugPrint('❌ Error getting subscription: $e');
      return SubscriptionModel.free(userId);
    }
  }

  /// Check if user has premium access
  Future<bool> hasPremiumAccess(String userId) async {
    final sub = await getSubscription(userId);
    return sub != null && sub.type != 'free' && sub.isValid;
  }

  /// Check if a specific feature is available
  Future<bool> hasFeature(String userId, String featureId) async {
    final sub = await getSubscription(userId);
    if (sub == null) return false;

    if (sub.type != 'free') return true; // Premium has all features

    // Check free tier limitations
    switch (featureId) {
      case 'unlimited_lessons':
        return false;
      case 'unlimited_practice':
        return false;
      case 'achievements':
        return FreeFeatureLimits.hasAchievements;
      case 'leaderboard':
        return FreeFeatureLimits.canSubmitLeaderboard;
      case 'tts':
        return FreeFeatureLimits.hasTTS;
      default:
        return false;
    }
  }

  /// Get remaining practice time for free users (in seconds)
  int getRemainingPracticeTime(String userId, int usedMinutesToday) {
    if (_currentSubscription?.type != 'free') return -1; // Unlimited

    final maxMinutes = FreeFeatureLimits.dailyPracticeMinutes;
    final remaining = (maxMinutes - usedMinutesToday) * 60;
    return remaining > 0 ? remaining : 0;
  }

  /// Get accessible lesson count for free users
  int getAccessibleLessonCount() {
    if (_currentSubscription?.type != 'free') return -1; // Unlimited
    return FreeFeatureLimits.maxLessons;
  }

  /// Get XP multiplier based on subscription
  double getXpMultiplier() {
    if (_currentSubscription == null) return 1.0;

    final boost = SubscriptionModel.getXpBoost(_currentSubscription!.subscriptionType);
    return 1.0 + (boost / 100.0);
  }
}

/// Provider for subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provider for current subscription
final currentSubscriptionProvider = FutureProvider.family<SubscriptionModel?, String>((ref, userId) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSubscription(userId);
});

/// Provider for premium status
final hasPremiumProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.hasPremiumAccess(userId);
});
