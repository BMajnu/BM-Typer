import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/subscription_model.dart';

/// Admin service for managing user subscriptions
class AdminSubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// Search users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final queryLower = query.toLowerCase();
      
      debugPrint('🔍 Fetching users for query: "$query"');
      
      // Fetch users (increased limit to ensure we find matches in small-medium DBs)
      final allUsers = await _firestore
          .collection('users')
          .limit(500)
          .get();
          
      debugPrint('🔍 Total users fetched from DB: ${allUsers.docs.length}');

      final List<Map<String, dynamic>> results = [];
      
      for (final doc in allUsers.docs) {
        final data = doc.data();
        
        final profile = data['profile'] as Map<String, dynamic>?;
        
        // Try multiple field variants including nested profile
        final name = (data['name'] ?? profile?['name'] ?? data['userName'] ?? data['displayName'] ?? data['fullName'] ?? '').toString();
        final email = (data['email'] ?? profile?['email'] ?? data['userEmail'] ?? '').toString();
        final phone = (data['phone'] ?? profile?['phoneNumber'] ?? profile?['phone'] ?? data['phoneNumber'] ?? '').toString();
        final userId = (data['userId'] ?? profile?['customUserId'] ?? doc.id).toString();
        final photoUrl = data['photoUrl'] ?? profile?['photoUrl'] ?? data['photoURL']; // Keep null if missing
        
        final nameLower = name.toLowerCase();
        final emailLower = email.toLowerCase();
        final userIdLower = userId.toLowerCase();
        
        // If query is empty, add everything (up to limit)
        // If query has text, filter by name/email/id
        if (query.isEmpty || 
            nameLower.contains(queryLower) || 
            emailLower.contains(queryLower) || 
            userIdLower.contains(queryLower)) {
          results.add({
            'id': doc.id,
            'userId': userId,
            'name': name,
            'email': email,
            'phone': phone,
            'photoUrl': photoUrl,
          });
        }
        
        if (results.length >= 20) break; // Limit results to 20 for UI
      }

      debugPrint('✅ Found ${results.length} matches');
      return results;
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }

  /// Create a new Firebase user and grant subscription
  Future<Map<String, dynamic>> createUserAndGrant({
    required String name,
    required String email,
    required String password,
    String? phone,
    required SubscriptionType subscriptionType,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return {'success': false, 'error': 'এই ইমেইল দিয়ে ইউজার আগে থেকেই আছে'};
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'error': 'ইউজার তৈরি করা যায়নি'};
      }

      final now = DateTime.now();
      final generatedUserId = 'BM${now.millisecondsSinceEpoch.toString().substring(5)}';

      // Create Firestore user document
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'userId': generatedUserId,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': now.toIso8601String(),
        'isActive': true,
        'isPremium': true,
        'level': 1,
        'xp': 0,
        'totalTypingTime': 0,
        'lessonsCompleted': 0,
      });

      // Grant subscription
      final days = SubscriptionModel.getDurationDays(subscriptionType);
      final endDate = now.add(Duration(days: days));

      await _firestore.collection('subscriptions').add({
        'userId': firebaseUser.uid,
        'type': subscriptionType.name,
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': true,
        'features': PremiumFeatures.all,
        'createdAt': now.toIso8601String(),
        'grantedBy': 'admin',
      });

      // Sign out the newly created user
      await _auth.signOut();
      
      debugPrint('✅ New user created with subscription');
      return {
        'success': true, 
        'userId': generatedUserId,
        'firebaseUid': firebaseUser.uid,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'ইউজার তৈরিতে সমস্যা হয়েছে';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'এই ইমেইল ইতিমধ্যে ব্যবহৃত';
      } else if (e.code == 'weak-password') {
        errorMessage = 'পাসওয়ার্ড দুর্বল (কমপক্ষে ৬ অক্ষর)';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'ইমেইল ফরম্যাট ভুল';
      }
      debugPrint('❌ Firebase Auth Error: ${e.code}');
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      return {'success': false, 'error': 'অজানা ত্রুটি: $e'};
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
