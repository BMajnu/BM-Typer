import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/services/achievement_service.dart';

/// আধুনিক অ্যাচিভমেন্ট কার্ড
/// 
/// গ্র্যাডিয়েন্ট বর্ডার এবং প্রগ্রেস ইন্ডিকেটর সহ।
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final UserModel user;
  final bool isUnlocked;
  final bool showProgress;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.user,
    required this.isUnlocked,
    this.showProgress = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AchievementService.getCategoryColor(achievement.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(isDark ? 0.2 : 0.1),
                    color.withOpacity(isDark ? 0.05 : 0.02),
                  ],
                )
              : null,
          color: isUnlocked
              ? null
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isUnlocked
                ? color.withOpacity(0.5)
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: isUnlocked ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, color),
              SizedBox(height: AppSpacing.sm),
              _buildContent(context),
              if (showProgress && !isUnlocked) ...[
                SizedBox(height: AppSpacing.md),
                _buildProgressIndicator(context, color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        // Icon container with gradient
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  )
                : null,
            color: isUnlocked ? null : (isDark ? Colors.grey[700] : Colors.grey[300]),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            achievement.icon,
            color: isUnlocked ? Colors.white : Colors.grey[500],
            size: AppSizes.iconMd,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        
        // Title and XP
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: AppTypography.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? color : null,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: (isUnlocked ? AppColors.xpGold : Colors.grey)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: isUnlocked ? AppColors.xpGold : Colors.grey[500],
                    ),
                    SizedBox(width: AppSpacing.xxs),
                    Text(
                      '+${achievement.xpReward} XP',
                      style: AppTypography.labelSmall(context).copyWith(
                        color: isUnlocked ? AppColors.xpGold : Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Check icon for unlocked
        if (isUnlocked)
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: AppSizes.iconSm,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Text(
      achievement.description,
      style: AppTypography.bodySmall(context).copyWith(
        color: isUnlocked ? null : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressIndicator(BuildContext context, Color color) {
    final progress = AchievementService.getProgressTowards(achievement, user);
    final progressPercent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'অগ্রগতি',
              style: AppTypography.labelSmall(context),
            ),
            Text(
              '$progressPercent%',
              style: AppTypography.labelSmall(context).copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// অ্যাচিভমেন্ট আনলক অ্যানিমেশন ডায়ালগ
class AchievementUnlockAnimation extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onComplete;

  const AchievementUnlockAnimation({
    super.key,
    required this.achievement,
    this.onComplete,
  });

  @override
  State<AchievementUnlockAnimation> createState() =>
      _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<AchievementUnlockAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final color = AchievementService.getCategoryColor(achievement.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 320,
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  color.withOpacity(0.3),
                                  color.withOpacity(0.1),
                                ]
                              : [
                                  Colors.white.withOpacity(0.95),
                                  color.withOpacity(0.1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        border: Border.all(
                          color: color.withOpacity(0.5),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trophy icon
                          Container(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [color, color.withOpacity(0.7)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              achievement.icon,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg),
                          
                          // Text
                          Text(
                            'অভিনন্দন! 🎉',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            achievement.title,
                            style: AppTypography.titleMedium(context).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            achievement.description,
                            style: AppTypography.bodySmall(context),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          
                          // XP Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.xpBarGradient,
                              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.xpGold.withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  '+${achievement.xpReward} XP',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSpacing.xl),
                          
                          // Button
                          FilledButton(
                            onPressed: widget.onComplete,
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xxl,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            child: Text(
                              'চমৎকার! 👏',
                              style: GoogleFonts.notoSansBengali(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
