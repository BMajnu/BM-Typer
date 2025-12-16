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
      
      await docRef.set({
        'profile': {
          'name': user.name,
          'email': user.email,
          'createdAt': user.createdAt?.toIso8601String(),
          'lastLoginDate': user.lastLoginDate?.toIso8601String(),
        },
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
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Error fetching user: $e');
      return null;
    }
  }

  /// Sync typing session to Firestore
  Future<void> syncTypingSession({
    required double wpm,
    required double accuracy,
    String? lessonId,
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
  Future<bool> processOperation(SyncOperation operation) async {
    if (!_connectivity.isOnline) return false;

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
    } catch (e) {
      debugPrint('❌ Error processing operation: $e');
      return false;
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
