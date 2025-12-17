import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';

/// Service to handle Firebase Authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    if (kDebugMode) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        debugPrint('❌ Google Sign In cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('✅ Google Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign In error: $e');
      rethrow;
    }
  }

  // ============================================================
  // EMAIL / PASSWORD AUTHENTICATION
  // ============================================================

  /// Sign up with Email and Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (!isGmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email-domain',
          message: 'শুধুমাত্র Gmail ব্যবহার করা যাবে',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Email Sign Up successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Email Sign Up error: $e');
      rethrow;
    }
  }

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Email Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Email Sign In error: $e');
      rethrow;
    }
  }

  /// Sign in with User ID (lookup email first)
  Future<UserCredential> signInWithUserId({
    required String userId,
    required String password,
  }) async {
    try {
      final cloudService = CloudSyncService();
      final email = await cloudService.getUserEmailByCustomId(userId);

      if (email == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'এই ইউজার আইডির কোনো অ্যাকাউন্ট পাওয়া যায়নি',
        );
      }

      return await signInWithEmail(email: email, password: password);
    } catch (e) {
      // Re-throw if it's already a FirebaseAuthException, otherwise wrap
      if (e is FirebaseAuthException) rethrow;
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'লগইন করা যাচ্ছে না',
      );
    }
  }

  /// Check if email is a Gmail address
  bool isGmail(String email) {
    return email.toLowerCase().endsWith('@gmail.com');
  }

  // ============================================================
  // PHONE AUTHENTICATION
  // ============================================================

  String? _verificationId;
  int? _resendToken;

  /// Verify phone number and send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function(PhoneAuthCredential credential)? onVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          debugPrint('📱 Auto-verification completed');
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.message}');
          String errorMessage = 'ভেরিফিকেশন ব্যর্থ হয়েছে';
          
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'ফোন নম্বর সঠিক নয়';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'অনেক বার চেষ্টা করা হয়েছে। কিছুক্ষণ পর চেষ্টা করুন';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS কোটা শেষ হয়ে গেছে';
          }
          
          onVerificationFailed(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📱 OTP sent to $phoneNumber');
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('📱 Auto-retrieval timeout');
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('❌ Phone verification error: $e');
      onVerificationFailed('ভেরিফিকেশনে সমস্যা হয়েছে');
    }
  }

  /// Verify OTP and sign in
  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Phone Sign In successful: ${userCredential.user?.phoneNumber}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ OTP verification error: ${e.code}');
      if (e.code == 'invalid-verification-code') {
        throw Exception('ভুল OTP কোড। আবার চেষ্টা করুন');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ OTP verification error: $e');
      rethrow;
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get display name from current user
  String? getDisplayName() {
    final user = currentUser;
    if (user == null) return null;
    
    return user.displayName ?? 
           user.email?.split('@').first ?? 
           user.phoneNumber;
  }

  /// Get email from current user
  String? getEmail() => currentUser?.email;

  /// Get phone number from current user
  String? getPhoneNumber() => currentUser?.phoneNumber;

  /// Get user ID
  String? getUserId() => currentUser?.uid;
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService().authStateChanges;
});
