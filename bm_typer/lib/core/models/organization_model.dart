import 'package:cloud_firestore/cloud_firestore.dart';

/// Organization model for team/company management
class OrganizationModel {
  final String id;
  final String name;
  final String adminEmail;
  final String? adminUserId;
  final int memberCount;
  final int maxMembers;
  final String subscriptionType; // 'team_monthly', 'team_yearly', 'enterprise'
  final DateTime? expiryDate;
  final DateTime createdAt;
  final bool isActive;
  final String? logoUrl;
  final String? address;
  final String? phone;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.adminEmail,
    this.adminUserId,
    this.memberCount = 0,
    this.maxMembers = 10,
    this.subscriptionType = 'team_monthly',
    this.expiryDate,
    required this.createdAt,
    this.isActive = true,
    this.logoUrl,
    this.address,
    this.phone,
  });

  /// Check if organization subscription is valid
  bool get isValid {
    if (!isActive) return false;
    if (expiryDate == null) return true;
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Get remaining days
  int get remainingDays {
    if (expiryDate == null) return -1;
    final now = DateTime.now();
    if (now.isAfter(expiryDate!)) return 0;
    return expiryDate!.difference(now).inDays;
  }

  /// Check if can add more members
  bool get canAddMembers => memberCount < maxMembers;

  /// Get subscription display name
  static String getSubscriptionName(String type) {
    switch (type) {
      case 'team_monthly':
        return 'টিম মাসিক';
      case 'team_yearly':
        return 'টিম বার্ষিক';
      case 'enterprise':
        return 'এন্টারপ্রাইজ';
      default:
        return 'অজানা';
    }
  }

  /// Get price per member
  static int getPricePerMember(String type) {
    switch (type) {
      case 'team_monthly':
        return 79; // BDT per member per month
      case 'team_yearly':
        return 599; // BDT per member per year
      case 'enterprise':
        return 0; // Custom pricing
      default:
        return 0;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'adminEmail': adminEmail,
        'adminUserId': adminUserId,
        'memberCount': memberCount,
        'maxMembers': maxMembers,
        'subscriptionType': subscriptionType,
        'expiryDate': expiryDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        'logoUrl': logoUrl,
        'address': address,
        'phone': phone,
      };

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      adminEmail: json['adminEmail'] as String? ?? '',
      adminUserId: json['adminUserId'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
      maxMembers: json['maxMembers'] as int? ?? 10,
      subscriptionType: json['subscriptionType'] as String? ?? 'team_monthly',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      logoUrl: json['logoUrl'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );
  }

  factory OrganizationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrganizationModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  OrganizationModel copyWith({
    String? name,
    String? adminEmail,
    String? adminUserId,
    int? memberCount,
    int? maxMembers,
    String? subscriptionType,
    DateTime? expiryDate,
    bool? isActive,
    String? logoUrl,
    String? address,
    String? phone,
  }) {
    return OrganizationModel(
      id: id,
      name: name ?? this.name,
      adminEmail: adminEmail ?? this.adminEmail,
      adminUserId: adminUserId ?? this.adminUserId,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }
}

/// Organization member model
class OrgMemberModel {
  final String id;
  final String userId;
  final String email;
  final String name;
  final String role; // 'admin', 'member'
  final DateTime joinedAt;
  final bool isActive;

  OrgMemberModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.name,
    this.role = 'member',
    required this.joinedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'email': email,
        'name': name,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
        'isActive': isActive,
      };

  factory OrgMemberModel.fromJson(Map<String, dynamic> json) {
    return OrgMemberModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  factory OrgMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrgMemberModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }
}
