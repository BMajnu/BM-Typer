import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view achievements')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: Icon(_viewType == 0 ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _viewType = _viewType == 0 ? 1 : 0;
              });
            },
            tooltip:
                _viewType == 0 ? 'Switch to Grid View' : 'Switch to List View',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: AchievementCategory.values.map((category) {
            return Tab(
              text: _getCategoryName(category),
              icon: Icon(AchievementService.getCategoryIcon(category)),
            );
          }).toList(),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: AchievementCategory.values.map((category) {
          return _buildCategoryTab(context, category, user);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(
      BuildContext context, AchievementCategory category, UserModel user) {
    final achievements = Achievements.byCategory(category);
    final unlockedIds = user.unlockedAchievements;

    // Sort achievements: unlocked first, then by required value
    achievements.sort((a, b) {
      // First by unlock status
      final aUnlocked = unlockedIds.contains(a.id);
      final bUnlocked = unlockedIds.contains(b.id);

      if (aUnlocked != bUnlocked) {
        return aUnlocked ? -1 : 1;
      }

      // Then by required value
      return a.requiredValue.compareTo(b.requiredValue);
    });

    if (achievements.isEmpty) {
      return const Center(child: Text('No achievements in this category'));
    }

    // Choose view type based on the toggle
    if (_viewType == 0) {
      // List View
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final isUnlocked = unlockedIds.contains(achievement.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AchievementCard(
              achievement: achievement,
              user: user,
              isUnlocked: isUnlocked,
            ),
          );
        },
      );
    } else {
      // Grid View
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress stats for this category
            _buildCategoryProgressStats(category, achievements, user),
            const SizedBox(height: 16),
            // Badge grid
            AchievementBadgeGrid(
              achievements: achievements,
              unlockedIds: unlockedIds,
              badgeSize: 80,
              usePerspectiveBadges: true,
              onTap: (achievement) =>
                  _showAchievementDetails(context, achievement, user),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCategoryProgressStats(AchievementCategory category,
      List<Achievement> achievements, UserModel user) {
    final unlockedCount = achievements
        .where((a) => user.unlockedAchievements.contains(a.id))
        .length;
    final progress =
        achievements.isEmpty ? 0.0 : unlockedCount / achievements.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      AchievementService.getCategoryIcon(category),
                      color: AchievementService.getCategoryColor(category),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryName(category),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$unlockedCount/${achievements.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AchievementService.getCategoryColor(category),
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% Complete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(
      BuildContext context, Achievement achievement, UserModel user) {
    final isUnlocked = user.unlockedAchievements.contains(achievement.id);
    final progress = AchievementService.getProgressTowards(achievement, user);
    final color = AchievementService.getCategoryColor(achievement.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Badge with animation
            isUnlocked
                ? AchievementBadge(
                    achievement: achievement,
                    size: 120,
                    isUnlocked: true,
                    showShine: true,
                    showAnimation: true,
                  )
                : PerspectiveBadge(
                    achievement: achievement,
                    size: 120,
                    isUnlocked: false,
                  ),
            const SizedBox(height: 24),
            // Achievement details
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'XP Reward: +${achievement.xpReward}',
              style: TextStyle(
                fontSize: 16,
                color: isUnlocked ? Colors.amber[700] : Colors.grey[600],
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 24),
            // Progress indicator if not unlocked
            if (!isUnlocked) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withOpacity(0.7),
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: isUnlocked ? color : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text(isUnlocked ? 'Awesome!' : 'Keep Working'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.speed:
        return 'Speed';
      case AchievementCategory.accuracy:
        return 'Accuracy';
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.lesson:
        return 'Lessons';
      case AchievementCategory.special:
        return 'Special';
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

    if (user == null) {
      return const SizedBox.shrink();
    }

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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${unlockedAchievements.length}/$totalAchievements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${progressPercentage.toStringAsFixed(0)}% Complete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Display a grid of badges for the most recent achievements
            if (unlockedAchievements.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final displayCount =
                      constraints.maxWidth > 500 ? maxToShow * 2 : maxToShow;
                  final recentAchievements =
                      unlockedAchievements.length <= displayCount
                          ? unlockedAchievements
                          : unlockedAchievements.sublist(0, displayCount);

                  return AchievementBadgeGrid(
                    achievements: recentAchievements,
                    unlockedIds: unlockedIds,
                    badgeSize: 60,
                    spacing: 8,
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No achievements unlocked yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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
                    MaterialPageRoute(
                        builder: (context) => const AchievementsScreen()),
                  );
                },
                icon: const Icon(Icons.emoji_events),
                label: const Text('View All'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
