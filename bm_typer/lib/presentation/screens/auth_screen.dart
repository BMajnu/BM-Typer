import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/services/auth_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/enums/user_role.dart';
import 'package:bm_typer/core/services/admin_auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Sign In Controllers
  final _signInIdentifierController = TextEditingController(); // ID, Email, or Phone
  final _signInPasswordController = TextEditingController();
  
  // Sign Up Controllers
  final _nameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController(); 
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  
  // Dynamic Sign In UI State
  bool _isPhoneLogin = false;
  String _verificationId = '';
  final _otpController = TextEditingController();
  bool _showOtpInput = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen to identifier changes to toggle UI mode
    _signInIdentifierController.addListener(() {
      final text = _signInIdentifierController.text.trim();
      final isDigit = RegExp(r'^[0-9+]+$').hasMatch(text);
       if (isDigit && text.length > 5 && !_isPhoneLogin) {
         setState(() => _isPhoneLogin = true);
       } else if (!isDigit && _isPhoneLogin) {
         setState(() => _isPhoneLogin = false);
       }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInIdentifierController.dispose();
    _signInPasswordController.dispose();
    _nameController.dispose();
    _userIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOGIC
  // --------------------------------------------------------------------------

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final identifier = _signInIdentifierController.text.trim();
    final authService = ref.read(authServiceProvider);

    try {
      if (_isPhoneLogin) {
        if (_showOtpInput) {
           // Verify OTP
           final cred = await authService.verifyOTP(
             verificationId: _verificationId,
             otp: _otpController.text.trim(),
           );
           if (cred?.user != null && mounted) {
              await _onLoginSuccess(cred!.user!);
           }
           // Send OTP
           await authService.verifyPhoneNumber(
             phoneNumber: identifier,
             onCodeSent: (verId) {
               setState(() {
                 _verificationId = verId;
                 _showOtpInput = true;
                 _isLoading = false;
               });
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('OTP পাঠানো হয়েছে')),
               );
             },
             onVerificationFailed: (msg) {
               setState(() => _isLoading = false);
               _showError(msg);
             },
             onVerificationCompleted: (cred) async {
                // Auto verify (Android only mostly)
                final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
                if (userCred.user != null && mounted) {
                   await _onLoginSuccess(userCred.user!);
                }
             }
           );
           return; // Return here as we wait for OTP
        }
      } else {
        // Email or ID Login
        final password = _signInPasswordController.text;
        UserCredential? cred;
        
        if (identifier.contains('@')) {
           // Email Login
           cred = await authService.signInWithEmail(email: identifier, password: password);
        } else {
           // User ID Login
           cred = await authService.signInWithUserId(userId: identifier, password: password);
        }
        
        if (cred?.user != null && mounted) {
           await _onLoginSuccess(cred!.user!);
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted && (!_isPhoneLogin || (_isPhoneLogin && !_showOtpInput))) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onLoginSuccess(User firebaseUser) async {
    try {
      final userNotifier = ref.read(currentUserProvider.notifier);
      final cloudService = ref.read(cloudSyncServiceProvider);
      
      // 1. Try to get user from Local DB first
      UserModel? user = DatabaseService.getUserById(firebaseUser.uid);
      
      // 2. If not local, try to fetch from Cloud
      if (user == null) {
        final cloudData = await cloudService.fetchUser();
        if (cloudData != null) {
          // Map cloud data to UserModel (simplified mapping)
          // We need a proper fromMap in UserModel, but for now constructing manually
          // based on what CloudSyncService saves: 
          // profile: {name, email, ...}, stats: {xpPoints, level...}
          
          final profile = cloudData['profile'] as Map<String, dynamic>? ?? {};
          final stats = cloudData['stats'] as Map<String, dynamic>? ?? {};
          final progress = cloudData['progress'] as Map<String, dynamic>? ?? {};

          final roleStr = (profile['role'] ?? cloudData['role']) as String?;
          final parsedRole = UserRole.values.firstWhere(
            (e) => e.name == roleStr,
            orElse: () => UserRole.student,
          );

          final isLegacyAdmin = AdminAuthService.legacyAdminEmails
              .contains((profile['email'] ?? firebaseUser.email ?? '').toString().toLowerCase());

          final safeRole = (!isLegacyAdmin && parsedRole == UserRole.superAdmin)
              ? UserRole.student
              : parsedRole;

          final organizationId = (profile['organizationId'] ?? cloudData['organizationId']) as String?;

          user = UserModel(
            id: firebaseUser.uid,
            name: profile['name'] ?? firebaseUser.displayName ?? 'Unknown',
            email: profile['email'] ?? firebaseUser.email ?? '',
            customUserId: profile['customUserId'],
            photoUrl: profile['photoUrl'] ?? firebaseUser.photoURL, // Restore from Firestore!
            phoneNumber: profile['phoneNumber'], // Restore phone too
            organizationId: organizationId,
            role: parsedRole,
            xpPoints: stats['xpPoints'] ?? 0,
            level: stats['level'] ?? 1,
            streakCount: stats['streakCount'] ?? 1,
            completedLessons: List<String>.from(progress['completedLessons'] ?? []),
            unlockedAchievements: List<String>.from(progress['unlockedAchievements'] ?? []),
          );
        }
      }

      // 3. If still null (New Google/Phone User), create fresh
      // OR if we found a user but want to update photoUrl if it's missing or changed
      if (user == null) {
         user = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'New User',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            streakCount: 1,
            lastLoginDate: DateTime.now(),
         );
      } else if (firebaseUser.photoURL != null && user.photoUrl != firebaseUser.photoURL) {
          // Update existing user with new photo URL if available
          user = user.copyWith(photoUrl: firebaseUser.photoURL);
      }

      final currentUser = user!;

      // Always pull role/org from Firestore to avoid stale local state
      try {
        final cloudData = await cloudService.fetchUser();
        if (cloudData != null) {
          final profile = cloudData['profile'] as Map<String, dynamic>? ?? {};

          final roleStr = (profile['role'] ?? cloudData['role']) as String?;
          final parsedRole = UserRole.values.firstWhere(
            (e) => e.name == roleStr,
            orElse: () => UserRole.student,
          );

          final isLegacyAdmin = AdminAuthService.legacyAdminEmails
              .contains((currentUser.email).toLowerCase());

          final safeRole = (!isLegacyAdmin && parsedRole == UserRole.superAdmin)
              ? UserRole.student
              : parsedRole;

          final cloudOrgId = (profile['organizationId'] ?? cloudData['organizationId']) as String?;

          var mergedUser = currentUser;
          if (cloudOrgId != null && cloudOrgId != currentUser.organizationId) {
            mergedUser = mergedUser.copyWith(organizationId: cloudOrgId);
          }
          if (roleStr != null && safeRole != currentUser.role) {
            mergedUser = mergedUser.copyWith(role: safeRole);
          }
          user = mergedUser;
        }
      } catch (_) {}

      if (user == null) {
        throw Exception('User model could not be resolved after login');
      }

      final resolvedUser = user!;

      // 4. Save to Local DB + Set Current
      await DatabaseService.saveUser(resolvedUser);
      await DatabaseService.setCurrentUser(resolvedUser);
      
      // 5. Update Provider (Triggers Redirect)
      await userNotifier.updateUser(resolvedUser);
      
    } catch (e) {
      debugPrint('Login post-processing error: $e');
      // Even if sync details fail, try to set basic user to allow entry
      final fallbackUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User', 
          email: firebaseUser.email ?? ''
      );
      await ref.read(currentUserProvider.notifier).updateUser(fallbackUser);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    final cloudService = ref.read(cloudSyncServiceProvider);
    
    final email = _emailController.text.trim();
    final userId = _userIdController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final phoneNumber = _phoneController.text.trim();

    try {
      // 1. Check if User ID is available
      final isTaken = await cloudService.isUserIdTaken(userId);
      if (isTaken) {
        throw Exception('এই User ID টি ইতিমধ্যে ব্যবহৃত হচ্ছে। অন্য একটি চেষ্টা করুন।');
      }

      UserCredential? userCred;
      
      // 2. Create Auth User - Email or Phone based
      if (email.isNotEmpty) {
        // Email-based signup
        userCred = await authService.signUpWithEmail(email: email, password: password);
      } else if (phoneNumber.isNotEmpty) {
        // Phone-based signup - need to verify phone first
        await authService.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          onCodeSent: (verId) {
            setState(() {
              _verificationId = verId;
              _showOtpInput = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP পাঠানো হয়েছে। কোড দিয়ে যাচাই করুন।')),
            );
          },
          onVerificationFailed: (msg) {
            setState(() => _isLoading = false);
            _showError(msg);
          },
          onVerificationCompleted: (cred) async {
            // Auto verify (Android only)
            final result = await FirebaseAuth.instance.signInWithCredential(cred);
            if (result.user != null && mounted) {
              await _createUserAfterPhoneAuth(result.user!, name, userId, phoneNumber);
            }
          },
        );
        return; // Wait for OTP verification
      } else {
        throw Exception('ইমেইল অথবা ফোন নম্বর দিতে হবে');
      }
      
      if (userCred == null) return;
      
      // 3. Create Database User Model
      final newUser = UserModel(
        id: userCred.user!.uid,
        customUserId: userId,
        photoUrl: userCred.user?.photoURL,
        name: name,
        email: email,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
        streakCount: 1,
        lastLoginDate: DateTime.now(),
      );

      // 4. Save to Local DB
      await DatabaseService.saveUser(newUser);
      await DatabaseService.setCurrentUser(newUser);
      
      // 5. Update Provider
      await ref.read(currentUserProvider.notifier).updateUser(newUser);

      // 6. Sync to Cloud
      debugPrint('📝 Saving user with customUserId: ${newUser.customUserId}, phone: ${newUser.phoneNumber}');
      await cloudService.syncUser(newUser);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('অ্যাকাউন্ট তৈরি সফল হয়েছে!')),
         );
      }

    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Helper to create user after phone auth
  Future<void> _createUserAfterPhoneAuth(User firebaseUser, String name, String userId, String phoneNumber) async {
    final cloudService = ref.read(cloudSyncServiceProvider);
    
    final newUser = UserModel(
      id: firebaseUser.uid,
      customUserId: userId,
      name: name,
      email: '', // Phone-only signup has no email
      phoneNumber: phoneNumber,
      streakCount: 1,
      lastLoginDate: DateTime.now(),
    );

    await DatabaseService.saveUser(newUser);
    await DatabaseService.setCurrentUser(newUser);
    await ref.read(currentUserProvider.notifier).updateUser(newUser);
    await cloudService.syncUser(newUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অ্যাকাউন্ট তৈরি সফল হয়েছে!')),
      );
    }
  }
  
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final cred = await authService.signInWithGoogle();
      
      if (cred?.user != null && mounted) {
        await _onLoginSuccess(cred!.user!);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.hindSiliguri()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI COMPONENTS
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // Violet -> Blue
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Branding
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(child: Image.asset('assets/BMT.png', width: 64, height: 64)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BM Typer',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'বাংলা টাইপিং শিখুন সহজে',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Glass Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            // Tabs
                            Container(
                              color: Colors.white.withOpacity(0.05),
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: Colors.white,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white60,
                                labelStyle: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                                tabs: const [
                                  Tab(text: 'সাইন ইন'),
                                  Tab(text: 'সাইন আপ'),
                                ],
                              ),
                            ),
                            
                            // Form Body
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                height: 500, // Fixed height for scrolling inside tabs if needed
                                padding: const EdgeInsets.all(24),
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildSignInForm(),
                                    _buildSignUpForm(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSavedUsersList(),
              
              _buildTextField(
                controller: _signInIdentifierController,
                label: 'User ID / ফোন / ইমেইল',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'অনুগ্রহ করে এটি পূরণ করুন' : null,
              ),
              const SizedBox(height: 16),
              
              if (_isPhoneLogin) ...[
                if (_showOtpInput) 
                  _buildTextField(
                    controller: _otpController,
                    label: 'OTP কোড',
                    icon: Icons.lock_clock_outlined,
                    isNumber: true,
                    validator: (v) => v!.length < 6 ? 'সঠিক OTP দিন' : null,
                  ),
              ] else
                _buildTextField(
                  controller: _signInPasswordController,
                  label: 'পাসওয়ার্ড',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                
              const SizedBox(height: 24),
              
              _buildGradientButton(
                text: _showOtpInput ? 'যাচাই করুন' : (_isPhoneLogin ? 'OTP পাঠান' : 'লগইন করুন'),
                onPressed: _handleSignIn,
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('অথবা', style: GoogleFonts.hindSiliguri(color: Colors.white60)),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                ],
              ),
              const SizedBox(height: 24),
              
              // Google Sign In Button
              _buildSocialButton(
                text: 'Google দিয়ে সাইন ইন',
                icon: Icons.g_mobiledata,
                onPressed: _handleGoogleSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: SingleChildScrollView(
         child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'আপনার নাম',
            icon: Icons.badge_outlined,
            validator: (v) => v!.isEmpty ? 'নাম প্রয়োজন' : null,
          ),
          const SizedBox(height: 16),
           _buildTextField(
            controller: _userIdController,
            label: 'User ID (যেমন: bmajnu123)',
            icon: Icons.alternate_email,
            validator: (v) {
               if (v!.isEmpty) return 'User ID প্রয়োজন';
               if (v.contains(' ')) return 'User ID তে স্পেস রাখা যাবে না';
               if (v.length < 4) return 'কমপক্ষে ৪ অক্ষরের হতে হবে';
               return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'ইমেইল (Gmail) - ঐচ্ছিক',
            icon: Icons.email_outlined,
            validator: (v) {
              // Email is optional, but if provided must be Gmail
              if (v != null && v.isNotEmpty && !v.toLowerCase().endsWith('@gmail.com')) {
                return 'শুধুমাত্র Gmail ব্যবহার করুন';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
           _buildTextField(
            controller: _phoneController,
            label: 'ফোন নম্বর (যেমন: +8801712345678)',
            icon: Icons.phone_android,
            isNumber: true,
            validator: (v) {
              // At least one of email or phone is required
              final email = _emailController.text.trim();
              final phone = v?.trim() ?? '';
              if (email.isEmpty && phone.isEmpty) {
                return 'ইমেইল অথবা ফোন নম্বর দিতে হবে';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'পাসওয়ার্ড',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (v) => v!.length < 6 ? 'কমপক্ষে ৬ অক্ষর হতে হবে' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'পাসওয়ার্ড নিশ্চিত করুন',
            icon: Icons.verified_user_outlined,
            isPassword: true,
            validator: (v) {
               if (v != _passwordController.text) return 'পাসওয়ার্ড মিলছে না';
               return null;
            },
          ),
          
          const SizedBox(height: 24),
          _buildGradientButton(
            text: 'সাইন আপ করুন',
            onPressed: _handleSignUp,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSavedUsersList() {
    // Get saved users from UserNotifier
    final savedUsers = ref.read(currentUserProvider.notifier).getAllSavedUsers();

    if (savedUsers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Accounts',
          style: GoogleFonts.hindSiliguri(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: savedUsers.length,
            separatorBuilder: (c, i) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final user = savedUsers[index];
              return Stack(
                children: [
                  InkWell(
                    onTap: () async {
                      // Switch to this saved user directly
                      await ref.read(currentUserProvider.notifier).switchToUser(user);
                      // Navigate to main app
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            image: user.photoUrl != null
                                ? DecorationImage(image: NetworkImage(user.photoUrl!))
                                : null,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: user.photoUrl == null
                              ? Center(
                                  child: Text(
                                    user.name[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.hindSiliguri(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () async {
                        // Remove user
                        await ref.read(currentUserProvider.notifier).removeSavedUser(user.id);
                        setState(() {}); // Refresh list
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Light Blue -> Blue
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                text,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({required String text, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
