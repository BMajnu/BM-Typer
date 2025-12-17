import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/subscription_model.dart';

/// Admin service for managing user subscriptions
class AdminSubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all subscriptions
  Stream<List<SubscriptionModel>> getAllSubscriptions() {
    return _firestore
        .collection('subscriptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return SubscriptionModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              });
            }).toList());
  }

  /// Get active subscriptions only
  Stream<List<SubscriptionModel>> getActiveSubscriptions() {
    return _firestore
        .collection('subscriptions')
        .where('isActive', isEqualTo: true)
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return SubscriptionModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              });
            }).toList());
  }

  /// Get subscriptions expiring soon (within 7 days)
  Future<List<SubscriptionModel>> getExpiringSoon() async {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));

    final snapshot = await _firestore
        .collection('subscriptions')
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: now.toIso8601String())
        .where('endDate', isLessThan: sevenDaysLater.toIso8601String())
        .get();

    return snapshot.docs.map((doc) {
      return SubscriptionModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }

  /// Grant subscription to a user
  Future<bool> grantSubscription({
    required String userId,
    required SubscriptionType type,
    int? customDays,
  }) async {
    try {
      final now = DateTime.now();
      final days = customDays ?? SubscriptionModel.getDurationDays(type);
      final endDate = now.add(Duration(days: days));

      // Deactivate any existing subscriptions
      await _deactivateUserSubscriptions(userId);

      // Create new subscription
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'type': type.name,
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': true,
        'features': PremiumFeatures.all,
        'createdAt': now.toIso8601String(),
        'grantedBy': 'admin',
      });

      debugPrint('✅ Subscription granted to $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error granting subscription: $e');
      return false;
    }
  }

  /// Extend an existing subscription
  Future<bool> extendSubscription({
    required String subscriptionId,
    required int additionalDays,
  }) async {
    try {
      final doc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      if (!doc.exists) return false;

      final currentEnd = DateTime.parse(doc.data()?['endDate'] as String);
      final newEnd = currentEnd.add(Duration(days: additionalDays));

      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'endDate': newEnd.toIso8601String(),
        'isActive': true,
      });

      debugPrint('✅ Subscription extended by $additionalDays days');
      return true;
    } catch (e) {
      debugPrint('❌ Error extending subscription: $e');
      return false;
    }
  }

  /// Cancel a subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'isActive': false,
        'cancelledAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Subscription cancelled');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling subscription: $e');
      return false;
    }
  }

  /// Deactivate all subscriptions for a user
  Future<void> _deactivateUserSubscriptions(String userId) async {
    final snapshot = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isActive': false});
    }
  }

  /// Get subscription stats
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      final allSubs = await _firestore.collection('subscriptions').get();
      final activeSubs = await _firestore
          .collection('subscriptions')
          .where('isActive', isEqualTo: true)
          .get();

      int totalRevenue = 0;
      int monthlyCount = 0;
      int quarterlyCount = 0;
      int halfYearlyCount = 0;
      int yearlyCount = 0;

      for (final doc in allSubs.docs) {
        final type = doc.data()['type'] as String?;
        if (type == null) continue;

        switch (type) {
          case 'monthly':
            monthlyCount++;
            totalRevenue += SubscriptionModel.getPrice(SubscriptionType.monthly);
            break;
          case 'quarterly':
            quarterlyCount++;
            totalRevenue += SubscriptionModel.getPrice(SubscriptionType.quarterly);
            break;
          case 'halfYearly':
          case 'half_yearly':
            halfYearlyCount++;
            totalRevenue += SubscriptionModel.getPrice(SubscriptionType.halfYearly);
            break;
          case 'yearly':
            yearlyCount++;
            totalRevenue += SubscriptionModel.getPrice(SubscriptionType.yearly);
            break;
        }
      }

      return {
        'totalSubscriptions': allSubs.docs.length,
        'activeSubscriptions': activeSubs.docs.length,
        'totalRevenue': totalRevenue,
        'monthlyCount': monthlyCount,
        'quarterlyCount': quarterlyCount,
        'halfYearlyCount': halfYearlyCount,
        'yearlyCount': yearlyCount,
      };
    } catch (e) {
      debugPrint('❌ Error getting stats: $e');
      return {};
    }
  }
}

/// Provider for admin subscription service
final adminSubscriptionServiceProvider = Provider<AdminSubscriptionService>((ref) {
  return AdminSubscriptionService();
});

/// Provider for all subscriptions stream
final allSubscriptionsProvider = StreamProvider<List<SubscriptionModel>>((ref) {
  final service = ref.watch(adminSubscriptionServiceProvider);
  return service.getAllSubscriptions();
});

/// Provider for subscription stats
final subscriptionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(adminSubscriptionServiceProvider);
  return service.getSubscriptionStats();
});
