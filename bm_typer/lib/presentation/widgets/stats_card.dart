import 'package:flutter/material.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/constants/app_text_styles.dart';

class StatsCard extends StatelessWidget {
  final String value;
  final String label;

  const StatsCard({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? Colors.grey.shade800 : AppColors.backgroundLegacy;
    final shadowColor = isDarkMode ? Colors.black : Colors.black;
    final shadowOpacity = isDarkMode ? 0.3 : 0.05;
    final textColor = isDarkMode ? Colors.white : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(shadowOpacity),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.statValue.copyWith(
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.statLabel.copyWith(
              color: textColor != null ? textColor.withOpacity(0.8) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsDisplay extends StatelessWidget {
  final int wpm;
  final int accuracy;
  final int repsCompleted;
  final int totalReps;
  final bool showReps;

  const StatsDisplay({
    super.key,
    required this.wpm,
    required this.accuracy,
    this.repsCompleted = 0,
    this.totalReps = 0,
    this.showReps = false,
  });

  // Translate labels to Bengali
  String _getBengaliLabel(String englishLabel) {
    switch (englishLabel) {
      case 'WPM':
        return 'শব্দ/মিনিট';
      case 'Accuracy':
        return 'নির্ভুলতা';
      case 'Repetitions':
        return 'পুনরাবৃত্তি';
      default:
        return englishLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;

        final stats = [
          StatsCard(
            value: wpm.toString(),
            label: _getBengaliLabel('WPM'),
          ),
          StatsCard(
            value: '$accuracy%',
            label: _getBengaliLabel('Accuracy'),
          ),
          if (showReps)
            StatsCard(
              value: '$repsCompleted/$totalReps',
              label: _getBengaliLabel('Repetitions'),
            ),
        ];

        if (isWide) {
          return Row(
            children: stats
                .map((stat) => Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: stat,
                    )))
                .toList(),
          );
        } else {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceEvenly,
            children: stats,
          );
        }
      },
    );
  }
}
