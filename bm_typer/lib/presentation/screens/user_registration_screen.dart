import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/auth_service.dart';
import 'package:bm_typer/presentation/screens/tutor_screen.dart';

class UserRegistrationScreen extends ConsumerStatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  ConsumerState<UserRegistrationScreen> createState() =>
      _UserRegistrationScreenState();
}

class _UserRegistrationScreenState
    extends ConsumerState<UserRegistrationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _isPhoneLoading = false;
  bool _showOtpField = false;
  String? _verificationId;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && userCredential.user != null) {
        final user = userCredential.user!;
        
        // Create local user with Firebase data
        await ref.read(currentUserProvider.notifier).registerUser(
          user.displayName ?? 'ব্যবহারকারী',
          user.email ?? '',
        );

        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TutorScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Google সাইন ইন ব্যর্থ: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  // ============================================================
  // PHONE AUTHENTICATION
  // ============================================================

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty) {
      _showErrorSnackBar('ফোন নম্বর দিন');
      return;
    }

    // Format phone number with country code
    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      if (phone.startsWith('0')) {
        formattedPhone = '+880${phone.substring(1)}';
      } else {
        formattedPhone = '+880$phone';
      }
    }

    setState(() => _isPhoneLoading = true);

    await _authService.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _showOtpField = true;
            _isPhoneLoading = false;
          });
          _showSuccessSnackBar('OTP পাঠানো হয়েছে');
        }
      },
      onVerificationFailed: (error) {
        if (mounted) {
          setState(() => _isPhoneLoading = false);
          _showErrorSnackBar(error);
        }
      },
      onVerificationCompleted: (credential) async {
        // Auto-verification on Android
        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          if (userCredential.user != null) {
            await _completePhoneAuth(userCredential.user!);
          }
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar('অটো ভেরিফিকেশন ব্যর্থ');
          }
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty || otp.length != 6) {
      _showErrorSnackBar('৬ ডিজিটের OTP দিন');
      return;
    }

    if (_verificationId == null) {
      _showErrorSnackBar('আবার OTP পাঠান');
      return;
    }

    setState(() => _isPhoneLoading = true);

    try {
      final userCredential = await _authService.verifyOTP(
        verificationId: _verificationId!,
        otp: otp,
      );

      if (userCredential != null && userCredential.user != null) {
        await _completePhoneAuth(userCredential.user!);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isPhoneLoading = false);
      }
    }
  }

  Future<void> _completePhoneAuth(user) async {
    // Create local user with phone data
    await ref.read(currentUserProvider.notifier).registerUser(
      user.phoneNumber ?? 'ব্যবহারকারী',
      user.phoneNumber ?? '',
    );

    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const TutorScreen()),
    );
  }

  // ============================================================
  // QUICK REGISTRATION (Name + Email only)
  // ============================================================

  Future<void> _quickRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(currentUserProvider.notifier).createUser(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TutorScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('রেজিস্ট্রেশন ব্যর্থ: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.hindSiliguri()),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.hindSiliguri()),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primaryContainer.withOpacity(0.3),
                    colorScheme.secondaryContainer.withOpacity(0.2),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 20 : 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo & Title Section
                        _buildLogoSection(colorScheme, isDark, isCompact),
                        
                        SizedBox(height: isCompact ? 32 : 48),
                        
                        // Auth Options Card
                        _buildAuthCard(colorScheme, isDark, isCompact),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(ColorScheme colorScheme, bool isDark, bool isCompact) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_rounded,
            size: isCompact ? 48 : 64,
            color: colorScheme.onPrimary,
          ),
        ),
        
        SizedBox(height: isCompact ? 20 : 28),
        
        Text(
          'BM Typer',
          style: GoogleFonts.poppins(
            fontSize: isCompact ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'বাংলা টাইপিং শিখুন সহজে',
          style: GoogleFonts.hindSiliguri(
            fontSize: isCompact ? 16 : 18,
            color: (isDark ? Colors.white : colorScheme.onSurface).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthCard(ColorScheme colorScheme, bool isDark, bool isCompact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 24 : 32),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Google Sign In Button
              _buildGoogleButton(colorScheme, isDark),
              
              const SizedBox(height: 20),
              
              // Divider with "অথবা"
              _buildDivider(isDark),
              
              const SizedBox(height: 20),
              
              // Phone Authentication Section
              _buildPhoneSection(colorScheme, isDark),
              
              const SizedBox(height: 20),
              
              // Divider with "অথবা"
              _buildDivider(isDark),
              
              const SizedBox(height: 20),
              
              // Quick Registration Form
              _buildQuickRegisterSection(colorScheme, isDark, isCompact),
              
              const SizedBox(height: 16),
              
              // Skip Button
              TextButton(
                onPressed: (_isSubmitting || _isGoogleLoading || _isPhoneLoading)
                    ? null
                    : () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const TutorScreen()),
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'এখন না, পরে করব',
                  style: GoogleFonts.hindSiliguri(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(ColorScheme colorScheme, bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isGoogleLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.g_mobiledata, size: 28, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Google দিয়ে সাইন ইন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'অথবা',
            style: GoogleFonts.hindSiliguri(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '📱 ফোন নম্বর দিয়ে সাইন ইন',
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        
        // Phone Input
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: '01XXXXXXXXX',
            prefixText: '+880 ',
            prefixStyle: GoogleFonts.poppins(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(Icons.phone_android, color: colorScheme.primary),
            filled: true,
            fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        
        if (_showOtpField) ...[
          const SizedBox(height: 12),
          
          // OTP Input
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '● ● ● ● ● ●',
              hintStyle: GoogleFonts.poppins(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: colorScheme.primary.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Send OTP / Verify Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isPhoneLoading
                ? null
                : (_showOtpField ? _verifyOTP : _sendOTP),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isPhoneLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    _showOtpField ? 'ভেরিফাই করুন' : 'OTP পাঠান',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
          ),
        ),
        
        if (_showOtpField) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isPhoneLoading ? null : _sendOTP,
            child: Text(
              'আবার OTP পাঠান',
              style: GoogleFonts.hindSiliguri(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickRegisterSection(ColorScheme colorScheme, bool isDark, bool isCompact) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '✨ দ্রুত শুরু করুন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          
          // Name Field
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.hindSiliguri(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'আপনার নাম',
              hintText: 'যেমন: রহিম উদ্দিন',
              labelStyle: GoogleFonts.hindSiliguri(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
              ),
              prefixIcon: Icon(Icons.person_rounded, color: colorScheme.primary),
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'দয়া করে আপনার নাম লিখুন';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.hindSiliguri(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'ইমেইল',
              hintText: 'example@email.com',
              labelStyle: GoogleFonts.hindSiliguri(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
              ),
              prefixIcon: Icon(Icons.email_rounded, color: colorScheme.primary),
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'দয়া করে ইমেইল লিখুন';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'সঠিক ইমেইল দিন';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Submit Button
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _quickRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded, color: colorScheme.onPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'শুরু করুন',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
