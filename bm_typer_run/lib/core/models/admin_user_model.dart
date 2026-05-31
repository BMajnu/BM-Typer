import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin role levels with hierarchical permissions
enum AdminRole {
  /// Hidden developer role with full access
  developer,
  
  /// Super admin - can manage all users, orgs, subscriptions, version control
  superAdmin,
  
  /// Organization admin - can manage own organization members
  orgAdmin,
  
  /// Team lead - can view team members' progress
  teamLead,
}

/// Extension methods for AdminRole
extension AdminRoleExtension on AdminRole {
  /// Get display name in Bengali
  String get displayName {
    switch (this) {
      case AdminRole.developer:
        return 'ডেভেলপার';
      case AdminRole.superAdmin:
        return 'সুপার অ্যাডমিন';
      case AdminRole.orgAdmin:
        return 'প্রতিষ্ঠান অ্যাডমিন';
      case AdminRole.teamLead:
        return 'টিম লিড';
    }
  }

  /// Get role priority (higher = more permissions)
  int get priority {
    switch (this) {
      case AdminRole.developer:
        return 100;
      case AdminRole.superAdmin:
        return 80;
      case AdminRole.orgAdmin:
        return 50;
      case AdminRole.teamLead:
        return 30;
    }
  }

  /// Check if this role can access a feature
  bool canAccess(AdminPermission permission) {
    return _rolePermissions[this]?.contains(permission) ?? false;
  }
}

/// Admin permissions for feature access control
enum AdminPermission {
  // Dashboard
  viewDashboard,
  
  // User Management
  viewUsers,
  editUsers,
  banUsers,
  deleteUsers,
  
  // Subscription Management
  viewSubscriptions,
  grantSubscriptions,
  revokeSubscriptions,
  
  // Organization Management
  viewOrganizations,
  createOrganizations,
  editOrganizations,
  deleteOrganizations,
  manageOwnOrgOnly,
  
  // Notifications
  viewNotifications,
  sendNotifications,
  
  // App Config
  viewAppConfig,
  editAppConfig,
  
  // Developer Tools
  accessDevTools,
  impersonateUsers,
  queryDatabase,
  manageFeatureFlags,
  
  // Analytics
  viewAnalytics,
  viewAdvancedAnalytics,
  
  // Settings
  viewSettings,
  editSettings,
}

/// Permission mapping for each role
const Map<AdminRole, Set<AdminPermission>> _rolePermissions = {
  AdminRole.developer: {
    // All permissions
    AdminPermission.viewDashboard,
    AdminPermission.viewUsers,
    AdminPermission.editUsers,
    AdminPermission.banUsers,
    AdminPermission.deleteUsers,
    AdminPermission.viewSubscriptions,
    AdminPermission.grantSubscriptions,
    AdminPermission.revokeSubscriptions,
    AdminPermission.viewOrganizations,
    AdminPermission.createOrganizations,
    AdminPermission.editOrganizations,
    AdminPermission.deleteOrganizations,
    AdminPermission.viewNotifications,
    AdminPermission.sendNotifications,
    AdminPermission.viewAppConfig,
    AdminPermission.editAppConfig,
    AdminPermission.accessDevTools,
    AdminPermission.impersonateUsers,
    AdminPermission.queryDatabase,
    AdminPermission.manageFeatureFlags,
    AdminPermission.viewAnalytics,
    AdminPermission.viewAdvancedAnalytics,
    AdminPermission.viewSettings,
    AdminPermission.editSettings,
  },
  
  AdminRole.superAdmin: {
    AdminPermission.viewDashboard,
    AdminPermission.viewUsers,
    AdminPermission.editUsers,
    AdminPermission.banUsers,
    AdminPermission.viewSubscriptions,
    AdminPermission.grantSubscriptions,
    AdminPermission.revokeSubscriptions,
    AdminPermission.viewOrganizations,
    AdminPermission.createOrganizations,
    AdminPermission.editOrganizations,
    AdminPermission.viewNotifications,
    AdminPermission.sendNotifications,
    AdminPermission.viewAppConfig,
    AdminPermission.editAppConfig,
    AdminPermission.viewAnalytics,
    AdminPermission.viewSettings,
    AdminPermission.editSettings,
  },
  
  AdminRole.orgAdmin: {
    AdminPermission.viewDashboard,
    AdminPermission.viewUsers,
    AdminPermission.viewOrganizations,
    AdminPermission.editOrganizations,
    AdminPermission.manageOwnOrgOnly,
    AdminPermission.viewAnalytics,
    AdminPermission.viewSettings,
  },
  
  AdminRole.teamLead: {
    AdminPermission.viewDashboard,
    AdminPermission.viewUsers,
    AdminPermission.viewAnalytics,
    AdminPermission.viewSettings,
  },
};

/// Admin user model for role-based access control
class AdminUser {
  final String id;
  final String email;
  final AdminRole role;
  final String? organizationId; // For orgAdmin/teamLead
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    this.organizationId,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  /// Check if user has a specific permission
  bool hasPermission(AdminPermission permission) {
    if (!isActive) return false;
    return role.canAccess(permission);
  }

  /// Check if user can manage a specific organization
  bool canManageOrganization(String orgId) {
    if (role == AdminRole.developer || role == AdminRole.superAdmin) {
      return true;
    }
    if (role == AdminRole.orgAdmin && organizationId == orgId) {
      return true;
    }
    return false;
  }

  /// Create from Firestore document
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      email: data['email'] ?? '',
      role: _parseRole(data['role']),
      organizationId: data['organizationId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role.name,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
    };
  }

  /// Copy with updates
  AdminUser copyWith({
    String? id,
    String? email,
    AdminRole? role,
    String? organizationId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Parse role string to enum
AdminRole _parseRole(dynamic roleValue) {
  if (roleValue == null) return AdminRole.teamLead;
  
  final roleStr = roleValue.toString().toLowerCase();
  
  switch (roleStr) {
    case 'developer':
      return AdminRole.developer;
    case 'superadmin':
    case 'super_admin':
      return AdminRole.superAdmin;
    case 'orgadmin':
    case 'org_admin':
      return AdminRole.orgAdmin;
    case 'teamlead':
    case 'team_lead':
      return AdminRole.teamLead;
    default:
      return AdminRole.teamLead;
  }
}
