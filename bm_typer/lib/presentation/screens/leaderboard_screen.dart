import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/leaderboard_entry_model.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
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
    final leaderboardData = ref.watch(
      leaderboardProvider(_selectedLessonId),
    );

    final userRankAsync = currentUser != null
        ? ref.watch(userRankProvider(currentUser.id))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overall Rankings'),
            Tab(text: 'By Lesson'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(leaderboardProvider);
              if (currentUser != null) {
                ref.invalidate(userRankProvider(currentUser.id));
              }
            },
            tooltip: 'Refresh',
          ),
          if (currentUser != null) ...[
            _isGeneratingMockData
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.science),
                    onPressed: _generateMockData,
                    tooltip: 'Generate Sample Data',
                  ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overall Leaderboard
          _buildLeaderboardTab(leaderboardData, currentUser, userRankAsync),

          // Tab 2: Lesson-specific leaderboards
          _buildLessonSelectionTab(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(
    AsyncValue<List<LeaderboardEntry>> leaderboardData,
    UserModel? currentUser,
    AsyncValue<int>? userRankAsync,
  ) {
    return Column(
      children: [
        // User's rank card (if logged in)
        if (currentUser != null) _buildUserRankCard(currentUser, userRankAsync),

        // Leaderboard title and filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedLessonId == null
                    ? 'Top Typists'
                    : 'Top Typists - ${_getLessonName(_selectedLessonId!)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_selectedLessonId != null)
                TextButton(
                  onPressed: () => setState(() {
                    _selectedLessonId = null;
                  }),
                  child: const Text('Show All'),
                ),
            ],
          ),
        ),

        // Leaderboard entries list
        Expanded(
          child: leaderboardData.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    'No entries yet. Be the first to join the leaderboard!',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isCurrentUser =
                      currentUser != null && entry.userId == currentUser.id;

                  return _buildLeaderboardEntryTile(
                    entry: entry,
                    rank: index + 1,
                    isCurrentUser: isCurrentUser,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading leaderboard: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRankCard(UserModel user, AsyncValue<int>? userRankAsync) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      color: AppColors.primaryLegacy.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryLegacy.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLegacy,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Position',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    userRankAsync?.when(
                          data: (rank) => Text(
                            rank > 0 ? 'Rank #$rank' : 'Not ranked yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          loading: () => const Text('Loading...'),
                          error: (_, __) => const Text('Error getting rank'),
                        ) ??
                        const Text('Not ranked yet'),
                  ],
                ),
                const Spacer(),
                Text(
                  'Best: ${user.highestWpm.toStringAsFixed(1)} WPM',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardEntryTile({
    required LeaderboardEntry entry,
    required int rank,
    required bool isCurrentUser,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: isCurrentUser ? AppColors.primaryLegacy.withOpacity(0.1) : null,
      child: ListTile(
        leading: _buildRankBadge(rank),
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _getAvatarColor(entry.userName),
              child: Text(
                entry.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.userName,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.wpm.toStringAsFixed(1)} WPM',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${entry.accuracy.toStringAsFixed(1)}% acc',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLegacy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lv ${entry.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${_getTimeAgo(entry.timestamp)} • ${entry.lessonId != null ? _getLessonName(entry.lessonId!) : 'Overall'}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;

    switch (rank) {
      case 1:
        color = Colors.amber; // Gold
        break;
      case 2:
        color = Colors.grey.shade300; // Silver
        break;
      case 3:
        color = Colors.brown.shade300; // Bronze
        break;
      default:
        color = Colors.grey.shade100; // Default
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildLessonSelectionTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: lessons.length + 1, // +1 for "Overall" option
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLessonTile(
            title: 'Overall Leaderboard',
            subtitle: 'All lessons combined',
            lessonId: null,
            isSelected: _selectedLessonId == null,
          );
        } else {
          final lesson = lessons[index - 1];
          return _buildLessonTile(
            title: lesson.title,
            subtitle: lesson.description,
            lessonId: lesson.title,
            isSelected: _selectedLessonId == lesson.title,
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
  }) {
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? AppColors.primaryLegacy.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.primaryLegacy, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : null,
            color: isSelected ? AppColors.primaryLegacy : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: AppColors.primaryLegacy,
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          setState(() {
            _selectedLessonId = lessonId;
            _tabController.animateTo(0); // Switch to leaderboard tab
          });
        },
      ),
    );
  }

  Future<void> _generateMockData() async {
    setState(() => _isGeneratingMockData = true);

    try {
      await LeaderboardService.generateMockData(20);

      // Refresh the leaderboard
      ref.invalidate(leaderboardProvider);

      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.invalidate(userRankProvider(currentUser.id));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample leaderboard data generated!'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isGeneratingMockData = false);
    }
  }

  String _getLessonName(String lessonId) {
    if (lessonId.startsWith('lesson-')) {
      final index = int.tryParse(lessonId.split('-').last);
      if (index != null && index > 0 && index <= lessons.length) {
        return lessons[index - 1].title;
      }
      return lessonId;
    }

    // Try to find a lesson with matching title
    final matchedLesson = lessons.firstWhere(
      (lesson) => lesson.title == lessonId,
      orElse: () => lessons[0],
    );

    return matchedLesson.title;
  }

  Color _getAvatarColor(String name) {
    // Generate a consistent color based on the name
    final colorIndex = name.codeUnits.fold<int>(
          0,
          (prev, element) => prev + element,
        ) %
        Colors.primaries.length;
    return Colors.primaries[colorIndex];
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.month}/${timestamp.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
