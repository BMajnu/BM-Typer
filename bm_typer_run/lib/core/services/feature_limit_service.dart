import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Feature limits for free users
class FeatureLimits {
  /// Maximum lessons accessible for free users
  static const int maxFreeLessons = 5;
  
  /// Maximum daily practice time in minutes for free users
  static const int maxDailyPracticeMinutes = 10;
  
  /// Maximum typing tests per day for free users
  static const int maxDailyTests = 3;
  
  /// Whether free users can access achievements
  static const bool freeAchievementsEnabled = false;
  
  /// Whether free users can submit to leaderboard
  static const bool freeLeaderboardSubmission = false;
  
  /// Whether free users can use TTS
  static const bool freeTTSEnabled = true; // Limited
  
  /// Maximum TTS uses per day for free users
  static const int maxDailyTTSUses = 5;
}

/// Daily usage tracking
class DailyUsage {
  final DateTime date;
  final int practiceMinutes;
  final int testsCompleted;
  final int ttsUses;
  final List<String> accessedLessons;

  DailyUsage({
    required this.date,
    this.practiceMinutes = 0,
    this.testsCompleted = 0,
    this.ttsUses = 0,
    this.accessedLessons = const [],
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      date: json['date'] is Timestamp 
          ? (json['date'] as Timestamp).toDate() 
          : DateTime.parse(json['date'].toString()),
      practiceMinutes: json['practiceMinutes'] ?? 0,
      testsCompleted: json['testsCompleted'] ?? 0,
      ttsUses: json['ttsUses'] ?? 0,
      accessedLessons: List<String>.from(json['accessedLessons'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'practiceMinutes': practiceMinutes,
      'testsCompleted': testsCompleted,
      'ttsUses': ttsUses,
      'accessedLessons': accessedLessons,
    };
  }

  DailyUsage copyWith({
    DateTime? date,
    int? practiceMinutes,
    int? testsCompleted,
    int? ttsUses,
    List<String>? accessedLessons,
  }) {
    return DailyUsage(
      date: date ?? this.date,
      practiceMinutes: practiceMinutes ?? this.practiceMinutes,
      testsCompleted: testsCompleted ?? this.testsCompleted,
      ttsUses: ttsUses ?? this.ttsUses,
      accessedLessons: accessedLessons ?? this.accessedLessons,
    );
  }
}

/// Feature limit check result
class LimitCheckResult {
  final bool allowed;
  final String? reason;
  final int? currentValue;
  final int? maxValue;

  const LimitCheckResult({
    required this.allowed,
    this.reason,
    this.currentValue,
    this.maxValue,
  });

  static const allowed_ = LimitCheckResult(allowed: true);
}

/// Service to manage feature limits for free users
class FeatureLimitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _hiveBoxName = 'feature_limits';
  
  Box? _box;

  /// Initialize the service
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_hiveBoxName);
    } catch (e) {
      debugPrint('❌ FeatureLimitService init error: $e');
    }
  }

  /// Get today's date key (YYYY-MM-DD)
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get today's usage from local storage
  DailyUsage _getTodayUsage() {
    final key = _getTodayKey();
    final data = _box?.get(key);
    
    if (data == null) {
      return DailyUsage(date: DateTime.now());
    }
    
    try {
      return DailyUsage.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return DailyUsage(date: DateTime.now());
    }
  }

  /// Save today's usage to local storage
  Future<void> _saveTodayUsage(DailyUsage usage) async {
    final key = _getTodayKey();
    await _box?.put(key, usage.toJson());
  }

  /// Check if user is premium
  Future<bool> isPremiumUser(String? userId) async {
    if (userId == null) return false;
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      
      final data = doc.data();
      return data?['isPremium'] ?? false;
    } catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Check if lesson access is allowed
  LimitCheckResult canAccessLesson(int lessonNumber, bool isPremium) {
    if (isPremium) {
      return LimitCheckResult.allowed_;
    }
    
    if (lessonNumber > FeatureLimits.maxFreeLessons) {
      return LimitCheckResult(
        allowed: false,
        reason: 'ফ্রি ভার্সনে সর্বোচ্চ ${FeatureLimits.maxFreeLessons}টি লেসন অ্যাক্সেস করা যায়।\nপ্রিমিয়ামে আপগ্রেড করুন সব লেসন আনলক করতে।',
        currentValue: lessonNumber,
        maxValue: FeatureLimits.maxFreeLessons,
      );
    }
    
    return LimitCheckResult.allowed_;
  }

  /// Check if daily practice time is available
  LimitCheckResult canPractice(bool isPremium) {
    if (isPremium) {
      return LimitCheckResult.allowed_;
    }
    
    final usage = _getTodayUsage();
    
    if (usage.practiceMinutes >= FeatureLimits.maxDailyPracticeMinutes) {
      return LimitCheckResult(
        allowed: false,
        reason: 'আজকের দৈনিক ${FeatureLimits.maxDailyPracticeMinutes} মিনিট প্র্যাক্টিস শেষ।\nকাল আবার প্র্যাক্টিস করুন অথবা প্রিমিয়ামে আপগ্রেড করুন।',
        currentValue: usage.practiceMinutes,
        maxValue: FeatureLimits.maxDailyPracticeMinutes,
      );
    }
    
    return LimitCheckResult(
      allowed: true,
      currentValue: usage.practiceMinutes,
      maxValue: FeatureLimits.maxDailyPracticeMinutes,
    );
  }

  /// Check if typing test is allowed
  LimitCheckResult canTakeTest(bool isPremium) {
    if (isPremium) {
      return LimitCheckResult.allowed_;
    }
    
    final usage = _getTodayUsage();
    
    if (usage.testsCompleted >= FeatureLimits.maxDailyTests) {
      return LimitCheckResult(
        allowed: false,
        reason: 'আজকের দৈনিক ${FeatureLimits.maxDailyTests}টি টেস্ট শেষ।\nকাল আবার টেস্ট দিন অথবা প্রিমিয়ামে আপগ্রেড করুন।',
        currentValue: usage.testsCompleted,
        maxValue: FeatureLimits.maxDailyTests,
      );
    }
    
    return LimitCheckResult(
      allowed: true,
      currentValue: usage.testsCompleted,
      maxValue: FeatureLimits.maxDailyTests,
    );
  }

  /// Check if TTS is allowed
  LimitCheckResult canUseTTS(bool isPremium) {
    if (isPremium) {
      return LimitCheckResult.allowed_;
    }
    
    if (!FeatureLimits.freeTTSEnabled) {
      return const LimitCheckResult(
        allowed: false,
        reason: 'TTS ফিচার শুধুমাত্র প্রিমিয়াম ইউজারদের জন্য।',
      );
    }
    
    final usage = _getTodayUsage();
    
    if (usage.ttsUses >= FeatureLimits.maxDailyTTSUses) {
      return LimitCheckResult(
        allowed: false,
        reason: 'আজকের দৈনিক ${FeatureLimits.maxDailyTTSUses}টি TTS ব্যবহার শেষ।',
        currentValue: usage.ttsUses,
        maxValue: FeatureLimits.maxDailyTTSUses,
      );
    }
    
    return LimitCheckResult(
      allowed: true,
      currentValue: usage.ttsUses,
      maxValue: FeatureLimits.maxDailyTTSUses,
    );
  }

  /// Check if achievements are accessible
  LimitCheckResult canAccessAchievements(bool isPremium) {
    if (isPremium || FeatureLimits.freeAchievementsEnabled) {
      return LimitCheckResult.allowed_;
    }
    
    return const LimitCheckResult(
      allowed: false,
      reason: 'অ্যাচিভমেন্ট ফিচার শুধুমাত্র প্রিমিয়াম ইউজারদের জন্য।',
    );
  }

  /// Check if leaderboard submission is allowed
  LimitCheckResult canSubmitToLeaderboard(bool isPremium) {
    if (isPremium || FeatureLimits.freeLeaderboardSubmission) {
      return LimitCheckResult.allowed_;
    }
    
    return const LimitCheckResult(
      allowed: false,
      reason: 'লিডারবোর্ডে জমা দেওয়া শুধুমাত্র প্রিমিয়াম ইউজারদের জন্য।',
    );
  }

  /// Record practice time
  Future<void> recordPracticeTime(int minutes) async {
    final usage = _getTodayUsage();
    await _saveTodayUsage(usage.copyWith(
      practiceMinutes: usage.practiceMinutes + minutes,
    ));
  }

  /// Record test completion
  Future<void> recordTestCompleted() async {
    final usage = _getTodayUsage();
    await _saveTodayUsage(usage.copyWith(
      testsCompleted: usage.testsCompleted + 1,
    ));
  }

  /// Record TTS usage
  Future<void> recordTTSUse() async {
    final usage = _getTodayUsage();
    await _saveTodayUsage(usage.copyWith(
      ttsUses: usage.ttsUses + 1,
    ));
  }

  /// Get remaining practice minutes for today
  int getRemainingPracticeMinutes(bool isPremium) {
    if (isPremium) return 999; // Unlimited
    
    final usage = _getTodayUsage();
    return (FeatureLimits.maxDailyPracticeMinutes - usage.practiceMinutes).clamp(0, FeatureLimits.maxDailyPracticeMinutes);
  }

  /// Get remaining tests for today
  int getRemainingTests(bool isPremium) {
    if (isPremium) return 999;
    
    final usage = _getTodayUsage();
    return (FeatureLimits.maxDailyTests - usage.testsCompleted).clamp(0, FeatureLimits.maxDailyTests);
  }

  /// Clean up old data (keep only last 7 days)
  Future<void> cleanupOldData() async {
    if (_box == null) return;
    
    final now = DateTime.now();
    final keysToDelete = <String>[];
    
    for (final key in _box!.keys) {
      try {
        final date = DateTime.parse(key.toString());
        if (now.difference(date).inDays > 7) {
          keysToDelete.add(key.toString());
        }
      } catch (_) {}
    }
    
    for (final key in keysToDelete) {
      await _box!.delete(key);
    }
  }
}

/// Provider for FeatureLimitService
final featureLimitServiceProvider = Provider<FeatureLimitService>((ref) {
  final service = FeatureLimitService();
  service.init();
  return service;
});

/// Provider for premium status
final isPremiumProvider = FutureProvider.family<bool, String?>((ref, userId) async {
  final service = ref.watch(featureLimitServiceProvider);
  return service.isPremiumUser(userId);
});
