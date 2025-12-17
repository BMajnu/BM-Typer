import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/cloudinary_service.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/auth_service.dart';
import 'package:bm_typer/core/services/subscription_service.dart';
import 'package:bm_typer/core/models/subscription_model.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('ব্যবহারকারী তথ্য পাওয়া যায়নি', style: GoogleFonts.hindSiliguri())),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(isDark, colorScheme),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Image Section
                      _buildProfileImageSection(user.photoUrl, colorScheme, isDark),
                      const SizedBox(height: 24),
                      
                      // Personal Info Section
                      _buildSectionCard(
                        title: 'ব্যক্তিগত তথ্য',
                        icon: Icons.person_outline,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        children: [
                          _buildInfoRow('ইমেইল', user.email, Icons.email_outlined, isDark, isEditable: false),
                          const SizedBox(height: 12),
                          _buildEditableField(
                            label: 'নাম',
                            controller: _nameController,
                            icon: Icons.badge_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildEditableField(
                            label: 'ফোন নম্বর',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            text: 'পরিবর্তন সংরক্ষণ করুন',
                            icon: Icons.save_outlined,
                            onPressed: _savePersonalInfo,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Security Section
                      _buildSectionCard(
                        title: 'নিরাপত্তা',
                        icon: Icons.security_outlined,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        children: [
                          _buildEditableField(
                            label: 'পুরানো পাসওয়ার্ড',
                            controller: _oldPasswordController,
                            icon: Icons.lock_outline,
                            isDark: isDark,
                            isPassword: true,
                          ),
                          const SizedBox(height: 12),
                          _buildEditableField(
                            label: 'নতুন পাসওয়ার্ড',
                            controller: _newPasswordController,
                            icon: Icons.lock_reset_outlined,
                            isDark: isDark,
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            text: 'পাসওয়ার্ড পরিবর্তন করুন',
                            icon: Icons.vpn_key_outlined,
                            onPressed: _changePassword,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subscription Section
                      _buildSubscriptionSection(user.id, colorScheme, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground(bool isDark, ColorScheme colorScheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f0f1a)]
            : [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surface, colorScheme.surface],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black87, size: 28),
          const SizedBox(width: 12),
          Text(
            'অ্যাকাউন্ট সেটিংস',
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(String? photoUrl, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _uploadProfileImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.1),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 3),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('❌ Image load error: $error');
                            return Icon(Icons.broken_image_rounded, size: 40, color: colorScheme.error.withOpacity(0.5));
                          },
                        )
                      : Icon(Icons.person, size: 60, color: colorScheme.primary.withOpacity(0.5)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _uploadProfileImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8)],
                  ),
                  child: _isUploadingImage
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'প্রোফাইল ছবি পরিবর্তন করতে ট্যাপ করুন',
          style: GoogleFonts.hindSiliguri(
            fontSize: 13,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required ColorScheme colorScheme,
    required List<Widget> children,
    bool dangerZone = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dangerZone ? Colors.red.withOpacity(0.3) : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: dangerZone ? Colors.red : colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dangerZone ? Colors.red : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark, {bool isEditable = true}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.hindSiliguri(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
              Text(value, style: GoogleFonts.hindSiliguri(fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),
        if (!isEditable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('যাচাইকৃত', style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.hindSiliguri(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)),
        prefixIcon: Icon(icon, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isDanger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon),
        label: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(text, style: GoogleFonts.hindSiliguri(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger ? Colors.red : colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(String userId, ColorScheme colorScheme, bool isDark) {
    return FutureBuilder<SubscriptionModel?>(
      future: SubscriptionService().getSubscription(userId),
      builder: (context, snapshot) {
        final subscription = snapshot.data;
        final planName = subscription != null
            ? SubscriptionModel.getDisplayName(subscription.subscriptionType)
            : 'ফ্রি';
        final isFreePlan = subscription?.type == 'free' || subscription == null;

        return _buildSectionCard(
          title: 'সাবস্ক্রিপশন',
          icon: Icons.card_membership_outlined,
          isDark: isDark,
          colorScheme: colorScheme,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('বর্তমান প্ল্যান', style: GoogleFonts.hindSiliguri(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
                    Text(planName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: isFreePlan ? Colors.orange : Colors.green)),
                  ],
                ),
                if (!isFreePlan && subscription?.endDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('মেয়াদ শেষ', style: GoogleFonts.hindSiliguri(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
                      Text(
                        '${subscription!.endDate!.day}/${subscription.endDate!.month}/${subscription.endDate!.year}',
                        style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  ),
              ],
            ),
            if (isFreePlan) ...[
              const SizedBox(height: 16),
              _buildActionButton(
                text: 'প্রিমিয়াম প্ল্যানে আপগ্রেড করুন',
                icon: Icons.upgrade_rounded,
                onPressed: () {
                  // TODO: Navigate to subscription screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('সাবস্ক্রিপশন পেজ শীঘ্রই আসছে!', style: GoogleFonts.hindSiliguri())),
                  );
                },
                colorScheme: colorScheme,
              ),
            ],
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _uploadProfileImage() async {
    setState(() => _isUploadingImage = true);
    
    try {
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      debugPrint('🚀 Starting image upload...');
      final imageUrl = await cloudinaryService.pickAndUploadImage();
      
      debugPrint('📸 Received imageUrl: $imageUrl');
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          debugPrint('👤 Current user photoUrl before: ${user.photoUrl}');
          final updatedUser = user.copyWith(photoUrl: imageUrl);
          debugPrint('👤 Updated user photoUrl: ${updatedUser.photoUrl}');
          
          await DatabaseService.saveUser(updatedUser);
          await ref.read(currentUserProvider.notifier).updateUser(updatedUser);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('প্রোফাইল ছবি আপডেট হয়েছে!\nURL: ${imageUrl.substring(0, 50)}...', 
                  style: GoogleFonts.hindSiliguri(fontSize: 12)),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        debugPrint('⚠️ imageUrl is null or empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ছবি আপলোড হয়নি! কনসোল চেক করুন।', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি আপলোড করতে সমস্যা হয়েছে: $e', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _savePersonalInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final updatedUser = user.copyWith(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
        
        await DatabaseService.saveUser(updatedUser);
        await ref.read(currentUserProvider.notifier).updateUser(updatedUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('তথ্য সংরক্ষণ করা হয়েছে!', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সংরক্ষণ করতে সমস্যা: $e', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('উভয় পাসওয়ার্ড ফিল্ড পূরণ করুন', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('নতুন পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null || firebaseUser.email == null) {
        throw Exception('ব্যবহারকারী সেশন পাওয়া যায়নি');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: _oldPasswordController.text,
      );
      await firebaseUser.reauthenticateWithCredential(credential);

      // Update password
      await firebaseUser.updatePassword(_newPasswordController.text);
      
      _oldPasswordController.clear();
      _newPasswordController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('পাসওয়ার্ড পরিবর্তন সফল হয়েছে!', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'পাসওয়ার্ড পরিবর্তন করতে সমস্যা হয়েছে';
        if (e.code == 'wrong-password') {
          message = 'পুরানো পাসওয়ার্ড সঠিক নয়';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message, style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('পাসওয়ার্ড পরিবর্তন করতে সমস্যা: $e', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('অ্যাকাউন্ট মুছে ফেলবেন?', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Text(
          'এই কাজটি অপরিবর্তনীয়! আপনার সমস্ত ডেটা স্থায়ীভাবে মুছে যাবে।',
          style: GoogleFonts.hindSiliguri(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('হ্যাঁ, মুছে ফেলুন', style: GoogleFonts.hindSiliguri(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      
      // Note: Full account deletion requires re-authentication
      // For now, just sign out. Full deletion can be implemented later.
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('অ্যাকাউন্ট মুছতে সমস্যা: $e', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
