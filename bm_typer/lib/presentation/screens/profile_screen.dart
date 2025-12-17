import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/presentation/screens/reminder_settings_screen.dart';
import 'package:bm_typer/presentation/screens/level_details_screen.dart';
import 'package:bm_typer/presentation/screens/export_screen.dart';
import 'package:bm_typer/presentation/widgets/streak_counter.dart';
import 'package:bm_typer/presentation/widgets/xp_progress_bar.dart';
import 'package:bm_typer/core/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(isDark, colorScheme),
          child: SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton(
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
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(isCompact ? 24 : 40),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(isCompact ? 24 : 32),
                            constraints: const BoxConstraints(maxWidth: 400),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_add_rounded,
                                    size: 48,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                Text(
                                  'প্রোফাইল তৈরি করুন',
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: isCompact ? 22 : 26,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Text(
                                  'আপনার অগ্রগতি ট্র্যাক করতে এবং লিডারবোর্ডে যোগ দিতে একটি প্রোফাইল তৈরি করুন।',
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 14,
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [colorScheme.primary, colorScheme.secondary],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/register');
                                      },
                                      icon: const Icon(Icons.person_add_rounded),
                                      label: Text(
                                        'রেজিস্ট্রেশন করুন',
                                        style: GoogleFonts.hindSiliguri(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Continue as Guest
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'অতিথি হিসেবে চালিয়ে যান',
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 14,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Features list
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildFeatureItem(Icons.trending_up_rounded, 'অগ্রগতি ট্র্যাক', colorScheme, isDark),
                                      const SizedBox(height: 8),
                                      _buildFeatureItem(Icons.leaderboard_rounded, 'লিডারবোর্ড', colorScheme, isDark),
                                      const SizedBox(height: 8),
                                      _buildFeatureItem(Icons.emoji_events_rounded, 'অ্যাচিভমেন্ট', colorScheme, isDark),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(isDark, colorScheme),
        child: CustomScrollView(
          slivers: [
            // Modern App Bar with Glassmorphism
            SliverAppBar(
              expandedHeight: isCompact ? 200 : 240,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(context, user, colorScheme, isDark, isCompact),
              ),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.settings_rounded, size: 20, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/account_settings'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Row
                    _buildQuickStats(context, user, colorScheme, isDark, isCompact),
                    
                    const SizedBox(height: 24),
                    
                    // XP Progress Section
                    _buildXPSection(context, user, colorScheme, isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Daily Streak Section
                    _buildStreakSection(context, user, colorScheme, isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Typing Statistics
                    _buildTypingStatsSection(context, user, colorScheme, isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Activity
                    _buildRecentActivitySection(context, user, colorScheme, isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons Row
                    _buildActionButtons(context, colorScheme, isDark),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
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
            ? [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
                const Color(0xFF0f0f1a),
              ]
            : [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.surface,
                colorScheme.surface,
              ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user, ColorScheme colorScheme, bool isDark, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
            colorScheme.tertiary ?? colorScheme.primary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar with Level Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Level Ring
                  Container(
                    width: isCompact ? 90 : 110,
                    height: isCompact ? 90 : 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                    ),
                  ),
                  // Avatar
                  Container(
                    width: isCompact ? 80 : 100,
                    height: isCompact ? 80 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      // Show Network Image if photoUrl exists, else show initials
                      image: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(user.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                        ? Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                fontSize: isCompact ? 36 : 44,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Level Badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        'Lv ${user.level}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isCompact ? 12 : 16),
              
              // Name
              Text(
                user.name,
                style: GoogleFonts.poppins(
                  fontSize: isCompact ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              // Level Title
              Text(
                _getLevelTitle(user.level),
                style: GoogleFonts.hindSiliguri(
                  fontSize: isCompact ? 14 : 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, UserModel user, ColorScheme colorScheme, bool isDark, bool isCompact) {
    return Row(
      children: [
        Expanded(child: _buildStatPill('${user.xpPoints}', 'XP', Icons.star_rounded, Colors.amber, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatPill('${user.streak}', 'Streak', Icons.local_fire_department_rounded, Colors.orange, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatPill('${user.totalLessonsCompleted}', 'Lessons', Icons.menu_book_rounded, colorScheme.primary, isDark)),
      ],
    );
  }

  Widget _buildStatPill(String value, String label, IconData icon, Color color, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXPSection(BuildContext context, UserModel user, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${user.level} • ${_getLevelTitle(user.level)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LevelDetailsScreen()),
                  );
                },
                child: Text('বিস্তারিত', style: GoogleFonts.hindSiliguri()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const XPProgressBar(),
          const SizedBox(height: 8),
          Text(
            '${user.xpPoints} XP • পরবর্তী লেভেলে ${user.xpToNextLevel} XP বাকি',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context, UserModel user, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'ডেইলি স্ট্রিক',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: colorScheme.primary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ReminderSettingsScreen()),
                  );
                },
                tooltip: 'রিমাইন্ডার সেটিংস',
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreakCounter(
            streak: user.streak,
            isActive: user.streakMaintained,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (user.streakMaintained ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  user.streakMaintained ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: user.streakMaintained ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.streakMaintained
                        ? 'আপনি ${user.streak} দিন ধরে প্র্যাক্টিস করছেন!'
                        : 'আজ প্র্যাক্টিস করুন এবং স্ট্রিক চালিয়ে যান!',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: user.streakMaintained ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingStatsSection(BuildContext context, UserModel user, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'টাইপিং পরিসংখ্যান',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTypingStat(
                  icon: Icons.speed_rounded,
                  value: '${user.highestWpm.toStringAsFixed(0)}',
                  label: 'সর্বোচ্চ WPM',
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypingStat(
                  icon: Icons.av_timer_rounded,
                  value: '${user.averageWpm.toStringAsFixed(0)}',
                  label: 'গড় WPM',
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypingStat(
                  icon: Icons.check_circle_rounded,
                  value: '${user.totalLessonsCompleted}',
                  label: 'সম্পন্ন',
                  color: colorScheme.primary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, UserModel user, ColorScheme colorScheme, bool isDark) {
    final recentSessions = user.typingSessions.reversed.take(5).toList();

    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'সাম্প্রতিক কার্যকলাপ',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          recentSessions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded, size: 40, color: colorScheme.primary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'এখনও কোনো কার্যকলাপ নেই\nকিছু লেসন সম্পূর্ণ করুন!',
                          style: GoogleFonts.hindSiliguri(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSessions.length,
                  separatorBuilder: (context, index) => Divider(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final session = recentSessions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.keyboard_rounded, color: colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.completedLesson ?? 'টাইপিং প্র্যাক্টিস',
                                  style: GoogleFonts.hindSiliguri(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  _formatDate(session.timestamp),
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 12,
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${session.wpm.toStringAsFixed(0)} WPM',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '${session.accuracy.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.speed_rounded,
            label: 'স্পিড টেস্ট',
            color: colorScheme.primary,
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/typing_test'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.ios_share_rounded,
            label: 'এক্সপোর্ট',
            color: colorScheme.secondary,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ExportScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 13,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} মিনিট আগে';
      }
      return '${difference.inHours} ঘন্টা আগে';
    } else if (difference.inDays == 1) {
      return 'গতকাল';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getLevelTitle(int level) {
    if (level < 3) {
      return 'শিক্ষানবিশ';
    } else if (level < 6) {
      return 'প্রশিক্ষণার্থী';
    } else if (level < 10) {
      return 'দক্ষ টাইপিস্ট';
    } else if (level < 15) {
      return 'বিশেষজ্ঞ টাইপিস্ট';
    } else if (level < 20) {
      return 'মাস্টার টাইপিস্ট';
    } else if (level < 30) {
      return 'গ্র্যান্ডমাস্টার';
    } else {
      return 'কিংবদন্তি টাইপিস্ট';
    }
  }
}
