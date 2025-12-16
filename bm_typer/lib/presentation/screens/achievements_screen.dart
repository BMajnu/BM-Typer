import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/achievement_service.dart';
import 'package:bm_typer/presentation/widgets/achievement_card.dart';
import 'package:bm_typer/presentation/widgets/achievement_badge.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _viewType = 0; // 0: List View, 1: Grid View

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(isDark, colorScheme),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_rounded, size: 64, color: colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'অ্যাচিভমেন্ট দেখতে লগইন করুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 18,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
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
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(context, colorScheme, isDark),
              
              // Category Tab Bar
              _buildCategoryTabs(colorScheme, isDark),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: AchievementCategory.values.map((category) {
                    return _buildCategoryTab(context, category, user, colorScheme, isDark);
                  }).toList(),
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

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(width: 8),
          Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Text(
            'অ্যাচিভমেন্ট',
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          // View toggle button
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _viewType == 0 ? Icons.grid_view_rounded : Icons.list_rounded,
                color: colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _viewType = _viewType == 0 ? 1 : 0;
                });
              },
              tooltip: _viewType == 0 ? 'গ্রিড ভিউ' : 'লিস্ট ভিউ',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.hindSiliguri(fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: AchievementCategory.values.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AchievementService.getCategoryIcon(category), size: 16),
                const SizedBox(width: 6),
                Text(_getCategoryName(category)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(BuildContext context, AchievementCategory category, UserModel user, ColorScheme colorScheme, bool isDark) {
    final achievements = Achievements.byCategory(category);
    final unlockedIds = user.unlockedAchievements;

    // Sort achievements: unlocked first, then by required value
    achievements.sort((a, b) {
      final aUnlocked = unlockedIds.contains(a.id);
      final bUnlocked = unlockedIds.contains(b.id);
      if (aUnlocked != bUnlocked) return aUnlocked ? -1 : 1;
      return a.requiredValue.compareTo(b.requiredValue);
    });

    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'এই ক্যাটাগরিতে কোনো অ্যাচিভমেন্ট নেই',
          style: GoogleFonts.hindSiliguri(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress stats card
          _buildCategoryProgressStats(category, achievements, user, colorScheme, isDark),
          const SizedBox(height: 16),
          // Achievements list or grid
          if (_viewType == 0)
            ...achievements.map((achievement) {
              final isUnlocked = unlockedIds.contains(achievement.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAchievementCard(achievement, isUnlocked, user, colorScheme, isDark),
              );
            }).toList()
          else
            AchievementBadgeGrid(
              achievements: achievements,
              unlockedIds: unlockedIds,
              badgeSize: 80,
              usePerspectiveBadges: true,
              onTap: (achievement) => _showAchievementDetails(context, achievement, user, colorScheme, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressStats(AchievementCategory category, List<Achievement> achievements, UserModel user, ColorScheme colorScheme, bool isDark) {
    final unlockedCount = achievements.where((a) => user.unlockedAchievements.contains(a.id)).length;
    final progress = achievements.isEmpty ? 0.0 : unlockedCount / achievements.length;
    final categoryColor = AchievementService.getCategoryColor(category);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: categoryColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(AchievementService.getCategoryIcon(category), color: categoryColor),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getCategoryName(category),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$unlockedCount/${achievements.length}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% সম্পন্ন',
                style: GoogleFonts.hindSiliguri(
                  color: categoryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, UserModel user, ColorScheme colorScheme, bool isDark) {
    final categoryColor = AchievementService.getCategoryColor(achievement.category);
    final progress = AchievementService.getProgressTowards(achievement, user);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked
                ? categoryColor.withOpacity(0.15)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked ? categoryColor.withOpacity(0.5) : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked ? categoryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                ),
                child: Icon(
                  AchievementService.getCategoryIcon(achievement.category),
                  color: isUnlocked ? categoryColor : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? categoryColor : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                      ),
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(categoryColor.withOpacity(0.7)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: isUnlocked ? Colors.amber : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '+${achievement.xpReward}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.amber[700] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement, UserModel user, ColorScheme colorScheme, bool isDark) {
    final isUnlocked = user.unlockedAchievements.contains(achievement.id);
    final progress = AchievementService.getProgressTowards(achievement, user);
    final categoryColor = AchievementService.getCategoryColor(achievement.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Badge
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? categoryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    boxShadow: isUnlocked
                        ? [BoxShadow(color: categoryColor.withOpacity(0.4), blurRadius: 20)]
                        : null,
                  ),
                  child: Icon(
                    AchievementService.getCategoryIcon(achievement.category),
                    color: isUnlocked ? categoryColor : Colors.grey,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  achievement.title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? categoryColor : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // XP reward
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+${achievement.xpReward} XP',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toInt()}% সম্পন্ন',
                    style: GoogleFonts.hindSiliguri(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnlocked ? categoryColor : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isUnlocked ? 'অসাধারণ!' : 'চেষ্টা চালিয়ে যান',
                      style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.speed:
        return 'গতি';
      case AchievementCategory.accuracy:
        return 'নির্ভুলতা';
      case AchievementCategory.consistency:
        return 'ধারাবাহিকতা';
      case AchievementCategory.lesson:
        return 'লেসন';
      case AchievementCategory.special:
        return 'বিশেষ';
    }
  }
}

class AchievementSummaryWidget extends ConsumerWidget {
  final int maxToShow;

  const AchievementSummaryWidget({
    super.key,
    this.maxToShow = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const SizedBox.shrink();

    final unlockedIds = user.unlockedAchievements;
    final unlockedAchievements = unlockedIds
        .map((id) => Achievements.getById(id))
        .where((a) => a != null)
        .cast<Achievement>()
        .toList();

    final totalAchievements = Achievements.all.length;
    final progressPercentage = totalAchievements > 0
        ? (unlockedAchievements.length / totalAchievements) * 100
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'অ্যাচিভমেন্ট',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${unlockedAchievements.length}/$totalAchievements',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progressPercentage.toStringAsFixed(0)}% সম্পন্ন',
                style: GoogleFonts.hindSiliguri(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (unlockedAchievements.isNotEmpty)
                AchievementBadgeGrid(
                  achievements: unlockedAchievements.take(maxToShow).toList(),
                  unlockedIds: unlockedIds,
                  badgeSize: 60,
                  spacing: 8,
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'এখনও কোনো অ্যাচিভমেন্ট আনলক হয়নি',
                      style: GoogleFonts.hindSiliguri(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                    );
                  },
                  icon: const Icon(Icons.emoji_events_rounded),
                  label: Text('সব দেখুন', style: GoogleFonts.hindSiliguri()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
