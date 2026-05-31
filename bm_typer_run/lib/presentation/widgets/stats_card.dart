import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bm_typer/core/theme/theme.dart';

/// আধুনিক স্ট্যাটস কার্ড উইজেট
/// 
/// গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড এবং অ্যানিমেটেড নম্বর সহ।
class StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? accentColor;
  final bool compact;

  const StatsCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final effectiveAccentColor = accentColor ?? colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? AppSizes.statsCardMinWidth : 100,
        maxWidth: AppSizes.statsCardMaxWidth,
      ),
      padding: EdgeInsets.symmetric(
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  effectiveAccentColor.withOpacity(0.15),
                  effectiveAccentColor.withOpacity(0.05),
                ]
              : [
                  effectiveAccentColor.withOpacity(0.08),
                  effectiveAccentColor.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: effectiveAccentColor.withOpacity(isDarkMode ? 0.3 : 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveAccentColor.withOpacity(isDarkMode ? 0.15 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: effectiveAccentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              ),
              child: Icon(
                icon,
                size: compact ? AppSizes.iconSm : AppSizes.iconMd,
                color: effectiveAccentColor,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
          ],
          Text(
            value,
            style: AppTypography.statNumber(context).copyWith(
              fontSize: compact ? 24 : 36,
              color: effectiveAccentColor,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.statLabel(context).copyWith(
              fontSize: compact ? 10 : 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// স্ট্যাটস ডিসপ্লে - WPM, Accuracy, Reps সহ
class StatsDisplay extends StatelessWidget {
  final int wpm;
  final int accuracy;
  final int repsCompleted;
  final int totalReps;
  final bool showReps;
  final bool compact;

  const StatsDisplay({
    super.key,
    required this.wpm,
    required this.accuracy,
    this.repsCompleted = 0,
    this.totalReps = 0,
    this.showReps = false,
    this.compact = false,
  });

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 400;

        final stats = [
          StatsCard(
            value: wpm.toString(),
            label: _getBengaliLabel('WPM'),
            icon: Icons.speed_rounded,
            accentColor: AppColors.secondary,
            compact: compact,
          ),
          StatsCard(
            value: '$accuracy%',
            label: _getBengaliLabel('Accuracy'),
            icon: Icons.check_circle_outline_rounded,
            accentColor: accuracy >= 90 
                ? AppColors.success 
                : accuracy >= 70 
                    ? AppColors.warning 
                    : AppColors.error,
            compact: compact,
          ),
          if (showReps)
            StatsCard(
              value: '$repsCompleted/$totalReps',
              label: _getBengaliLabel('Repetitions'),
              icon: Icons.repeat_rounded,
              accentColor: colorScheme.tertiary,
              compact: compact,
            ),
        ];

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: stats
                .map((stat) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: stat,
                    ))
                .toList(),
          );
        } else {
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: stats,
          );
        }
      },
    );
  }
}

/// অ্যানিমেটেড কাউন্টার উইজেট
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String? suffix;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, child) {
        return Text(
          '$animatedValue${suffix ?? ''}',
          style: style ?? AppTypography.statNumber(context),
        );
      },
    );
  }
}

/// মিনি স্ট্যাটস চিপ
class MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const MiniStatChip({
    super.key,
    required this.icon,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: effectiveColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: effectiveColor,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.labelMedium(context).copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
