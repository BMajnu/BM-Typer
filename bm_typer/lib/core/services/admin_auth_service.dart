import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling admin authentication
/// Provides secondary PIN-based verification for admin dashboard access
class AdminAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Admin emails list (should match AdminDashboardScreen)
  static const List<String> adminEmails = [
    'badiuzzamanmajnu786@gmail.com',
    // Add more admin emails as needed
  ];
  
  /// Check if an email is in the admin list
  bool isAdminEmail(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.toLowerCase());
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

/// Admin session state
class AdminSessionState {
  final bool isAuthenticated;
  final DateTime? authenticatedAt;
  final int sessionTimeoutMinutes;
  
  const AdminSessionState({
    this.isAuthenticated = false,
    this.authenticatedAt,
    this.sessionTimeoutMinutes = 30,
  });
  
  bool get isSessionValid {
    if (!isAuthenticated || authenticatedAt == null) return false;
    final elapsed = DateTime.now().difference(authenticatedAt!);
    return elapsed.inMinutes < sessionTimeoutMinutes;
  }
  
  AdminSessionState copyWith({
    bool? isAuthenticated,
    DateTime? authenticatedAt,
    int? sessionTimeoutMinutes,
  }) {
    return AdminSessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
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
  
  /// Attempt to authenticate with PIN
  Future<bool> authenticate(String pin) async {
    final isValid = await _authService.verifyPin(pin);
    
    if (isValid) {
      final timeout = await _authService.getSessionTimeout();
      state = AdminSessionState(
        isAuthenticated: true,
        authenticatedAt: DateTime.now(),
        sessionTimeoutMinutes: timeout,
      );
      return true;
    }
    
    return false;
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
}

/// Provider for admin session state
final adminSessionProvider = StateNotifierProvider<AdminSessionNotifier, AdminSessionState>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return AdminSessionNotifier(authService);
});
