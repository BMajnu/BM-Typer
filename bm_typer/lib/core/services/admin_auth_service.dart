import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bm_typer/core/models/admin_user_model.dart';

/// Service for handling admin authentication
/// Provides secondary PIN-based verification for admin dashboard access
class AdminAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Legacy admin emails list (for backward compatibility)
  // New system uses admin_users collection in Firestore
  static const List<String> legacyAdminEmails = [
    'badiuzzamanmajnu786@gmail.com',
  ];
  
  /// Check if an email is in the admin list (legacy or Firestore)
  bool isAdminEmail(String? email) {
    if (email == null) return false;
    return legacyAdminEmails.contains(email.toLowerCase());
  }
  
  /// Get admin user from Firestore by email
  Future<AdminUser?> getAdminUser(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: email.toLowerCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // Fallback: Check legacy admin emails and create temporary admin
        if (legacyAdminEmails.contains(email.toLowerCase())) {
          return AdminUser(
            id: 'legacy_${email.hashCode}',
            email: email.toLowerCase(),
            role: AdminRole.developer, // Legacy admins get developer role
            createdAt: DateTime.now(),
            isActive: true,
          );
        }
        return null;
      }
      
      return AdminUser.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Error fetching admin user: $e');
      // Fallback for legacy admin
      if (legacyAdminEmails.contains(email.toLowerCase())) {
        return AdminUser(
          id: 'legacy_${email.hashCode}',
          email: email.toLowerCase(),
          role: AdminRole.developer,
          createdAt: DateTime.now(),
          isActive: true,
        );
      }
      return null;
    }
  }
  
  /// Create or update admin user in Firestore
  Future<bool> createAdminUser(AdminUser adminUser) async {
    try {
      await _firestore
          .collection('admin_users')
          .doc(adminUser.id)
          .set(adminUser.toFirestore(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('❌ Error creating admin user: $e');
      return false;
    }
  }
  
  /// Update admin user role
  Future<bool> updateAdminRole(String adminId, AdminRole newRole) async {
    try {
      await _firestore.collection('admin_users').doc(adminId).update({
        'role': newRole.name,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error updating admin role: $e');
      return false;
    }
  }
  
  /// Get all admin users
  Future<List<AdminUser>> getAllAdminUsers() async {
    try {
      final snapshot = await _firestore.collection('admin_users').get();
      return snapshot.docs.map((doc) => AdminUser.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching admin users: $e');
      return [];
    }
  }
  
  /// Hash a PIN for secure storage/comparison
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify admin PIN against stored hash
  Future<bool> verifyPin(String pin) async {
    try {
      final doc = await _firestore.collection('admin_config').doc('auth').get();
      
      if (!doc.exists) {
        // If no config exists, create default (PIN: 123456)
        final defaultHash = _hashPin('123456');
        await _firestore.collection('admin_config').doc('auth').set({
          'pinHash': defaultHash,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return pin == '123456';
      }
      
      final storedHash = doc.data()?['pinHash'] as String?;
      if (storedHash == null) return false;
      
      return _hashPin(pin) == storedHash;
    } catch (e) {
      // If Firestore fails, allow default PIN for development
      return pin == '123456';
    }
  }
  
  /// Update admin PIN
  Future<bool> updatePin(String currentPin, String newPin) async {
    try {
      // Verify current PIN first
      final isValid = await verifyPin(currentPin);
      if (!isValid) return false;
      
      // Update to new PIN
      await _firestore.collection('admin_config').doc('auth').update({
        'pinHash': _hashPin(newPin),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get session timeout duration (in minutes)
  Future<int> getSessionTimeout() async {
    try {
      final doc = await _firestore.collection('admin_config').doc('auth').get();
      return doc.data()?['sessionTimeoutMinutes'] as int? ?? 30;
    } catch (e) {
      return 30; // Default 30 minutes
    }
  }
}

/// Admin session state with role information
class AdminSessionState {
  final bool isAuthenticated;
  final DateTime? authenticatedAt;
  final int sessionTimeoutMinutes;
  final AdminUser? adminUser;
  
  const AdminSessionState({
    this.isAuthenticated = false,
    this.authenticatedAt,
    this.sessionTimeoutMinutes = 30,
    this.adminUser,
  });
  
  bool get isSessionValid {
    if (!isAuthenticated || authenticatedAt == null) return false;
    final elapsed = DateTime.now().difference(authenticatedAt!);
    return elapsed.inMinutes < sessionTimeoutMinutes;
  }
  
  /// Check if current admin has a specific permission
  bool hasPermission(AdminPermission permission) {
    return adminUser?.hasPermission(permission) ?? false;
  }
  
  /// Get current admin role
  AdminRole? get role => adminUser?.role;
  
  AdminSessionState copyWith({
    bool? isAuthenticated,
    DateTime? authenticatedAt,
    int? sessionTimeoutMinutes,
    AdminUser? adminUser,
  }) {
    return AdminSessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      adminUser: adminUser ?? this.adminUser,
    );
  }
}

/// Provider for AdminAuthService
final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService();
});

/// State notifier for admin session
class AdminSessionNotifier extends StateNotifier<AdminSessionState> {
  final AdminAuthService _authService;
  
  AdminSessionNotifier(this._authService) : super(const AdminSessionState());
  
  /// Attempt to authenticate with PIN and load admin user
  Future<bool> authenticate(String pin, {String? email}) async {
    final isValid = await _authService.verifyPin(pin);
    
    if (isValid) {
      final timeout = await _authService.getSessionTimeout();
      
      // Try to load admin user if email provided
      AdminUser? adminUser;
      if (email != null) {
        adminUser = await _authService.getAdminUser(email);
      }
      
      state = AdminSessionState(
        isAuthenticated: true,
        authenticatedAt: DateTime.now(),
        sessionTimeoutMinutes: timeout,
        adminUser: adminUser,
      );
      return true;
    }
    
    return false;
  }
  
  /// Set admin user after authentication
  Future<void> setAdminUser(String email) async {
    final adminUser = await _authService.getAdminUser(email);
    if (adminUser != null) {
      state = state.copyWith(adminUser: adminUser);
    }
  }
  
  /// Log out of admin session
  void logout() {
    state = const AdminSessionState();
  }
  
  /// Check if session is still valid
  bool checkSession() {
    if (!state.isSessionValid) {
      state = const AdminSessionState();
      return false;
    }
    return true;
  }
  
  /// Check if current admin has permission
  bool hasPermission(AdminPermission permission) {
    return state.hasPermission(permission);
  }
}

/// Provider for admin session state
final adminSessionProvider = StateNotifierProvider<AdminSessionNotifier, AdminSessionState>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return AdminSessionNotifier(authService);
});
