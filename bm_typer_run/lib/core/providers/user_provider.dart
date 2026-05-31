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
import 'package:bm_typer/core/models/typing_session.dart';
import 'package:bm_typer/core/enums/user_role.dart';
import 'package:bm_typer/core/services/auth_service.dart';
import 'package:bm_typer/core/services/admin_auth_service.dart';
import 'package:bm_typer/core/providers/organization_provider.dart';
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
    _setupAuthStateListener();
  }

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  /// Listen to Firebase Auth state changes and sync data when user logs in
  void _setupAuthStateListener() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? authUser) async {
      if (authUser != null) {
        debugPrint('🔥 Auth state changed: User logged in - ${authUser.email}');
        // User just logged in - force sync from cloud
        await _syncUserDataFromCloud(authUser);
      } else {
        debugPrint('🔥 Auth state changed: User logged out');
      }
    });
  }

  /// Sync complete user data from Firebase Cloud (called on login)
  Future<void> _syncUserDataFromCloud(User authUser) async {
    if (!_connectivity.isOnline) {
      debugPrint('⚠️ _syncUserDataFromCloud: Offline, skipping');
      return;
    }

    debugPrint('☁️ _syncUserDataFromCloud: Fetching data for ${authUser.email}');

    try {
      final cloudData = await _cloudSync.fetchUser();
      if (cloudData == null) {
        debugPrint('⚠️ _syncUserDataFromCloud: No cloud data found');
        return;
      }

      final profile = cloudData['profile'] as Map<String, dynamic>? ?? {};
      final stats = cloudData['stats'] as Map<String, dynamic>? ?? {};
      final progress = cloudData['progress'] as Map<String, dynamic>? ?? {};

      // Extract key fields
      final cloudOrgId = profile['organizationId'] ?? cloudData['organizationId'];
      final cloudRoleStr = profile['role'] ?? cloudData['role'];

      debugPrint('☁️ Cloud data received: orgId=$cloudOrgId, role=$cloudRoleStr');

      // Parse role
      final parsedRole = cloudRoleStr != null
          ? UserRole.values.firstWhere((e) => e.name == cloudRoleStr, orElse: () => UserRole.student)
          : UserRole.student;

      // Safety check for superAdmin
      final isLegacyAdmin = AdminAuthService.legacyAdminEmails
          .contains((profile['email'] ?? authUser.email ?? '').toString().toLowerCase());
      final safeRole = (!isLegacyAdmin && parsedRole == UserRole.superAdmin)
          ? UserRole.student
          : parsedRole;

      // Get or create user
      UserModel? currentUser = state ?? await DatabaseService.getCurrentUser();

      // Parse completedExercises from cloud format (Map<String, dynamic> with List values)
      Map<String, List<int>> parseExerciseMap(dynamic data) {
        if (data == null) return {};
        final raw = data as Map<String, dynamic>;
        return raw.map((key, value) => MapEntry(key, List<int>.from(value ?? [])));
      }
      
      // Parse exerciseRepProgress from cloud format
      Map<String, int> parseRepProgress(dynamic data) {
        if (data == null) return {};
        final raw = data as Map<String, dynamic>;
        return raw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
      }
      
      final cloudCompletedExercises = parseExerciseMap(progress['completedExercises']);
      final cloudSkippedExercises = parseExerciseMap(progress['skippedExercises']);
      final cloudExerciseRepProgress = parseRepProgress(progress['exerciseRepProgress']);
      final cloudLastLessonIndex = (progress['lastLessonIndex'] as num?)?.toInt() ?? 0;
      final cloudLastExerciseIndex = (progress['lastExerciseIndex'] as num?)?.toInt() ?? 0;
      
      debugPrint('☁️ Cloud progress: completedExercises=${cloudCompletedExercises.length} lessons, '
          'repProgress=${cloudExerciseRepProgress.length} exercises, '
          'lastPosition=L$cloudLastLessonIndex/E$cloudLastExerciseIndex');

      if (currentUser == null) {
        // Create new user from cloud data
        currentUser = UserModel(
          id: authUser.uid,
          name: profile['name'] ?? authUser.displayName ?? 'User',
          email: profile['email'] ?? authUser.email ?? '',
          customUserId: profile['customUserId'],
          photoUrl: profile['photoUrl'] ?? authUser.photoURL,
          phoneNumber: profile['phoneNumber'],
          organizationId: cloudOrgId,
          role: safeRole,
          xpPoints: stats['xpPoints'] ?? 0,
          level: stats['level'] ?? 1,
          streakCount: stats['streakCount'] ?? 1,
          completedLessons: List<String>.from(progress['completedLessons'] ?? []),
          unlockedAchievements: List<String>.from(progress['unlockedAchievements'] ?? []),
          // CRITICAL: Also load exercise progress data from cloud!
          completedExercises: cloudCompletedExercises,
          skippedExercises: cloudSkippedExercises,
          exerciseRepProgress: cloudExerciseRepProgress,
          lastLessonIndex: cloudLastLessonIndex,
          lastExerciseIndex: cloudLastExerciseIndex,
        );
        debugPrint('✅ Created new user from cloud: ${currentUser.name}');
      } else {
        // Update existing user with cloud org/role AND progress data
        bool needsUpdate = false;

        if (cloudOrgId != null && currentUser.organizationId != cloudOrgId) {
          currentUser = currentUser.copyWith(organizationId: cloudOrgId.toString());
          needsUpdate = true;
          debugPrint('✅ Updated organizationId: $cloudOrgId');
        }

        if (safeRole != currentUser.role) {
          currentUser = currentUser.copyWith(role: safeRole);
          needsUpdate = true;
          debugPrint('✅ Updated role: ${safeRole.name}');
        }
        
        // CRITICAL: Merge exercise progress from cloud (cloud takes priority for multi-device sync)
        // This ensures progress made on other devices is reflected here
        if (cloudCompletedExercises.isNotEmpty || cloudExerciseRepProgress.isNotEmpty) {
          // Merge completedExercises: combine local and cloud
          final mergedCompletedExercises = Map<String, List<int>>.from(currentUser.completedExercises);
          cloudCompletedExercises.forEach((lesson, exercises) {
            final existing = mergedCompletedExercises[lesson] ?? [];
            final merged = {...existing, ...exercises}.toList()..sort();
            mergedCompletedExercises[lesson] = merged;
          });
          
          // Merge skippedExercises
          final mergedSkippedExercises = Map<String, List<int>>.from(currentUser.skippedExercises);
          cloudSkippedExercises.forEach((lesson, exercises) {
            final existing = mergedSkippedExercises[lesson] ?? [];
            final merged = {...existing, ...exercises}.toList()..sort();
            mergedSkippedExercises[lesson] = merged;
          });
          
          // Merge exerciseRepProgress: take the MAX value (most progress)
          final mergedRepProgress = Map<String, int>.from(currentUser.exerciseRepProgress);
          cloudExerciseRepProgress.forEach((key, value) {
            final localValue = mergedRepProgress[key] ?? 0;
            mergedRepProgress[key] = value > localValue ? value : localValue;
          });
          
          // Take the furthest position (user might have progressed more on another device)
          final mergedLastLessonIndex = cloudLastLessonIndex > currentUser.lastLessonIndex 
              ? cloudLastLessonIndex : currentUser.lastLessonIndex;
          final mergedLastExerciseIndex = (cloudLastLessonIndex >= currentUser.lastLessonIndex)
              ? (cloudLastExerciseIndex > currentUser.lastExerciseIndex ? cloudLastExerciseIndex : currentUser.lastExerciseIndex)
              : currentUser.lastExerciseIndex;
          
          currentUser = currentUser.copyWith(
            completedExercises: mergedCompletedExercises,
            skippedExercises: mergedSkippedExercises,
            exerciseRepProgress: mergedRepProgress,
            lastLessonIndex: mergedLastLessonIndex,
            lastExerciseIndex: mergedLastExerciseIndex,
          );
          needsUpdate = true;
          debugPrint('✅ Merged exercise progress from cloud: ${mergedCompletedExercises.length} lessons, '
              '${mergedRepProgress.length} rep entries, position L$mergedLastLessonIndex/E$mergedLastExerciseIndex');
        }

        if (needsUpdate) {
          debugPrint('✅ User state updated from cloud');
        }
      }

      // Save and update state
      await DatabaseService.saveUser(currentUser);
      state = currentUser;
      
      // IMPORTANT: Invalidate org provider to refetch with new organizationId
      debugPrint('🔄 Invalidating currentOrgProvider to refetch org data');
      _ref.invalidate(currentOrgProvider);
      
      // Fetch typing sessions history from cloud
      try {
        final cloudSessionsData = await _cloudSync.fetchUserSessions();
        if (cloudSessionsData.isNotEmpty) {
          debugPrint('📜 Fetching ${cloudSessionsData.length} typing sessions from cloud');
          final cloudSessions = cloudSessionsData.map((data) {
            return TypingSession(
              wpm: (data['wpm'] as num).toDouble(),
              accuracy: (data['accuracy'] as num).toDouble(),
              lessonId: data['lessonId'] as String? ?? 'Practice',
              timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              typedText: data['typedText'] as String?,
            );
          }).toList();
          
          // Merge: Keep unique sessions by comparing timestamps
          final existingSessions = state?.typingSessions ?? [];
          final existingTimestamps = existingSessions.map((s) => s.timestamp.millisecondsSinceEpoch).toSet();
          
          // Add cloud sessions that don't exist locally
          final newSessions = cloudSessions.where((s) => 
            !existingTimestamps.contains(s.timestamp.millisecondsSinceEpoch)
          ).toList();
          
          if (newSessions.isNotEmpty || existingSessions.isEmpty) {
            final mergedSessions = [...existingSessions, ...newSessions];
            // Sort by timestamp descending (newest first)
            mergedSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            final updatedUserWithSessions = state!.copyWith(typingSessions: mergedSessions);
            await DatabaseService.saveUser(updatedUserWithSessions);
            state = updatedUserWithSessions;
            debugPrint('✅ Typing history synced: ${mergedSessions.length} total sessions (${newSessions.length} new from cloud)');
          }
        } else {
          debugPrint('ℹ️ No typing sessions found in cloud');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching typing sessions: $e');
      }

    } catch (e) {
      debugPrint('❌ _syncUserDataFromCloud error: $e');
    }
  }

  /// Initialize the notifier by loading the current user from storage
  Future<void> _initialize() async {
    UserModel? user = await DatabaseService.getCurrentUser();
    
    // CRITICAL FIX: On web, local storage may be empty/stale.
    // Wait for Firebase Auth to settle (it may not be ready immediately on web)
    User? authUser = FirebaseAuth.instance.currentUser;
    
    if (authUser == null && _connectivity.isOnline) {
      // Wait for auth state to settle (max 3 seconds)
      debugPrint('⏳ Waiting for Firebase Auth to settle...');
      try {
        authUser = await FirebaseAuth.instance.authStateChanges()
            .where((u) => u != null)
            .first
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
      } catch (e) {
        debugPrint('⚠️ Auth state timeout: $e');
      }
    }
    
    if (authUser != null && _connectivity.isOnline) {
      debugPrint('🔄 Firebase Auth user found: ${authUser.email}');
      
      try {
        final cloudData = await _cloudSync.fetchUser();
        if (cloudData != null) {
          // Extract critical fields from cloud
          final cloudOrgId = cloudData['profile']?['organizationId'] ?? cloudData['organizationId'];
          final cloudRoleStr = cloudData['profile']?['role'] ?? cloudData['role'];
          
          debugPrint('☁️ Cloud data: orgId=$cloudOrgId, role=$cloudRoleStr');
          
          // If we have cloud data but no local user, create from cloud
          if (user == null) {
            debugPrint('📥 No local user, creating from cloud data');
            user = UserModel(
              id: authUser.uid,
              name: cloudData['profile']?['name'] ?? authUser.displayName ?? 'User',
              email: authUser.email ?? '',
              organizationId: cloudOrgId,
              role: cloudRoleStr != null 
                ? UserRole.values.firstWhere((e) => e.name == cloudRoleStr, orElse: () => UserRole.student)
                : UserRole.student,
            );
          } else {
            // Update existing user with cloud org/role if different
            bool needsUpdate = false;
            UserModel updated = user;
            
            if (cloudOrgId != null && user.organizationId != cloudOrgId) {
              updated = updated.copyWith(organizationId: cloudOrgId);
              needsUpdate = true;
              debugPrint('🔄 Updating organizationId from cloud: $cloudOrgId');
            }
            
            if (cloudRoleStr != null) {
              final cloudRole = UserRole.values.firstWhere((e) => e.name == cloudRoleStr, orElse: () => UserRole.student);
              if (user.role != cloudRole) {
                updated = updated.copyWith(role: cloudRole);
                needsUpdate = true;
                debugPrint('🔄 Updating role from cloud: ${cloudRole.name}');
              }
            }
            
            if (needsUpdate) {
              user = updated;
              await DatabaseService.saveUser(user);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching cloud user data during init: $e');
      }
    } else if (user != null && authUser == null && _connectivity.isOnline) {
      // CRITICAL: We have local user but NO Firebase Auth session
      // This means the auth session has expired or was never established in this browser
      // Clear local state to force re-login
      debugPrint('⚠️ Local user found but Firebase Auth is null - clearing state for re-login');
      debugPrint('⚠️ User "${user.name}" needs to login again for cloud sync');
      
      // Clear the current user but keep them in saved users list for easy re-login
      await DatabaseService.clearCurrentUser();
      user = null;
      state = null;
      return; // Exit early - user needs to login
    }
    
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
      
      // CRITICAL: Force Fetch from Cloud FIRST to ensure Org/Role consistency (PULL FIX)
      // This must happen BEFORE pushing local data to avoid overwriting cloud data
      if (_connectivity.isOnline) {
        try {
          final cloudData = await _cloudSync.fetchUser();
          if (cloudData != null) {
            bool hasUpdates = false;
            UserModel syncedUser = state!;

            // Check Org ID
            String? cloudOrgId = cloudData['profile']?['organizationId'] ?? cloudData['organizationId'];
            if (cloudOrgId != null && syncedUser.organizationId != cloudOrgId) {
              syncedUser = syncedUser.copyWith(organizationId: cloudOrgId);
              hasUpdates = true;
              debugPrint('♻️ OrganizationId synced from cloud: $cloudOrgId');
            }

            // Check Role
            String? cloudRoleStr = cloudData['profile']?['role'] ?? cloudData['role'];
            if (cloudRoleStr != null) {
               final role = UserRole.values.firstWhere(
                (e) => e.name == cloudRoleStr,
                orElse: () => UserRole.student,
              );
              final isLegacyAdmin = AdminAuthService.legacyAdminEmails.contains(syncedUser.email.toLowerCase());
              final safeRole = (!isLegacyAdmin && role == UserRole.superAdmin) ? UserRole.student : role;
              if (syncedUser.role != safeRole) {
                syncedUser = syncedUser.copyWith(role: safeRole);
                hasUpdates = true;
                debugPrint('♻️ Role synced from cloud: ${safeRole.name}');
              }
            }

             if (hasUpdates) {
              await DatabaseService.saveUser(syncedUser);
              state = syncedUser;
              debugPrint('✅ Local user updated with latest Cloud data');
            }

            // Sync Typing Sessions History
            try {
              final cloudSessionsData = await _cloudSync.fetchUserSessions();
              if (cloudSessionsData.isNotEmpty) {
                 final cloudSessions = cloudSessionsData.map((data) {
                    return TypingSession(
                      wpm: (data['wpm'] as num).toDouble(),
                      accuracy: (data['accuracy'] as num).toDouble(),
                      lessonId: data['lessonId'] as String? ?? 'Practice',
                      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    );
                 }).toList();
                 
                 // Merge sessions (avoid duplicates based on timestamp/content match if needed, 
                 // but simpler to just replace or append if local is empty)
                 // For now, let's take Cloud as master for history if local is empty or to refresh
                 
                 final updatedUserWithSessions = state!.copyWith(typingSessions: cloudSessions);
                 await DatabaseService.saveUser(updatedUserWithSessions);
                 state = updatedUserWithSessions;
                 debugPrint('📜 Typing history synced: ${cloudSessions.length} sessions');
              }
            } catch (e) {
               debugPrint('⚠️ Error fetching sessions history: $e');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error force-fetching cloud data: $e');
        }
      }

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
            final isLegacyAdmin = AdminAuthService.legacyAdminEmails.contains(claimUser.email.toLowerCase());
            final safeRole = (!isLegacyAdmin && role == UserRole.superAdmin) ? UserRole.student : role;
            if (claimUser.role != safeRole) {
              claimUser = claimUser.copyWith(role: safeRole);
              claimsChanged = true;
              debugPrint('🔐 Role applied from Custom Claims: ${safeRole.name}');
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

      // 3. Now push local stats to cloud (AFTER pulling org/role from cloud)
      await _syncToCloud(state!);

      // 4. Setup real-time listener for Role/Org updates (Firestore)
      _setupRealtimeSync(finalUser.id);
    }
  }

  /// Force sync user data from cloud (called manually by user)
  Future<void> forceCloudSync() async {
    if (state == null) {
      debugPrint('⚠️ forceCloudSync: No user state');
      return;
    }
    
    if (!_connectivity.isOnline) {
      debugPrint('⚠️ forceCloudSync: Offline');
      return;
    }
    
    debugPrint('🔄 forceCloudSync: Starting manual sync...');
    
    try {
      final cloudData = await _cloudSync.fetchUser();
      if (cloudData != null) {
        final cloudOrgId = cloudData['organizationId'] ?? cloudData['profile']?['organizationId'];
        final cloudRoleStr = cloudData['profile']?['role'] ?? cloudData['role'];
        
        debugPrint('☁️ forceCloudSync: orgId=$cloudOrgId, role=$cloudRoleStr');
        
        bool needsUpdate = false;
        UserModel updated = state!;
        
        // Update organizationId
        if (cloudOrgId != null && cloudOrgId.toString().isNotEmpty && updated.organizationId != cloudOrgId) {
          updated = updated.copyWith(organizationId: cloudOrgId.toString());
          needsUpdate = true;
          debugPrint('✅ forceCloudSync: Updated organizationId to $cloudOrgId');
        }
        
        // Update role
        if (cloudRoleStr != null) {
          final cloudRole = UserRole.values.firstWhere(
            (e) => e.name == cloudRoleStr,
            orElse: () => UserRole.student,
          );
          if (updated.role != cloudRole) {
            updated = updated.copyWith(role: cloudRole);
            needsUpdate = true;
            debugPrint('✅ forceCloudSync: Updated role to ${cloudRole.name}');
          }
        }
        
        if (needsUpdate) {
          await DatabaseService.saveUser(updated);
          state = updated;
          debugPrint('✅ forceCloudSync: User state updated');
        } else {
          debugPrint('ℹ️ forceCloudSync: No changes needed');
        }
      } else {
        debugPrint('⚠️ forceCloudSync: No cloud data returned');
      }
    } catch (e) {
      debugPrint('❌ forceCloudSync error: $e');
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

          final isLegacyAdmin = AdminAuthService.legacyAdminEmails.contains(currentUser.email.toLowerCase());
          final safeRole = (!isLegacyAdmin && newRole == UserRole.superAdmin) ? UserRole.student : newRole;

          if (currentUser.role != safeRole) {
            currentUser = currentUser.copyWith(role: safeRole);
            hasChanges = true;
            debugPrint('⚡ Real-time ROLE update: ${safeRole.name}');
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

        // 3. Check for COMPLETED EXERCISES update
        final progress = data['progress'] as Map<String, dynamic>?;
        if (progress != null) {
          // Sync completedExercises
          final cloudCompletedExercises = progress['completedExercises'] as Map<String, dynamic>?;
          if (cloudCompletedExercises != null) {
            final Map<String, List<int>> parsedCompleted = {};
            cloudCompletedExercises.forEach((key, value) {
              if (value is List) {
                parsedCompleted[key] = List<int>.from(value.map((e) => e as int));
              }
            });
            // Merge: Cloud + Local (keep both, no data loss)
            final mergedCompleted = Map<String, List<int>>.from(currentUser.completedExercises);
            parsedCompleted.forEach((lesson, indices) {
              if (mergedCompleted.containsKey(lesson)) {
                mergedCompleted[lesson] = {...mergedCompleted[lesson]!, ...indices}.toList();
              } else {
                mergedCompleted[lesson] = indices;
              }
            });
            if (!_mapEquals(currentUser.completedExercises, mergedCompleted)) {
              currentUser = currentUser.copyWith(completedExercises: mergedCompleted);
              hasChanges = true;
              debugPrint('⚡ Real-time completedExercises synced');
            }
          }

          // Sync skippedExercises
          final cloudSkippedExercises = progress['skippedExercises'] as Map<String, dynamic>?;
          if (cloudSkippedExercises != null) {
            final Map<String, List<int>> parsedSkipped = {};
            cloudSkippedExercises.forEach((key, value) {
              if (value is List) {
                parsedSkipped[key] = List<int>.from(value.map((e) => e as int));
              }
            });
            // Merge: Cloud + Local
            final mergedSkipped = Map<String, List<int>>.from(currentUser.skippedExercises);
            parsedSkipped.forEach((lesson, indices) {
              if (mergedSkipped.containsKey(lesson)) {
                mergedSkipped[lesson] = {...mergedSkipped[lesson]!, ...indices}.toList();
              } else {
                mergedSkipped[lesson] = indices;
              }
            });
            if (!_mapEquals(currentUser.skippedExercises, mergedSkipped)) {
              currentUser = currentUser.copyWith(skippedExercises: mergedSkipped);
              hasChanges = true;
              debugPrint('⚡ Real-time skippedExercises synced');
            }
          }
          
          // Sync exerciseRepProgress (new!)
          final cloudRepProgress = progress['exerciseRepProgress'] as Map<String, dynamic>?;
          if (cloudRepProgress != null) {
            final Map<String, int> parsedRepProgress = {};
            cloudRepProgress.forEach((key, value) {
              if (value is int) {
                parsedRepProgress[key] = value;
              } else if (value is num) {
                parsedRepProgress[key] = value.toInt();
              }
            });
            // Merge: Take max reps (cloud vs local)
            final mergedRepProgress = Map<String, int>.from(currentUser.exerciseRepProgress);
            parsedRepProgress.forEach((key, cloudReps) {
              final localReps = mergedRepProgress[key] ?? 0;
              mergedRepProgress[key] = cloudReps > localReps ? cloudReps : localReps;
            });
            if (mergedRepProgress.toString() != currentUser.exerciseRepProgress.toString()) {
              currentUser = currentUser.copyWith(exerciseRepProgress: mergedRepProgress);
              hasChanges = true;
              debugPrint('⚡ Real-time exerciseRepProgress synced');
            }
          }
          
          // Sync last position (new!)
          final cloudLastLesson = progress['lastLessonIndex'] as int?;
          final cloudLastExercise = progress['lastExerciseIndex'] as int?;
          if (cloudLastLesson != null && cloudLastLesson != currentUser.lastLessonIndex) {
            currentUser = currentUser.copyWith(lastLessonIndex: cloudLastLesson);
            hasChanges = true;
            debugPrint('⚡ Real-time lastLessonIndex synced: $cloudLastLesson');
          }
          if (cloudLastExercise != null && cloudLastExercise != currentUser.lastExerciseIndex) {
            currentUser = currentUser.copyWith(lastExerciseIndex: cloudLastExercise);
            hasChanges = true;
            debugPrint('⚡ Real-time lastExerciseIndex synced: $cloudLastExercise');
          }
        }

        // 4. Apply changes if any
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

  /// Helper to compare exercise maps
  bool _mapEquals(Map<String, List<int>> a, Map<String, List<int>> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final listA = a[key]!..sort();
      final listB = b[key]!..sort();
      if (!listEquals(listA, listB)) return false;
    }
    return true;
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
    String? typedText,
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

    // Create new TypingSession with typedText
    final newSession = TypingSession(
      wpm: wpm,
      accuracy: accuracy,
      lessonId: completedLesson ?? 'Practice', // Use 'Practice' if null
      timestamp: DateTime.now(),
      typedText: typedText,
    );

    final newTypingSessions = List<TypingSession>.from(state!.typingSessions)
      ..add(newSession);

    // Create updated user with new stats and history
    final updatedUser = state!.copyWith(
      wpmHistory: newWpmHistory,
      accuracyHistory: newAccuracyHistory,
      highestWpm: newHighestWpm,
      completedLessons: newCompletedLessons,
      typingSessions: newTypingSessions,
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
      // Online: Direct upload with typedText
      await _cloudSync.syncTypingSession(
        wpm: wpm,
        accuracy: accuracy,
        lessonId: completedLesson,
        typedText: typedText,
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
          'typedText': typedText,
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

  /// Mark exercises as skipped when user jumps to a later exercise
  Future<void> markExercisesSkipped(String lessonTitle, List<int> exerciseIndices) async {
     if (state == null) return;
     
     UserModel updatedUser = state!;
     for (final index in exerciseIndices) {
       // Only mark as skipped if not already completed
       if (!updatedUser.isExerciseCompleted(lessonTitle, index)) {
         updatedUser = updatedUser.markExerciseSkipped(lessonTitle, index);
       }
     }
     
     state = updatedUser;
     await DatabaseService.saveUser(updatedUser);

     // Sync to cloud
     if (_connectivity.isOnline) {
       _cloudSync.syncUser(updatedUser); 
     }
  }

  /// Update exercise rep progress (how many reps completed for an exercise)
  Future<void> updateExerciseRepProgress(int lessonIndex, int exerciseIndex, int repsCompleted) async {
    if (state == null) return;
    
    final updatedUser = state!.updateExerciseRepProgress(lessonIndex, exerciseIndex, repsCompleted);
    state = updatedUser;
    await DatabaseService.saveUser(updatedUser);
    
    debugPrint('💾 Rep progress saved: Lesson $lessonIndex, Exercise $exerciseIndex, Reps: $repsCompleted');
    
    // Sync to cloud
    if (_connectivity.isOnline) {
      _cloudSync.syncUser(updatedUser);
    }
  }

  /// Update last position (lesson and exercise) for resume functionality
  Future<void> updateLastPosition(int lessonIndex, int exerciseIndex) async {
    if (state == null) return;
    
    final updatedUser = state!.updateLastPosition(lessonIndex, exerciseIndex);
    state = updatedUser;
    await DatabaseService.saveUser(updatedUser);
    
    debugPrint('📍 Last position saved: Lesson $lessonIndex, Exercise $exerciseIndex');
    
    // Sync to cloud
    if (_connectivity.isOnline) {
      _cloudSync.syncUser(updatedUser);
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
  /// NOTE: This also syncs role from cloud IF the user matches Firebase Auth user
  Future<void> switchToUser(UserModel user) async {
    await DatabaseService.setCurrentUser(user);
    state = user;
    debugPrint('🔄 Switched to user: ${user.name} (${user.email})');
    
    // Check if Firebase Auth user matches the user we're switching to
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final bool isFirebaseAuthenticated = firebaseUser != null;
    final bool isMatchingUser = firebaseUser?.uid == user.id;
    
    if (!isFirebaseAuthenticated) {
      debugPrint('⚠️ No Firebase Auth user - using local data only. User should re-login for full sync.');
      // Just invalidate org provider to use whatever data we have
      _ref.invalidate(currentOrgProvider);
      return;
    }
    
    if (!isMatchingUser) {
      debugPrint('⚠️ Firebase Auth user (${firebaseUser.email}) does not match switched user (${user.email})');
      debugPrint('⚠️ Cloud sync skipped. User should logout and login with ${user.email} for full sync.');
      _ref.invalidate(currentOrgProvider);
      return;
    }
    
    // Firebase user matches - proceed with cloud sync
    debugPrint('✅ Firebase user matches - syncing from cloud');
    
    if (_connectivity.isOnline) {
      try {
        // Use fetchUser (which uses Firebase UID) since we know they match
        final cloudData = await _cloudSync.fetchUser();
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
          
          // Invalidate org provider to refetch with updated orgId
          _ref.invalidate(currentOrgProvider);
        } else {
          debugPrint('⚠️ No cloud data found for user: ${user.email}');
        }
      } catch (e) {
        debugPrint('⚠️ Error syncing from cloud during user switch: $e');
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
    String? typedText,
  }) {
    return addTypingStats(
      wpm: wpm,
      accuracy: accuracy,
      completedLesson: completedLesson,
      additionalXp: earnedXp,
      typedText: typedText,
    );
  }
}

