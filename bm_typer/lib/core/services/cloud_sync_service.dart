import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/models/sync_operation.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';

/// Service to sync data with Firebase Cloud Firestore
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isInitialized = false;
  StreamSubscription<User?>? _authSubscription;

  /// Initialize the cloud sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configure Firestore settings for offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Listen for auth state changes
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('🔐 User signed in: ${user.uid}');
        _syncUserData();
      }
    });

    _isInitialized = true;
    debugPrint('☁️ CloudSyncService initialized');
  }

  /// Get current Firebase user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // ============================================================
  // USER SYNC OPERATIONS
  // ============================================================

  /// Sync local user data to Firestore
  Future<void> syncUser(UserModel user) async {
    if (!_connectivity.isOnline || !isAuthenticated) return;

    try {
      final docRef = _firestore.collection('users').doc(currentUserId);

      final profileData = <String, dynamic>{
        'name': user.name,
        'email': user.email,
        'customUserId': user.customUserId,
        'photoUrl': user.photoUrl,
        'phoneNumber': user.phoneNumber,
        'lastLoginDate': user.lastLoginDate?.toIso8601String(),
      };
      
      await docRef.set({
        'profile': profileData,
        'stats': {
          'highestWpm': user.highestWpm,
          'avgAccuracy': user.averageAccuracy,
          'xpPoints': user.xpPoints,
          'level': user.level,
          'streakCount': user.streakCount,
          'totalSessions': user.typingSessions.length,
        },
        'progress': {
          'completedLessons': user.completedLessons,
          'unlockedAchievements': user.unlockedAchievements,
          'completedExercises': user.completedExercises.map((key, value) => MapEntry(key, value.toList())),
          'skippedExercises': user.skippedExercises.map((key, value) => MapEntry(key, value.toList())),
          'exerciseRepProgress': user.exerciseRepProgress, // Rep progress per exercise
          'lastLessonIndex': user.lastLessonIndex, // Last position
          'lastExerciseIndex': user.lastExerciseIndex,
        },
        'goals': {
          'wpmGoal': user.goalWpm,
          'accuracyGoal': user.goalAccuracy,
        },
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('☁️ User synced to Firestore: ${user.name}');
    } catch (e) {
      debugPrint('❌ Error syncing user: $e');
      rethrow;
    }
  }

  /// Fetch user data from Firestore
  Future<Map<String, dynamic>?> fetchUser() async {
    if (!isAuthenticated) {
      debugPrint('❌ fetchUser: Not authenticated');
      return null;
    }

    try {
      debugPrint('📥 fetchUser: Fetching user doc for: $currentUserId');
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      final data = doc.data();
      
      if (data != null) {
        // Log key fields for debugging
        final rootOrgId = data['organizationId'];
        final profileOrgId = data['profile']?['organizationId'];
        final role = data['profile']?['role'] ?? data['role'];
        debugPrint('✅ fetchUser: rootOrgId=$rootOrgId, profileOrgId=$profileOrgId, role=$role');
      } else {
        debugPrint('⚠️ fetchUser: No data found for user');
      }
      
      return data;
    } catch (e) {
      debugPrint('❌ Error fetching user: $e');
      return null;
    }
  }

  /// Fetch typing sessions from sub-collection
  Future<List<Map<String, dynamic>>> fetchUserSessions() async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sessions')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to last 50 sessions to save bandwidth
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error fetching sessions: $e');
      return [];
    }
  }

  /// Stream user data from Firestore for real-time updates
  Stream<DocumentSnapshot> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Fetch user data from Firestore by email (for user switching)
  /// This allows fetching correct user data even when local user differs from Firebase auth user
  Future<Map<String, dynamic>?> fetchUserByEmail(String email) async {
    try {
      debugPrint('🔍 Fetching user by email: $email');
      
      // Try profile.email first
      final querySnapshot = await _firestore
          .collection('users')
          .where('profile.email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        debugPrint('✅ Found user by profile.email: ${data['profile']?['role'] ?? 'no role'}');
        return data;
      }
      
      // Try root email field for backward compatibility
      final rootQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (rootQuery.docs.isNotEmpty) {
        final data = rootQuery.docs.first.data();
        debugPrint('✅ Found user by root email: ${data['role'] ?? data['profile']?['role'] ?? 'no role'}');
        return data;
      }
      
      debugPrint('❌ User not found by email: $email');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user by email: $e');
      return null;
    }
  }


  /// Get user email by custom User ID
  Future<String?> getUserEmailByCustomId(String customUserId) async {
    try {
      debugPrint('🔍 Looking up user by customUserId: $customUserId');
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('profile.customUserId', isEqualTo: customUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Try searching in root level for backward compatibility or different structure
        final rootQuery = await _firestore
            .collection('users')
            .where('customUserId', isEqualTo: customUserId)
            .limit(1)
            .get();
            
        if (rootQuery.docs.isNotEmpty) {
           final data = rootQuery.docs.first.data();
           debugPrint('✅ Found user by root customUserId: ${data['email'] ?? data['profile']?['email']}');
           return data['email'] ?? data['profile']?['email'];
        }
        debugPrint('❌ User not found by customUserId: $customUserId');
        return null;
      }

      final data = querySnapshot.docs.first.data();
      debugPrint('✅ Found user by profile.customUserId: ${data['profile']?['email']}');
      return data['profile']?['email'] as String?;
    } catch (e) {
      debugPrint('❌ Error fetching user email by ID: $e');
      return null;
    }
  }

  /// Get user email by phone number (for phone login)
  Future<String?> getUserEmailByPhoneNumber(String phoneNumber) async {
    try {
      // Normalize phone number (remove spaces, ensure + prefix)
      String normalizedPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '');
      if (!normalizedPhone.startsWith('+')) {
        // Assume Bangladesh if no country code
        if (normalizedPhone.startsWith('0')) {
          normalizedPhone = '+88$normalizedPhone';
        } else {
          normalizedPhone = '+880$normalizedPhone';
        }
      }
      
      debugPrint('🔍 Looking up user by phone: $normalizedPhone');
      
      // Try profile.phoneNumber first
      final querySnapshot = await _firestore
          .collection('users')
          .where('profile.phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        debugPrint('✅ Found user by profile.phoneNumber: ${data['profile']?['email']}');
        return data['profile']?['email'] as String?;
      }
      
      // Also try without normalization
      final rawQuery = await _firestore
          .collection('users')
          .where('profile.phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
          
      if (rawQuery.docs.isNotEmpty) {
        final data = rawQuery.docs.first.data();
        debugPrint('✅ Found user by raw phoneNumber: ${data['profile']?['email']}');
        return data['profile']?['email'] as String?;
      }
      
      debugPrint('❌ User not found by phone: $phoneNumber');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user email by phone: $e');
      return null;
    }
  }

  /// Check if a User ID is already taken
  Future<bool> isUserIdTaken(String customUserId) async {
    try {
       debugPrint('🔍 Checking if User ID is taken: $customUserId');
       
       final querySnapshot = await _firestore
          .collection('users')
          .where('profile.customUserId', isEqualTo: customUserId)
          .limit(1)
          .get();
          
       if (querySnapshot.docs.isNotEmpty) {
         debugPrint('❌ User ID already taken (profile.customUserId match)');
         return true;
       }

       final rootQuery = await _firestore
            .collection('users')
            .where('customUserId', isEqualTo: customUserId)
            .limit(1)
            .get();
       
       if (rootQuery.docs.isNotEmpty) {
         debugPrint('❌ User ID already taken (root customUserId match)');
         return true;
       }
       
       debugPrint('✅ User ID is available: $customUserId');
       return false;
    } catch (e) {
      debugPrint('⚠️ Error checking User ID availability: $e');
      // Return false on error to allow signup (not secure but better UX)
      // The actual uniqueness will be enforced by Firebase Auth email
      return false;
    }
  }

  /// Sync typing session to Firestore
  Future<void> syncTypingSession({
    required double wpm,
    required double accuracy,
    String? lessonId,
    String? typedText,
  }) async {
    if (!_connectivity.isOnline || !isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sessions')
          .add({
        'wpm': wpm,
        'accuracy': accuracy,
        'lessonId': lessonId,
        'typedText': typedText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('☁️ Session synced: WPM=$wpm, Accuracy=$accuracy');
    } catch (e) {
      debugPrint('❌ Error syncing session: $e');
    }
  }


  // ============================================================
  // LEADERBOARD SYNC
  // ============================================================

  /// Submit score to global leaderboard
  Future<void> submitToLeaderboard({
    required String userName,
    required double wpm,
    required double accuracy,
    required int level,
    String? lessonId,
  }) async {
    if (!_connectivity.isOnline || !isAuthenticated) return;

    try {
      await _firestore.collection('leaderboard').add({
        'userId': currentUserId,
        'userName': userName,
        'wpm': wpm,
        'accuracy': accuracy,
        'level': level,
        'lessonId': lessonId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('🏆 Leaderboard entry submitted');
    } catch (e) {
      debugPrint('❌ Error submitting to leaderboard: $e');
    }
  }

  /// Get global leaderboard entries
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('wpm', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('❌ Error fetching leaderboard: $e');
      return [];
    }
  }

  // ============================================================
  // SYNC QUEUE PROCESSING
  // ============================================================

  /// Process a single sync operation from the queue
  /// Returns `true` if successful, `false` if failed permanently (should be removed).
  /// Throws exception if failed transiently (should retry).
  Future<bool> processOperation(SyncOperation operation) async {
    if (!_connectivity.isOnline) throw Exception('Offline');

    try {
      final docRef = _firestore.collection(operation.collection).doc(operation.documentId);

      switch (operation.type) {
        case SyncOperationType.create:
        case SyncOperationType.update:
          await docRef.set(operation.data, SetOptions(merge: true));
          break;
        case SyncOperationType.delete:
          await docRef.delete();
          break;
      }

      return true;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase Sync Error [${e.code}]: ${e.message}');
      
      // Permanent errors - should remove from queue
      if (e.code == 'permission-denied' || 
          e.code == 'not-found' || 
          e.code == 'already-exists' ||
          e.code == 'invalid-argument') {
        return false; 
      }
      
      // Transient errors (network, unavailable, etc) - retry
      rethrow;
    } catch (e) {
      debugPrint('❌ Unknown Sync Error: $e');
      rethrow; // Retry on unknown errors to be safe
    }
  }

  // ============================================================
  // DATA SYNC (PULL FROM CLOUD)
  // ============================================================

  /// Sync user data from cloud to local
  Future<void> _syncUserData() async {
    if (!isAuthenticated) return;

    try {
      final cloudData = await fetchUser();
      if (cloudData == null) return;

      final localUser = DatabaseService.getCurrentUser();
      if (localUser == null) return;

      // Check if cloud data is newer
      final cloudLastSynced = cloudData['lastSynced'] as Timestamp?;
      if (cloudLastSynced != null) {
        // Merge cloud data with local data if needed
        // For now, we prioritize local data (offline-first)
        debugPrint('☁️ Cloud user data available. Local data preserved (offline-first).');
      }
    } catch (e) {
      debugPrint('❌ Error syncing user data: $e');
    }
  }

  // ============================================================
  // APP CONFIG
  // ============================================================

  /// Get app configuration from Firestore
  Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final doc = await _firestore.collection('app_config').doc('version').get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Error fetching app config: $e');
      return null;
    }
  }

  /// Check if app update is required
  Future<bool> isUpdateRequired(String currentVersion) async {
    final config = await getAppConfig();
    if (config == null) return false;

    final minVersion = config['minVersion'] as String?;
    final forceUpdate = config['forceUpdate'] as bool? ?? false;

    if (minVersion == null) return false;

    // Simple version comparison (can be enhanced)
    return forceUpdate && _compareVersions(currentVersion, minVersion) < 0;
  }

  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
  }
}

/// Provider for CloudSyncService
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final service = CloudSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});
