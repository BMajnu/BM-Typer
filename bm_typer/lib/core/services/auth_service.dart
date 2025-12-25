import 'dart:io' show Platform, HttpServer, HttpStatus, ContentType, InternetAddress;
import 'dart:convert' show json;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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
      // Check if running on Windows desktop
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return await _signInWithGoogleDesktop();
      }
      
      // Mobile/Web flow using google_sign_in package
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('✅ Google Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign In error: $e');
      rethrow;
    }
  }

  /// Desktop-specific Google Sign-In using default browser and localhost callback
  Future<UserCredential?> _signInWithGoogleDesktop() async {
    try {
      debugPrint('🔐 Starting Google Sign-In for Desktop (Default Browser)...');
      
      // Google OAuth configuration from Firebase/Google Cloud Console
      const googleClientId = '121426968554-rpvgac48m5s3rnjg87iobkajv8s40p85.apps.googleusercontent.com';
      const callbackPort = 8585;
      final redirectUri = 'http://localhost:$callbackPort/callback';
      
      // Build the Google OAuth URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': googleClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'email profile openid',
        'access_type': 'offline',
        'prompt': 'select_account',
      });

      // Start a local HTTP server to catch the callback
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, callbackPort);
      debugPrint('🌐 Localhost server started on port $callbackPort');

      // Open the auth URL in the default browser
      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await server.close();
        throw Exception('ব্রাউজার খোলা যায়নি');
      }

      debugPrint('🌐 Opened Google Sign-In in default browser');

      // Wait for the callback (with timeout)
      String? authCode;
      try {
        await for (final request in server) {
          if (request.uri.path == '/callback') {
            authCode = request.uri.queryParameters['code'];
            
            // Send a nice response to the browser
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write('''
                <!DOCTYPE html>
                <html>
                <head>
                  <meta charset="UTF-8">
                  <title>BM Typer - Login সফল</title>
                  <style>
                    body { 
                      font-family: 'Segoe UI', sans-serif; 
                      display: flex; 
                      justify-content: center; 
                      align-items: center; 
                      height: 100vh; 
                      margin: 0;
                      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: white;
                    }
                    .container { text-align: center; padding: 40px; }
                    h1 { font-size: 2em; margin-bottom: 10px; }
                    p { font-size: 1.2em; opacity: 0.9; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <h1>✅ Login সফল!</h1>
                    <p>আপনি এখন এই ট্যাব বন্ধ করে BM Typer অ্যাপে ফিরে যেতে পারেন।</p>
                  </div>
                </body>
                </html>
              ''');
            await request.response.close();
            break;
          }
        }
      } finally {
        await server.close();
        debugPrint('🌐 Localhost server closed');
      }

      if (authCode == null) {
        debugPrint('❌ No auth code received');
        return null;
      }

      debugPrint('✅ Got auth code, exchanging for tokens...');

      // Exchange auth code for tokens
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': authCode,
          'client_id': googleClientId,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode != 200) {
        debugPrint('❌ Token exchange failed: ${tokenResponse.body}');
        throw Exception('Token exchange failed');
      }

      final tokenData = json.decode(tokenResponse.body);
      final accessToken = tokenData['access_token'] as String?;
      final idToken = tokenData['id_token'] as String?;

      if (accessToken == null) {
        throw Exception('No access token received');
      }

      debugPrint('✅ Got tokens, signing in to Firebase...');

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('✅ Desktop Google Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Desktop Google Sign In error: $e');
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

  /// Sign in with User ID or Phone Number (lookup email first)
  Future<UserCredential> signInWithUserId({
    required String userId,
    required String password,
  }) async {
    try {
      final cloudService = CloudSyncService();
      String? email;
      
      // First try looking up by custom User ID
      email = await cloudService.getUserEmailByCustomId(userId);
      
      // If not found by userId, try phone number lookup
      if (email == null) {
        email = await cloudService.getUserEmailByPhoneNumber(userId);
      }

      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'এই User ID বা ফোন নম্বরের কোনো অ্যাকাউন্ট পাওয়া যায়নি',
        );
      }

      return await signInWithEmail(email: email, password: password);
    } catch (e) {
      // Re-throw if it's already a FirebaseAuthException, otherwise wrap
      if (e is FirebaseAuthException) rethrow;
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'লগইন করা যাচ্ছে না: $e',
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
