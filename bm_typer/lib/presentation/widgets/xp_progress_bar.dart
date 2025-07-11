import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/models/user_model.dart';

class XPProgressBar extends ConsumerWidget {
  final bool isExpanded;

  const XPProgressBar({
    super.key,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    final level = user.level;
    final nextLevelProgress = user.nextLevelProgress;
    final xpToNextLevel = user.xpToNextLevel;
    final currentLevelXp =
        user.xpPoints - (xpToNextLevel - UserModel.xpRequiredForLevel(level));

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade800,
              Colors.indigo.shade600,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: isExpanded
            ? _buildExpandedView(context, level, nextLevelProgress,
                currentLevelXp, xpToNextLevel)
            : _buildCompactView(
                level, nextLevelProgress, currentLevelXp, xpToNextLevel),
      ),
    );
  }

  Widget _buildCompactView(
    int level,
    double nextLevelProgress,
    int currentLevelXp,
    int xpToNextLevel,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLevelBadge(level),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildProgressBar(nextLevelProgress),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedView(
    BuildContext context,
    int level,
    double nextLevelProgress,
    int currentLevelXp,
    int xpToNextLevel,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            _buildLevelBadge(level),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Level $level Typist',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getLevelTitle(level),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        _buildProgressBar(nextLevelProgress),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentLevelXp XP',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
            Text(
              '$xpToNextLevel XP to next level',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _getLevelDescription(level),
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: progress * 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber,
                    Colors.orange,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getLevelColor(level),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
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

  String _getLevelDescription(int level) {
    if (level < 3) {
      return 'Keep practicing to improve your typing skills and earn XP. Complete lessons and maintain your daily streak for bonus XP!';
    } else if (level < 6) {
      return 'Your consistency is paying off! Continue practicing regularly to unlock new achievements and rise through the ranks.';
    } else if (level < 10) {
      return 'You\'re becoming proficient! Focus on improving your accuracy and speed to earn more XP and climb to higher levels.';
    } else if (level < 15) {
      return 'Impressive progress! You\'re among the top typists. Challenge yourself with more difficult exercises to continue improving.';
    } else if (level < 20) {
      return 'Your dedication has made you a master typist! Few reach this level of expertise. Keep pushing your limits!';
    } else if (level < 30) {
      return 'Extraordinary typing skills! You\'ve mastered the art of typing. Share your knowledge and help others improve.';
    } else {
      return 'You\'ve achieved legendary status! Your typing prowess is unmatched. Continue to set records and inspire others.';
    }
  }
}
