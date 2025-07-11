import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/presentation/widgets/xp_progress_bar.dart';

class LevelDetailsScreen extends ConsumerWidget {
  const LevelDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Level & XP Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const XPProgressBar(isExpanded: true),
            const SizedBox(height: 24),
            _buildLevelingInfo(context, user),
            const SizedBox(height: 24),
            _buildXPGains(context),
            const SizedBox(height: 24),
            _buildUpcomingLevels(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelingInfo(BuildContext context, UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Leveling Works',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Earn XP by completing typing exercises and lessons, maintaining daily practice streaks, and unlocking achievements.',
            ),
            const SizedBox(height: 8),
            Text(
              'Current Level: ${user.level}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Current XP: ${user.xpPoints}'),
            Text('XP to Next Level: ${user.xpToNextLevel}'),
            const SizedBox(height: 16),
            const Text(
              'XP Earning Activities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildXPInfoItem(
              context,
              icon: Icons.check_circle,
              label: 'Complete Exercise',
              xp: '3-5 XP',
            ),
            _buildXPInfoItem(
              context,
              icon: Icons.book,
              label: 'Complete Lesson',
              xp: '20 XP',
            ),
            _buildXPInfoItem(
              context,
              icon: Icons.local_fire_department,
              label: 'Daily Streak Bonus',
              xp: '5 XP per day (multiplier for longer streaks)',
            ),
            _buildXPInfoItem(
              context,
              icon: Icons.emoji_events,
              label: 'Achievement Unlocked',
              xp: '10-500 XP (varies by achievement)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String xp,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLegacy),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              xp,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPGains(BuildContext context) {
    // This would ideally be connected to a real XP history in the user model
    final mockGains = [
      {'activity': 'Completed Exercise', 'amount': 5, 'time': '10 minutes ago'},
      {'activity': 'Daily Streak (5 days)', 'amount': 25, 'time': '1 hour ago'},
      {
        'activity': 'Achievement: Fast Fingers',
        'amount': 50,
        'time': '2 hours ago'
      },
      {
        'activity': 'Completed Lesson: Basic Home Row',
        'amount': 20,
        'time': '1 day ago'
      },
      {'activity': 'Completed Exercise', 'amount': 3, 'time': '2 days ago'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent XP Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockGains.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final gain = mockGains[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Text(
                    '+${gain['amount']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(gain['activity'] as String),
                subtitle: Text(gain['time'] as String),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show details of this XP gain
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingLevels(BuildContext context, UserModel user) {
    final currentLevel = user.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Levels',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              final levelNumber = currentLevel + index + 1;
              final xpRequired = UserModel.xpRequiredForLevel(levelNumber);
              final levelTitle = _getLevelTitle(levelNumber);
              final isNextLevel = index == 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getLevelColor(levelNumber),
                  child: Text(
                    '$levelNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      levelTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isNextLevel)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLegacy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLegacy,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text('Required XP: $xpRequired'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show level details
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(int level) {
    if (level < 5) {
      return Colors.green;
    } else if (level < 10) {
      return Colors.blue;
    } else if (level < 20) {
      return Colors.purple;
    } else if (level < 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getLevelTitle(int level) {
    if (level < 3) {
      return 'Beginner';
    } else if (level < 6) {
      return 'Apprentice';
    } else if (level < 10) {
      return 'Skilled Typist';
    } else if (level < 15) {
      return 'Expert Typist';
    } else if (level < 20) {
      return 'Master Typist';
    } else if (level < 30) {
      return 'Grandmaster';
    } else {
      return 'Legendary Typist';
    }
  }
}
