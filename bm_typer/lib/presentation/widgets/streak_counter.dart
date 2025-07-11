import 'package:flutter/material.dart';
import 'package:bm_typer/core/constants/app_colors.dart';

class StreakCounter extends StatelessWidget {
  final int streak;
  final bool isActive;
  final bool isExpanded;

  const StreakCounter({
    super.key,
    required this.streak,
    required this.isActive,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final streakCount = streak;

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
              AppColors.primaryLegacy,
              AppColors.primaryLegacy.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: isExpanded
            ? _buildExpandedView(context, streakCount)
            : _buildCompactView(streakCount),
      ),
    );
  }

  Widget _buildCompactView(int streakCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_fire_department,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          '$streakCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(BuildContext context, int streakCount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Streak',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$streakCount ${streakCount == 1 ? 'day' : 'days'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _getStreakMessage(streakCount),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        _buildStreakCalendarIndicator(context, streakCount),
      ],
    );
  }

  Widget _buildStreakCalendarIndicator(BuildContext context, int streakCount) {
    // Show up to 7 days of streak history
    final daysToShow = 7;
    final maxStreak = streakCount > daysToShow ? daysToShow : streakCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(daysToShow, (index) {
        final dayIndex = daysToShow - 1 - index;
        final isActive = dayIndex < maxStreak;
        final isToday = dayIndex == 0;

        return Column(
          children: [
            Container(
              width: 8,
              height: 20,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getDayLetter(dayIndex),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  String _getDayLetter(int dayIndex) {
    final now = DateTime.now();
    final day = now.subtract(Duration(days: dayIndex));
    final weekday = day.weekday;

    switch (weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }

  String _getStreakMessage(int streakCount) {
    if (streakCount == 0) {
      return "Practice today to start your streak!";
    } else if (streakCount == 1) {
      return "Great start! Come back tomorrow to continue your streak.";
    } else if (streakCount < 5) {
      return "Keep it up! You're building a habit.";
    } else if (streakCount < 10) {
      return "Impressive dedication! You're making great progress.";
    } else if (streakCount < 30) {
      return "Amazing streak! Your typing skills are improving fast!";
    } else {
      return "Phenomenal dedication! You're a typing champion!";
    }
  }
}
