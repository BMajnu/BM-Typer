import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

/// Subscription plan types
enum SubscriptionType {
  free,
  monthly,
  quarterly,
  halfYearly,
  yearly,
}

/// Subscription model for user subscriptions
@HiveType(typeId: 11)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String type; // 'free', 'monthly', 'quarterly', 'half_yearly', 'yearly'

  @HiveField(3)
  final DateTime? startDate;

  @HiveField(4)
  final DateTime? endDate;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final List<String> features;

  @HiveField(7)
  final DateTime? createdAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.type,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.features = const [],
    this.createdAt,
  });

  SubscriptionType get subscriptionType {
    switch (type) {
      case 'monthly':
        return SubscriptionType.monthly;
      case 'quarterly':
        return SubscriptionType.quarterly;
      case 'half_yearly':
        return SubscriptionType.halfYearly;
      case 'yearly':
        return SubscriptionType.yearly;
      default:
        return SubscriptionType.free;
    }
  }

  /// Check if subscription is currently valid
  bool get isValid {
    if (type == 'free') return true;
    if (!isActive) return false;
    if (endDate == null) return false;
    return DateTime.now().isBefore(endDate!);
  }

  /// Get remaining days
  int get remainingDays {
    if (endDate == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  /// Get subscription price in BDT
  static int getPrice(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return 0;
      case SubscriptionType.monthly:
        return 99;
      case SubscriptionType.quarterly:
        return 249;
      case SubscriptionType.halfYearly:
        return 449;
      case SubscriptionType.yearly:
        return 799;
    }
  }

  /// Get subscription duration in days
  static int getDurationDays(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return -1; // Unlimited
      case SubscriptionType.monthly:
        return 30;
      case SubscriptionType.quarterly:
        return 90;
      case SubscriptionType.halfYearly:
        return 180;
      case SubscriptionType.yearly:
        return 365;
    }
  }

  /// Get subscription display name in Bengali
  static String getDisplayName(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return 'ফ্রি';
      case SubscriptionType.monthly:
        return 'মাসিক';
      case SubscriptionType.quarterly:
        return '৩ মাস';
      case SubscriptionType.halfYearly:
        return '৬ মাস';
      case SubscriptionType.yearly:
        return 'বার্ষিক';
    }
  }

  /// Get XP boost percentage
  static int getXpBoost(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return 0;
      case SubscriptionType.monthly:
      case SubscriptionType.quarterly:
        return 0;
      case SubscriptionType.halfYearly:
        return 10;
      case SubscriptionType.yearly:
        return 20;
    }
  }

  SubscriptionModel copyWith({
    String? userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<String>? features,
  }) {
    return SubscriptionModel(
      id: id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      features: features ?? this.features,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
        'features': features,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? false,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Create a free subscription
  factory SubscriptionModel.free(String userId) {
    return SubscriptionModel(
      id: 'free_$userId',
      userId: userId,
      type: 'free',
      isActive: true,
      features: ['basic_lessons', 'limited_practice'],
      createdAt: DateTime.now(),
    );
  }
}

/// Free tier limitations
class FreeFeatureLimits {
  static const int maxLessons = 5;
  static const int dailyPracticeMinutes = 10;
  static const bool hasAchievements = false;
  static const bool canSubmitLeaderboard = false;
  static const bool hasTTS = false;
}

/// Premium features available
class PremiumFeatures {
  static const List<String> all = [
    'unlimited_lessons',
    'unlimited_practice',
    'achievements',
    'leaderboard',
    'tts',
    'detailed_stats',
    'export_data',
    'priority_support',
  ];
}
