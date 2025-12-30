import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/achievement_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';
import 'package:bm_typer/core/services/sync_queue_service.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';
import 'package:bm_typer/core/models/sync_operation.dart';
import 'package:bm_typer/core/enums/user_role.dart';
import 'package:bm_typer/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Provider for the current user
final currentUserProvider =
    StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier(ref);
});

/// Notifier to manage user state
class UserNotifier extends StateNotifier<UserModel?> {
  final Ref _ref;
  final CloudSyncService _cloudSync = CloudSyncService();
  final SyncQueueService _syncQueue = SyncQueueService();
  final ConnectivityService _connectivity = ConnectivityService();

  UserNotifier(this._ref) : super(null) {
    _initialize();
  }

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  /// Initialize the notifier by loading the current user from storage
  Future<void> _initialize() async {
    final user = await DatabaseService.getCurrentUser();
    if (user != null) {
      // Check and update login streak
      final updatedUser = user.updateLoginStreak();

      // Check for achievements after streak update
      final achievements = AchievementService.checkForNewAchievements(
        updatedUser,
        user,
      );

      // Check for special login achievement
      final specialAchievements = AchievementService.checkSpecialAchievements(
        updatedUser,
        'first_login',
      );

      // Combine all achievements
      final allAchievements = [...achievements, ...specialAchievements];

      // Calculate total XP to award
      final xpToAward =
          AchievementService.calculateTotalXpReward(allAchievements);

      // Add achievements and XP
      UserModel finalUser = updatedUser;

      if (xpToAward > 0) {
        finalUser = finalUser.addXP(xpToAward);
      }

      for (final achievement in allAchievements) {
        finalUser = finalUser.unlockAchievement(achievement.id);
      }

      // Save and update state
      await DatabaseService.saveUser(finalUser);
      state = finalUser;
      
      // Sync to cloud (Push local stats)
      await _syncToCloud(finalUser);

      // 1. Force Sync from Custom Claims (FASTEST & MOST RELIABLE)
      // This works even if Firestore document is missing
      try {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          final tokenResult = await authUser.getIdTokenResult(true); // true = force refresh
          final claims = tokenResult.claims ?? {};
          
          bool claimsChanged = false;
          UserModel claimUser = state!; // Current state

          // Apply Role Claim
          if (claims.containsKey('role')) {
            final roleStr = claims['role'] as String;
            final role = UserRole.values.firstWhere(
              (e) => e.name == roleStr,
              orElse: () => UserRole.student,
            );
            if (claimUser.role != role) {
              claimUser = claimUser.copyWith(role: role);
              claimsChanged = true;
              debugPrint('🔐 Role applied from Custom Claims: ${role.name}');
            }
          }

          // Apply Organization Claim
          if (claims.containsKey('organizationId')) {
            final orgId = claims['organizationId'] as String;
            if (claimUser.organizationId != orgId) {
              claimUser = claimUser.copyWith(organizationId: orgId);
              claimsChanged = true;
              debugPrint('🔐 OrganizationId applied from Custom Claims: $orgId');
            }
          }

          if (claimsChanged) {
            await DatabaseService.saveUser(claimUser);
            state = claimUser;
            // Also sync this back to Firestore to ensure consistency
            _cloudSync.syncUser(claimUser);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error reading custom claims: $e');
      }

      // 2. Setup real-time listener for Role/Org updates (Firestore)
      _setupRealtimeSync(finalUser.id);
    }
  }

  /// Setup real-time listener for user data
  void _setupRealtimeSync(String userId) {
    // Cancel existing subscription if any
    _userSubscription?.cancel();

    if (!_connectivity.isOnline) return;

    debugPrint('🔌 Setting up real-time sync for user: $userId');
    
    _userSubscription = _cloudSync.streamUserData(userId).listen(
      (snapshot) async {
        if (!snapshot.exists || state == null) return;
        
        final data = snapshot.data() as Map<String, dynamic>;
        bool hasChanges = false;
        UserModel currentUser = state!;

        // 1. Check for ROLE update
        // Support both root 'role' and 'profile.role' for backward compatibility
        String? roleStr = data['profile']?['role'] as String?;
        roleStr ??= data['role'] as String?;

        if (roleStr != null) {
          final newRole = UserRole.values.firstWhere(
            (e) => e.name == roleStr,
            orElse: () => UserRole.student,
          );

          if (currentUser.role != newRole) {
            currentUser = currentUser.copyWith(role: newRole);
            hasChanges = true;
            debugPrint('⚡ Real-time ROLE update: ${newRole.name}');
          }
        }

        // 2. Check for ORGANIZATION update (Premium status)
        String? orgId = data['profile']?['organizationId'] as String?;
        orgId ??= data['organizationId'] as String?;

        if (orgId != null && currentUser.organizationId != orgId) {
          currentUser = currentUser.copyWith(organizationId: orgId);
          hasChanges = true;
          debugPrint('⚡ Real-time ORG update: $orgId');
        }

        // 3. Apply changes if any
        if (hasChanges) {
          await DatabaseService.saveUser(currentUser);
          state = currentUser;
          debugPrint('✅ User state updated from real-time stream');
        }
      },
      onError: (e) {
        debugPrint('❌ Real-time sync error: $e');
      },
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  /// Sync user data to cloud (with offline queue fallback)
  Future<void> _syncToCloud(UserModel user) async {
    try {
      if (_connectivity.isOnline) {
        await _cloudSync.syncUser(user);
        debugPrint('☁️ User synced to cloud: ${user.name}');
      } else {
        // Add to offline queue
        await _syncQueue.addOperation(SyncOperation(
          collection: 'users',
          documentId: user.id,
          data: {
            'profile': {
              'name': user.name,
              'email': user.email,
              'lastLoginDate': user.lastLoginDate?.toIso8601String(),
            },
            'stats': {
              'highestWpm': user.highestWpm,
              'xpPoints': user.xpPoints,
              'level': user.level,
              'streakCount': user.streakCount,
            },
            'progress': {
              'completedLessons': user.completedLessons,
              'unlockedAchievements': user.unlockedAchievements,
            },
          },
          operationType: 'update',
        ));
        debugPrint('📥 User queued for sync: ${user.name}');
      }
    } catch (e) {
      debugPrint('❌ Sync error: $e');
    }
  }

  /// Register a new user
  Future<void> registerUser(String name, String email) async {
    final user = UserModel(
      name: name,
      email: email,
      lastLoginDate: DateTime.now(),
      streakCount: 1,
    );

    await DatabaseService.saveUser(user);
    await DatabaseService.setCurrentUser(user);

    // Check for first login achievement
    final achievements = AchievementService.checkSpecialAchievements(
      user,
      'first_login',
    );

    // Calculate total XP to award
    final xpToAward = AchievementService.calculateTotalXpReward(achievements);

    // Add achievements and XP
    UserModel finalUser = user;

    if (xpToAward > 0) {
      finalUser = finalUser.addXP(xpToAward);
    }

    for (final achievement in achievements) {
      finalUser = finalUser.unlockAchievement(achievement.id);
    }

    if (finalUser != user) {
      await DatabaseService.saveUser(finalUser);
    }

    state = finalUser;
    
    // Sync new user to cloud
    await _syncToCloud(finalUser);
  }

  /// Update the user information
  Future<void> updateUser(UserModel updatedUser) async {
    // if (state == null) return; // Removed to allow login/initialization

    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
    
    // Sync to cloud
    await _syncToCloud(updatedUser);
  }

  /// Update user typing goals
  Future<void> updateGoals({double? wpm, double? accuracy}) async {
    if (state == null) return;

    final updatedUser = state!.copyWith(
      goalWpm: wpm,
      goalAccuracy: accuracy,
    );

    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
    
    // Sync goals to cloud
    await _syncToCloud(updatedUser);
  }

  /// Mark an achievement notification as shown
  Future<void> markAchievementAsShown(String achievementId) async {
    if (state == null) return;

    final updatedUser = state!.markAchievementNotificationShown(achievementId);
    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
  }

  /// Add typing statistics and check for achievements
  Future<List<Achievement>> addTypingStats({
    required double wpm,
    required double accuracy,
    String? completedLesson,
    int additionalXp = 0,
  }) async {
    if (state == null) return [];

    // Keep a copy of the previous user state for achievement comparison
    final previousUser = state!;

    // Create new WPM and accuracy history
    final newWpmHistory = List<double>.from(state!.wpmHistory)..add(wpm);
    final newAccuracyHistory = List<double>.from(state!.accuracyHistory)
      ..add(accuracy);

    // Update highest WPM if needed
    final newHighestWpm = wpm > state!.highestWpm ? wpm : state!.highestWpm;

    // Update completed lessons if needed
    List<String>? newCompletedLessons;
    if (completedLesson != null &&
        !state!.completedLessons.contains(completedLesson)) {
      newCompletedLessons = List<String>.from(state!.completedLessons)
        ..add(completedLesson);
    }

    // Create updated user with new stats
    final updatedUser = state!.copyWith(
      wpmHistory: newWpmHistory,
      accuracyHistory: newAccuracyHistory,
      highestWpm: newHighestWpm,
      completedLessons: newCompletedLessons,
    );

    // Check for new achievements
    final achievements = AchievementService.checkForNewAchievements(
      updatedUser,
      previousUser,
    );

    // Calculate total XP to award
    final xpToAward = AchievementService.calculateTotalXpReward(achievements);

    // Add XP and achievements
    UserModel finalUser = updatedUser;

    if (xpToAward > 0) {
      finalUser = finalUser.addXP(xpToAward);
    }

    for (final achievement in achievements) {
      finalUser = finalUser.unlockAchievement(achievement.id);
    }

    // Save and update state
    await DatabaseService.saveUser(finalUser);
    state = finalUser;

    // Sync user stats and typing session to cloud
    await _syncToCloud(finalUser);

    if (_connectivity.isOnline) {
      // Online: Direct upload
      await _cloudSync.syncTypingSession(
        wpm: wpm,
        accuracy: accuracy,
        lessonId: completedLesson,
      );
    } else {
      // Offline: Queue session upload
      final sessionId = Uuid().v4();
      await _syncQueue.addOperation(SyncOperation(
        collection: 'users/${finalUser.id}/sessions',
        documentId: sessionId,
        operationType: 'create',
        data: {
          'wpm': wpm,
          'accuracy': accuracy,
          'lessonId': completedLesson,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
      debugPrint('📥 Session queued for sync: WPM=$wpm');
    }

    return achievements;
  }

  /// Mark an exercise as completed efficiently
  Future<void> markExerciseCompleted(String lessonTitle, int exerciseIndex) async {
     if (state == null) return;
     
     // Update user state
     UserModel updatedUser = state!.updateCompletedExercises(lessonTitle, exerciseIndex);
     state = updatedUser;
     await DatabaseService.saveUser(updatedUser);

     // Debounced sync to cloud could go here, or just wait for next major sync
     // For now, let's sync to ensure persistence across devices if needed
     if (_connectivity.isOnline) {
       // We can optimize this later to not sync FULL user object every exercise
       _cloudSync.syncUser(updatedUser); 
     } else {
        // Queue light update? Or just full user for now
     }
  }

  /// Add XP to the user
  Future<void> addXP(int amount) async {
    if (state == null) return;

    final updatedUser = state!.addXP(amount);
    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
  }

  /// Logout the current user (both Firebase and local)
  Future<void> logout() async {
    try {
      // Sign out from Firebase first
      await AuthService().signOut();
      debugPrint('✅ Firebase signOut completed');
    } catch (e) {
      debugPrint('⚠️ Firebase signOut error (continuing anyway): $e');
    }
    
    // Always clear local state regardless of Firebase result
    await DatabaseService.clearCurrentUser();
    state = null;
    debugPrint('✅ Local user cleared');
  }

  /// Get all saved users from local database (for user switching)
  List<UserModel> getAllSavedUsers() {
    return DatabaseService.getAllUsers();
  }

  /// Switch to a different saved user (local switch only, no Firebase re-auth)
  /// NOTE: This also syncs role from cloud to ensure proper role detection
  Future<void> switchToUser(UserModel user) async {
    await DatabaseService.setCurrentUser(user);
    state = user;
    debugPrint('🔄 Switched to user: ${user.name} (${user.email})');
    
    // Sync role from cloud using EMAIL (important: fetchUser uses Firebase UID which may differ)
    if (_connectivity.isOnline) {
      try {
        // Use fetchUserByEmail to get the CORRECT user's cloud data
        final cloudData = await _cloudSync.fetchUserByEmail(user.email);
        if (cloudData != null) {
          UserModel updatedUser = user;
          
          // Check for Role update from cloud (try multiple paths)
          String? roleStr = cloudData['profile']?['role'] as String?;
          roleStr ??= cloudData['role'] as String?;
          
          if (roleStr != null) {
            final role = UserRole.values.firstWhere(
              (e) => e.name == roleStr,
              orElse: () => UserRole.student,
            );
            
            if (user.role != role) {
              updatedUser = user.copyWith(role: role);
              debugPrint('♻️ Role synced from cloud for ${user.name}: ${role.name}');
            }
          }
          
          // Also check for organizationId update
          String? orgId = cloudData['profile']?['organizationId'] as String?;
          orgId ??= cloudData['organizationId'] as String?;
          
          if (orgId != null && user.organizationId != orgId) {
            updatedUser = updatedUser.copyWith(organizationId: orgId);
            debugPrint('♻️ OrgId synced from cloud: $orgId');
          }
          
          // Save updated user if any changes were made
          if (updatedUser != user) {
            await DatabaseService.saveUser(updatedUser);
            state = updatedUser;
            debugPrint('✅ User data updated from cloud sync');
          }
        } else {
          debugPrint('⚠️ No cloud data found for user: ${user.email}');
        }
      } catch (e) {
        debugPrint('⚠️ Error syncing role from cloud during user switch: $e');
        // Continue with local user data even if cloud sync fails
      }
    }
  }

  /// Add a new user to saved users list (for multi-user support)
  Future<void> addSavedUser(UserModel user) async {
    await DatabaseService.saveUser(user);
    debugPrint('➕ Added user to saved list: ${user.name}');
  }

  /// Remove a user from saved users list
  Future<void> removeSavedUser(String userId) async {
    await DatabaseService.deleteUser(userId);
    debugPrint('🗑️ Removed user from saved list: $userId');
  }

  /// Fetch current user from database
  Future<void> loadCurrentUser() async {
    try {
      state = DatabaseService.getCurrentUser();
    } catch (e) {
      state = null;
    }
  }

  // -----------------------------------------------------------------------
  // Backwards-compatibility helpers
  // -----------------------------------------------------------------------

  /// Alias for [registerUser] kept for compatibility with older UI code.
  Future<void> createUser({required String name, required String email}) {
    return registerUser(name, email);
  }

  /// Alias for [addTypingStats] that uses the parameter names expected by
  /// the older implementation (e.g. `earnedXp`).
  Future<List<Achievement>> updateTypingStats({
    required double wpm,
    required double accuracy,
    String? completedLesson,
    int earnedXp = 0,
  }) {
    return addTypingStats(
      wpm: wpm,
      accuracy: accuracy,
      completedLesson: completedLesson,
      additionalXp: earnedXp,
    );
  }
}
