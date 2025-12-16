import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
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
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('রেজিস্ট্রেশন ব্যর্থ: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                        
                        // Form Card with Glassmorphism
                        _buildFormCard(colorScheme, isDark, isCompact),
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
        // Animated Logo Container
        Container(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
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
        
        // Title
        Text(
          'BM Typer',
          style: GoogleFonts.poppins(
            fontSize: isCompact ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : colorScheme.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle in Bengali
        Text(
          'বাংলা টাইপিং শিখুন সহজে',
          style: GoogleFonts.hindSiliguri(
            fontSize: isCompact ? 16 : 18,
            color: (isDark ? Colors.white : colorScheme.onBackground).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(ColorScheme colorScheme, bool isDark, bool isCompact) {
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section Title
                Text(
                  'আপনার তথ্য দিন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isCompact ? 20 : 28),
                
                // Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'আপনার নাম',
                  hint: 'যেমন: রহিম উদ্দিন',
                  icon: Icons.person_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'দয়া করে আপনার নাম লিখুন';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'ইমেইল',
                  hint: 'example@email.com',
                  icon: Icons.email_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'দয়া করে ইমেইল লিখুন';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'সঠিক ইমেইল দিন';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _register(),
                ),
                
                SizedBox(height: isCompact ? 24 : 32),
                
                // Submit Button
                _buildSubmitButton(colorScheme, isCompact),
                
                const SizedBox(height: 16),
                
                // Skip Button
                TextButton(
                  onPressed: _isSubmitting
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.hindSiliguri(
        color: isDark ? Colors.white : colorScheme.onBackground,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.hindSiliguri(
          color: (isDark ? Colors.white : colorScheme.onBackground).withOpacity(0.7),
        ),
        hintStyle: GoogleFonts.hindSiliguri(
          color: (isDark ? Colors.white : colorScheme.onBackground).withOpacity(0.4),
        ),
        prefixIcon: Icon(
          icon,
          color: colorScheme.primary,
        ),
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme, bool isCompact) {
    return Container(
      height: isCompact ? 52 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                  Icon(Icons.rocket_launch_rounded, color: colorScheme.onPrimary),
                  const SizedBox(width: 10),
                  Text(
                    'শুরু করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
