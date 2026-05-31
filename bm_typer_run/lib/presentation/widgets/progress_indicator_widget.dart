import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/data/local_lesson_data.dart';

/// আধুনিক লেসন প্রগ্রেস ইন্ডিকেটর
/// 
/// সার্কুলার প্রগ্রেস এবং গ্রেডিয়েন্ট সহ।
class LessonProgressIndicator extends ConsumerWidget {
  const LessonProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final completedLessons = user.completedLessons;
    final totalLessons = lessons.length;
    final completionPercentage = user.getCompletionPercentage(totalLessons);

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.primary.withOpacity(0.05),
                ]
              : [
                  colorScheme.primary.withOpacity(0.08),
                  colorScheme.primary.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Circular progress
          _CircularProgressWidget(
            progress: completionPercentage / 100,
            size: 80,
            strokeWidth: 8,
            primaryColor: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${completionPercentage.toStringAsFixed(0)}%',
                  style: AppTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'লেসন প্রগ্রেস',
                  style: AppTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '${completedLessons.length}টি লেসন সম্পন্ন / মোট ${totalLessons}টি',
                  style: AppTypography.bodySmall(context),
                ),
                SizedBox(height: AppSpacing.sm),
                
                // Linear progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (completionPercentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(3),
                      ),
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
}

/// সার্কুলার প্রগ্রেস উইজেট
class _CircularProgressWidget extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color primaryColor;
  final Color backgroundColor;
  final Widget? child;

  const _CircularProgressWidget({
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.primaryColor,
    required this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: 1.0,
              strokeWidth: strokeWidth,
              color: backgroundColor,
            ),
          ),
          // Progress circle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: AppDurations.slow,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _CircularProgressPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  color: primaryColor,
                  gradient: AppColors.primaryGradient,
                ),
              );
            },
          ),
          // Child content
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Gradient? gradient;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color;
    }

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// লেসন কমপ্লিশন গ্রিড
class LessonCompletionGrid extends ConsumerWidget {
  const LessonCompletionGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final completedLessons = user.completedLessons;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: AppSizes.iconMd,
                color: colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'লেসন কমপ্লিশন স্ট্যাটাস',
                style: AppTypography.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1,
            ),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final isCompleted = completedLessons.contains(lesson.title);

              return _buildLessonStatusItem(context, index + 1, isCompleted);
            },
          ),
          SizedBox(height: AppSpacing.md),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, 'সম্পন্ন', colorScheme.primary),
              SizedBox(width: AppSpacing.lg),
              _buildLegendItem(context, 'বাকি', colorScheme.surfaceContainerHighest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonStatusItem(BuildContext context, int lessonNumber, bool isCompleted) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedContainer(
      duration: AppDurations.normal,
      decoration: BoxDecoration(
        gradient: isCompleted
            ? AppColors.successGradient
            : null,
        color: isCompleted ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: AppSizes.iconMd,
              )
            : Text(
                '$lessonNumber',
                style: AppTypography.labelMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall(context),
        ),
      ],
    );
  }
}
