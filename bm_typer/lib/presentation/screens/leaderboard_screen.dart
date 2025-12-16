import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/models/leaderboard_entry_model.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/data/local_lesson_data.dart';

final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, String?>((ref, lessonId) async {
  await LeaderboardService.initialize();
  return LeaderboardService.getTopEntries(lessonId: lessonId);
});

final userRankProvider =
    FutureProvider.autoDispose.family<int, String>((ref, userId) async {
  await LeaderboardService.initialize();
  return LeaderboardService.getUserRank(userId);
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLessonId;
  bool _isGeneratingMockData = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final leaderboardData = ref.watch(leaderboardProvider(_selectedLessonId));
    final userRankAsync = currentUser != null
        ? ref.watch(userRankProvider(currentUser.id))
        : null;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f0f1a)]
                : [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surface, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(context, colorScheme, isDark, currentUser),
              
              // Tab Bar
              _buildTabBar(colorScheme, isDark),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardTab(leaderboardData, currentUser, userRankAsync, colorScheme, isDark),
                    _buildLessonSelectionTab(colorScheme, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, bool isDark, UserModel? currentUser) {
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
            'লিডারবোর্ড',
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
            onPressed: () {
              ref.invalidate(leaderboardProvider);
              if (currentUser != null) {
                ref.invalidate(userRankProvider(currentUser.id));
              }
            },
          ),
          if (currentUser != null)
            _isGeneratingMockData
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: Icon(Icons.science_rounded, color: colorScheme.secondary),
                    onPressed: _generateMockData,
                    tooltip: 'টেস্ট ডেটা তৈরি',
                  ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.hindSiliguri(),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'সার্বিক র‌্যাংকিং'),
          Tab(text: 'লেসন অনুযায়ী'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(
    AsyncValue<List<LeaderboardEntry>> leaderboardData,
    UserModel? currentUser,
    AsyncValue<int>? userRankAsync,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return leaderboardData.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(isDark, colorScheme);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User's Rank Card
              if (currentUser != null)
                _buildUserRankCard(currentUser, userRankAsync, colorScheme, isDark),
              
              const SizedBox(height: 20),
              
              // Podium for Top 3
              if (entries.length >= 3) _buildPodium(entries.take(3).toList(), colorScheme, isDark),
              
              const SizedBox(height: 24),
              
              // Rest of the leaderboard
              _buildRankList(entries.skip(3).toList(), currentUser, colorScheme, isDark),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('লোড হচ্ছে...', style: GoogleFonts.hindSiliguri(color: isDark ? Colors.white60 : Colors.black54)),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Text('ত্রুটি: $error', style: GoogleFonts.hindSiliguri(color: Colors.red)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_rounded, size: 64, color: colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'এখনও কোনো এন্ট্রি নেই',
            style: GoogleFonts.hindSiliguri(fontSize: 18, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'প্রথম হতে চান? লেসন সম্পন্ন করুন!',
            style: GoogleFonts.hindSiliguri(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(UserModel user, AsyncValue<int>? userRankAsync, ColorScheme colorScheme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary.withOpacity(0.2), colorScheme.secondary.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'আপনার অবস্থান',
                      style: GoogleFonts.hindSiliguri(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)),
                    ),
                    userRankAsync?.when(
                      data: (rank) => Text(
                        rank > 0 ? '#$rank' : 'র‌্যাংক করা হয়নি',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                      loading: () => Text('লোড হচ্ছে...', style: GoogleFonts.hindSiliguri()),
                      error: (_, __) => Text('ত্রুটি', style: GoogleFonts.hindSiliguri(color: Colors.red)),
                    ) ?? Text('র‌্যাংক করা হয়নি', style: GoogleFonts.hindSiliguri()),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user.highestWpm.toStringAsFixed(0)} WPM',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  Text(
                    'সর্বোচ্চ',
                    style: GoogleFonts.hindSiliguri(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3, ColorScheme colorScheme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (top3.length > 1) _buildPodiumItem(top3[1], 2, 100, colorScheme, isDark),
        const SizedBox(width: 8),
        // 1st Place
        _buildPodiumItem(top3[0], 1, 130, colorScheme, isDark),
        const SizedBox(width: 8),
        // 3rd Place
        if (top3.length > 2) _buildPodiumItem(top3[2], 3, 80, colorScheme, isDark),
      ],
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int rank, double height, ColorScheme colorScheme, bool isDark) {
    Color podiumColor;
    Color medalColor;
    IconData medalIcon;
    
    switch (rank) {
      case 1:
        podiumColor = Colors.amber;
        medalColor = Colors.amber;
        medalIcon = Icons.emoji_events_rounded;
        break;
      case 2:
        podiumColor = Colors.grey.shade300;
        medalColor = Colors.grey.shade400;
        medalIcon = Icons.workspace_premium_rounded;
        break;
      default:
        podiumColor = Colors.brown.shade300;
        medalColor = Colors.brown.shade400;
        medalIcon = Icons.military_tech_rounded;
    }

    return Column(
      children: [
        // Medal
        Icon(medalIcon, color: medalColor, size: rank == 1 ? 32 : 24),
        const SizedBox(height: 8),
        // Avatar
        Container(
          width: rank == 1 ? 64 : 52,
          height: rank == 1 ? 64 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getAvatarColor(entry.userName),
            border: Border.all(color: podiumColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: podiumColor.withOpacity(0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Text(
              entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontSize: rank == 1 ? 26 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.userName,
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // WPM
        Text(
          '${entry.wpm.toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            fontSize: rank == 1 ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: podiumColor,
          ),
        ),
        Text(
          'WPM',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        // Podium Stand
        Container(
          width: rank == 1 ? 90 : 70,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [podiumColor, podiumColor.withOpacity(0.6)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankList(List<LeaderboardEntry> entries, UserModel? currentUser, ColorScheme colorScheme, bool isDark) {
    if (entries.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'অন্যান্য র‌্যাংকিং',
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.asMap().entries.map((e) {
          final index = e.key;
          final entry = e.value;
          final rank = index + 4; // Starting from 4th place
          final isCurrentUser = currentUser != null && entry.userId == currentUser.id;
          
          return _buildRankTile(entry, rank, isCurrentUser, colorScheme, isDark);
        }),
      ],
    );
  }

  Widget _buildRankTile(LeaderboardEntry entry, int rank, bool isCurrentUser, ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primary.withOpacity(0.15)
            : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser ? Border.all(color: colorScheme.primary.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(entry.userName),
            ),
            child: Center(
              child: Text(
                entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: GoogleFonts.hindSiliguri(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _getTimeAgo(entry.timestamp),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.wpm.toStringAsFixed(0)} WPM',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                '${entry.accuracy.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(fontSize: 11, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSelectionTab(ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLessonTile(
            title: 'সার্বিক লিডারবোর্ড',
            subtitle: 'সব লেসন একত্রে',
            lessonId: null,
            isSelected: _selectedLessonId == null,
            colorScheme: colorScheme,
            isDark: isDark,
            icon: Icons.leaderboard_rounded,
          );
        } else {
          final lesson = lessons[index - 1];
          return _buildLessonTile(
            title: lesson.title,
            subtitle: lesson.description,
            lessonId: lesson.title,
            isSelected: _selectedLessonId == lesson.title,
            colorScheme: colorScheme,
            isDark: isDark,
            icon: Icons.school_rounded,
          );
        }
      },
    );
  }

  Widget _buildLessonTile({
    required String title,
    required String subtitle,
    required String? lessonId,
    required bool isSelected,
    required ColorScheme colorScheme,
    required bool isDark,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.15)
            : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: colorScheme.primary) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : colorScheme.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.hindSiliguri(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
            : Icon(Icons.arrow_forward_ios_rounded, size: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
        onTap: () {
          setState(() {
            _selectedLessonId = lessonId;
            _tabController.animateTo(0);
          });
        },
      ),
    );
  }

  Future<void> _generateMockData() async {
    setState(() => _isGeneratingMockData = true);
    try {
      await LeaderboardService.generateMockData(20);
      ref.invalidate(leaderboardProvider);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.invalidate(userRankProvider(currentUser.id));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('টেস্ট ডেটা তৈরি হয়েছে!', style: GoogleFonts.hindSiliguri()),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      setState(() => _isGeneratingMockData = false);
    }
  }

  Color _getAvatarColor(String name) {
    final colorIndex = name.codeUnits.fold<int>(0, (prev, element) => prev + element) % Colors.primaries.length;
    return Colors.primaries[colorIndex];
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 7) return '${timestamp.month}/${timestamp.day}';
    if (difference.inDays > 0) return '${difference.inDays} দিন আগে';
    if (difference.inHours > 0) return '${difference.inHours} ঘন্টা আগে';
    if (difference.inMinutes > 0) return '${difference.inMinutes} মিনিট আগে';
    return 'এইমাত্র';
  }
}
